"""pose_server.py - Autonomous Pose Estimation Server

Flask server with MediaPipe for real-time squat form analysis.
Provides machine-generated feedback (form score, pass/fail, flags)
with rule-driven, autonomous assessment.
"""

import cv2
import numpy as np
import mediapipe as mp
import base64
from flask import Flask, request, jsonify
from flask_cors import CORS
import json

app = Flask(__name__)
CORS(app)

# Initialize MediaPipe Pose
mp_pose = mp.solutions.pose
mp_drawing = mp.solutions.drawing_utils
pose = mp_pose.Pose(
    static_image_mode=False,
    model_complexity=1,
    smooth_landmarks=True,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)


class SquatAnalyzer:
    """Rule-driven squat form analyzer - fully autonomous."""
    
    def __init__(self):
        self.squat_state = 'up'
        self.squat_count = 0
        self.form_issues = []
        
    def calculate_angle(self, a, b, c):
        """Calculate angle between three points."""
        a = np.array(a)
        b = np.array(b)
        c = np.array(c)
        
        radians = np.arctan2(c[1]-b[1], c[0]-b[0]) - np.arctan2(a[1]-b[1], a[0]-b[0])
        angle = np.abs(radians*180.0/np.pi)
        
        if angle > 180.0:
            angle = 360-angle
            
        return angle
    
    def analyze_squat_form(self, landmarks):
        """Analyze squat form using rule-based logic.
        
        Returns:
            dict: {
                'form_score': float (0-100),
                'pass_fail': str ('PASS' or 'FAIL'),
                'flags': list of form issues,
                'metrics': dict of angle measurements
            }
        """
        self.form_issues = []
        
        # Extract key landmarks
        try:
            # Get coordinates
            left_hip = [landmarks[mp_pose.PoseLandmark.LEFT_HIP.value].x,
                       landmarks[mp_pose.PoseLandmark.LEFT_HIP.value].y]
            left_knee = [landmarks[mp_pose.PoseLandmark.LEFT_KNEE.value].x,
                        landmarks[mp_pose.PoseLandmark.LEFT_KNEE.value].y]
            left_ankle = [landmarks[mp_pose.PoseLandmark.LEFT_ANKLE.value].x,
                         landmarks[mp_pose.PoseLandmark.LEFT_ANKLE.value].y]
            left_shoulder = [landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER.value].x,
                            landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER.value].y]
            
            right_hip = [landmarks[mp_pose.PoseLandmark.RIGHT_HIP.value].x,
                        landmarks[mp_pose.PoseLandmark.RIGHT_HIP.value].y]
            right_knee = [landmarks[mp_pose.PoseLandmark.RIGHT_KNEE.value].x,
                         landmarks[mp_pose.PoseLandmark.RIGHT_KNEE.value].y]
            right_ankle = [landmarks[mp_pose.PoseLandmark.RIGHT_ANKLE.value].x,
                          landmarks[mp_pose.PoseLandmark.RIGHT_ANKLE.value].y]
            right_shoulder = [landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER.value].x,
                             landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER.value].y]
            
            # Calculate angles
            left_knee_angle = self.calculate_angle(left_hip, left_knee, left_ankle)
            right_knee_angle = self.calculate_angle(right_hip, right_knee, right_ankle)
            left_hip_angle = self.calculate_angle(left_shoulder, left_hip, left_knee)
            right_hip_angle = self.calculate_angle(right_shoulder, right_hip, right_knee)
            
            # Average angles for bilateral assessment
            knee_angle = (left_knee_angle + right_knee_angle) / 2
            hip_angle = (left_hip_angle + right_hip_angle) / 2
            
            # Calculate torso lean
            hip_center_y = (left_hip[1] + right_hip[1]) / 2
            shoulder_center_y = (left_shoulder[1] + right_shoulder[1]) / 2
            hip_center_x = (left_hip[0] + right_hip[0]) / 2
            shoulder_center_x = (left_shoulder[0] + right_shoulder[0]) / 2
            
            # Rule-based form assessment
            form_score = 100.0
            
            # Rule 1: Knee depth assessment (squat should reach ~90 degrees or below)
            if knee_angle > 110:
                self.form_issues.append("NOT_DEEP_ENOUGH")
                form_score -= 20
            elif knee_angle < 70:
                self.form_issues.append("TOO_DEEP")
                form_score -= 10
                
            # Rule 2: Hip hinge assessment
            if hip_angle > 160:
                self.form_issues.append("INSUFFICIENT_HIP_HINGE")
                form_score -= 15
                
            # Rule 3: Torso position (should maintain relatively upright position)
            torso_lean = abs(shoulder_center_x - hip_center_x)
            if torso_lean > 0.15:
                self.form_issues.append("EXCESSIVE_FORWARD_LEAN")
                form_score -= 15
                
            # Rule 4: Knee alignment (knees shouldn't cave inward)
            knee_width = abs(left_knee[0] - right_knee[0])
            hip_width = abs(left_hip[0] - right_hip[0])
            if knee_width < hip_width * 0.7:
                self.form_issues.append("KNEE_VALGUS")
                form_score -= 20
                
            # Rule 5: Asymmetry check
            angle_asymmetry = abs(left_knee_angle - right_knee_angle)
            if angle_asymmetry > 15:
                self.form_issues.append("ASYMMETRIC_FORM")
                form_score -= 15
            
            # Ensure score doesn't go negative
            form_score = max(0, form_score)
            
            # Determine pass/fail (threshold: 70)
            pass_fail = "PASS" if form_score >= 70 else "FAIL"
            
            # Update squat state for counting
            if knee_angle < 90 and self.squat_state == 'up':
                self.squat_state = 'down'
            elif knee_angle > 160 and self.squat_state == 'down':
                self.squat_state = 'up'
                self.squat_count += 1
            
            return {
                'form_score': round(form_score, 2),
                'pass_fail': pass_fail,
                'flags': self.form_issues,
                'metrics': {
                    'knee_angle': round(knee_angle, 2),
                    'hip_angle': round(hip_angle, 2),
                    'torso_lean': round(torso_lean, 4),
                    'left_knee_angle': round(left_knee_angle, 2),
                    'right_knee_angle': round(right_knee_angle, 2)
                },
                'squat_count': self.squat_count,
                'squat_state': self.squat_state
            }
            
        except Exception as e:
            return {
                'form_score': 0,
                'pass_fail': 'ERROR',
                'flags': [f'ANALYSIS_ERROR: {str(e)}'],
                'metrics': {},
                'squat_count': self.squat_count,
                'squat_state': self.squat_state
            }


