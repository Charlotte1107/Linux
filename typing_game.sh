#!/bin/bash

# --- 顏色和特殊字元定義 ---
# 使用 tput 確保與各種終端機相容
# 注意：如果您的系統未安裝 tput，可能需要安裝（例如：sudo apt install ncurses-bin）
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BOLD=$(tput bold)
RESET=$(tput sgr0)
CLEAR=$(tput clear)
CENTER_COLUMNS=$(( $(tput cols) / 2 ))

# --- 遊戲設定 ---
MIN_WORD_LENGTH=5
MAX_WORD_LENGTH=12
GAME_DURATION=60  # 遊戲時間，單位：秒

# --- 字元集定義 ---
ALPHABET="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
NUMBERS="0123456789"
ALPHANUMERIC="$ALPHABET$NUMBERS"

# --- 函數：顯示歡迎畫面 ---
show_welcome() {
    $CLEAR
    echo -e "${BOLD}${CYAN}"
    echo "======================================================"
    echo "  🚀 Bash 打字遊戲 🚀"
    echo "======================================================"
    echo "  目標：在一分鐘內盡快且準確地輸入螢幕上的字元。"
    echo "  按 ${BOLD}${YELLOW}Ctrl+C${CYAN} 隨時退出。"
    echo "======================================================"
    echo -e "${RESET}"
    sleep 2
}

# --- 函數：處理退出信號 (Ctrl+C) ---
cleanup_and_exit() {
    $CLEAR
    echo -e "\n${BOLD}${RED}👋 遊戲結束。感謝您的遊玩！${RESET}\n"
    exit 0
}

# 捕捉中斷信號 (Ctrl+C)
trap cleanup_and_exit SIGINT

# --- 函數：選擇字元類別 ---
select_category() {
    while true; do
        $CLEAR
        echo -e "${BOLD}${MAGENTA}### 選擇打字類別 ###${RESET}"
        echo -e "${GREEN}1)${RESET} 字母 (a-z, A-Z)"
        echo -e "${GREEN}2)${RESET} 數字 (0-9)"
        echo -e "${GREEN}3)${RESET} 混合 (字母與數字)"
        echo -e "${YELLOW}請輸入選擇 (1-3): ${RESET}\c"
        read -r category_choice

        case $category_choice in
            1)
                CHAR_SET=$ALPHABET
                echo "您選擇了：字母"
                break
                ;;
            2)
                CHAR_SET=$NUMBERS
                echo "您選擇了：數字"
                break
                ;;
            3)
                CHAR_SET=$ALPHANUMERIC
                echo "您選擇了：混合"
                break
                ;;
            *)
                echo -e "${RED}無效的選擇。請重新輸入。${RESET}"
                sleep 1
                ;;
        esac
    done
    sleep 1
}

