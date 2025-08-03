![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-47A248?style=for-the-badge&logo=mongodb&logoColor=white)
![Architecture](https://img.shields.io/badge/Architecture-MVVM%20%26%20Clean-red)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

# AI Visual Assistant for the Visually Impaired

This repository contains the source code for a 4th-year computer science project focused on developing a mobile application to assist blind and low-vision (BLV) users. The application leverages state-of-the-art multimodal AI models to provide real-time information about the user's surroundings.

## 🚀 Project Overview

The primary goal of this project is to create a functional prototype of an AI-powered "seeing-eye" assistant. The application allows users to capture images or video of their environment and interact with them through natural language to gain a better understanding of the scene, read text, and receive crucial safety information. The system is built on a robust and scalable client-server architecture, with a Flutter-based mobile application and a Python FastAPI backend.

## ✨ Features

* **Interactive Scene Explorer (VQA):** The core feature of the application. Users can take a picture and ask questions like "What is in front of me?" or "Is there a clear space on this table?" to get detailed and context-aware answers.
* **Text Reader (OCR):** Allows users to read text from signs, documents, and other objects in their environment by simply taking a picture.
* **Live Session Q&A:** This feature allows users to record a scene by capturing a series of video clips or image frames. The backend then constructs a narrative of the events in the scene, and the user can ask questions about it.
* **Centralized AI Engine:** The backend allows for easy updates and model management without requiring frontend changes.
* **Dataset Creation:** Every request to the VQA endpoint is logged to a MongoDB database, creating a valuable dataset for future research and model fine-tuning.

## 🏗️ Architecture

The project follows a modern client-server architecture, ensuring a separation of concerns between the user interface and the backend processing.

* ### **Frontend (Mobile App)**
    * **Framework:** Flutter
    * **Architecture:** The application is structured using the **Model-View-ViewModel (MVVM)** pattern, with the **Provider** package for state management. This ensures a clean and maintainable codebase.
    * **Responsibilities:** Capturing images and video, handling user input, sending requests to the backend API, and displaying the AI-generated results.

* ### **Backend (Server)**
    * **Framework:** Python with FastAPI
    * **Architecture:** The backend is built with a clean, layered architecture, separating concerns into presentation (API endpoints), application (use cases), and infrastructure (services).
    * **Database:** MongoDB is used for logging requests and creating a dataset.
    * **Responsibilities:** Providing a robust API, processing image and video uploads, interfacing with the Gemini Vision API, and returning the analysis.

## 🛠️ Setup and Installation

### Backend Setup

1.  **Clone the repository:**
    ```
    git clone [your-repository-url]
    cd [your-repository-name]
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
    * Create a file named `.env` in the root directory.
    * Add your Google Gemini API key to it:
        ```
        GEMINI_API_KEY="YOUR_API_KEY_HERE"
        ```
    * You can also configure the MongoDB connection string in the `.env` file (it defaults to `mongodb://localhost:27017`):
        ```
        MONGODB_URI="YOUR_MONGODB_URI"
        ```

### Frontend Setup

1.  **Ensure you have the Flutter SDK installed.**
2.  **Navigate to the `lib` directory:**
    ```
    cd lib
    ```
3.  **Get Flutter dependencies:**
    ```
    flutter pub get
    ```

## 🚀 How to Run the Application

1.  **Start the backend server:**
    * In your activated backend environment, run:
        ```
        uvicorn main:app --host 0.0.0.0 --port 8000
        ```
    * Ensure that your MongoDB server is running.
2.  **Run the Flutter app:**
    * Open the project in your IDE (like VS Code or Android Studio).
    * Run the app on an emulator or a physical device.
    * **Important:** When the app first launches, it will prompt you to enter the local IP address of the machine running the backend server.
