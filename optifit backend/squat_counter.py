import cv2
import mediapipe as mp
import numpy as np
import os
import subprocess
import time
import csv
import collections

mp_drawing = mp.solutions.drawing_utils
mp_pose = mp.solutions.pose

def calculate_angle(a, b, c):
    a, b, c = np.array(a), np.array(b), np.array(c)
    radians = np.arctan2(c[1]-b[1], c[0]-b[0]) - np.arctan2(a[1]-b[1], a[0]-b[0])
    angle = np.abs(radians * 180.0 / np.pi)
    return angle if angle <= 180.0 else 360 - angle

def _get_visibility(lm):
    return getattr(lm, "visibility", 1.0)

def process_squat_video(input_path, output_path, sample_rate=1, log_csv=True):
    """
    Processes the input video, annotates skeleton + debug overlays, writes a H.264 encoded output,
    and returns aggregated squat stats. Defaults are tuned for debugging (sample_rate=1).
    """
    raw_path = output_path.replace('.mp4', '_raw.mp4')
    csv_path = output_path.replace('.mp4', '_angles.csv')

    cap = cv2.VideoCapture(input_path)
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = int(cap.get(cv2.CAP_PROP_FPS)) or 20

    out = cv2.VideoWriter(raw_path, cv2.VideoWriter_fourcc(*'mp4v'), fps, (width, height))

    # State & stats
    rep_count = 0
    squat_stage = None        # 'up' or 'down'
    rep_start_time = None
    rep_durations = []
    rep_min_angle = None
    rep_knees_in = False
    all_rep_issues = []
    latest_rep_feedback = ""
    last_rep_time = None

    frame_count = 0
    angle_history = collections.deque(maxlen=5)  # smoothing window

    # Thresholds (tune these if needed)
    UP_THRESHOLD = 160          # angle considered standing
    START_DOWN_THRESHOLD = 140  # start of descent detection
    DEPTH_THRESHOLD = 100       # angle considered below parallel (deep)
    # margin for knees caving detection in normalized coords
    KNEE_CAVE_MARGIN = 0.03

    # prepare CSV logging
    csv_file = None
    csv_writer = None
    if log_csv:
        csv_file = open(csv_path, mode='w', newline='')
        csv_writer = csv.writer(csv_file)
        csv_writer.writerow([
            "frame", "timestamp", "selected_side", "smooth_angle",
            "stage", "rep_count", "rep_min_angle", "rep_knees_in"
        ])

    with mp_pose.Pose(min_detection_confidence=0.5, min_tracking_confidence=0.5) as pose:
        start_time_global = time.time()
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            # sampling to speed up (set sample_rate=1 while debugging)
            if frame_count % sample_rate != 0:
                frame_count += 1
                out.write(frame)
                continue

            image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            image_rgb.flags.writeable = False
            results = pose.process(image_rgb)
            image_rgb.flags.writeable = True
            image = cv2.cvtColor(image_rgb, cv2.COLOR_RGB2BGR)

            timestamp = time.time() - start_time_global
            selected_side = "none"
            smooth_angle = None

            if results.pose_landmarks:
                lm = results.pose_landmarks.landmark

                # helper to get normalized landmarks by side
                def side_points(side_prefix):
                    # side_prefix: 'LEFT' or 'RIGHT'
                    hip = lm[getattr(mp_pose.PoseLandmark, f"{side_prefix}_HIP").value]
                    knee = lm[getattr(mp_pose.PoseLandmark, f"{side_prefix}_KNEE").value]
                    ankle = lm[getattr(mp_pose.PoseLandmark, f"{side_prefix}_ANKLE").value]
                    return hip, knee, ankle

                # compute both sides' angles + visibility
                left_hip, left_knee, left_ankle = side_points("LEFT")
                right_hip, right_knee, right_ankle = side_points("RIGHT")

                left_vis = _get_visibility(left_hip) + _get_visibility(left_knee) + _get_visibility(left_ankle)
                right_vis = _get_visibility(right_hip) + _get_visibility(right_knee) + _get_visibility(right_ankle)

                left_coords = ([left_hip.x, left_hip.y], [left_knee.x, left_knee.y], [left_ankle.x, left_ankle.y])
                right_coords = ([right_hip.x, right_hip.y], [right_knee.x, right_knee.y], [right_ankle.x, right_ankle.y])

                left_angle = calculate_angle(*left_coords)
                right_angle = calculate_angle(*right_coords)

                # Choose side based on visibility (and fallback to smaller angle if vis close)
                if left_vis >= right_vis:
                    selected_side = "left"
                    chosen_angle = left_angle
                    hip_norm, knee_norm, ankle_norm = left_coords
                    knee_x = left_coords[1][0]
                else:
                    selected_side = "right"
                    chosen_angle = right_angle
                    hip_norm, knee_norm, ankle_norm = right_coords
                    knee_x = right_coords[1][0]

                # smoothing
                angle_history.append(chosen_angle)
                smooth_angle = float(np.mean(angle_history))

                # detect knees caving in for the selected side
                if selected_side == "left":
                    # left: caving inward if knee x is noticeably left of hip and ankle (smaller x)
                    if (knee_norm[0] < hip_norm[0] - KNEE_CAVE_MARGIN) and (knee_norm[0] < ankle_norm[0] - KNEE_CAVE_MARGIN):
                        rep_knees_in = True
                else:
                    # right: caving inward if knee x is noticeably right of hip and ankle (larger x)
                    if (knee_norm[0] > hip_norm[0] + KNEE_CAVE_MARGIN) and (knee_norm[0] > ankle_norm[0] + KNEE_CAVE_MARGIN):
                        rep_knees_in = True

                # Initialize stage if unknown
                if squat_stage is None:
                    squat_stage = "up" if smooth_angle > UP_THRESHOLD else "down"

                # State machine with hysteresis
                if squat_stage == "up":
                    # Look for descent start
                    if smooth_angle < START_DOWN_THRESHOLD:
                        squat_stage = "down"
                        rep_start_time = time.time()
                        rep_min_angle = smooth_angle
                        rep_knees_in = False
                elif squat_stage == "down":
                    # update min angle
                    if rep_min_angle is None or smooth_angle < rep_min_angle:
                        rep_min_angle = smooth_angle
                    # Check if we rose back up past the UP_THRESHOLD -> rep finished
                    if smooth_angle > UP_THRESHOLD:
                        # finalize rep
                        rep_end_time = time.time()
                        duration = rep_end_time - rep_start_time if rep_start_time else 0.0
                        rep_durations.append(duration)
                        # decide issues
                        rep_issues = []
                        feedback_reasons = []
                        if rep_min_angle is None or rep_min_angle > DEPTH_THRESHOLD:
                            rep_issues.append("shallow_depth")
                            feedback_reasons.append("go deeper")
                        if rep_knees_in:
                            rep_issues.append("knees_in")
                            feedback_reasons.append("knees in")
                        all_rep_issues.append(rep_issues)
                        rep_count += 1
                        # feedback
                        latest_rep_feedback = "Good rep" if not feedback_reasons else "Bad rep - " + ", ".join(feedback_reasons)
                        last_rep_time = time.time()
                        # reset per-rep
                        rep_start_time = None
                        rep_min_angle = None
                        rep_knees_in = False
                        squat_stage = "up"

                # draw landmarks + connections
                mp_drawing.draw_landmarks(
                    image,
                    results.pose_landmarks,
                    mp_pose.POSE_CONNECTIONS,
                    mp_drawing.DrawingSpec(color=(245, 117, 66), thickness=2, circle_radius=2),
                    mp_drawing.DrawingSpec(color=(245, 66, 230), thickness=2, circle_radius=2)
                )

                # convert a selected keypoint to pixel coords for text placement
                kp_px = (int(knee_norm[0] * width), int(knee_norm[1] * height))
                cv2.circle(image, kp_px, 6, (0, 255, 255), -1)
                cv2.putText(image, f"{selected_side} knee: {int(smooth_angle)}°",
                            (kp_px[0] + 10, max(20, kp_px[1] - 10)),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 0), 2, cv2.LINE_AA)

            else:
                # No pose detected
                cv2.putText(image, "No pose detected", (15, 80),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0, 0, 255), 2, cv2.LINE_AA)

            # overlay overall debug info
            cv2.putText(image, f"Reps: {rep_count}", (width - 220, 40),
                        cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 200, 0), 3, cv2.LINE_AA)
            if smooth_angle is not None:
                cv2.putText(image, f"Angle: {int(smooth_angle)}", (15, height - 60),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2, cv2.LINE_AA)
            cv2.putText(image, f"Stage: {squat_stage}", (15, height - 30),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, (200, 200, 200), 2, cv2.LINE_AA)
            cv2.putText(image, f"Side: {selected_side}", (200, height - 30),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, (200, 200, 200), 2, cv2.LINE_AA)
            if rep_min_angle is not None:
                cv2.putText(image, f"Min: {int(rep_min_angle)}", (350, height - 30),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.8, (180, 180, 180), 2, cv2.LINE_AA)
            # blinking rep feedback
            if last_rep_time is not None:
                elapsed = time.time() - last_rep_time
                if elapsed < 0.9:
                    if latest_rep_feedback:
                        color = (0, 200, 0) if latest_rep_feedback.startswith("Good rep") else (0, 0, 255)
                        cv2.putText(image, latest_rep_feedback, (15, 40),
                                    cv2.FONT_HERSHEY_SIMPLEX, 1.0, color, 3, cv2.LINE_AA)

            # CSV logging
            if log_csv and csv_writer is not None:
                csv_writer.writerow([
                    frame_count, f"{timestamp:.3f}", selected_side,
                    f"{smooth_angle:.2f}" if smooth_angle is not None else "",
                    squat_stage if squat_stage is not None else "",
                    rep_count, f"{rep_min_angle:.2f}" if rep_min_angle is not None else "",
                    rep_knees_in
                ])

            out.write(image)
            frame_count += 1

    cap.release()
    out.release()
    if csv_file:
        csv_file.close()

    # encode to H.264 using ffmpeg (preserve annotations)
    print("🎞 Converting to H.264 using ffmpeg...")
    ffmpeg_cmd = [
        'ffmpeg', '-y',
        '-i', raw_path,
        '-vcodec', 'libx264',
        '-preset', 'fast',
        '-crf', '23',
        '-acodec', 'aac',
        output_path
    ]
    subprocess.run(ffmpeg_cmd, check=True)
    try:
        os.remove(raw_path)
    except:
        pass
    print("✅ H.264 conversion complete")

    # compile aggregated stats
    rep_time = {
        "average": round(float(np.mean(rep_durations)), 2) if rep_durations else 0.0,
        "fastest": round(float(np.min(rep_durations)), 2) if rep_durations else 0.0,
        "slowest": round(float(np.max(rep_durations)), 2) if rep_durations else 0.0
    }
    form_issues = list(set([issue for rep in all_rep_issues for issue in rep]))

    result = {
        "squat_count": rep_count,
        "reps_below_parallel": sum(1 for rep in all_rep_issues for issue in rep if issue == "shallow_depth"),
        "bad_reps": sum(1 for rep in all_rep_issues for issue in rep if issue == "knees_in"),
        "form_issues": form_issues,
        "rep_time": rep_time,
        "debug_csv": csv_path if log_csv else None
    }

    return result
