# AI Visual Assistant for the Visually Impaired

This repository contains the source code for a 4th-year computer science project focused on developing a mobile application to assist blind and low-vision (BLV) users. The application leverages state-of-the-art multimodal AI models to provide real-time information about the user's surroundings.

## Project Overview

The primary goal of this project is to create a functional prototype of an AI-powered "seeing-eye" assistant. The application allows users to capture images of their environment and ask questions in natural language to gain a better understanding of the scene, identify objects, and receive crucial safety information. The system is built on a robust hybrid architecture that balances cutting-edge performance with real-world reliability.

## Features

* **Interactive Scene Explorer (VQA):** The core feature of the application. Users can take a picture and ask questions like "What is in front of me?" or "Is there a clear space on this table?".
* **Hybrid AI Engine:** The application uses a sophisticated backend that can switch between two primary AI models:
    * **Gemini Flash (API-Based):** A state-of-the-art model from Google that provides extremely fast, detailed, and proactively safe responses. This is the primary engine for the best user experience.
    * **Llava (Local):** A powerful, self-hosted model that serves as a reliable offline failsafe, ensuring the app remains functional even without an internet connection.
* **User-Friendly Model Selection:** The mobile app provides a simple dropdown menu for the user to choose their preferred model based on their needs (e.g., speed vs. offline availability).

## Architecture

The project follows a standard client-server architecture:

* **Frontend (Mobile App):**
    * **Framework:** Flutter
    * **Responsibilities:** Capturing images, handling user input (text and voice), sending requests to the backend, and presenting the AI-generated answers to the user, primarily through text-to-speech.
* **Backend (Server):**
    * **Framework:** Python with FastAPI
    * **Responsibilities:** Receiving requests from the mobile app, preprocessing images, routing requests to the appropriate AI model (Gemini API or local Ollama service), and returning the final answer.

## Setup and Installation

### Backend Setup

1.  **Clone the repository:**
    ```
    git clone [your-repository-url]
    cd [your-repository-name]/Backend
    ```
2.  **Create and activate a virtual environment:**
    ```
    # Create the environment
    python -m venv .venv

    # Activate on Windows (PowerShell)
    .\.venv\Scripts\Activate.ps1

    # Activate on macOS/Linux
    source .venv/bin/activate
    ```
3.  **Install Python dependencies:**
    ```
    pip install -r requirements.txt
    ```
4.  **Set up local model (Llava):**
    * Install [Ollama](https://ollama.com/).
    * Pull the Llava model:
    ```
    ollama pull llava
    ```
5.  **Set up environment variables:**
    * Create a file named `.env` in the `Backend` directory.
    * Add your Google Gemini API key to it:
    ```
    GEMINI_API_KEY="YOUR_API_KEY_HERE"
    ```

### Frontend Setup

1.  **Ensure you have the Flutter SDK installed.**
2.  **Navigate to the mobile app directory:**
    ```
    cd ../Mobile app
    ```
3.  **Get Flutter dependencies:**
    ```
    flutter pub get
    ```

## How to Run the Application

1.  **Start the local model server (if testing Llava):**
    * Ensure the Ollama application/service is running.
2.  **Start the backend server:**
    * In your activated backend environment, run:
    ```
    uvicorn main:app --host 0.0.0.0 --port 8000
    ```
3.  **Run the Flutter app:**
    * Open the `Mobile app` folder in your IDE (like VS Code or Android Studio).
    * Run the app on an emulator or a physical device.
    * **Important:** In the app, make sure to enter the correct local IP address of the machine running the backend server.

## Project Status (As of June 12, 2025)

* **[Complete]** Phase 1: Research and pivot from object detection to VQA.
* **[Complete]** Phase 2: Development of a full-stack prototype.
* **[Complete]** Phase 3: Systematic evaluation and selection of final AI models.
* **[Complete]** Phase 4: Refactoring of backend and frontend to implement the final hybrid architecture.
* **[In Progress]** Phase 5: Development of core application features (Scene Explorer, Text Reader).
* **[Upcoming]** Phase 6: Research and implementation for video analysis capabilities.
