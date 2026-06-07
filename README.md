## How to Run

1. Find your IP:
   ipconfig getifaddr en0
2. In Bot.py update line 7:
   SERVER_URL = "http://YOUR_IP:8000"
3. Run the server:
   uvicorn Authentication:app --reload --host 0.0.0.0

### iOS App
1. Open the project in Xcode
2. In Auth.swift update the URL:
   let url = "http://YOUR_IP:8000"
3. Run on simulator or iPhone
