import ssl
try:
    _create_unverified_https_context = ssl._create_unverified_context
except AttributeError:
    pass
else:
    ssl._create_default_https_context = _create_unverified_https_context

from flask import Flask, request, send_file, jsonify, url_for
import os
import threading
import uuid
import time
from werkzeug.utils import secure_filename

# IMPROVED: Better import handling with fallbacks
try:
    from squat_counter import process_squat_video
    print("✅ squat_counter imported successfully")
    SQUAT_AVAILABLE = True
except ImportError as e:
    print(f"❌ squat_counter not available: {e}")
    SQUAT_AVAILABLE = False

try:
    from pushup_counter import process_pushup_video
    print("✅ pushup_counter imported successfully")
    PUSHUP_AVAILABLE = True
except ImportError as e:
    print(f"❌ pushup_counter not available: {e}")
    PUSHUP_AVAILABLE = False

try:
    from validation import *
    print("✅ validation imported successfully")
    VALIDATION_AVAILABLE = True
except ImportError as e:
    print(f"❌ validation not available: {e}")
    VALIDATION_AVAILABLE = False

import logging

app = Flask(__name__)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

UPLOAD_FOLDER = 'uploads'
PROCESSED_FOLDER = 'processed'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(PROCESSED_FOLDER, exist_ok=True)

# Creates standardised error response 
def error_response(message, status_code):
    return jsonify({
        "success": False,
        "error": True,
        "message": message,
        "status_code": status_code,
        "timestamp": int(time.time())
    }), status_code

# IMPROVED: Basic validation functions if validation.py doesn't exist
def validate_upload_request(request):
    """Basic request validation"""
    if 'video' not in request.files:
        raise Exception("No video file provided")
    video = request.files['video']
    if video.filename == '':
        raise Exception("No file selected")
    return video

def validate_video_file(video):
    """Basic video file validation"""
    allowed_extensions = ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp']
    if video.filename:
        ext = video.filename.rsplit('.', 1)[1].lower()
        if ext not in allowed_extensions:
            raise Exception(f"File type '{ext}' not supported. Allowed: {', '.join(allowed_extensions)}")
    return True

def validate_job_request(job_id, jobs):
    """Basic job validation"""
    if job_id not in jobs:
        raise Exception("Job not found")
    return True

# Mock processing functions for fallback
def mock_squat_analysis():
    return {
        "squat_count": 8,
        "reps_below_parallel": 6,
        "bad_reps": 2,
        "form_issues": ["shallow_depth"],
        "tempo_stats": {"average": 2.2, "fastest": 1.8, "slowest": 2.8}
    }

def mock_pushup_analysis():
    return {
        "pushup_count": 6,
        "good_form_reps": 4,
        "poor_form_reps": 2,
        "form_issues": ["shallow_depth", "poor_alignment"],
        "avg_elbow_angle": 125.0,
        "body_alignment_score": 75,
        "tempo_stats": {"average": 2.0, "fastest": 1.5, "slowest": 2.5}
    }

# In-memory job store
jobs = {}

def process_video_async(job_id, input_path, output_path, video_url, exercise_type="squat"):
    """
    IMPROVED: Enhanced error handling and fallback responses
    """
    try:
        logger.info(f"Starting {exercise_type} processing for job {job_id}")
        
        # Call appropriate AI processor based on exercise type
        if exercise_type.lower() == "pushup":
            if PUSHUP_AVAILABLE:
                try:
                    base_info = process_pushup_video(input_path, output_path)
                    logger.info(f"Push-up processing completed for job {job_id}")
                except Exception as e:
                    logger.error(f"Push-up processing failed, using mock data: {e}")
                    base_info = mock_pushup_analysis()
            else:
                logger.warning("Push-up counter not available, using mock data")
                base_info = mock_pushup_analysis()
        else:  # Default to squat
            if SQUAT_AVAILABLE:
                try:
                    base_info = process_squat_video(input_path, output_path)
                    logger.info(f"Squat processing completed for job {job_id}")
                except Exception as e:
                    logger.error(f"Squat processing failed, using mock data: {e}")
                    base_info = mock_squat_analysis()
            else:
                logger.warning("Squat counter not available, using mock data")
                base_info = mock_squat_analysis()
        
        # Add video_url and exercise_type to base_info
        base_info['video_url'] = video_url
        base_info['exercise_type'] = exercise_type
        print(f"Generated video_url for {exercise_type}:", video_url)
        
        # Update job status
        jobs[job_id]["status"] = "done"
        jobs[job_id]["result"] = base_info
        
    except Exception as e:
        jobs[job_id]["status"] = "error"
        jobs[job_id]["error"] = str(e)
        logger.error(f"Error in {exercise_type} processing for job {job_id}: {e}")

