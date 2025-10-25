# OptiFit Backend

This is the backend for the OptiFit application, a Python-based Flask server responsible for processing workout videos and providing AI-driven analysis. It uses MediaPipe for pose estimation and FFmpeg for video processing.

## Features

- **Video Upload & Processing:** Accepts video uploads from the frontend.
- **Squat Analysis:** Analyzes squat form, counting reps and identifying common issues like shallow depth or knees caving in.
- **Real-time Feedback:** Provides detailed feedback on each rep.
- **Video Processing:** Uses FFmpeg to process and annotate videos for playback.

## Architecture

The backend is built using the Flask framework and follows a RESTful API design. Key components include:

- **Flask Application:** The main server handling HTTP requests.
- **Video Processing Service:** Uses MediaPipe for pose detection and FFmpeg for video encoding.
- **API Endpoints:** Provides endpoints for video upload, processing status, and result retrieval.

## Getting Started

### Docker Deployment (Recommended)

For quick deployment using Docker:

```bash
# Using Docker Compose
docker-compose up -d

# Test the API
curl http://localhost:5000/ping
```

For detailed Docker deployment instructions, see:
- [**Docker Deployment Guide**](./deployment/DOCKER_DEPLOYMENT.md)

### Manual Setup

For manual setup and development, please refer to:
- [**Backend Setup Guide**](./SETUP_BACKEND.md)