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
    """Calculate angle between three points - same as squat counter"""
    a, b, c = np.array(a), np.array(b), np.array(c)
    radians = np.arctan2(c[1]-b[1], c[0]-b[0]) - np.arctan2(a[1]-b[1], a[0]-b[0])
    angle = np.abs(radians * 180.0 / np.pi)
    return angle if angle <= 180.0 else 360 - angle

def _get_visibility(lm):
    """Get landmark visibility - same as squat counter"""
    return getattr(lm, "visibility", 1.0)

def calculate_body_alignment(landmarks):
    """Calculate body alignment score for push-up form"""
    try:
        # Get key body points
        left_shoulder = landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER.value]
        right_shoulder = landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER.value]
        left_hip = landmarks[mp_pose.PoseLandmark.LEFT_HIP.value]
        right_hip = landmarks[mp_pose.PoseLandmark.RIGHT_HIP.value]
        left_ankle = landmarks[mp_pose.PoseLandmark.LEFT_ANKLE.value]
        right_ankle = landmarks[mp_pose.PoseLandmark.RIGHT_ANKLE.value]
        
        # Calculate center points
        shoulder_center = [(left_shoulder.x + right_shoulder.x) / 2, (left_shoulder.y + right_shoulder.y) / 2]
        hip_center = [(left_hip.x + right_hip.x) / 2, (left_hip.y + right_hip.y) / 2]
        ankle_center = [(left_ankle.x + right_ankle.x) / 2, (left_ankle.y + right_ankle.y) / 2]
        
        # Calculate alignment angles
        shoulder_hip_angle = np.arctan2(hip_center[1] - shoulder_center[1], hip_center[0] - shoulder_center[0])
        hip_ankle_angle = np.arctan2(ankle_center[1] - hip_center[1], ankle_center[0] - hip_center[0])
        
        # Calculate alignment deviation (perfect alignment = small deviation)
        angle_diff = abs(shoulder_hip_angle - hip_ankle_angle)
        alignment_score = max(0, 100 - (angle_diff * 180 / np.pi) * 10)
        
        return alignment_score
    except:
        return 50

