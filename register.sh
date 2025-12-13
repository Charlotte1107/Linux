#!/bin/bash

echo "===== User Registration ====="

# 輸入帳號
echo -n "Create Username: "
read username

# 輸入密碼（不顯示）
echo -n "Create Password: "
read -s password
echo

# 呼叫後端 API 進行註冊
response=$(curl -s -X POST http://localhost:3000/api/auth/register \
-H "Content-Type: application/json" \
-d "{\"username\":\"$username\",\"password\":\"$password\"}")

echo
echo "Server response: $response"
echo
