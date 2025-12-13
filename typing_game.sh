#!/bin/bash

# =====================================================
# Bash 打字遊戲 + MongoDB 紀錄版（可直接執行）
# =====================================================

# ---------- 顏色 ----------
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
MAGENTA="\033[0;35m"
BOLD="\033[1m"
RESET="\033[0m"

CLEAR_SCREEN() { tput cup 0 0; tput ed; }

# ---------- MongoDB ----------
MONGO_DB="typing_game"
MONGO_COLLECTION="records"
MONGO_USER=""

# ---------- 題庫 ----------
WORDS=(spit split dispose blast consume attack value score object system linux bash typing practice apple banana window function random)
LETTERS=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ
NUMBERS=0123456789

# ---------- 遊戲設定 ----------
MODE="word"
DELAY=5
DIFFICULTY="Normal"

# ---------- 玩家登入 ----------
login_player() {
  CLEAR_SCREEN
  read -p "請輸入玩家名稱: " MONGO_USER
  [[ -z "$MONGO_USER" ]] && MONGO_USER="Guest"
}

# ---------- 產生題目 ----------
generate_row() {
  row=()
  case $MODE in
    word)   for i in {1..5}; do row+=("${WORDS[RANDOM % ${#WORDS[@]}]}"); done ;;
    letter) for i in {1..5}; do row+=("${LETTERS:RANDOM%${#LETTERS}:1}"); done ;;
    number) for i in {1..5}; do row+=("${NUMBERS:RANDOM%${#NUMBERS}:1}"); done ;;
    mix)
      for i in {1..5}; do
        len=$((RANDOM % 4 + 3))
        row+=("$(tr -dc 'a-zA-Z0-9' </dev/urandom | head -c $len)")
      done ;;
  esac
}

# ---------- 選難易度 ----------
select_difficulty() {
  while true; do
    CLEAR_SCREEN
    echo -e "${MAGENTA}### 選擇難易度 ###${RESET}"
    echo "1) Easy (8 秒)"
    echo "2) Normal (5 秒)"
    echo "3) Hard (3 秒)"
    read -p "Enter 1-3: " opt
    case $opt in
      1) DELAY=8; DIFFICULTY="Easy"; break ;;
      2) DELAY=5; DIFFICULTY="Normal"; break ;;
      3) DELAY=3; DIFFICULTY="Hard"; break ;;
      *) echo "無效選項"; sleep 1 ;;
    esac
  done
}

# ---------- 選模式 ----------
select_mode() {
  while true; do
    CLEAR_SCREEN
    echo -e "${CYAN}### 選擇模式 ###${RESET}"
    echo "1) Number  2) Letter  3) Mix  4) Word"
    read -p "Enter 1-4: " opt
    case $opt in
      1) MODE="number"; break ;;
      2) MODE="letter"; break ;;
      3) MODE="mix"; break ;;
      4) MODE="word"; break ;;
      *) echo "無效選項"; sleep 1 ;;
    esac
  done
}

# ---------- 畫面 ----------
draw_frame() {
  tput cup 0 0; tput ed
  echo "================================================="
  echo "| Player: $MONGO_USER   Ctrl+C 離開              |"
  echo "| Difficulty: $DIFFICULTY   Mode: $MODE           |"
  echo "================================================="
  printf "| Time:%-4s Total:%-3s Right:%-3s Acc:%-3s%% |\n" "$TIME" "$SUM" "$RIGHT" "$ACC"
  echo "================================================="
  printf "| "; printf "%s  " "${row[@]}"; echo
  echo "================================================="
  tput cup 8 2; printf "Your input: "
}

# ---------- MongoDB ----------
save_to_mongodb() {
mongosh <<EOF
use $MONGO_DB
db.$MONGO_COLLECTION.insertOne({
  player: "$MONGO_USER",
  mode: "$MODE",
  difficulty: "$DIFFICULTY",
  playTime: $TIME,
  total: $SUM,
  right: $RIGHT,
  accuracy: $ACC,
  playedAt: new Date()
})
EOF
}

# ---------- Ctrl+C ----------
cleanup_and_exit() {
  tput cnorm
  CLEAR_SCREEN
  echo "正在儲存遊戲紀錄..."
  save_to_mongodb
  echo "✔ 已存入 MongoDB"
  exit 0
}
trap cleanup_and_exit SIGINT

# ---------- 主遊戲 ----------
start_game() {
  SUM=0; RIGHT=0; TIME=0; ACC=0
  tput civis
  start_time=$(date +%s)

  while true; do
    generate_row
    draw_frame
    read -r -t $DELAY input
    SUM=$((SUM+1))

    if [[ $? -eq 0 ]]; then
      match=false
      for w in "${row[@]}"; do
        [[ "$input" == "$w" ]] && match=true
      done

      if $match; then
        tput cup 9 2; echo -e "${GREEN}✔ 正確${RESET}"
        RIGHT=$((RIGHT+1))
      else
        tput cup 9 2; echo -e "${RED}✘ 錯誤${RESET}"
      fi
    else
      tput cup 9 2; echo -e "${RED}⌛ 超時${RESET}"
    fi

    TIME=$(( $(date +%s) - start_time ))
    ACC=$(( RIGHT * 100 / SUM ))
    sleep 1
  done
}

# ---------- 主流程 ----------
login_player
select_difficulty
select_mode
start_game
