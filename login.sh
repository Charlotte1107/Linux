#!/bin/bash

LOGFILE="/var/log/node-login/login.log"

echo "===== User Login ====="
read -p "Username: " username
read -s -p "Password: " password
echo ""

# 呼叫 Node.js API（注意：路徑要和 server.js 一致）
response=$(curl -s -X POST http://localhost:3000/login \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$username\", \"password\":\"$password\"}")

echo "Server response: $response"

if [[ "$response" == *"success"* ]]; then
    echo " Login success, entering Typing Game.."
    sleep 1
    bash ./typing_game.sh
else
    echo " Login failed"
fi

