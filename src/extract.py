import requests
import json
from pathlib import Path

# Project paths
BASE_DIR = Path(__file__).resolve().parent.parent
RAW_FOLDER = BASE_DIR / "data" / "raw"

# Create raw folder if it doesn't exist
RAW_FOLDER.mkdir(parents=True, exist_ok=True)

# API endpoints
endpoints = {
    "products": "https://fakestoreapi.com/products",
    "carts": "https://fakestoreapi.com/carts",
    "users": "https://fakestoreapi.com/users"
}

# Extract data
for name, url in endpoints.items():

    response = requests.get(url, timeout=30)
    response.raise_for_status()

    data = response.json()

    file_path = RAW_FOLDER / f"data_{name}.json"

    with open(file_path, "w") as file:
        json.dump(data, file, indent=4)

    print(f"{name} data extracted successfully")