def process_pushup_video(input_path, output_path, sample_rate=1, log_csv=True):
    """
    Process input video for push-up detection, following squat counter structure.
    Detects push-ups based on elbow angles instead of knee angles.
    """
    raw_path = output_path.replace('.mp4', '_raw.mp4')
    csv_path = output_path.replace('.mp4', '_angles.csv')

    cap = cv2.VideoCapture(input_path)
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = int(cap.get(cv2.CAP_PROP_FPS)) or 20

    out = cv2.VideoWriter(raw_path, cv2.VideoWriter_fourcc(*'mp4v'), fps, (width, height))

    # State & stats - adapted for push-ups
    rep_count = 0
    pushup_stage = None        # 'up' or 'down'
    rep_start_time = None
    rep_durations = []
    rep_max_angle = None       # max angle reached (up position)
    rep_min_angle = None       # min angle reached (down position)
    rep_poor_alignment = False
    rep_hands_wrong = False
    all_rep_issues = []
    latest_rep_feedback = ""
    last_rep_time = None

    frame_count = 0
    angle_history = collections.deque(maxlen=5)  # smoothing window
    alignment_history = collections.deque(maxlen=5)

    # Push-up specific thresholds
    UP_THRESHOLD = 150          # angle considered up position
    START_DOWN_THRESHOLD = 130  # start of descent detection
    DOWN_THRESHOLD = 90         # angle considered down position (good depth)
    ALIGNMENT_THRESHOLD = 70    # minimum body alignment score
    HAND_POSITION_MARGIN = 0.05 # margin for hand position relative to shoulders

    # Prepare CSV logging
    csv_file = None
    csv_writer = None
    if log_csv:
        csv_file = open(csv_path, mode='w', newline='')
        csv_writer = csv.writer(csv_file)
        csv_writer.writerow([
            "frame", "timestamp", "selected_side", "smooth_angle", "body_alignment",
            "stage", "rep_count", "rep_min_angle", "rep_max_angle", "rep_poor_alignment", "rep_hands_wrong"
        ])

    with mp_pose.Pose(min_detection_confidence=0.5, min_tracking_confidence=0.5) as pose:
        start_time_global = time.time()
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            # Sampling to speed up
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
            body_alignment = None

            if results.pose_landmarks:
                lm = results.pose_landmarks.landmark

                # Helper to get elbow angle for each side
                def elbow_angle(side_prefix):
                    shoulder = lm[getattr(mp_pose.PoseLandmark, f"{side_prefix}_SHOULDER").value]
                    elbow = lm[getattr(mp_pose.PoseLandmark, f"{side_prefix}_ELBOW").value]
                    wrist = lm[getattr(mp_pose.PoseLandmark, f"{side_prefix}_WRIST").value]
                    return shoulder, elbow, wrist

                # Compute both sides' elbow angles + visibility
                left_shoulder, left_elbow, left_wrist = elbow_angle("LEFT")
                right_shoulder, right_elbow, right_wrist = elbow_angle("RIGHT")

                left_vis = _get_visibility(left_shoulder) + _get_visibility(left_elbow) + _get_visibility(left_wrist)
                right_vis = _get_visibility(right_shoulder) + _get_visibility(right_elbow) + _get_visibility(right_wrist)

                left_coords = ([left_shoulder.x, left_shoulder.y], [left_elbow.x, left_elbow.y], [left_wrist.x, left_wrist.y])
                right_coords = ([right_shoulder.x, right_shoulder.y], [right_elbow.x, right_elbow.y], [right_wrist.x, right_wrist.y])

                left_angle = calculate_angle(*left_coords)
                right_angle = calculate_angle(*right_coords)

                # Choose side based on visibility
                if left_vis >= right_vis:
                    selected_side = "left"
                    chosen_angle = left_angle
                    elbow_coords = left_coords
                else:
                    selected_side = "right"
                    chosen_angle = right_angle
                    elbow_coords = right_coords

                # Smoothing
                angle_history.append(chosen_angle)
                smooth_angle = float(np.mean(angle_history))

                # Calculate body alignment
                body_alignment = calculate_body_alignment(lm)
                alignment_history.append(body_alignment)
                smooth_alignment = float(np.mean(alignment_history))

                # Check hand position relative to shoulders
                left_wrist_x = left_wrist.x
                right_wrist_x = right_wrist.x
                left_shoulder_x = left_shoulder.x
                right_shoulder_x = right_shoulder.x
                
                hand_width = abs(right_wrist_x - left_wrist_x)
                shoulder_width = abs(right_shoulder_x - left_shoulder_x)
                
                # Check if hands are too close or too far
                if hand_width < shoulder_width * 0.8 or hand_width > shoulder_width * 1.5:
                    rep_hands_wrong = True

                # Check body alignment
                if smooth_alignment < ALIGNMENT_THRESHOLD:
                    rep_poor_alignment = True

                # Initialize stage if unknown
                if pushup_stage is None:
                    pushup_stage = "up" if smooth_angle > UP_THRESHOLD else "down"

                # State machine - adapted for push-ups
                if pushup_stage == "up":
                    # Look for descent start
                    if smooth_angle < START_DOWN_THRESHOLD:
                        pushup_stage = "down"
                        rep_start_time = time.time()
                        rep_max_angle = smooth_angle
                        rep_min_angle = smooth_angle
                        rep_poor_alignment = False
                        rep_hands_wrong = False
                elif pushup_stage == "down":
                    # Update min and max angles
                    if rep_min_angle is None or smooth_angle < rep_min_angle:
                        rep_min_angle = smooth_angle
                    if rep_max_angle is None or smooth_angle > rep_max_angle:
                        rep_max_angle = smooth_angle
                    
                    # Check if we rose back up past the UP_THRESHOLD -> rep finished
                    if smooth_angle > UP_THRESHOLD:
                        # Finalize rep
                        rep_end_time = time.time()
                        duration = rep_end_time - rep_start_time if rep_start_time else 0.0
                        rep_durations.append(duration)
                        
                        # Decide issues
                        rep_issues = []
                        feedback_reasons = []
                        
                        if rep_min_angle is None or rep_min_angle > DOWN_THRESHOLD:
                            rep_issues.append("shallow_depth")
                            feedback_reasons.append("go down more")
                        
                        if rep_poor_alignment:
                            rep_issues.append("poor_alignment")
                            feedback_reasons.append("keep body straight")
                        
                        if rep_hands_wrong:
                            rep_issues.append("hand_position")
                            feedback_reasons.append("check hand position")
                        
                        all_rep_issues.append(rep_issues)
                        rep_count += 1
                        
                        # Feedback
                        latest_rep_feedback = "Good rep" if not feedback_reasons else "Bad rep - " + ", ".join(feedback_reasons)
                        last_rep_time = time.time()
                        
                        # Reset per-rep
                        rep_start_time = None
                        rep_min_angle = None
                        rep_max_angle = None
                        rep_poor_alignment = False
                        rep_hands_wrong = False
                        pushup_stage = "up"

                # Draw landmarks + connections
                mp_drawing.draw_landmarks(
                    image,
                    results.pose_landmarks,
                    mp_pose.POSE_CONNECTIONS,
                    mp_drawing.DrawingSpec(color=(245, 117, 66), thickness=2, circle_radius=2),
                    mp_drawing.DrawingSpec(color=(245, 66, 230), thickness=2, circle_radius=2)
                )

                # Convert elbow keypoint to pixel coords for text placement
                elbow_px = (int(elbow_coords[1][0] * width), int(elbow_coords[1][1] * height))
                cv2.circle(image, elbow_px, 6, (0, 255, 255), -1)
                cv2.putText(image, f"{selected_side} elbow: {int(smooth_angle)}°",
                           (elbow_px[0] + 10, max(20, elbow_px[1] - 10)),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 0), 2, cv2.LINE_AA)

            else:
                # No pose detected
                cv2.putText(image, "No pose detected", (15, 80),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0, 0, 255), 2, cv2.LINE_AA)

            # Overlay debug info - adapted for push-ups
            cv2.putText(image, f"Push-ups: {rep_count}", (width - 220, 40),
                       cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 200, 0), 3, cv2.LINE_AA)
            if smooth_angle is not None:
                cv2.putText(image, f"Elbow Angle: {int(smooth_angle)}", (15, height - 90),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2, cv2.LINE_AA)
            if body_alignment is not None:
                cv2.putText(image, f"Alignment: {int(body_alignment)}%", (15, height - 60),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2, cv2.LINE_AA)
            cv2.putText(image, f"Stage: {pushup_stage}", (15, height - 30),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.8, (200, 200, 200), 2, cv2.LINE_AA)
            cv2.putText(image, f"Side: {selected_side}", (200, height - 30),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.8, (200, 200, 200), 2, cv2.LINE_AA)
            if rep_min_angle is not None:
                cv2.putText(image, f"Min: {int(rep_min_angle)}", (350, height - 30),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.8, (180, 180, 180), 2, cv2.LINE_AA)

            # Blinking rep feedback
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
                    f"{body_alignment:.2f}" if body_alignment is not None else "",
                    pushup_stage if pushup_stage is not None else "",
                    rep_count,
                    f"{rep_min_angle:.2f}" if rep_min_angle is not None else "",
                    f"{rep_max_angle:.2f}" if rep_max_angle is not None else "",
                    rep_poor_alignment,
                    rep_hands_wrong
                ])

            out.write(image)
            frame_count += 1

    cap.release()
    out.release()
    if csv_file:
        csv_file.close()

    # Encode to H.264 using ffmpeg
    print("🎞 Converting push-up video to H.264 using ffmpeg...")
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

    # Compile aggregated stats - adapted for push-ups
    tempo_stats = {
        "average": round(float(np.mean(rep_durations)), 2) if rep_durations else 0.0,
        "fastest": round(float(np.min(rep_durations)), 2) if rep_durations else 0.0,
        "slowest": round(float(np.max(rep_durations)), 2) if rep_durations else 0.0
    }
    
    form_issues = list(set([issue for rep in all_rep_issues for issue in rep]))
    
    # Calculate good vs bad reps
    good_form_reps = sum(1 for rep in all_rep_issues if len(rep) == 0)
    poor_form_reps = rep_count - good_form_reps

    result = {
        "pushup_count": rep_count,
        "good_form_reps": good_form_reps,
        "poor_form_reps": poor_form_reps,
        "form_issues": form_issues,
        "tempo_stats": tempo_stats,
        "debug_csv": csv_path if log_csv else None
    }

    return result
