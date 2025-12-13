#!/bin/bash

LOGFILE="logs/login.log"

echo "===== User Login ====="
read -p "Username: " username
read -s -p "Password: " password
echo ""

# 呼叫 Node.js API
response=$(curl -s -X POST http://localhost:3000/api/auth/login \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$username\", \"password\":\"$password\"}")

echo "Server response: $response"

# 判斷登入結果並寫入 log（Fail2ban 會讀這個）
if [[ "$response" == *"Login successful"* ]]; then
    echo "LOGIN SUCCESS - USER: $username - $(date)" >> "$LOGFILE"
else
    echo "LOGIN FAILED - USER: $username - $(date)" >> "$LOGFILE"
fi

