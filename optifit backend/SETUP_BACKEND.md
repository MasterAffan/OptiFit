# OptiFit Backend Setup Guide

This guide provides step-by-step instructions for setting up the OptiFit backend on your local machine.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Python 3.x:** [Install Python](https://www.python.org/downloads/)
- **pip:** Python's package installer (usually comes with Python)
- **Git:** For cloning the repository
- **FFmpeg:** For video processing. [Install FFmpeg](https://ffmpeg.org/download.html) and ensure it's added to your system's PATH.

## Setup Instructions

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
    cd optifit/optifit backend
    ```

### 3. Create a virtual environment (recommended):**
    ```bash
    python -m venv venv
    ```
    - **Activate the virtual environment:**
      - **Windows:** `venv\Scripts\activate`
      - **macOS/Linux:** `source venv/bin/activate`

3.  **Install the dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

4.  **Verify FFmpeg installation:**
    ```bash
    ffmpeg -version
    ```
    If FFmpeg is installed correctly, you should see its version information.

5.  **Run the Flask server:**
    ```bash
    flask run
    ```
    The server will start on `http://localhost:5000`.

6.  **Expose your local server to the internet using ngrok:**
    - If you don't have ngrok, [download and install it](https://ngrok.com/download).
    - Run the following command to start an ngrok tunnel:
      ```bash
      ngrok http 5000
      ```
    - Copy the forwarding URL provided by ngrok (e.g., `https://random-string.ngrok.io`). You'll need this for the frontend.

## API Endpoints

Once the server is running, you can interact with the following endpoints:

- **GET `/`**: Returns a welcome message and available routes.
- **GET `/ping`**: Checks if the server is live.
- **POST `/upload`**: Uploads a video for squat analysis.
- **GET `/result/<job_id>`**: Retrieves the analysis results for a given job ID.
- **GET `/processed/<filename>`**: Serves the processed video file.

## Troubleshooting

- **ModuleNotFoundError:** Ensure all dependencies are installed by running `pip install -r requirements.txt`.
- **FFmpeg not found:** Make sure FFmpeg is installed and added to your system's PATH.
- **Port already in use:** If port 5000 is already in use, you can specify a different port: `flask run --port 5001`.