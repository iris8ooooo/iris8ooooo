#!/bin/bash
# 두 번 눌러 실행 — 케이블로 연결한 실물 아이폰에 공수장부를 설치해 띄운다.
#
# 미리 해 둘 것 (처음 한 번만, docs/RUN_GUIDE.md 7단계 참고):
#   1. 아이폰을 케이블로 연결하고 아이폰에서 "이 컴퓨터를 신뢰"
#   2. 아이폰 설정 > 개인정보 보호 및 보안 > 개발자 모드 켜기 > 재부팅
#   3. Xcode 에서 Runner 와 GongsuWidget 의 Team 을 본인 Apple ID 로 한 번 선택

cd "$(dirname "$0")/../.." || exit 1
export PATH="$HOME/development/flutter/bin:$PATH"

echo "=============================================="
echo " 공수장부 — 실물 아이폰으로 실행"
echo "=============================================="
echo

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter 를 찾지 못했습니다. docs/RUN_GUIDE.md 3단계를 먼저 하세요."
  read -r -p "엔터 " _
  exit 1
fi

echo "[0/4] 최신 코드 받기"
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  echo "  내 Mac 에서 고친 파일이 있어 이번엔 건너뜁니다 (그대로 실행합니다)."
else
  git pull --ff-only origin main 2>&1 | tail -3 || echo "  (인터넷이 안 되면 건너뜁니다 — 실행에는 지장 없습니다)"
fi
echo
echo "[1/4] 준비 (flutter pub get)"
flutter pub get || { echo; echo "준비 단계 실패. 위 내용을 복사해 Claude 에게 보여 주세요."; read -r -p "엔터 " _; exit 1; }

echo
echo "[2/4] 연결된 아이폰 찾기"
DEVICE_ID="$(flutter devices --machine 2>/dev/null | python3 -c '
import json,sys
try:
    devices = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for d in devices:
    if d.get("targetPlatform","").startswith("ios") and not d.get("emulator", True):
        print(d.get("id",""))
        break
' 2>/dev/null)"

if [ -z "$DEVICE_ID" ]; then
  echo "  케이블로 연결된 아이폰을 찾지 못했습니다."
  echo "  - 케이블이 꽂혀 있는지, 아이폰에서 '신뢰'를 눌렀는지 확인하세요."
  echo "  - 아이폰 설정 > 개인정보 보호 및 보안 > 개발자 모드가 켜져 있어야 합니다."
  echo
  echo "  그래도 안 되면 아래 목록에서 아이폰이 보이는지 확인해 주세요:"
  echo
  flutter devices
  echo
  read -r -p "엔터를 누르면 창이 닫힙니다 " _
  exit 1
fi

echo "  찾았습니다: $DEVICE_ID"
echo
echo "[3/4] 설치하고 실행 — 첫 설치는 몇 분 걸립니다."
echo "      끝낼 때는 이 창에서 q 를 누르세요 (앱은 아이폰에 남습니다)."
echo
flutter run -d "$DEVICE_ID"
STATUS=$?

echo
if [ $STATUS -ne 0 ]; then
  echo "----------------------------------------------"
  echo " 실패했을 때 자주 나오는 두 가지"
  echo "----------------------------------------------"
  echo
  echo "1) 'Signing for \"Runner\" requires a development team'"
  echo "   → Xcode 로 ios/Runner.xcworkspace 를 열고 TARGETS 의 Runner 와"
  echo "     GongsuWidget 둘 다 Signing & Capabilities 탭에서 Team 을 고르세요."
  echo
  echo "2) 'Provisioning profile ... does not support the App Groups capability'"
  echo "   → 무료 Apple ID 는 App Groups(위젯 데이터 공유)를 쓸 수 없습니다."
  echo "     위젯을 잠시 끄고 앱만 설치하려면 아래를 실행한 뒤 다시 시도하세요:"
  echo "       ruby tool/ios_app_group.rb off"
  echo "     유료 개발자 계정을 넣은 뒤에는 되돌리세요:"
  echo "       ruby tool/ios_app_group.rb on"
  echo
fi
read -r -p "엔터를 누르면 창이 닫힙니다 " _
