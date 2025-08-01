#!/bin/bash
# Ubuntu/Debian
curl -fsSL https://download.cursor.sh/linux | sh

# Arch Linux
yay -S cursor-bin

# Manual download
wget https://downloader.cursor.sh/linux/appImage/x64
chmod +x cursor-*.AppImage
sudo mv cursor-*.AppImage /usr/local/bin/cursor
