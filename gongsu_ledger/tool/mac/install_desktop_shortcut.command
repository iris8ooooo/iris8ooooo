#!/bin/bash
# 두 번 눌러 실행 — 바탕화면에 "공수수첩" 아이콘을 만든다.
# 앞으로는 폴더를 찾아 들어갈 필요 없이 바탕화면 아이콘만 두 번 누르면 된다.

REPO_SCRIPT="$(cd "$(dirname "$0")" && pwd)/run_simulator.command"
SHORTCUT="$HOME/Desktop/공수수첩.command"

cat > "$SHORTCUT" <<LAUNCHER
#!/bin/bash
exec "$REPO_SCRIPT"
LAUNCHER
chmod +x "$SHORTCUT"

echo "=============================================="
echo " 바탕화면에 '공수수첩' 아이콘을 만들었습니다"
echo "=============================================="
echo
echo "앞으로는 바탕화면의 '공수수첩' 를 두 번 누르면"
echo "최신 코드 받기부터 앱 실행까지 알아서 진행됩니다."
echo
read -r -p "엔터를 누르면 창이 닫힙니다 " _
