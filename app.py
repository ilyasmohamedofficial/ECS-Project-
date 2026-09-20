from fastapi import FastAPI, HTTPException
from fastapi.responses import RedirectResponse
from pydantic import BaseModel
import boto3
import string
import random
import os

app = FastAPI()

# Get DynamoDB table name from environment variables (we will set this in Terraform)
TABLE_NAME = os.getenv("TABLE_NAME", "url-shortener-table")
REGION = os.getenv("AWS_REGION", "us-east-1")

# Initialize Boto3 DynamoDB resource
dynamodb = boto3.resource("dynamodb", region_name=REGION)
table = dynamodb.Table(TABLE_NAME)

class URLRequest(BaseModel):
    url: str

def generate_short_code(length=6):
    chars = string.ascii_letters + string.digits
    return "".join(random.choice(chars) for _ in range(length))

# 1. Health Check Endpoint (For your Load Balancer)
@app.get("/health")
def health_check():
    return {"status": "healthy"}

# 2. Shorten URL Endpoint (FastAPI receives URL -> Boto3 saves to DynamoDB)
@app.post("/shorten")
def shorten_url(request: URLRequest):
    short_code = generate_short_code()
    table.put_item(
        Item={
            "short_code": short_code,
            "original_url": request.url
        }
    )
    return {"short_code": short_code, "redirect_url": f"/{short_code}"}

# 3. Redirect Endpoint (FastAPI receives code -> Boto3 gets from DynamoDB -> Redirect)
@app.get("/{short_code}")
def redirect_to_url(short_code: str):
    response = table.get_item(Key={"short_code": short_code})
    item = response.get("Item")
    
    if not item:
        raise HTTPException(status_code=404, detail="Short URL not found")
        
    return RedirectResponse(url=item["original_url"], status_code=301)
