import io
import os
import re
import string
import numpy as np
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from mangum import Mangum
from tensorflow.keras.models import load_model
from PIL import Image
from fastapi.middleware.cors import CORSMiddleware

# Initialize FastAPI and handler
app = FastAPI()
handler = Mangum(app)

# allow your frontend origin (or "*" to allow all)
origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,           # you can use ["*"] in development
    allow_credentials=True,
    allow_methods=["*"],             # allow POST, GET, OPTIONS, etc.
    allow_headers=["*"],             # allow Content-Type, Authorization, etc.
)

# Load Keras model
#MODEL_PATH = 'models/research_exp01.keras'
MODEL_PATH = 'models/research_exp01.keras'
model = load_model(MODEL_PATH)
IMG_SIZE = 175

# Image preprocessing for RGB images
async def preprocess_image(file: UploadFile) -> np.ndarray:
    contents = await file.read()
    try:
        # Convert to RGB instead of grayscale ('L')
        img = Image.open(io.BytesIO(contents)).convert('RGB').resize((IMG_SIZE, IMG_SIZE))
    except Exception:
        raise HTTPException(status_code=400, detail='Invalid image file')
    arr = np.array(img, dtype=np.float32)
    # Reshape with 3 channels instead of 1
    arr = arr.reshape((1, IMG_SIZE, IMG_SIZE, 3)) / 255.0
    return arr

@app.post('/predict-image')
async def predict_image(file: UploadFile = File(...)):
    img_arr = await preprocess_image(file)
    pred = model.predict(img_arr)[0][0]
    label = 'Jaundice Eye' if pred > 0.5 else 'Healthy Eye'
    confidence = float(pred) if pred > 0.5 else 1 - float(pred)
    return JSONResponse({'prediction': label, 'confidence': round(confidence, 3)})

@app.get('/')
def health_check():
    return {'status': 'healthy'}