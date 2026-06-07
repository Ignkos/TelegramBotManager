from fastapi import FastAPI, HTTPException, Header, Request
from pydantic import BaseModel, EmailStr
from jose import jwt
from supabase import create_client
from datetime import datetime, timedelta
import bcrypt
from fastapi.middleware.cors import CORSMiddleware
from Bot import run_bot
import threading

app = FastAPI()
sb = create_client("https://ghkpniqjhcejftifyyns.supabase.co", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdoa3BuaXFqaGNlamZ0aWZ5eW5zIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3OTYyNTk3OSwiZXhwIjoyMDk1MjAxOTc5fQ.wwpgvL-lzTmfgfCR2bvjv8hi9m_wH5BWuEwRBwJQG6Q")
key = "RanDomkey__192837--"

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    username: str

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

def genToken(userID):
    payload = {"user": userID, "exp": datetime.now() + timedelta(days=3)}
    return jwt.encode(payload, key, algorithm="HS256")

@app.post("/auth/register")
def register(data: RegisterRequest):
    realUsers = sb.table("users").select("id").eq("email", data.email).execute()
    if realUsers.data:
        raise HTTPException(status_code=409, detail="This email is already used")

    hashedPass = bcrypt.hashpw(data.password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")
    response = sb.table("users").insert({"email": data.email, "password": hashedPass, "username": data.username}).execute()
    return {"token": genToken(response.data[0]["id"])}


@app.post("/auth/login")
def login(data: LoginRequest):
    response = sb.table("users").select("*").eq("email", data.email).execute()
    if not response.data:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    user = response.data[0]

    if not bcrypt.checkpw(data.password.encode("utf-8"), user["password"].encode("utf-8")):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    return {"token": genToken(user["id"])}


def get_user_id(request: Request) -> str:
    auth = request.headers.get("authorization")
    if not auth:
        raise HTTPException(status_code=401, detail="No token")
    token = auth.split(" ")[1]
    try:
        payload = jwt.decode(token, key, algorithms=["HS256"])
        return payload["user"]
    except:
        raise HTTPException(status_code=401, detail="Invalid token")


@app.get("/me")
def get_me(request: Request):
    user_id = get_user_id(request)
    result = sb.table("users").select("id, email, username").eq("id", user_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="User not found")
    return result.data[0]


@app.post("/bots")
def create_bot(request: Request, bot_name: str, telegram_token: str):
    user_id = get_user_id(request)
    result = sb.table("Telegram_bots").insert({"user_id": user_id,"bot_name": bot_name,"telegram_token": telegram_token}).execute()
    return result.data[0]


@app.get("/bots")
def get_bots(request: Request):
    user_id = get_user_id(request)
    result = sb.table("Telegram_bots").select("*").eq("user_id", user_id).execute()
    return result.data


@app.delete("/bots/{bot_id}")
def delete_bot(bot_id: str, request: Request):
    user_id = get_user_id(request)
    sb.table("Telegram_bots").delete().eq("id", bot_id).eq("user_id", user_id).execute()
    return {"message": "Bot deleted"}

@app.get("/bots/{bot_id}/blocks")
def get_blocks(bot_id: str, request: Request):
    user_id = get_user_id(request)
    result = sb.table("blocks").select("*").eq("bot_id", bot_id).execute()
    return result.data

@app.post("/bots/{bot_id}/blocks")
def add_block(bot_id: str, request: Request, block_type: str, config: str):
    user_id = get_user_id(request)
    result = sb.table("blocks").insert({
        "bot_id": bot_id,
        "type": block_type,
        "config": config
    }).execute()
    return result.data[0]

@app.delete("/blocks/{block_id}")
def delete_block(block_id: str, request: Request):
    user_id = get_user_id(request)
    sb.table("blocks").delete().eq("id", block_id).execute()
    return {"message": "Block deleted"}

@app.put("/blocks/{block_id}")
def update_block(block_id: str, request: Request, config: str):
    user_id = get_user_id(request)
    result = sb.table("blocks").update({"config": config}).eq("id", block_id).execute()
    return result.data[0]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.post("/bots/{bot_id}/start")
def start_bot(bot_id: str, request: Request):
    user_id = get_user_id(request)
    auth = request.headers.get("authorization")
    server_token = auth.split(" ")[1]

    result = sb.table("Telegram_bots").select("*").eq("id", bot_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="Bot not found")

    bot = result.data[0]
    blocks = sb.table("blocks").select("*").eq("bot_id", bot_id).execute().data

    thread = threading.Thread(target=run_bot, args=(bot["telegram_token"], blocks, server_token, sb, bot["id"]))
    thread.daemon = True
    thread.start()

    return {"message": "Bot started"}

@app.post("/bookings")
def create_booking(request: Request, bot_id: str, type: str, name: str, selection: str):
    user_id = get_user_id(request)
    result = sb.table("Bookings").insert({
        "bot_id": bot_id,
        "type": type,
        "name": name,
        "selection": selection
    }).execute()
    return result.data[0]

@app.get("/bots/{bot_id}/bookings")
def get_bookings(bot_id: str, request: Request):
    user_id = get_user_id(request)
    result = sb.table("Bookings").select("*").eq("bot_id", bot_id).execute()
    return result.data

@app.delete("/bookings/{booking_id}")
def delete_booking(booking_id: str, request: Request):
    user_id = get_user_id(request)
    sb.table("Bookings").delete().eq("id", booking_id).execute()
    return {"message": "Booking deleted"}