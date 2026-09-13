#!/bin/bash
# 두 번 눌러 실행 — 아이폰 시뮬레이터에 공수장부를 띄운다.
# (Finder 에서 이 파일을 두 번 누르면 터미널이 열리고 알아서 진행됩니다)

cd "$(dirname "$0")/../.." || exit 1
export PATH="$HOME/development/flutter/bin:$PATH"

echo "=============================================="
echo " 공수장부 — 시뮬레이터로 실행"
echo "=============================================="
echo

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter 를 찾지 못했습니다."
  echo "docs/RUN_GUIDE.md 의 3단계(Flutter 설치)를 먼저 하세요."
  echo
  read -r -p "엔터를 누르면 창이 닫힙니다 " _
  exit 1
fi

echo "[1/3] 준비 (flutter pub get)"
flutter pub get || { echo; echo "준비 단계에서 실패했습니다. 위 빨간 글씨를 복사해 Claude 에게 보여 주세요."; read -r -p "엔터 " _; exit 1; }

echo
echo "[2/3] 시뮬레이터 켜기 (처음이면 1분쯤 걸립니다)"
open -a Simulator

echo
echo "[3/3] 앱 실행 — 첫 빌드는 몇 분 걸립니다."
echo "      끝낼 때는 이 창에서 q 를 누르세요."
echo
flutter run

echo
read -r -p "끝났습니다. 엔터를 누르면 창이 닫힙니다 " _
