# 출시 가이드 (비개발자용, 단계별)

앱을 앱스토어와 플레이스토어에 올리는 전체 순서입니다. 한 번에 다 하지 않아도 됩니다. 각 단계 끝의 체크 표시를 채워 가세요.

## 0. 준비물

- Mac (Xcode 설치, RUN_GUIDE 1~5번 완료)
- 애플 개발자 프로그램 가입 (연 129,000원, https://developer.apple.com/programs/ , 승인 1~2일)
- 구글 플레이 개발자 계정 (1회 25달러, https://play.google.com/console , 신원 확인 며칠)
- 개인정보처리방침 공개 링크 (5단계)

## 1. 앱 아이콘과 버전 (이미 되어 있음)

- 아이콘은 코드로 그려 두었습니다 (`assets/icon/app_icon.png`). 바꾸고 싶으면 1024×1024 PNG로 교체한 뒤 터미널에서:
  ```bash
  cd gongsu_ledger
  dart run flutter_launcher_icons
  ```
- 버전은 `pubspec.yaml`의 `version: 1.0.0+1` 입니다. 업데이트를 낼 때마다 `+1` 뒤 숫자를 올리고, 기능이 바뀌면 앞 숫자도 올립니다 (예: `1.0.1+2`). `lib/app_info.dart`의 숫자도 같이 맞춥니다(테스트가 확인).

## 2. 아이폰 (App Store)

1. **App Store Connect** (https://appstoreconnect.apple.com) → 나의 앱 → **+** → 새로운 앱
   - 플랫폼 iOS, 이름 `공수장부`, 기본 언어 한국어, 번들 ID `com.gongsujangbu.gongsuLedger` (Xcode에서 한 번 실행하면 목록에 생깁니다), SKU `gongsu-ledger`
2. **앱 내 구입** → **+** → 비소모성 → 참조 이름 `공수장부 프로`, 제품 ID **`gongsu_pro`** (정확히), 가격 6,600원에 가장 가까운 티어, 현지화 이름/설명은 `STORE_LISTING.md`의 "앱 내 구입 상품"
   - 심사용 스크린샷: 설정 → 프로 화면 캡쳐
3. **Xcode 서명**: `ios/Runner.xcworkspace` 열기 → Runner → Signing & Capabilities → Team을 개발자 계정으로. **GongsuWidget** 타깃도 같은 Team. App Groups `group.com.gongsujangbu.gongsuLedger`가 두 타깃 모두에 체크되어 있는지 확인
4. **빌드 올리기**: 터미널에서
   ```bash
   cd gongsu_ledger
   flutter build ipa
   ```
   끝나면 `build/ios/ipa/공수장부.ipa`(또는 gongsu_ledger.ipa)가 생깁니다. Mac의 **Transporter** 앱(앱스토어에서 무료 설치)을 열고 그 파일을 끌어다 놓고 "전송".
5. **TestFlight**: App Store Connect → TestFlight 탭 → 방금 올린 빌드 → 본인 아이폰에 TestFlight 앱으로 설치해 실제 폰에서 확인. 프로 결제는 **샌드박스 테스터**(사용자 및 액세스 → Sandbox → 테스터 추가)로 무료 테스트
6. **앱 정보** 채우기: `STORE_LISTING.md`의 설명·키워드·스크린샷·개인정보 설문(데이터 수집 안 함). 개인정보처리방침 URL 입력
7. **심사 제출** → 보통 1~2일. 거절되면 이유가 메일로 오니 그대로 붙여 주시면 고칩니다

## 3. 갤럭시 (Google Play)

1. **서명 키 만들기 (한 번만, 잃어버리면 앱 업데이트를 못 하니 꼭 백업)**
   ```bash
   cd gongsu_ledger/android
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   비밀번호를 물어보면 정하고 적어 두세요. 그런 다음 `android/key.properties.example`을 복사해 `android/key.properties`로 만들고 비밀번호·경로를 채웁니다. (이 두 파일은 git에 올라가지 않도록 이미 제외되어 있습니다)
2. **앱 번들 만들기**
   ```bash
   cd gongsu_ledger
   flutter build appbundle
   ```
   → `build/app/outputs/bundle/release/app-release.aab`
3. **Play Console** → 앱 만들기 → 이름 `공수장부`, 앱, 무료
4. 왼쪽 **수익 창출 → 제품 → 인앱 상품** → 상품 만들기 → 제품 ID **`gongsu_pro`**, 이름 `공수장부 프로`, 가격 6,600원, 활성화
5. **정책 → 앱 콘텐츠**: 개인정보처리방침 URL, 광고 없음, 데이터 보안(수집 없음), 타겟층 18세 이상 성인(직업용) 등 설문
6. **테스트 → 내부 테스트** → 새 버전 만들기 → aab 업로드 → 테스터(본인 구글 계정) 추가 → 링크로 갤럭시에 설치해 확인. 인앱 상품은 **라이선스 테스터**(설정 → 라이선스 테스트)로 무료 테스트
7. **프로덕션** → 버전 만들기 → 같은 aab → 검토 후 출시 (첫 심사 며칠)

## 4. 출시 전 마지막 확인

- [ ] 비행기 모드에서 앱을 처음부터 끝까지 써 본다 (온보딩 → 입력 → 정산 → 백업 → 복원)
- [ ] 큰글씨 "아주 크게"에서 화면이 깨지지 않는다
- [ ] 프로 구매·복원이 샌드박스/라이선스 테스터로 된다
- [ ] 위젯이 실제 폰에서 뜬다
- [ ] 스크린샷·설명·개인정보처리방침 링크가 들어갔다

## 5. 개인정보처리방침 공개 링크 만들기

스토어는 "인터넷에서 열리는 주소"를 요구합니다. 가장 쉬운 방법:
- GitHub 저장소의 `gongsu_ledger/docs/PRIVACY_POLICY.md` 파일을 브라우저에서 열고 그 주소를 씁니다 (저장소가 공개여야 함), 또는
- 노션(Notion)에 내용을 붙여 넣고 "웹에 게시"한 링크를 씁니다.
문의처는 스토어 등록 시 입력하는 개발자 이메일이 표시되므로 본문에 따로 적지 않아도 됩니다.

## 6. 출시 후 해마다

- 1월: 4대보험 요율·국민연금 상한 갱신 (`lib/domain/tax_rates.dart`)
- 월력요항 발표 후: 다음 해 공휴일 갱신 (`lib/domain/korean_holidays.dart`)
- 업데이트 때마다 `version` 올리기
