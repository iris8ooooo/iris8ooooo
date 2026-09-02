# 공수장부 실행 가이드 (비개발자용, Windows PC + 갤럭시 기준)

Windows PC에서 공수장부 앱을 갤럭시(또는 가상 안드로이드 폰)에 띄워 보는 방법입니다.
처음 한 번만 1~7단계를 하면, 이후에는 8단계부터만 반복하면 됩니다.
아이폰·Mac은 `RUN_GUIDE.md`를 보세요.

> 시간: 설치 1~2시간(다운로드가 큽니다), 이후 실행은 몇 분.
> 준비물: Windows 10/11 64비트, 여유 공간 15GB 이상, 갤럭시, **데이터 전송이 되는** USB 케이블(충전 전용 케이블은 안 됩니다).

---

## 0. 명령어 넣는 창(PowerShell) 여는 법

- 시작 버튼 → `PowerShell` 검색 → **Windows PowerShell** 실행.
- 아래 회색 상자의 명령어는 **한 줄씩 복사해 PowerShell에 붙여넣고(마우스 오른쪽 클릭이 붙여넣기) 엔터**를 칩니다.
- 설치 중간에 PowerShell을 **완전히 닫았다가 새로 열어야** 새 설정이 적용됩니다. 아래에서 "새로 열기"라고 쓴 곳이 그런 곳입니다.

## 1. Windows 개발자 모드 켜기 (처음 한 번만)

Flutter가 안드로이드용 부품을 연결할 때 필요합니다.

- Windows 11: 설정 → 시스템 → **개발자용** → **개발자 모드** 켜기 → "예".
- Windows 10: 설정 → 업데이트 및 보안 → 개발자용 → 개발자 모드.

## 2. Git 설치 (처음 한 번만)

1. https://git-scm.com/download/win 에서 **64-bit Git for Windows Setup** 다운로드.
2. 설치 화면은 전부 기본값으로 **Next** → **Install**.
3. PowerShell을 새로 열고 확인:
   ```powershell
   git --version
   ```
   `git version 2.xx` 같은 글이 나오면 성공.

## 3. Flutter 설치 (처음 한 번만)

1. PowerShell에서 폴더를 만들고 내려받습니다 (한글·공백이 없는 `C:\dev` 를 씁니다. `Program Files`나 OneDrive 폴더는 안 됩니다):
   ```powershell
   mkdir C:\dev
   cd C:\dev
   curl.exe -o flutter.zip https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.47.2-stable.zip
   Expand-Archive flutter.zip -DestinationPath C:\dev
   ```
   (다운로드 약 1GB, 압축 풀기 몇 분. 끝나면 `C:\dev\flutter` 폴더가 생깁니다.)
2. **경로(PATH) 등록**: 시작 → `환경 변수` 검색 → **시스템 환경 변수 편집** → 오른쪽 아래 **환경 변수(N)...** → 위쪽 "사용자 변수"에서 **Path** 선택 → **편집** → **새로 만들기** → `C:\dev\flutter\bin` 입력 → **확인**을 세 번 눌러 모두 닫기.
3. PowerShell을 **새로 열고** 확인:
   ```powershell
   flutter --version
   ```
   `Flutter 3.47.2` 가 보이면 성공. "flutter는(은) 내부 또는 외부 명령... 아닙니다"가 나오면 2번의 경로를 다시 확인하고 PowerShell을 새로 여세요.

## 4. Android Studio 설치 (처음 한 번만, 약 30분)

안드로이드 앱을 만드는 부품(SDK)이 이 프로그램 안에 들어 있습니다. 프로그램 자체는 거의 쓰지 않습니다.

1. https://developer.android.com/studio 에서 **Download Android Studio** → 약관 동의 → 설치 파일 실행 → 전부 기본값으로 **Next** → **Install** → **Finish**.
2. Android Studio가 처음 열리면 설정 마법사가 나옵니다: **Standard** 선택 → 약관 화면에서 왼쪽 항목마다 **Accept** → **Finish** (SDK 다운로드, 몇 분).
3. 시작 화면에서 **More Actions** → **SDK Manager** → 위쪽 **SDK Tools** 탭 → **Android SDK Command-line Tools (latest)** 체크 → **Apply** → **OK**. 끝나면 Android Studio는 닫아도 됩니다.
4. PowerShell을 **새로 열고** 약관에 동의합니다 (물어볼 때마다 `y` 입력 후 엔터):
   ```powershell
   flutter doctor --android-licenses
   ```
5. 상태 확인:
   ```powershell
   flutter doctor
   ```
   **Flutter**, **Android toolchain**, **Android Studio** 줄이 초록 체크(✓)면 됩니다.
   `Visual Studio`나 `Chrome` 줄의 X는 무시해도 됩니다 (윈도우 프로그램·웹용이라 우리와 상관없음).

## 5. 앱 코드 내려받기 (처음 한 번만)

```powershell
cd C:\dev
git clone https://github.com/iris8ooooo/iris8ooooo.git gongsu-app
cd gongsu-app
git checkout claude/worker-timesheet-flutter-app-6pltoc
cd gongsu_ledger
flutter pub get
```

## 6. 갤럭시 준비 (처음 한 번만)

PC가 폰에 앱을 넣으려면 폰에서 "USB 디버깅"을 켜야 합니다.

1. 갤럭시 **설정** → **휴대전화 정보** → **소프트웨어 정보** → **빌드번호**를 **7번 연속** 톡톡 두드리기 → "개발자 모드가 켜졌습니다" (잠금 비밀번호를 물을 수 있음).
2. 설정 맨 아래에 생긴 **개발자 옵션** → **USB 디버깅** 켜기 → "허용".
3. 케이블로 PC에 연결 → 폰 화면의 **"USB 디버깅을 허용하시겠습니까?"** 에서 **이 컴퓨터에서 항상 허용** 체크 → **허용**.
   (폰 알림에서 USB 연결 모드를 묻는다면 "파일 전송/Android Auto"를 고릅니다.)
