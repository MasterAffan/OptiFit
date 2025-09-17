import os
import uuid

class APIError(Exception):
    def __init__(self, message, status_code=500):
        self.message = message
        self.status_code = status_code

class BadRequestError(APIError):
    def __init__(self, message):
        super().__init__(message, 400)

class NotFoundError(APIError):
    def __init__(self, message):
        super().__init__(message, 404)

class MethodNotAllowedError(APIError):
    def __init__(self, message):
        super().__init__(message, 405)

class UnsupportedMediaTypeError(APIError):
    def __init__(self, message):
        super().__init__(message, 415)

class InternalServerError(APIError):
    def __init__(self, message):
        super().__init__(message, 500)

class PayloadTooLargeError(APIError):
    def __init__(self, message):
        super().__init__(message, 413)


# Configuration constants
MAX_FILE_SIZE = 100 * 1024 * 1024  # 100MB (removed extra * 1024)
ALLOWED_EXTENSIONS = {'.mp4', '.avi', '.mov', '.mkv', '.wmv'}


# Validating the upload request for the file 
def validate_upload_request(request):
    # Checks included -> valid method, video field in request, if video is provided 

    if request.method != 'POST':
        raise MethodNotAllowedError("Only POST method is allowed")
    
    if not request.files:
        raise BadRequestError("No files sent in request")
    
    if 'video' not in request.files:
        raise BadRequestError("No 'video' field found in request")
    
    video = request.files['video']
    
    if not video:
        raise BadRequestError("No video file provided")
    
    if not video.filename or video.filename.strip() == '':
        raise BadRequestError("No video file selected")

    return video


# Validates the video file iteslf in terms of file size, extensions and filename
def validate_video_file(file):
    # Calculating the file size 
    file.seek(0, 2)  # Seek to end
    file_size = file.tell()
    file.seek(0)     
    
    #Checks if the file size is within limits
    if file_size == 0:
        raise BadRequestError("Video file is empty")
    
    if file_size > MAX_FILE_SIZE:
        raise PayloadTooLargeError(
            f"File size ({file_size / (1024*1024):.1f}MB) exceeds maximum "
            f"allowed size ({MAX_FILE_SIZE / (1024*1024)}MB)"
        )
    
    if not file.filename:
        raise BadRequestError("File has no name")
    

    # Validates for given extensions
    file_ext = os.path.splitext(file.filename)[1].lower()
    if file_ext not in ALLOWED_EXTENSIONS:
        raise UnsupportedMediaTypeError(
            f"Unsupported file format '{file_ext}'. "
            f"Allowed formats: {', '.join(ALLOWED_EXTENSIONS)}"
        )
    

# Validating the job request for getting the results
def validate_job_request(job_id, jobs):
    if not job_id:
        raise BadRequestError("Job ID is required")

    # Validate UUID format
    try:
        uuid.UUID(job_id)
    except ValueError:
        raise BadRequestError("Invalid job ID format")

    job = jobs.get(job_id)
    if not job:
        raise NotFoundError("Job not found")


def validate_file_serving(filename):
    if not filename:
        raise BadRequestError("Filename is required")
    
    if '..' in filename or '/' in filename or '\\' in filename:
        raise BadRequestError("Invalid filename - path traversal not allowed")
    
    return True

