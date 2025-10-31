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

---

## Autonomous Pose Estimation Server (`pose_server.py`)

### Overview

The `pose_server.py` file implements a standalone Flask server dedicated to **autonomous, real-time pose estimation and squat form analysis**. This server uses MediaPipe for pose detection and provides **machine-generated feedback** without requiring human data labeling or supervision.

### Key Features

✅ **Rule-Driven Analysis**: All assessments are based on biomechanical rules and angle calculations
✅ **No Human Labeling**: Fully autonomous system with no training data required
✅ **Real-Time Processing**: Analyzes individual video frames via REST API
✅ **Comprehensive Feedback**: Returns form scores, pass/fail status, and specific form flags
✅ **Session Management**: Tracks squat counts and workout progress

### Architecture

```
┌─────────────────┐
│  Client/WebRTC  │
│   (Frontend)    │
└────────┬────────┘
         │ HTTP POST
         │ /analyze_frame
         ▼
┌─────────────────────────┐
│   pose_server.py        │
│   (Flask on port 5001)  │
├─────────────────────────┤
│  • MediaPipe Pose       │
│  • SquatAnalyzer        │
│  • Rule Engine          │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│   Response JSON         │
│  • form_score           │
│  • pass_fail            │
│  • flags                │
│  • metrics              │
└─────────────────────────┘
```

### API Endpoints

#### 1. Health Check
```bash
GET /health
```
Returns server status and MediaPipe availability.

**Response:**
```json
{
  "status": "healthy",
  "service": "pose_server",
  "mediapipe_loaded": true
}
```

#### 2. Analyze Frame
```bash
POST /analyze_frame
Content-Type: application/json
```

**Request Body:**
```json
{
  "frame": "base64_encoded_image_string",
  "session_id": "optional_session_id",
  "include_landmarks": false
}
```

**Response:**
```json
{
  "success": true,
  "pose_detected": true,
  "analysis": {
    "form_score": 85.5,
    "pass_fail": "PASS",
    "flags": [],
    "metrics": {
      "knee_angle": 92.34,
      "hip_angle": 145.67,
      "torso_lean": 0.08,
      "left_knee_angle": 91.5,
      "right_knee_angle": 93.18
    },
    "squat_count": 5,
    "squat_state": "up"
  }
}
```

#### 3. Reset Session
```bash
POST /reset_session
```
Resets squat counter and analyzer state for a new workout session.

#### 4. Get Statistics
```bash
GET /get_stats
```
Returns current session statistics (squat count, state).

### Form Assessment Rules

The `SquatAnalyzer` class implements the following autonomous rules:

| Rule | Assessment | Penalty |
|------|------------|----------|
| **Depth** | Knee angle should reach ~90° or below | -20 points if > 110° |
| **Hip Hinge** | Proper hip flexion during descent | -15 points if insufficient |
| **Torso Position** | Maintain upright position | -15 points if excessive lean |
| **Knee Alignment** | Knees track over toes (no valgus) | -20 points if knees cave in |
| **Symmetry** | Bilateral movement consistency | -15 points if asymmetric |

**Pass Threshold:** Form score ≥ 70

### Form Flags

The system automatically generates these flags when issues are detected:

- `NOT_DEEP_ENOUGH`: Squat depth insufficient (knee angle > 110°)
- `TOO_DEEP`: Excessive depth that may compromise form (knee angle < 70°)
- `INSUFFICIENT_HIP_HINGE`: Limited hip flexion during movement
- `EXCESSIVE_FORWARD_LEAN`: Torso leans too far forward
- `KNEE_VALGUS`: Knees cave inward (potential injury risk)
- `ASYMMETRIC_FORM`: Left/right sides moving differently

### Installation & Setup

#### 1. Install Dependencies
```bash
pip install flask flask-cors mediapipe opencv-python numpy
```

#### 2. Run the Server
```bash
python pose_server.py
```

The server will start on `http://0.0.0.0:5001`

#### 3. Test the Server
```bash
# Health check
curl http://localhost:5001/health

# Test frame analysis (requires base64 image)
curl -X POST http://localhost:5001/analyze_frame \
  -H "Content-Type: application/json" \
  -d '{"frame": "<base64_image_data>"}'
```

### Integration with Node.js Signaling Server

To connect the pose estimation server with the Node.js WebRTC signaling server:

