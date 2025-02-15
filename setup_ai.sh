#!/bin/bash

echo "🚀 Begin AI-installatie..."
sleep 2

# Update en upgrade Ubuntu
echo "🔄 Systeem bijwerken..."
sudo apt update && sudo apt upgrade -y

# Installeer essentiële pakketten
echo "📦 Vereiste pakketten installeren..."
sudo apt install -y git python3-pip unzip wget tmux

# ROCm GPU-drivers installeren voor AMD GPU's
echo "⚙️ AMD GPU-drivers installeren..."
sudo apt install -y rocm-dev rocm-libs miopen-hip
echo 'export PATH=/opt/rocm/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Controleer of ROCm correct is geïnstalleerd
rocminfo || { echo "❌ ROCm installatie mislukt!"; exit 1; }

# Installeer PyTorch voor ROCm
echo "🔥 PyTorch installeren..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm5.4.2

# YOLOv5 downloaden en installeren
echo "📥 YOLOv5 downloaden..."
git clone https://github.com/ultralytics/yolov5.git
cd yolov5 || exit
pip install -r requirements.txt

# Dataset downloaden
echo "📂 Dataset downloaden..."
mkdir -p datasets/casino
cd datasets/casino || exit
wget https://www.kaggleusercontent.com/datasets/marco93/playing-cards -O playing_cards.zip
wget https://github.com/eriklindernoren/ML-Projects/raw/master/datasets/roulette.zip
unzip playing_cards.zip
unzip roulette.zip
cd ~/yolov5 || exit

# Trainingsconfiguraties aanmaken
echo "📝 Configuratiebestanden aanmaken..."
echo "train: datasets/casino/train
val: datasets/casino/val
nc: 3
names: ['kaart', 'fiche', 'nummer']" > datasets/cards.yaml

echo "train: datasets/casino/train
val: datasets/casino/val
nc: 3
names: ['nummer', 'kleur', 'fiche']" > datasets/roulette.yaml

# YOLOv5 trainen
echo "🎓 Start training voor speelkaarten..."
python train.py --img 640 --batch 16 --epochs 50 --data datasets/cards.yaml --weights yolov5s.pt --project runs/train/cards

echo "🎓 Start training voor roulette..."
python train.py --img 640 --batch 16 --epochs 50 --data datasets/roulette.yaml --weights yolov5s.pt --project runs/train/roulette

# Telegram-meldingen instellen
echo "📡 Telegram-notificatie instellen..."
cat <<EOT > telegram_notify.py
import requests

TELEGRAM_BOT_TOKEN = "7815675562:AAGkaleoBRaq2gd4xtTfeJFyh_-Emq9dYgA"
TELEGRAM_CHAT_ID = "7150147183"

def send_telegram_message(message):
    url = f"https://api.telegram.org/bot{7815675562:AAGkaleoBRaq2gd4xtTfeJFyh_-Emq9dYgA}/sendMessage"
    payload = {"chat_id": 7150147183, "text": message}
    requests.post(url, data=payload)

send_telegram_message("🚀 YOLO training is gestart!")
EOT

# Maak script uitvoerbaar en test Telegram-meldingen
chmod +x telegram_notify.py
python telegram_notify.py

echo "✅ Installatie voltooid! 🚀"