# Global analyzer instance
analyzer = SquatAnalyzer()


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy',
        'service': 'pose_server',
        'mediapipe_loaded': True
    })


@app.route('/analyze_frame', methods=['POST'])
def analyze_frame():
    """Process a single video frame and return pose analysis.
    
    Expected JSON payload:
    {
        'frame': 'base64_encoded_image_string',
        'session_id': 'optional_session_identifier'
    }
    
    Returns:
    {
        'success': bool,
        'pose_detected': bool,
        'analysis': {
            'form_score': float,
            'pass_fail': str,
            'flags': list,
            'metrics': dict,
            'squat_count': int,
            'squat_state': str
        },
        'landmarks': list (optional)
    }
    """
    try:
        data = request.get_json()
        
        if 'frame' not in data:
            return jsonify({
                'success': False,
                'error': 'No frame data provided'
            }), 400
        
        # Decode base64 image
        frame_data = data['frame']
        if ',' in frame_data:
            frame_data = frame_data.split(',')[1]
        
        img_bytes = base64.b64decode(frame_data)
        nparr = np.frombuffer(img_bytes, np.uint8)
        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if frame is None:
            return jsonify({
                'success': False,
                'error': 'Failed to decode image'
            }), 400
        
        # Convert BGR to RGB
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        
        # Process with MediaPipe
        results = pose.process(rgb_frame)
        
        if results.pose_landmarks:
            # Run autonomous analysis
            analysis = analyzer.analyze_squat_form(results.pose_landmarks.landmark)
            
            # Optionally include landmark coordinates
            landmarks_data = []
            if data.get('include_landmarks', False):
                for landmark in results.pose_landmarks.landmark:
                    landmarks_data.append({
                        'x': landmark.x,
                        'y': landmark.y,
                        'z': landmark.z,
                        'visibility': landmark.visibility
                    })
            
            response = {
                'success': True,
                'pose_detected': True,
                'analysis': analysis,
                'timestamp': data.get('timestamp', None)
            }
            
            if landmarks_data:
                response['landmarks'] = landmarks_data
            
            return jsonify(response)
        else:
            return jsonify({
                'success': True,
                'pose_detected': False,
                'message': 'No pose detected in frame'
            })
            
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/reset_session', methods=['POST'])
def reset_session():
    """Reset the analyzer state for a new workout session."""
    global analyzer
    analyzer = SquatAnalyzer()
    return jsonify({
        'success': True,
        'message': 'Session reset successfully'
    })


@app.route('/get_stats', methods=['GET'])
def get_stats():
    """Get current session statistics."""
    return jsonify({
        'success': True,
        'stats': {
            'squat_count': analyzer.squat_count,
            'current_state': analyzer.squat_state
        }
    })


if __name__ == '__main__':
    print("="*60)
    print("Pose Estimation Server Starting")
    print("Autonomous squat analysis with MediaPipe")
    print("Rule-driven feedback - no human labeling required")
    print("="*60)
    app.run(host='0.0.0.0', port=5001, debug=True)
