#!/bin/bash
# 두 번 눌러 실행 — 아이폰 시뮬레이터에 공수수첩를 띄운다.
# (Finder 에서 이 파일을 두 번 누르면 터미널이 열리고 알아서 진행됩니다)

cd "$(dirname "$0")/../.." || exit 1
export PATH="$HOME/development/flutter/bin:$PATH"

echo "=============================================="
echo " 공수수첩 — 시뮬레이터로 실행"
echo "=============================================="
echo

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter 를 찾지 못했습니다."
  echo "docs/RUN_GUIDE.md 의 3단계(Flutter 설치)를 먼저 하세요."
  echo
  read -r -p "엔터를 누르면 창이 닫힙니다 " _
  exit 1
fi

echo "[0/4] 최신 코드 받기"
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  echo "  ⚠️  내 Mac 에서 고친 파일이 있어 최신 코드를 못 받았습니다."
  echo "     (그대로 실행은 됩니다. 최신으로 맞추려면 아래 한 줄을 터미널에 붙여넣으세요)"
  echo
  echo "       cd ~/development/gongsu-app && git stash -u && git pull origin main"
  echo
else
  git pull --ff-only origin main 2>&1 | tail -3 || echo "  (인터넷이 안 되면 건너뜁니다 — 실행에는 지장 없습니다)"
fi
echo
echo "[1/4] 준비 (flutter pub get)"
flutter pub get || { echo; echo "준비 단계에서 실패했습니다. 위 빨간 글씨를 복사해 Claude 에게 보여 주세요."; read -r -p "엔터 " _; exit 1; }

echo
echo "[2/4] 시뮬레이터 켜기 (처음이면 1분쯤 걸립니다)"
open -a Simulator

echo
echo "[3/4] 앱 실행 — 첫 빌드는 몇 분 걸립니다."
echo "      끝낼 때는 이 창에서 q 를 누르세요."
echo
flutter run

echo
read -r -p "끝났습니다. 엔터를 누르면 창이 닫힙니다 " _
