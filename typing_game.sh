#!/bin/bash

# =====================================================
# Bash 打字遊戲（含遊戲結束結果）
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

# ---------- 題庫 ----------
WORDS=(spit split dispose blast consume attack value score object system linux bash typing practice apple banana window function random)
LETTERS=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ
NUMBERS=0123456789

# ---------- 遊戲設定 ----------
MODE="word"
DELAY=5
DIFFICULTY="Normal"
PLAYER=""
GAME_LIMIT=60   # ★ 遊戲總時間（秒）
# ---------- 玩家登入 ----------
login_player() {
  CLEAR_SCREEN
  read -p "請輸入玩家名稱: " PLAYER
  [[ -z "$PLAYER" ]] && PLAYER="Guest"
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
  echo "| Player: $PLAYER     Ctrl+C 離開               |"
  echo "| Difficulty: $DIFFICULTY   Mode: $MODE           |"
  echo "================================================="
  printf "| Time:%-4s/%-3s Total:%-3s Right:%-3s Acc:%-3s%% |\n" "$TIME" "$GAME_LIMIT" "$SUM" "$RIGHT" "$ACC"
  echo "================================================="
  printf "| "; printf "%s  " "${row[@]}"; echo
  echo "================================================="
  tput cup 8 2; printf "Your input: "
}
# ---------- 結果畫面 ----------
show_result() {
  tput cnorm
  CLEAR_SCREEN
  echo -e "${BOLD}${CYAN}===== 遊戲結果 =====${RESET}"
  echo
  echo "玩家名稱：$PLAYER"
  echo "模式：$MODE"
  echo "難度：$DIFFICULTY"
  echo "遊玩時間：$TIME 秒"
  echo "總題數：$SUM"
  echo "答對題數：$RIGHT"
  echo "命中率：$ACC %"
  echo
  echo -e "${GREEN}感謝遊玩！${RESET}"
  echo
  read -p "按 Enter 鍵結束..."
  exit 0
}

# ---------- Ctrl+C ----------
cleanup_and_exit() {
  show_result
}
trap cleanup_and_exit SIGINT

# ---------- 主遊戲 ----------
start_game() {
  SUM=0; RIGHT=0; TIME=0; ACC=0
  tput civis
  start_time=$(date +%s)

  while true; do
    TIME=$(( $(date +%s) - start_time ))

    # ★ 時間到 → 結束遊戲
    if (( TIME >= GAME_LIMIT )); then
      show_result
    fi

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

    ACC=$(( RIGHT * 100 / SUM ))
    sleep 1
  done
}

# ---------- 主流程 ----------
login_player
select_difficulty
select_mode
start_game
