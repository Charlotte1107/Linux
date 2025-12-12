#!/bin/bash

LOGFILE="logs/login.log"
USER="student"
PASS="1234"

echo "==== Secure Login ===="
read -p "Username: " input_user
read -s -p "Password: " input_pass
echo

timestamp=$(date "+%Y-%m-%d %H:%M:%S")

# Compare
if [[ "$input_user" == "$USER" && "$input_pass" == "$PASS" ]]; then
    echo "$timestamp LOGIN SUCCESS user=$input_user" >> $LOGFILE
    echo "Login successful."
    exit 0
else
    echo "$timestamp LOGIN FAILED user=$input_user" >> $LOGFILE
    echo "Login failed."
    exit 1
fi
