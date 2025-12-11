#!/bin/bash

# -------------------------
# 顏色和特殊字元定義
# -------------------------
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
MAGENTA="\033[0;35m"
BOLD="\033[1m"
RESET="\033[0m"
# CLEAR="\033[2J\033[H" # 不再使用全螢幕清除
CLEAR_SCREEN() { tput cup 0 0; tput ed; } # 使用 tput 清除螢幕

# -------------------------
# 單字庫和字元集
# -------------------------
WORDS=(
    spit split dispose blast consume attack value score object system
    linux bash typing practice apple banana window function random
)

LETTERS=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ
NUMBERS=0123456789

# -------------------------
# 遊戲設定變數
# -------------------------
MODE="word" 
DELAY=5     # 挑戰時間 (秒)

# -------------------------
# 函數：生成隨機一排字詞 (無變動)
# -------------------------
generate_row() {
    row=()
    case $MODE in
        word)
            for i in {1..5}; do
                row+=("${WORDS[RANDOM % ${#WORDS[@]}]}")
            done
            ;;
        letter)
            for i in {1..5}; do
                row+=("${LETTERS:RANDOM%${#LETTERS}:1}")
            done
            ;;
        number)
            for i in {1..5}; do
                row+=("${NUMBERS:RANDOM%${#NUMBERS}:1}")
            done
            ;;
        mix)
            for i in {1..5}; do
                local len=$((RANDOM % 4 + 3))
                local s=$(tr -dc 'a-zA-Z0-9' </dev/urandom | head -c $len)
                row+=("$s")
            done
            ;;
    esac
}

# -------------------------
# 函數：選擇難易度 (使用 CLEAR_SCREEN)
# -------------------------
select_difficulty() {
    while true; do
        CLEAR_SCREEN # 使用 tput 清除
        echo -e "${MAGENTA}### 選擇難易度 (決定輸入間隔時間) ###${RESET}"
        echo -e "${GREEN}1) Easy (8 秒)${RESET}"
        echo -e "${YELLOW}2) Normal (5 秒)${RESET}"
        echo -e "${RED}3) Hard (3 秒)${RESET}"
        read -p "Enter 1-3: " opt

        case $opt in
            1) DELAY=8; break ;;
            2) DELAY=5; break ;;
            3) DELAY=3; break ;;
            *) echo -e "${RED}無效選項!${RESET}"; sleep 1 ;;
        esac
    done
}

# -------------------------
# 函數：選擇類別 (使用 CLEAR_SCREEN)
# -------------------------
select_mode() {
    while true; do
        CLEAR_SCREEN # 使用 tput 清除
        echo -e "${CYAN}### 選擇練習類別 ###${RESET}"
        echo "1) Number (數字)"
        echo "2) Letter (字母)"
        echo "3) Mix (混合)"
        echo "4) Word (單字)"
        read -p "Enter 1-4: " opt

        case $opt in
            1) MODE="number"; break ;;
            2) MODE="letter"; break ;;
            3) MODE="mix"; break ;;
            4) MODE="word"; break ;;
            *) echo -e "${RED}無效選項!${RESET}"; sleep 1 ;;
        esac
    done
}

