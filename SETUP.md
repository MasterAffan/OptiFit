# OptiFit Setup Guide

This guide provides comprehensive instructions for setting up both the frontend and backend of the OptiFit application.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter:** For running the mobile application.
- **Python 3.x:** For running the backend server.
- **ngrok:** For exposing the local backend server to the internet.
- **FFmpeg:** For video processing on the backend.

## Getting Started

### 1. Fork the Repository

1.  Go to the [OptiFit repository](https://github.com/your-username/optifit) on GitHub.
2.  Click the **"Fork"** button in the top-right corner of the page.
3.  This will create a copy of the repository under your GitHub account.

### 2. Clone Your Fork

1.  Open your terminal or command prompt.
2.  Navigate to the directory where you want to clone the repository.
3.  Run the following command, replacing `your-username` with your actual GitHub username:
    ```bash
    git clone https://github.com/your-username/optifit.git
    cd optifit
    ```

### 3. Set Up the Backend

For detailed instructions on setting up the backend, please refer to the backend setup guide:

- [**Backend Setup Guide**](./optifit%20backend/SETUP_BACKEND.md)

### 4. Set Up the Frontend

For detailed instructions on setting up the frontend, please refer to the frontend setup guide:

- [**Frontend Setup Guide**](./optifit%20app/SETUP_FRONTEND.md)

## Running the Full Application

1.  **Start the backend server:** Follow the instructions in the backend setup guide to start the Flask server.
2.  **Start the ngrok tunnel:** Use ngrok to expose your local backend server to the internet.
3.  **Configure the frontend:** Update the `.env` file in the `optifit app` directory with your ngrok forwarding URL and Gemini API key.
4.  **Run the frontend app:** Follow the instructions in the frontend setup guide to run the Flutter application on your device or emulator.