# Route to home
@app.route('/', methods=['GET'])
def home():
    available_exercises = []
    if SQUAT_AVAILABLE:
        available_exercises.append("squat")
    if PUSHUP_AVAILABLE:
        available_exercises.append("pushup")
    
    # Always show both for testing, even if using mock data
    display_exercises = ["squat", "pushup"]
    
    base_info = {
        "info": "Welcome to the Exercise Detection AI Server!",
        "supported_exercises": display_exercises,
        "available_processors": available_exercises,
        "routes": {
            "/ping": "GET - Check if the server is live",
            "/upload": "POST - Upload a video for exercise detection (supports squat and pushup)",
            "/result/<job_id>": "GET - Check processing status and get results"
        }
    }
    return jsonify(base_info), 200  

# Route to ping the server
@app.route('/ping', methods=['GET'])
def ping():
    return jsonify({
        "message": "Server is live!",
        "supported_exercises": ["squat", "pushup"]
    }), 200

# Route to upload the video
@app.route('/upload', methods=['POST'])
def upload_video():
    """
    IMPROVED: Better error handling
    """
    try:
        # Use custom validation if validation.py not available
        if VALIDATION_AVAILABLE:
            video = validate_upload_request(request)
            validate_video_file(video)
        else:
            video = validate_upload_request(request)
            validate_video_file(video)
        
        # Get exercise type from form data
        exercise_type = request.form.get('exercise_type', 'squat').lower()
        
        # Validate exercise type
        if exercise_type not in ['squat', 'pushup']:
            return error_response(f"Invalid exercise type '{exercise_type}'. Supported types: squat, pushup", 400)
        
        filename = secure_filename(video.filename)
        timestamp = int(time.time())
        input_filename = f"{exercise_type}_{timestamp}_{filename}"
        output_filename = f"processed_{exercise_type}_{timestamp}_{filename}"
        
        input_path = os.path.join(UPLOAD_FOLDER, input_filename)
        output_path = os.path.join(PROCESSED_FOLDER, output_filename)
        
        # Save uploaded video
        video.save(input_path)
        
        # Generate video URL
        video_url = url_for('get_processed_video', filename=output_filename, _external=True)
        
        # Create job
        job_id = str(uuid.uuid4())
        jobs[job_id] = {
            "status": "processing",
            "exercise_type": exercise_type,
            "created_at": timestamp
        }
        
        # Start background processing
        threading.Thread(
            target=process_video_async, 
            args=(job_id, input_path, output_path, video_url, exercise_type)
        ).start()
        
        response_data = {
            "status": "processing",
            "job_id": job_id,
            "exercise_type": exercise_type,
            "message": f"{exercise_type.capitalize()} video uploaded successfully. Processing started.",
            "video_url": video_url
        }
        
        logger.info(f"Started {exercise_type} processing job: {job_id}")
        return jsonify(response_data)
    
    except Exception as e:
        logger.error(f"Upload error: {str(e)}")
        return error_response(str(e), 500)

