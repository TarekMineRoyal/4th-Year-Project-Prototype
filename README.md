![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![Architecture](https://img.shields.io/badge/Architecture-MVVM%20%26%20Clean-red)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

# AI Visual Assistant for the Visually Impaired

This repository contains the source code for a 4th-year computer science project focused on developing a mobile application to assist blind and low-vision (BLV) users. The application leverages state-of-the-art multimodal AI models to provide real-time information about the user's surroundings.

## Project Overview

The primary goal of this project is to create a functional prototype of an AI-powered "seeing-eye" assistant. The application allows users to capture images of their environment and interact with them through natural language to gain a better understanding of the scene, read text, and receive crucial safety information. The system is built on a robust and scalable client-server architecture, with a Flutter-based mobile application and a Python FastAPI backend.

## Features

* **Interactive Scene Explorer (VQA):** The core feature of the application. Users can take a picture and ask questions like "What is in front of me?" or "Is there a clear space on this table?" to get detailed and context-aware answers.
* **Text Reader (OCR):** Allows users to read text from signs, documents, and other objects in their environment by simply taking a picture.
* **Live Scene Analysis:** Provides a continuous, real-time description of the user's surroundings by analyzing frames from the device's camera feed and highlighting changes in the environment.
* **Centralized AI Engine:** The backend exclusively uses **Google's Gemini models** for all visual analysis tasks. This allows for easy updates and model management without requiring frontend changes.

## Architecture

The project follows a modern client-server architecture, ensuring a separation of concerns between the user interface and the backend processing.

* **Frontend (Mobile App):**
    * **Framework:** Flutter
    * **Architecture:** The application is structured using the **Model-View-ViewModel (MVVM)** pattern, with the **Provider** package for state management. This ensures a clean and maintainable codebase.
    * **Responsibilities:** Capturing images, handling user input, sending requests to the backend API, and displaying the AI-generated results.

* **Backend (Server):**
    * **Framework:** Python with FastAPI
    * **Architecture:** The backend is built with a clean, layered architecture, separating concerns into presentation (API endpoints), application (use cases), and infrastructure (services).
    * **Responsibilities:** Providing a robust API, processing image uploads, interfacing with the Gemini Vision API, and returning the analysis.

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
4.  **Set up environment variables:**
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

1.  **Start the backend server:**
    * In your activated backend environment, run:
    ```
    uvicorn main:app --host 0.0.0.0 --port 8000
    ```
2.  **Run the Flutter app:**
    * Open the `Mobile app` folder in your IDE (like VS Code or Android Studio).
    * Run the app on an emulator or a physical device.
    * **Important:** When the app first launches, it will prompt you to enter the local IP address of the machine running the backend server.

## Project Status (As of July 22, 2025)

* **[Complete]** Phase 1: Research and pivot from object detection to VQA.
* **[Complete]** Phase 2: Development of a full-stack prototype.
* **[Complete]** Phase 3: Systematic evaluation and selection of final AI models (centralized on Gemini).
* **[Complete]** Phase 4: Refactoring of backend to a clean, layered architecture and frontend to MVVM with Provider.
* **[Complete]** Phase 5: Implementation of core application features (Scene Explorer, Text Reader, Live Scene Analysis).
* **[Upcoming]** Phase 6: Further refinement, user testing, and exploring potential for Text-to-Speech (TTS) integration.