# -------------------------
# 函數：畫框線 (修改: 不再清除整個螢幕，只在頂部繪製)
# -------------------------
draw_frame() {
    tput cup 0 0 # 移動游標到左上角 (0, 0)
    tput ed # 清除到螢幕底部

    # 計算準確率顏色
    local acc_color=$YELLOW
    if [ $SUM -gt 0 ]; then
        if [ $ACC -ge 80 ]; then acc_color=$GREEN; fi
        if [ $ACC -lt 50 ]; then acc_color=$RED; fi
    fi
    
    echo -e "${BOLD}=====================================================================${RESET}" # Line 1
    echo -e "| ${CYAN}${BOLD}提示：按 Ctrl+C 隨時退出遊戲。${RESET}                                            |" # Line 2
    echo -e "| Please type ${CYAN}one of the words${RESET} before the time runs out!         |" # Line 3
    echo -e "| Challenge Time: ${MAGENTA}${DELAY}s${RESET}                                                    |" # Line 4
    echo -e "=====================================================================" # Line 5
    
    # 狀態列 (Line 6)
    printf "| Playtime: ${YELLOW}%-5s${RESET}  Accuracy: ${acc_color}%-5s%%${RESET}  Sum: ${GREEN}%-5s${RESET}                                    |\n" \
           "${TIME}s" "$ACC" "$SUM"

    echo "=====================================================================" # Line 7
    
    # 題目列 (Line 8)
    printf "| "
    printf "${BOLD}${CYAN}%s${RESET}   " "${row[@]}"
    local space_needed=$(( 65 - ${#row[*]} * 7 ))
    printf "%-${space_needed}s|\n" "" 

    echo "=====================================================================" # Line 9
    
    # 輸入列的標籤 (Line 10)
    tput cup 10 2
    printf "| Your input: "
    tput cup 10 16   # 游標定位在 Your input: 後面

    # 注意：我們在這裡不打印換行，讓下一行輸出在標籤旁邊

    # 確保接下來的結果行被清除 (Line 11)
    tput el
}

# -------------------------
# 函數：處理退出信號 (Ctrl+C)
# -------------------------
cleanup_and_exit() {
    tput cnorm # 顯示游標
    tput cup 0 0
    tput ed # 清除螢幕
    echo -e "\n${RED}👋 遊戲結束。總結結果：${RESET}"
    echo -e "遊玩時間: ${TIME} 秒"
    echo -e "總題數: ${SUM}"
    echo -e "答對數: ${RIGHT}"
    echo -e "最終準確率: ${ACC}%"
    echo -e "\n${CYAN}感謝您的遊玩！${RESET}\n"
    exit 0
}
trap cleanup_and_exit SIGINT

# -------------------------
# 遊戲主體
# -------------------------
start_game() {
    SUM=0
    RIGHT=0
    TIME=0
    ACC=0
    
    tput civis # 隱藏游標
    local game_start_time=$(date +%s) # 記錄遊戲開始的絕對時間

    while true; do
        generate_row
        draw_frame
        
        # 移動游標到輸入區域 (第 10 行，第 15 列)，開始讀取
        
        
        local input_start_time=$(date +%s)
        # 關鍵：read -r -t $DELAY input 會在 tput cup 指定的位置等待輸入，且即時顯示字元。
        read -r -t $DELAY input
        local input_end_time=$(date +%s)
        
        # 清除輸入行 (Line 10) 和結果行 (Line 11)
        tput cup 10 0; tput el # 清除輸入行
        tput cup 11 0; tput el # 清除結果行

        local round_time_spent=0
        
        # 1. 檢查是否因超時而退出 ($? -ne 0)
        if [[ $? -ne 0 ]]; then
            # 超時處理
            tput cup 11 15 # 移動游標到結果行
            echo -e "${RED}${BOLD}TIMEOUT! (超時)${RESET}"
            round_time_spent=$DELAY
            SUM=$((SUM + 1))
        else
            # 2. 玩家在時間內輸入
            round_time_spent=$(( input_end_time - input_start_time ))
            SUM=$((SUM + 1))
            
            match=false
            for w in "${row[@]}"; do
                if [[ "$input" == "$w" ]]; then
                    match=true
                    break
                fi
            done

            # 3. 顯示即時驗證結果
            tput cup 11 15 # 移動游標到結果行
            if $match; then
                echo -e "${GREEN}${BOLD}right! (正確)${RESET}"
                RIGHT=$((RIGHT + 1))
            else
                echo -e "${RED}${BOLD}wrong! (錯誤)${RESET}"
            fi
        fi

        # 4. 更新狀態
        TIME=$(( ( $(date +%s) - game_start_time ) )) # 總時間為絕對時間差
        
        if [ $SUM -gt 0 ]; then
            ACC=$(( RIGHT * 100 / SUM ))
        fi
        
        # 讓玩家看到結果
        sleep 1
    done
}

# -------------------------
# 主流程
# -------------------------
select_difficulty
select_mode
start_game