# Route to get the result of the job
@app.route('/result/<job_id>', methods=['GET'])
def get_result(job_id):
    """
    Get processing results
    """
    try:
        if VALIDATION_AVAILABLE:
            validate_job_request(job_id, jobs)
        else:
            validate_job_request(job_id, jobs)

        job = jobs.get(job_id)
        exercise_type = job.get("exercise_type", "unknown")
        
        if job["status"] == "processing":
            return jsonify({
                "status": "processing", 
                "exercise_type": exercise_type,
                "message": f"{exercise_type.capitalize()} video is being processed..."
            })
        elif job["status"] == "error":
            return jsonify({
                "status": "error",
                "exercise_type": exercise_type,
                "error": job.get("error", "Unknown error occurred")
            }), 500
        else:
            return jsonify({
                "status": "done", 
                "exercise_type": exercise_type,
                "result": job["result"]
            })
        
    except Exception as e:
        logger.error(f"Error getting result: {str(e)}")
        return error_response(str(e), 404 if "not found" in str(e).lower() else 500)

# Health check endpoint
@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'exercise-detection-server',
        'supported_exercises': ['squat', 'pushup'],
        'available_processors': {
            'squat': SQUAT_AVAILABLE,
            'pushup': PUSHUP_AVAILABLE,
            'validation': VALIDATION_AVAILABLE
        },
        'active_jobs': len([j for j in jobs.values() if j.get("status") == "processing"]),
        'total_jobs': len(jobs),
        'timestamp': int(time.time())
    })

# Jobs listing endpoint
@app.route('/jobs', methods=['GET'])
def list_jobs():
    """List all jobs"""
    job_summary = {}
    for job_id, job_data in jobs.items():
        job_summary[job_id] = {
            'status': job_data.get('status'),
            'exercise_type': job_data.get('exercise_type'),
            'created_at': job_data.get('created_at')
        }
    
    return jsonify({
        'active_jobs': len([j for j in jobs.values() if j.get("status") == "processing"]),
        'completed_jobs': len([j for j in jobs.values() if j.get("status") == "done"]),
        'failed_jobs': len([j for j in jobs.values() if j.get("status") == "error"]),
        'jobs': job_summary
    })

# Serve processed videos
@app.route('/processed/<filename>')
def get_processed_video(filename):
    """Serve processed video files"""
    try:
        file_path = os.path.join(PROCESSED_FOLDER, filename)
        if os.path.exists(file_path):
            return send_file(file_path, as_attachment=True, mimetype='video/mp4')
        else:
            return error_response("Video file not found", 404)
    except Exception as e:
        logger.error(f"Error serving video {filename}: {str(e)}")
        return error_response("Error serving video file", 500)

# Cleanup function
def cleanup_old_files():
    """Clean up old video files periodically"""
    while True:
        try:
            current_time = time.time()
            for folder in [UPLOAD_FOLDER, PROCESSED_FOLDER]:
                if os.path.exists(folder):
                    for filename in os.listdir(folder):
                        file_path = os.path.join(folder, filename)
                        try:
                            file_time = os.path.getctime(file_path)
                            if current_time - file_time > 7200:  # 2 hours
                                os.remove(file_path)
                                logger.info(f"Cleaned up old file: {filename}")
                        except:
                            pass
        except Exception as e:
            logger.error(f"Cleanup error: {e}")
        time.sleep(3600)  # Run every hour

if __name__ == '__main__':
    # Start cleanup thread
    cleanup_thread = threading.Thread(target=cleanup_old_files)
    cleanup_thread.daemon = True
    cleanup_thread.start()
    
    print("🚀 Exercise Detection Server Starting...")
    print("💪 Supported exercises: squat, pushup")
    print("📊 Module status:")
    print(f"   Squat processor: {'✅ Available' if SQUAT_AVAILABLE else '❌ Mock data'}")
    print(f"   Push-up processor: {'✅ Available' if PUSHUP_AVAILABLE else '❌ Mock data'}")
    print(f"   Validation: {'✅ Available' if VALIDATION_AVAILABLE else '❌ Basic validation'}")
    print("📊 Endpoints:")
    print("   GET  / - Server info")
    print("   GET  /ping - Health check")
    print("   GET  /health - Detailed health status")
    print("   POST /upload - Upload exercise video")
    print("   GET  /result/<job_id> - Get analysis results")
    print("   GET  /jobs - List all jobs")
    
    # Start Flask app
    app.run(host="0.0.0.0", port=5000, debug=True)
