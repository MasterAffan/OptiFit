# Optifit Backend

This is the backend for the Optifit application. It's a Flask server that uses Python scripts to analyze workout videos, such as counting squats and providing form feedback. It utilizes MediaPipe for pose estimation and FFmpeg for video processing.

## Prerequisites

- Python 3.x
- [FFmpeg](https://ffmpeg.org/download.html): You must have FFmpeg installed and available in your system's PATH.

## Setup

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/optifit.git
    cd optifit/optifit backend
    ```

2.  **Create a virtual environment:**
    ```bash
    python -m venv venv
    source venv/bin/activate  # On Windows, use `venv\Scripts\activate`
    ```

3.  **Install the dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

4.  **Run the Flask server:**
    ```bash
    flask run
    ```

5.  **Expose your local server to the internet using ngrok:**
    - If you don't have ngrok, [download and install it](https://ngrok.com/download).
    - Run the following command to start an ngrok tunnel:
      ```bash
      ngrok http 5000
      ```
    - Copy the forwarding URL provided by ngrok (e.g., `https://random-string.ngrok.io`). You'll need this for the frontend.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request if you have any suggestions or improvements.