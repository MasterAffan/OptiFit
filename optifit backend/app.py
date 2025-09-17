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
from squat_counter import process_squat_video  # Import the actual processing logic
from validation import *

app = Flask(__name__)

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

# In-memory job store: {job_id: {"status": "processing"/"done", "result": {...}}}
jobs = {}

def process_video_async(job_id, input_path, output_path, video_url):
    try:
        # Call AI squat detection processor and get all base info
        base_info = process_squat_video(input_path, output_path)
        
        # Add video_url to base_info
        base_info['video_url'] = video_url
        print("Generated video_url:", video_url)
        
        # Update job status
        jobs[job_id]["status"] = "done"
        jobs[job_id]["result"] = base_info
    except Exception as e:
        jobs[job_id]["status"] = "error"
        jobs[job_id]["error"] = str(e)
        print(f"Error in background processing: {e}")

#Route to home
@app.route('/', methods=['GET'])
def home():
    base_info = {
        "info": "Welcome to the Squat Counter AI Server!",
        "routes": {
            "/ping": "GET - Check if the server is live",
            "/upload": "POST - Upload a video for squat detection",
            "/result/<job_id>": "GET - Check processing status and get results"
        }
    }

    return jsonify(base_info), 200  

#Route to ping the server
@app.route('/ping', methods=['GET'])
def ping():
    return jsonify({"message": "Server is live!"}), 200

#Route to get upload the video
@app.route('/upload', methods=['POST'])
def upload_video():
    try:
        video = validate_upload_request(request)
        validate_video_file(video)

        filename = secure_filename(video.filename)
        input_path = os.path.join(UPLOAD_FOLDER, filename)
        output_path = os.path.join(PROCESSED_FOLDER, f"processed_{filename}")
        
        # Save uploaded video
        video.save(input_path)
        
        # Generate video URL
        video_url = url_for('get_processed_video', filename=f"processed_{filename}", _external=True)
        
        # Create job
        job_id = str(uuid.uuid4())
        jobs[job_id] = {"status": "processing"}
        
        # Start background processing with pre-generated URL
        threading.Thread(target=process_video_async, args=(job_id, input_path, output_path, video_url)).start()
        
        response_data = {
            "status": "processing",
            "job_id": job_id,
            "message": "Video uploaded successfully. Processing started.",
            "video_url": video_url
        }
        
        return jsonify(response_data)
    
    except APIError as e:
        return error_response(e.message, e.status_code)
    


# Route to get the result of the job with the job id
@app.route('/result/<job_id>', methods=['GET'])
def get_result(job_id):
    try:
        validate_job_request(job_id,jobs)

        job = jobs.get(job_id)
        if job["status"] == "processing":
            return jsonify({"status": "processing", "message": "Video is being processed..."})
        elif job["status"] == "error":
            raise InternalServerError("Unknown Error")
        else:
            return jsonify({"status": "done", "result": job["result"]})
        
    except APIError as e:
        return error_response(e.message, e.status_code)

# New endpoint to serve processed videos by filename
@app.route('/processed/<filename>')
def get_processed_video(filename):
    return send_file(os.path.join(PROCESSED_FOLDER, filename), as_attachment=True, mimetype='video/mp4')


if __name__ == '__main__':
    # Start Flask app
    app.run(host="0.0.0.0", port=5000)
