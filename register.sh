#!/bin/bash

echo "===== User Register ====="
read -p "Username: " username
read -s -p "Password: " password
echo ""

response=$(curl -s -X POST http://localhost:3000/register \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$username\",\"password\":\"$password\"}")

echo "Server response: $response"

