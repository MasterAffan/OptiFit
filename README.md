<div align="center">

## 🎯 About OptiFit

OptiFit is an innovative mobile application designed to revolutionize your workout experience. Using the power of AI, OptiFit analyzes your exercise form in real-time, providing immediate feedback to help you improve your technique, prevent injuries, and maximize your results. Whether you're a beginner or a seasoned athlete, OptiFit is your personal AI trainer, available anytime, anywhere.

## ✨ Features

- ✅ **Real-Time Form Analysis:** Get instant feedback on your squat form, with more exercises to come.
- 🤖 **AI-Powered Chat:** Ask our AI assistant for fitness advice, workout plans, and nutritional guidance.
- 📊 **Track Your Progress:** Monitor your performance over time with detailed statistics and charts.
- 🏋️ **Personalized Workouts:** Coming soon: AI-generated workout plans tailored to your goals and abilities.

## 📂 Project Structure

This repository is a monorepo containing both the frontend mobile application and the backend server.

- **`optifit app/`**: The Flutter-based mobile application for Android and iOS.
  - [**Frontend README**](./optifit%20app/README_FRONTEND.md)
- **`optifit backend/`**: The Python-based Flask server that handles video processing and AI analysis.
  - [**Backend README**](./optifit%20backend/README_BACKEND.md)

## 🎥 Demo

<p align="center">
  <a href="optifit app/assets/videos/demo.mp4">
    <img src="optifit app/assets/applogo.png" alt="Click to watch demo video" width="300">
  </a>
</p>

> The demo video is included in the repository under `optifit app/assets/videos/demo.mp4`.
  
> Click the image above to open the video locally.

## 🚀 Getting Started

Ready to contribute? Follow our comprehensive setup guide to get both frontend and backend running:

- [**Master Setup Guide**](./SETUP.md)

## 📹 WebRTC Signaling Server

The `server.js` file provides a minimal backend signaling and room management implementation for live video workout sessions.

### Usage

```bash
# Install dependencies
npm install express socket.io

# Run the server
node server.js
```

The server runs on port 3000 by default (configurable via `PORT` environment variable).

### Socket.io Events

**Client → Server:**
- `join-room(roomId)` - Join a specific room
- `offer({target, offer})` - Send WebRTC offer to target peer
- `answer({target, answer})` - Send WebRTC answer to target peer
- `ice-candidate({target, candidate})` - Send ICE candidate to target peer
- `leave-room(roomId)` - Leave a specific room

**Server → Client:**
- `user-joined(userId)` - Notifies when a new user joins the room
- `offer({offer, sender})` - Receives WebRTC offer from sender
- `answer({answer, sender})` - Receives WebRTC answer from sender
- `ice-candidate({candidate, sender})` - Receives ICE candidate from sender
- `user-left(userId)` - Notifies when a user leaves the room

## 🤝 Contributors

A huge thank you to all the amazing contributors who have helped make OptiFit better!

<p align="center">
  <a href="https://github.com/MasterAffan/optifit/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=MasterAffan/optifit" alt="Contributors" />
  </a>
</p>

<!-- If your name is not appearing in the contributors list above, please add it here manually. -->
<sub><b>All contributors: Adez017, shubhranshu-sahu, Meghana-2124, Jai-76,Manar-Elhabbal7</b></sub>

## 🤝 Contributing

We welcome contributions from the community! Please read our [Contributing Guidelines](./CONTRIBUTING.md) for detailed instructions on how to contribute to this project.

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.
