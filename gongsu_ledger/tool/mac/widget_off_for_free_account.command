#!/bin/bash
# 두 번 눌러 실행 — 무료 Apple ID 로 실물 아이폰에 설치할 수 있게
# App Groups(위젯 데이터 공유) 권한을 잠시 뺀다.
#
# 무료 Apple ID 는 App Groups 를 쓸 수 없어서, 이걸 빼지 않으면
# 실물 아이폰 설치가 "does not support the App Groups capability" 로 막힌다.
# 대신 홈 위젯은 숫자를 못 읽어 빈 값으로 보인다 (앱 본체는 전부 정상).
# 유료 개발자 계정을 넣은 뒤에는 widget_on.command 로 되돌린다.

cd "$(dirname "$0")/../.." || exit 1

EMPTY='<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
</dict>
</plist>'

printf '%s\n' "$EMPTY" > ios/Runner/Runner.entitlements
printf '%s\n' "$EMPTY" > ios/GongsuWidget/GongsuWidget.entitlements

echo "=============================================="
echo " App Groups 를 뺐습니다 (무료 계정용 임시 설정)"
echo "=============================================="
echo
echo "이제 실물 아이폰 설치를 다시 시도하세요:"
echo "  tool/mac/run_iphone.command 를 두 번 누르기"
echo
echo "지금 상태에서는"
echo "  - 앱 본체: 전부 정상 (달력·정산·백업·확인서 모두)"
echo "  - 홈 위젯: 숫자를 못 읽어 빈 값으로 보입니다"
echo
echo "되돌릴 때: tool/mac/widget_on.command 를 두 번 누르기"
echo "(이 변경은 내 Mac 안에만 있습니다. 저장소에는 영향 없습니다)"
echo
read -r -p "엔터를 누르면 창이 닫힙니다 " _