# --- 函數：生成隨機字串 ---
# 參數 1: 字元集, 參數 2: 最小長度, 參數 3: 最大長度
generate_random_string() {
    local charset=$1
    local min_len=$2
    local max_len=$3
    local len_range=$(( max_len - min_len + 1 ))
    # 確保長度在範圍內
    local string_len=$(( $RANDOM % len_range + min_len ))
    local random_string=""

    for i in $(seq 1 $string_len); do
        local char_index=$(( $RANDOM % ${#charset} ))
        random_string+="${charset:$char_index:1}"
    done

    echo "$random_string"
}

# --- 函數：主遊戲迴圈 ---
start_game() {
    local start_time=$(date +%s)
    local end_time=$(( start_time + GAME_DURATION ))
    local total_typed_chars=0
    local correct_chars=0
    local total_words=0
    local elapsed_time=0

    $CLEAR
    echo -e "${BOLD}${BLUE}### 遊戲開始！ (持續 ${GAME_DURATION} 秒) ###${RESET}"
    echo -e "${CYAN}準備好了嗎...${RESET}"
    sleep 2

    while [ $(date +%s) -lt $end_time ]; do
        elapsed_time=$(( $(date +%s) - start_time ))
        local remaining_time=$(( GAME_DURATION - elapsed_time ))

        if [ $remaining_time -le 0 ]; then
            break
        fi

        # 1. 生成並顯示目標字串
        TARGET_STRING=$(generate_random_string "$CHAR_SET" $MIN_WORD_LENGTH $MAX_WORD_LENGTH)
        
        $CLEAR
        echo -e "${BOLD}${BLUE}### Bash 打字遊戲 ###${RESET}"
        echo -e "${YELLOW}剩餘時間: ${remaining_time} 秒${RESET}"
        echo "------------------------------------------------------"
        echo -e "${BOLD}${GREEN}🎯 請輸入: ${RESET}"
        echo -e "${BOLD}${CYAN}> $TARGET_STRING <${RESET}"
        echo "------------------------------------------------------"
        
        # 2. 獲取使用者輸入
        echo -e "${BOLD}您的輸入: ${WHITE}\c"
        read -r USER_INPUT
        
        # 3. 檢查輸入結果
        if [ "$USER_INPUT" == "$TARGET_STRING" ]; then
            echo -e "${GREEN}✅ 正確！${RESET}"
            total_words=$(( total_words + 1 ))
            total_typed_chars=$(( total_typed_chars + ${#TARGET_STRING} ))
            correct_chars=$(( correct_chars + ${#TARGET_STRING} ))
        else
            echo -e "${RED}❌ 錯誤！${RESET}"
            # 計算錯誤字元數
            local min_len=$(( ${#TARGET_STRING} < ${#USER_INPUT} ? ${#TARGET_STRING} : ${#USER_INPUT} ))
            local temp_correct=0
            
            for ((i=0; i<$min_len; i++)); do
                if [ "${TARGET_STRING:$i:1}" == "${USER_INPUT:$i:1}" ]; then
                    temp_correct=$(( temp_correct + 1 ))
                fi
            done
            # 總字元數 += 目標字串長度 (計算準確率時，分母是目標字串的長度總和)
            total_typed_chars=$(( total_typed_chars + ${#TARGET_STRING} ))
            correct_chars=$(( correct_chars + temp_correct ))
        fi
        
        sleep 0.5 # 讓使用者看到結果
    done

    show_results $total_typed_chars $correct_chars $total_words $GAME_DURATION
}

# --- 函數：顯示結果 ---
show_results() {
    local total_typed_chars=$1
    local correct_chars=$2
    local total_words=$3
    local duration=$4 # 以秒為單位
    
    $CLEAR
    echo -e "${BOLD}${YELLOW}===================================================${RESET}"
    echo -e "${BOLD}${YELLOW}                 🏆 遊戲結果 🏆                  ${RESET}"
    echo -e "${BOLD}${YELLOW}===================================================${RESET}"

    # 1. 計算 WPM (Word Per Minute): 假設一個單詞平均 5 個字元
    if [ $duration -gt 0 ]; then
        # 注意：WPM 需要浮點數運算，Bash 使用 bc 實現
        local wpm=$(echo "scale=2; ($correct_chars / 5) / ($duration / 60)" | bc)
    else
        local wpm="0.00"
    fi
    
    # 2. 計算準確率 (Accuracy)
    local accuracy="0.00"
    if [ $total_typed_chars -gt 0 ]; then
        accuracy=$(echo "scale=2; ($correct_chars * 100) / $total_typed_chars" | bc)
    fi
    
    echo -e "${BOLD}${GREEN}✔ 正確字元數: ${correct_chars}${RESET}"
    echo -e "${BOLD}${CYAN}Σ 總字元數 (目標): ${total_typed_chars}${RESET}"
    echo -e "${BOLD}${MAGENTA}🎯 完成字串數: ${total_words}${RESET}"
    echo "---"
    echo -e "${BOLD}${YELLOW}🚀 準確率 (Accuracy): ${accuracy}%${RESET}"
    echo -e "${BOLD}${YELLOW}⏱ 每分鐘單詞數 (WPM): ${wpm}${RESET}"
    echo "---"
    
    echo -e "\n${BOLD}按 ${GREEN}Enter${RESET} 退出遊戲... \c"
    read -r
    cleanup_and_exit
}


# --- 主程式流程 ---
show_welcome
select_category
start_game
