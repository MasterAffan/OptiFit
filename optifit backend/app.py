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

app = Flask(__name__)

UPLOAD_FOLDER = 'uploads'
PROCESSED_FOLDER = 'processed'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(PROCESSED_FOLDER, exist_ok=True)

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
    
    return base_info, 200

@app.route('/ping', methods=['GET'])
def ping():
    return {"message": "Server is live!"}, 200

@app.route('/upload', methods=['POST'])
def upload_video():
    if 'video' not in request.files:
        return {'error': 'No video file part'}, 400

    video = request.files['video']
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

@app.route('/result/<job_id>', methods=['GET'])
def get_result(job_id):
    job = jobs.get(job_id)
    if not job:
        return jsonify({"status": "not_found", "error": "Job not found"}), 404
    
    if job["status"] == "processing":
        return jsonify({"status": "processing", "message": "Video is being processed..."})
    elif job["status"] == "error":
        return jsonify({"status": "error", "error": job.get("error", "Unknown error")}), 500
    else:
        return jsonify({"status": "done", "result": job["result"]})

# New endpoint to serve processed videos by filename
@app.route('/processed/<filename>')
def get_processed_video(filename):
    return send_file(os.path.join(PROCESSED_FOLDER, filename), as_attachment=True, mimetype='video/mp4')


if __name__ == '__main__':
    # Start Flask app
    app.run(host="0.0.0.0", port=5000)
