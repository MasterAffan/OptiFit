<div align="center">
  <img src="optifit app/assets/applogo.png" alt="OptiFit Logo" width="200">

# OptiFit 🏋️

Your AI-Powered Personal Trainer

  [![Contributors](https://img.shields.io/github/contributors/MasterAffan/OptiFit?style=flat-square)](https://github.com/MasterAffan/OptiFit/graphs/contributors)
  [![Forks](https://img.shields.io/github/forks/MasterAffan/OptiFit?style=flat-square)](https://github.com/MasterAffan/OptiFit/network/members)
  [![Stars](https://img.shields.io/github/stars/MasterAffan/OptiFit?style=flat-square)](https://github.com/MasterAffan/OptiFit/stargazers)
  [![Issues](https://img.shields.io/github/issues/MasterAffan/OptiFit?style=flat-square)](https://github.com/MasterAffan/OptiFit/issues)
  [![MIT License](https://img.shields.io/github/license/MasterAffan/OptiFit?style=flat-square)](https://github.com/MasterAffan/OptiFit/blob/main/LICENSE)
</div>

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
>
> Click the image above to open the video locally.

## 🚀 Getting Started

Ready to contribute? Follow our comprehensive setup guide to get both frontend and backend running:

- [**Master Setup Guide**](./SETUP.md)

## 📹 WebRTC Signaling Server

The `server.js` file provides a minimal backend signaling and room management implementation for live video workout sessions.

### Setup

```bash
npm install express@4.18.x socket.io@4.7.x
node server.js
```

The server will listen on port 3000 by default.

### Features

- Real-time signaling for WebRTC peer-to-peer connections
- Room management for workout sessions
- Broadcasting messages within rooms

### Usage

Clients can connect via Socket.IO and join rooms to establish peer-to-peer video connections for collaborative workout sessions.

---

## 🤝 Contributing

We welcome contributions from everyone! Please check out our [Contributing Guide](CONTRIBUTING.md) for guidelines about how to proceed.

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.

## 🌟 Show Your Support

Give a ⭐️ if this project helped you!

---

Made with ❤️ by the OptiFit team
