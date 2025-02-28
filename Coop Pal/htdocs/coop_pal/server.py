# server.py

import os
import cv2
import glob
import numpy as np
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, FileResponse
from ultralytics import YOLO
from fastapi.staticfiles import StaticFiles

# Path of YOLOv8 model
model = YOLO("Egg Detection/EggDetectionAI - Nano.pt")

# Path of stored images from ESP32 CAM
IMAGE_FOLDER = "Egg Detection/images"

app = FastAPI()

# CORS setup
app.add_middleware(
    CORSMiddleware,
    allow_origins = ["*"],
    allow_credentials = True,
    allow_methods = ["*"],
    allow_headers = ["*"],
)

app.mount("/static", StaticFiles(directory = "Egg Detection/static"), name = "static")

def get_latest_image():
    """Get the latest image from the folder."""
    list_of_files = glob.glob(os.path.join(IMAGE_FOLDER, "*.png"))  # Change extension if needed
    if not list_of_files:
        return None
    return max(list_of_files, key=os.path.getctime)


@app.get("/analyze")
def analyze():
    latest_image = get_latest_image()
    if latest_image is None:
        return JSONResponse({"error": "No images found"}, status_code=404)

    results = model(latest_image)
    num_eggs = len(results[0].boxes)

    img = cv2.imread(latest_image)
    for box in results[0].boxes:
        x1, y1, x2, y2 = map(int, box.xyxy[0])
        cv2.rectangle(img, (x1, y1), (x2, y2), (0, 255, 0), 2)

    output_filename = "annotated.png"
    output_path = os.path.join("Egg Detection/static", output_filename)
    cv2.imwrite(output_path, img)

    return {"num_eggs": num_eggs, "image_url": f"/static/{output_filename}"}

@app.get("/static/annotated.png")
def get_annotated_image():
    return FileResponse("Egg Detection/static/annotated.png")