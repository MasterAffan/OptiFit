# OptiFit Frontend Setup Guide

This guide provides step-by-step instructions for setting up the OptiFit frontend on your local machine.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK:** [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Dart SDK:** (Comes bundled with Flutter)
- **Android Studio / Xcode:** For Android/iOS development
- **Git:** For cloning the repository

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
    cd optifit/optifit app
    ```

### 3. Install dependencies:
    ```bash
    flutter pub get
    ```

3.  **Configure environment variables:**
    - Create a file named `.env` in the `optifit app` directory.
    - Add the following environment variables to the `.env` file:
      ```
      GEMINI_API_KEY=your_gemini_api_key
      NGROK_FORWARDING_URL=your_ngrok_forwarding_url
      ```
    - Replace `your_gemini_api_key` with your actual Gemini API key.
    - Replace `your_ngrok_forwarding_url` with the URL provided by ngrok after starting the backend server (e.g., `https://random-string.ngrok.io`).

4.  **Run the app:**
    - **Android:** Connect an Android device or start an emulator, then run:
      ```bash
      flutter run
      ```
    - **iOS:** Connect an iOS device or start a simulator, then run:
      ```bash
      flutter run
      ```

## Troubleshooting

- **Flutter Doctor:** Run `flutter doctor` to check for any missing dependencies or configuration issues.
- **Device Not Found:** Ensure your device is connected and recognized by running `flutter devices`.
- **Build Errors:** Try running `flutter clean` and then `flutter pub get` to resolve dependency issues.