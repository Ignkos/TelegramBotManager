from telegram import Update, ReplyKeyboardMarkup
from telegram.ext import Application, CommandHandler, ContextTypes, MessageHandler, filters
import json
import asyncio
import httpx

SERVER_URL = "http://Your_IP:8000"
SERVER_TOKEN = ""


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE, blocks):
    response = "Welcome! Here are the available options:\n\n"
    buttons = []
    for block in blocks:
        if block["type"] == "scheduling":
            response += "📅 Tap the button to book a time slot\n"
            buttons.append(["/schedule"])
        if block["type"] == "ordering":
            response += "🛒 Tap the button to see the menu\n"
            buttons.append(["/order"])
    keyboard = ReplyKeyboardMarkup(buttons, resize_keyboard=True)
    await update.message.reply_text(response, reply_markup=keyboard)


async def schedule(update: Update, context: ContextTypes.DEFAULT_TYPE, sb, bot_id: str):
    blocks = sb.table("blocks").select("*").eq("bot_id", bot_id).execute().data
    scheduling = next((a for a in blocks if a["type"] == "scheduling"), None)
    if scheduling:
        config = json.loads(scheduling["config"])
        slots = config.get("slots", [])
        if slots:
            message_text = "Available time slots:\n\n"
            for i, slot in enumerate(slots, 1):
                message_text += f"{i}. {slot}\n"
            message_text += "\nReply with the number to book a slot."
            context.user_data["slots"] = slots.copy()
            context.user_data["waiting"] = "slot"
            context.user_data["schedule_block_id"] = scheduling["id"]
            context.user_data["bot_id"] = bot_id
            await update.message.reply_text(message_text)
        else:
            await update.message.reply_text("No time slots available yet.")
    else:
        await update.message.reply_text("Scheduling is not set up.")


async def order(update: Update, context: ContextTypes.DEFAULT_TYPE, sb, bot_id: str):
    blocks = sb.table("blocks").select("*").eq("bot_id", bot_id).execute().data
    ordering = next((b for b in blocks if b["type"] == "ordering"), None)
    if ordering:
        config = json.loads(ordering["config"])
        items = config.get("items", [])
        if items:
            message_text = "Our menu:\n\n"
            for i, item in enumerate(items, 1):
                message_text += f"{i}. {item}\n"
            message_text += "\nReply with the number to order."
            context.user_data["items"] = items.copy()
            context.user_data["waiting"] = "item"
            context.user_data["bot_id"] = bot_id
            await update.message.reply_text(message_text)
        else:
            await update.message.reply_text("No menu items yet.")
    else:
        await update.message.reply_text("Ordering is not set up.")


async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    text = update.message.text
    waiting = context.user_data.get("waiting")

    if waiting == "slot":
        try:
            index = int(text) - 1
            slots = context.user_data.get("slots", [])
            if 0 <= index < len(slots):
                context.user_data["selected_slot"] = slots[index]
                context.user_data["waiting"] = "name_schedule"
                await update.message.reply_text(f"You selected {slots[index]}. What's your name?")
            else:
                await update.message.reply_text("Invalid number. Please try again.")
        except ValueError:
            await update.message.reply_text("Please reply with a number.")

    elif waiting == "name_schedule":
        slot = context.user_data.get("selected_slot")
        slots = context.user_data.get("slots", [])
        block_id = context.user_data.get("schedule_block_id")
        bot_id = context.user_data.get("bot_id")

        if slot in slots:
            slots.remove(slot)

        new_config = json.dumps({"slots": slots})
        async with httpx.AsyncClient() as client:
            await client.put(
                f"{SERVER_URL}/blocks/{block_id}",
                params={"config": new_config},
                headers={"Authorization": f"Bearer {SERVER_TOKEN}"}
            )
            await client.post(  # ← add this
                f"{SERVER_URL}/bookings",
                params={"bot_id": bot_id, "type": "scheduling", "name": text, "selection": slot},
                headers={"Authorization": f"Bearer {SERVER_TOKEN}"}
            )

        context.user_data["waiting"] = None
        await update.message.reply_text(f"✅ Booked {slot} for {text}. See you then!")

    elif waiting == "item":
        try:
            index = int(text) - 1
            items = context.user_data.get("items", [])
            if 0 <= index < len(items):
                context.user_data["selected_item"] = items[index]
                context.user_data["waiting"] = "name_order"
                await update.message.reply_text(f"You selected {items[index]}. What's your name?")
            else:
                await update.message.reply_text("Invalid number. Please try again.")
        except ValueError:
            await update.message.reply_text("Please reply with a number.")

    elif waiting == "name_order":
        item = context.user_data.get("selected_item")
        bot_id = context.user_data.get("bot_id")
        async with httpx.AsyncClient() as client:
            await client.post(
                f"{SERVER_URL}/bookings",
                params={"bot_id": bot_id, "type": "ordering", "name": text, "selection": item},
                headers={"Authorization": f"Bearer {SERVER_TOKEN}"}
            )
        context.user_data["waiting"] = None
        await update.message.reply_text(f"✅ Order placed: {item} for {text}. See you soon!")


def run_bot(token: str, blocks: list, server_token: str, sb, bot_id: str):
    global SERVER_TOKEN
    SERVER_TOKEN = server_token
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    loop.run_until_complete(run_bot_async(token, blocks, sb, bot_id))


async def run_bot_async(token: str, blocks: list, sb, bot_id: str):
    app = Application.builder().token(token).build()

    app.add_handler(CommandHandler("start", lambda u, c: start(u, c, blocks)))
    app.add_handler(CommandHandler("schedule", lambda u, c: schedule(u, c, sb, bot_id)))
    app.add_handler(CommandHandler("order", lambda u, c: order(u, c, sb, bot_id)))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))

    await app.initialize()
    await app.start()
    await app.updater.start_polling()

    while True:
        await asyncio.sleep(1)