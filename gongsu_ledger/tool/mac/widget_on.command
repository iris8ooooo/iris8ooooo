#!/bin/bash
# 두 번 눌러 실행 — App Groups(위젯 데이터 공유) 권한을 원래대로 되돌린다.
# 유료 Apple Developer Program 계정을 쓰거나, 시뮬레이터로만 확인할 때의 정상 상태.

cd "$(dirname "$0")/../.." || exit 1

APP_GROUP='group.com.gongsujangbu.gongsuLedger'

write_entitlements() {
  cat > "$1" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>${APP_GROUP}</string>
	</array>
</dict>
</plist>
PLIST
}

write_entitlements ios/Runner/Runner.entitlements
write_entitlements ios/GongsuWidget/GongsuWidget.entitlements

echo "=============================================="
echo " App Groups 를 되돌렸습니다 (정상 상태)"
echo "=============================================="
echo
echo "App Group: ${APP_GROUP}"
echo
echo "시뮬레이터는 이 상태로 위젯까지 정상 동작합니다."
echo "실물 아이폰에서 위젯까지 쓰려면 유료 Apple Developer Program 이 필요합니다."
echo
read -r -p "엔터를 누르면 창이 닫힙니다 " _