4. PC에서 확인:
   ```powershell
   flutter devices
   ```
   `SM-S9xx (mobile)` 처럼 폰 모델명이 보이면 성공.

폰이 안 보이면: 폰 잠금을 풀어 두고, 다른 케이블·다른 USB 단자로 바꿔 보고, 그래도 안 되면 삼성 USB 드라이버(https://developer.samsung.com/android-usb-driver)를 설치한 뒤 PC를 재부팅합니다.

## 7. 실행 (갤럭시에 앱 띄우기)

```powershell
cd C:\dev\gongsu-app\gongsu_ledger
flutter run
```

- 첫 실행은 필요한 부품을 더 내려받느라 **5~10분** 걸립니다 (두 번째부터는 1분 안쪽).
- 기기가 여러 개라 번호를 물으면 갤럭시 번호를 입력합니다.
- 폰에 **공수장부**(첫 실행이면 직군 선택 화면)가 뜨면 성공. PowerShell에서 `q` 를 누르면 끝납니다.
- 이렇게 넣은 앱은 케이블을 뽑아도 폰에 남아 있어 계속 써 볼 수 있습니다 (개발용 버전이라 스토어 버전보다 조금 느립니다).

## 8. 나중에 새 버전 받기

```powershell
cd C:\dev\gongsu-app
git pull
cd gongsu_ledger
flutter pub get
flutter run
```

## 9. (선택) 설치 파일(APK)로 케이블 없이 설치하기

지인 갤럭시에 넣어 보거나 케이블 없이 설치하고 싶을 때:

```powershell
cd C:\dev\gongsu-app\gongsu_ledger
flutter build apk
```

끝나면 `C:\dev\gongsu-app\gongsu_ledger\build\app\outputs\flutter-apk\app-release.apk` 파일이 생깁니다.
이 파일을 카카오톡 "나에게 보내기"나 구글 드라이브로 폰에 보내고, 폰에서 파일을 열어 설치합니다 ("출처를 알 수 없는 앱 설치 허용"을 물으면 허용).

> 주의: 이 방식으로 넣은 앱은 나중에 스토어 정식 버전으로 바로 덮어씌워지지 않을 수 있습니다(서명이 다름). 정식 출시 뒤에는 이 앱을 지우고 스토어에서 다시 설치하세요. 그 전에 **백업 텍스트 복사**로 기록을 옮기면 됩니다.

## 10. (선택) 갤럭시 없이 가상 폰(에뮬레이터)으로 보기

1. Android Studio 시작 화면 → **More Actions** → **Virtual Device Manager** → **Create Virtual Device** → **Pixel 8** 선택 → **Next** → 추천(Recommended) 목록의 최신 시스템 이미지 옆 **다운로드** 아이콘 → 끝나면 **Next** → **Finish**.
2. 목록에서 ▶ 버튼으로 가상 폰을 켭니다 (첫 켜짐은 1~2분).
3. PowerShell에서 `flutter run`. 가상 폰에 앱이 뜹니다. 홈 위젯도 가상 폰에서 넣어 볼 수 있습니다.

## 11. 자주 막히는 곳

| 증상 | 해결 |
|---|---|
| `flutter`는 내부 또는 외부 명령이 아닙니다 | 3-2 경로 등록을 다시 확인하고 PowerShell을 새로 연다 |
| `Unable to locate Android SDK` | Android Studio 설치·4-3 SDK Tools 확인. 그래도 안 되면 `flutter config --android-sdk "C:\Users\본인이름\AppData\Local\Android\Sdk"` |
| `Building with plugins requires symlink support` | 1단계 Windows 개발자 모드를 켠다 |
| Gradle 다운로드가 멈추거나 오류 | 인터넷 확인, 백신·방화벽을 잠시 끄고 다시. 반복되면 `flutter clean` 후 `flutter run` |
| 폰이 `flutter devices`에 안 보임 | 6단계 USB 디버깅 허용 팝업, 케이블 교체, 삼성 USB 드라이버 설치 |
| 경로에 한글이나 공백이 있어 이상한 오류 | 코드와 Flutter를 `C:\dev` 아래에 둔다 |
| 개발자 옵션 메뉴가 안 보임 | 삼성은 "휴대전화 정보 → 소프트웨어 정보" 안의 빌드번호를 7번 눌러야 생긴다 |
| 빌드가 너무 느림 | Windows 보안 → 바이러스 및 위협 방지 → 제외 항목에 `C:\dev` 추가 (선택) |

## 갤럭시에서 확인해 볼 것

`RUN_GUIDE.md` 의 **M1 ~ M6 체크리스트**를 그대로 따라 하면 됩니다 (화면과 메뉴가 아이폰과 같습니다). 갤럭시에서만 다른 부분:

- [ ] 홈 화면에 **공수장부** 이름과 파란 달력 아이콘이 보인다
- [ ] 홈 위젯: 홈 화면 빈 곳 길게 누르기 → **위젯** → **공수장부** → "이번 달 공수"(2×2)를 끌어다 놓기. 무료 상태면 "프로 전용" 문구, 프로면 이번 달 공수·실수령이 보인다
- [ ] 뒤로 가기 제스처(또는 버튼)로 화면이 정상적으로 닫힌다
- [ ] 갤럭시 "글꼴 크기"를 키운 상태에서도 앱 글씨가 같이 커지고 깨지지 않는다 (설정의 "아주 크게"와 겹치면 상한에서 멈춤)