#### Step 1: Configure CORS

The `pose_server.py` already includes Flask-CORS configuration. Ensure your Node.js server's origin is allowed.

#### Step 2: Client-Side Integration (Frontend)

```javascript
// Capture video frame from WebRTC stream
const captureFrame = (videoElement) => {
  const canvas = document.createElement('canvas');
  canvas.width = videoElement.videoWidth;
  canvas.height = videoElement.videoHeight;
  const ctx = canvas.getContext('2d');
  ctx.drawImage(videoElement, 0, 0);
  return canvas.toDataURL('image/jpeg', 0.8);
};

// Send frame to pose server
const analyzePose = async (frameData) => {
  try {
    const response = await fetch('http://localhost:5001/analyze_frame', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ frame: frameData })
    });
    const result = await response.json();
    
    if (result.success && result.pose_detected) {
      console.log('Form Score:', result.analysis.form_score);
      console.log('Status:', result.analysis.pass_fail);
      console.log('Flags:', result.analysis.flags);
      // Update UI with feedback
    }
  } catch (error) {
    console.error('Pose analysis error:', error);
  }
};

// Periodic frame analysis (e.g., every 500ms)
setInterval(() => {
  const frame = captureFrame(videoElement);
  analyzePose(frame);
}, 500);
```

#### Step 3: Node.js Server Proxy (Optional)

For better architecture, you can proxy requests through the Node.js signaling server:

```javascript
// In your Node.js signaling server (e.g., server.js)
const axios = require('axios');

app.post('/api/analyze', async (req, res) => {
  try {
    const response = await axios.post('http://localhost:5001/analyze_frame', {
      frame: req.body.frame,
      session_id: req.body.session_id
    });
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: 'Pose analysis failed' });
  }
});
```

#### Step 4: WebRTC Data Channel Integration (Advanced)

For lower latency, send frames via WebRTC data channels:

```javascript
// Create data channel for pose feedback
const dataChannel = peerConnection.createDataChannel('pose-feedback');

dataChannel.onmessage = (event) => {
  const analysis = JSON.parse(event.data);
  // Display real-time feedback in UI
  updateFeedbackUI(analysis);
};

// Server-side: relay pose analysis results through WebRTC
```

### Production Deployment

#### Using Docker

Create a `Dockerfile` for the pose server:

```dockerfile
FROM python:3.9-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY pose_server.py .

EXPOSE 5001

CMD ["python", "pose_server.py"]
```

**requirements.txt:**
```
flask==2.3.0
flask-cors==4.0.0
mediapipe==0.10.9
opencv-python==4.8.1.78
numpy==1.24.3
```

Build and run:
```bash
docker build -t optifit-pose-server .
docker run -p 5001:5001 optifit-pose-server
```

#### Using Docker Compose

Add to your `docker-compose.yml`:

```yaml
services:
  pose-server:
    build: ./optifit backend
    ports:
      - "5001:5001"
    environment:
      - FLASK_ENV=production
    networks:
      - optifit-network

  signaling-server:
    # Your existing Node.js signaling server config
    depends_on:
      - pose-server
    networks:
      - optifit-network

networks:
  optifit-network:
    driver: bridge
```

### Performance Considerations

- **Frame Rate**: Analyze 2-4 frames per second for optimal balance
- **Image Quality**: JPEG quality 0.7-0.8 reduces bandwidth without losing accuracy
- **Batch Processing**: For recorded videos, process frames in parallel
- **Caching**: Consider Redis for session state in multi-instance deployments

### Troubleshooting

#### MediaPipe Not Loading
```bash
pip install --upgrade mediapipe opencv-python
```

#### CORS Issues
Verify Flask-CORS is installed and origins are configured correctly in `pose_server.py`.

#### Slow Processing
- Reduce video resolution to 640x480
- Adjust MediaPipe model complexity (currently set to 1)
- Use GPU acceleration if available

### Future Enhancements

- [ ] Support for additional exercises (pushups, lunges, deadlifts)
- [ ] GPU acceleration with CUDA
- [ ] Multi-person pose detection
- [ ] Historical analysis and progress tracking
- [ ] Custom rule configuration via API
- [ ] WebSocket support for streaming analysis

---

## License

This backend is part of the OptiFit project. See the main repository for license information.
