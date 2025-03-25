#!/bin/bash

# 定義顯示顏色的函數
print_color() {
    case $2 in
        "green") echo -e "\033[32m$1\033[0m" ;;
        "red") echo -e "\033[31m$1\033[0m" ;;
        "yellow") echo -e "\033[33m$1\033[0m" ;;
        "blue") echo -e "\033[34m$1\033[0m" ;;
        *) echo "$1" ;;
    esac
}

# 打印歡迎信息
print_color "=== 原子習慣追蹤器啟動工具 ===" "green"
print_color "正在啟動網頁應用..." "blue"

# 檢查操作系統並打開瀏覽器
case "$(uname -s)" in
    Darwin)
        # macOS
        open index.html
        print_color "在 Safari 中啟動成功！" "green"
        ;;
    Linux)
        # Linux
        if command -v xdg-open > /dev/null; then
            xdg-open index.html
            print_color "在默認瀏覽器中啟動成功！" "green"
        elif command -v firefox > /dev/null; then
            firefox index.html
            print_color "在 Firefox 中啟動成功！" "green"
        elif command -v google-chrome > /dev/null; then
            google-chrome index.html
            print_color "在 Chrome 中啟動成功！" "green"
        else
            print_color "無法找到瀏覽器。請手動打開 index.html 文件。" "red"
            exit 1
        fi
        ;;
    CYGWIN*|MINGW*|MSYS*)
        # Windows
        start index.html
        print_color "在默認瀏覽器中啟動成功！" "green"
        ;;
    *)
        # 其他操作系統
        print_color "未知操作系統。請手動打開 index.html 文件。" "yellow"
        exit 1
        ;;
esac

print_color "提示：所有數據保存在本地瀏覽器中。請勿清除瀏覽器數據，否則將丟失習慣記錄。" "yellow"
print_color "盡情享受原子習慣的旅程吧！" "green" 