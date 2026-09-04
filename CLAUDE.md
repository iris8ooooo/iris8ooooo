# 공수장부 (가칭) — 현장 노동자용 공수 기록 Flutter 앱

한 줄 정의: **광고 없고, 인터넷 없어도 되고, 기록이 절대 안 사라지는 공수달력.**
타겟: 공수×단가로 급여를 계산하는 모든 현장 노동자 (건설 일용직, 조선소, 플랜트, 제조, 반도체, 인테리어 등).
iOS + Android 동시 출시 목표. 사용자(프로젝트 오너)는 비개발자 — 모든 단계 완료 시 실행/확인 방법을 비개발자 눈높이로 안내할 것.

앱 코드는 `gongsu_ledger/` 디렉토리에 있다 (Flutter 프로젝트 루트).

## 절대 원칙 (시장조사 데이터에서 도출. 위반 금지)

1. **서버 없음.** 모든 데이터 로컬 DB. 비행기모드에서 전 기능 작동. (경쟁앱 '일다오'가 서버 의존으로 죽은 표본: 네트워크 오류 리뷰 수십 건, 로그인 시 데이터 초기화 사고)
2. **회원가입/로그인 없음.** 설치 → 앱 열기 → 바로 달력.
3. **광고 SDK 절대 금지.** (리뷰 487개 중 불만 1위 25.9%. "광고 없음"이 핵심 마케팅 무기)
4. **데이터 유실 = 사형.** 3중 안전장치: (a) 자동 로컬 스냅샷 백업 (b) base64 텍스트 내보내기/복원 (c) JSON 파일 내보내기. DB 마이그레이션은 반드시 하위호환 테스트 후 배포. (리뷰: "공수 다 날아감, 장난합니까?" — 이 데이터는 월급 증빙)
5. **성능:** 콜드 스타트 1초 이내, 공수 입력 3탭 이내 완료.
6. **숫자 정확성:** 입력 공수값 반올림 절대 금지(1.8은 1.8 그대로, 경쟁앱은 2.0으로 반올림하는 버그). 금액 계산은 정수(원 단위) 연산으로 부동소수점 오차 방지 — **공수는 ×100 정수(centi-공수)로 저장**, 금액은 int 원. 정산 로직은 전부 단위 테스트.
7. **UI:** 한국어, 큰글씨 모드(설정 단계 조절), 다크모드, 고대비 색상. 주 사용층 40~60대 남성, 큰 글씨와 단순한 화면 선호.

## 확정된 설계 결정 (사용자 확인 완료 — 재질문 금지)

| 항목 | 결정 |
|---|---|
| 주 시작 요일 | 일요일 (설정에서 변경 가능하게) |
| 하루 기록 수 | 무제한 여러 건 (오전/오후 두 업체, 본공수+잔업 분리 기록 등 대응) |
| 세금 끝전 처리 | 세금 10원 미만 절사(원천징수 실무 관행). 설정으로 방식 변경 가능하게 설계 |
| 공수 단위 | 0.05 단위 입력 허용, 내부 저장은 ×100 정수 |
| 사용자 확인 환경 | Mac 보유(iOS 시뮬레이터+아이폰), Windows PC+갤럭시도 가능. **개발환경 처음 설치부터 안내 필요** |

## 시장조사 요약 (판단 근거 — 개발 중 모든 판단은 이 데이터 기준)

앱스토어 공수앱 7종 리뷰 487개 + 커뮤니티 조사 결과:

- 불만 순위: 광고 25.9% > 오류/먹통 18.1% > 오프라인 필요 5.7% > 데이터 유실 5.1% > 로그인 강요 반감 4.9% > 세금 계산 4.1% > 백업/이전 3.9% > 공수값 유연성 2.9% > 현장별 색상 구분 2.5% > 일비/식비 1.6% > 위젯 1.4%(지불의사 직접 증거) > 연간 통계 1.0% > 공휴일 표시 0.8% > 미수금 0.4%
- 경쟁 4강: **공수노트**(★4.57, 미수금 관리 유일, 광고 과다로 이탈 중) / **워크캘린더**(★4.69, 최대 경쟁자. 광고 없음, 퇴직공제금+실업급여 계산 독점, base64 복붙 백업 호평. 약점: 공수 프리셋 1.0/1.5/2.0 고정·소수점 입력 버그·색상 구분 약함·유실 사고 2건·위젯 없음) / **공수계산기 홍준표**(★4.61, 최장수, 광고 폭주·백업 없음) / **일다오**(★3.26, 서버 의존으로 신뢰 상실)
- 4강 전원 공백 = 우리 차별화: ① 홈 위젯 ② 명세서 PDF 증빙 내보내기 ③ 완성도 높은 커스텀 공수(자유 프리셋+0.05 단위+반올림 없음) ④ 로컬 기반 팀장 모드(v2)
- 커뮤니티 추가 니즈: 여러 현장 동시 근무(날짜별 다른 단가 필수), 단가 인상 이력(과거 기록은 당시 단가 유지), 조선소 코드 공수(A=0.9/B=1.0/E잔업=1.5/야간=2.0 → 프리셋 자유 정의로 흡수), 일 단위 식비/숙식비 정산, 연속 기간 채우기, 임금체불 증빙용 기록(PDF 근거)

## MVP v1 기능 명세

### F1. 달력 홈 + 원터치 공수 입력
- 월 달력이 첫 화면. 날짜 탭 → 하단 시트에 공수 프리셋 버튼들
- 프리셋은 유저가 자유 정의 (이름 + 공수값 + 색상). 온보딩 직군 선택 시 기본 제공:
  - 건설형: 1.0 / 1.5 / 2.0 / 0.5 / 휴무
  - 조선소형: A(0.9) / B(1.0) / E잔업(1.5) / 야간(2.0) / 반공(0.5) / 휴무
  - 직접 만들기
- 임의 값 직접 입력: 0.05 단위, 소수점 키보드 정상 작동, 반올림 금지
- 연속 기간 채우기: 시작~종료일 선택 → 같은 공수/업체 일괄 입력
- 날짜별 메모 + 메모 검색
- 한국 공휴일 빨간날 표시 (로컬 데이터 내장, API 호출 없음. 연도 갱신은 앱 업데이트로)
- 당일로 이동 버튼, 월 스와이프 이동

### F2. 업체(현장) 다중 관리
- 업체별: 이름, 기본 단가, 색상 (고대비 팔레트 10색+, 서로 확실히 구분)
- 단가 변경 이력: 적용 시작일 기준 개정. 과거 기록은 당시 단가로 계산 유지
- 특정 날짜만 단가 개별 오버라이드
- 달력에 업체 색상 표시. 하루 여러 건 기록 가능

### F3. 정산 계산
- 월 요약 카드: 총 공수, 세전, 세후 실수령 (달력 화면 상시 표시)
- 세금 방식: 3.3% 원천징수 / 4대보험 / 공제 없음 — 업체별 선택
- 4대보험 요율은 연도별 상수 테이블 + 유저 직접 수정 가능. 2026년 요율 정확히 조사해 반영
- 일 단위 부가 항목: 일비/식비/숙식비(가산), 공제 항목(차감) 날짜별 기록 → 월 정산 자동 반영
- 기간 지정 정산 (예: 전월 21일~당월 20일 마감 현장)
- 통계: 월별 추이, 연간 누적(연봉 뷰), 업체별 합산

### F4. 백업/복원
- base64 텍스트 내보내기 (복사 → 카톡 나에게 보내기 → 새 기기에서 붙여넣어 복원)
- JSON 파일 내보내기/가져오기
- 자동 로컬 스냅샷 최근 7일치 + 복원 메뉴

### F5. 증빙 내보내기 (차별화 #1)
- 월 공수확인서 PDF/이미지: 업체명, 기간, 날짜별 공수 표, 단가, 부가항목, 합계, 서명란
- 품질 기준: 노동청에 들이밀 수 있는 수준
- 달력 화면 이미지 캡쳐 공유

### F6. 홈 위젯 (차별화 #2)
- iOS WidgetKit + Android Glance: 이번 달 총 공수 + 예상 실수령액
- home_widget 패키지, v1은 소형 1종만

### v1 제외 (만들지 마)
- 팀장 모드, 미수금/수금 → v2 (단, DB 스키마는 확장 가능하게)
- 퇴직공제금/실업급여 계산 → v2
- 구인구직, 커뮤니티, 임금 시세, 푸시 알림, 애널리틱스/추적 SDK → 영원히 안 함

### 수익 모델
- 기본 무료: 달력, 공수 입력, 업체 3개까지, 정산, 백업
- 프로 일회성 6,600원 (비소모성 IAP, 구독 아님): PDF 증빙, 위젯, 업체 4개+, 테마
- 복원 구매 버튼 필수. v1 출시에 IAP 포함

## 기술 스택

- Flutter 최신 stable, Material 3, 한국어 로케일
- 상태관리: Riverpod
- 로컬 DB: drift(sqlite) — 마이그레이션 하위호환이 최우선
- intl(통화/날짜), pdf + printing(증빙), home_widget(위젯), in_app_purchase(IAP)
- 달력: 자체 구현 우선 검토 (경쟁앱 수준의 커스텀 표시가 필요)
- 테스트: 정산 로직(세금, 단가 이력, 공수 합산, 부가항목) 단위 테스트 필수

### 확정 아키텍처 (M1 설계 워크플로 심사 결과 — 변경 시 근거 필요)

- **달력 자체 구현** (table_calendar 미사용): 셀 정체성 = dateKey(yyyyMMdd int), 탭→저장 경로에 DateTime 변환 없음. 고정 6주(42칸) 격자. 격자 산출은 `domain/month_grid.dart` 순수 함수 + 경계 테스트
- **커스텀 값 입력은 자체 키패드** (`ui/common/gongsu_keypad.dart`): 시스템 소수점 키보드(삼성 키보드 버그 계열)를 아예 쓰지 않는다. 1건 상한 10공수(UI 검증 전용)
- **기록은 스냅샷**: WorkEntries에 입력 시점의 프리셋 이름(labelSnapshot)/색(colorIdSnapshot) 복사. 프리셋은 삭제 대신 보관(isArchived)
- **soft delete만 존재**: 기록 삭제 = deletedAtMillis 세팅 + 실행 취소. 읽기는 DAO의 alive 필터 단일 진입점만 사용(백업 내보내기만 예외로 삭제 행 포함). 물리 삭제/DROP은 소스 가드 테스트로 부재 증명
- **모든 기록성 행에 uid(UUIDv4)**: 백업 병합·v2 기기 간 병합의 upsert 키. 시드 프리셋은 고정 uid (기기 간 중복 생성 방지)
- **연속 입력은 기본 동작** (설정 아님): 빈 날 첫 입력은 저장 후 시트 자동 닫힘, 기록 있는 날은 시트 유지 append
- **마이그레이션**: additive-only 하드 룰(CREATE TABLE/ADD COLUMN/CREATE INDEX만). drift 열기 전 pre-open guard가 user_version 검사 → 업그레이드 직전 DB 파일 + -wal/-shm 동반 백업(최근 2세트 회전), 다운그레이드는 열지 않고 안내. 업그레이드는 **재시도 안전**: onCreate 는 한 트랜잭션(스키마+시드+user_version), onUpgrade 는 컬럼(`_hasColumn`)·인덱스(`IF NOT EXISTS`)를 있으면 건너뛰고 마지막에 user_version 을 직접 쓴다 — 커밋 뒤 버전 기록 전에 죽어도 다음 실행이 같은 단계를 무사히 다시 돈다(`migration_test` 재시도 테스트)
- **간이 JSON 백업을 M1부터 탑재** (M4 정식 백업의 축소판, 같은 봉투 규약): 내보내기는 삭제 행 포함, 가져오기는 병합 전용(uid upsert, updatedAt 최신 승리) — 기존 데이터를 지우는 경로 없음. 백업 schemaVersion > 앱 버전이면 명시 거부
- **provider 구조**: 월 쿼리 1회(monthEntriesProvider)가 유일한 소스, 월 합계/일 상세는 파생. family 키는 전부 int. 이웃 달 ±1 미리 구독. main()은 shared_preferences 1회 로드 + runApp만(DB lazy open — M6에서 첫 프레임 설정값을 위해 prefs 읽기 추가)
- **M6 온보딩 직군 선택 규칙(선확정)**: 사용자가 수정하지 않은 시드 프리셋(고정 uid + createdAt==updatedAt)만 교체, 손댄 프리셋은 불변
- 주 시작 요일은 M1에서 일요일 상수. M6에서 설정으로 풀 때 첫 프레임 깜빡임 방지를 위해 경량 동기 저장소(SharedPreferences)에 미러할 것

### 도메인 데이터 규칙 (중요)
- 공수: `int` centi-공수 (1공수 = 100). 표시 시 `1.8`처럼 후행 0 제거. 파싱/표시 어디서도 double 경유 반올림 금지
- 금액: `int` 원. 곱셈 시 `(centiGongsu * dangaWon) ~/ 100` — 단가가 100원 단위가 아닐 수 있으므로 절사 규칙을 정산 테스트로 고정
- 세금: 10원 미만 절사 기본, 방식은 설정 가능하게 추상화
- 날짜: DB에는 `yyyyMMdd` int 키 (타임존 무관)

## 마일스톤 진행 상황

- [x] **M1: 스캐폴드 + 달력 + 프리셋/커스텀 공수 입력 + 월 합계** — 완료 (2026-08-31, 테스트 76개 그린, 4차원 리뷰+적대적 검증 통과. 메모/프리셋 관리/간이 백업/다크모드 팔레트 포함)
- [x] **M2: 업체 관리 + 단가 이력 + 색상 표시 + 부가항목** — 완료 (2026-09-02, 테스트 111개 그린. schemaVersion 2: Sites/SiteRateHistories/DayExtraItems 추가, v1→v2 골든 데이터 마이그레이션 테스트, 단가 해석(적용시작일 기준·오버라이드 우선) 순수 함수, 월 세전 수입 카드, 백업 봉투 확장(uid 재매핑))
- [x] **M3: 세금 정산 + 기간 정산 + 통계 + 공휴일** — 완료 (2026-09-02, 테스트 156개 그린. schemaVersion 3: Sites.taxMode/taxOptionsJson ADD COLUMN, v1/v2→v3 골든 마이그레이션 테스트, 세금 엔진(3.3%/4대보험+일용소득세) 정수 계산, 연도별 요율 테이블+사용자 오버라이드, 기간 정산 화면(마감 주기), 통계 화면, 공휴일 2025~2027 내장)
- [x] **M4: 백업/복원 + PDF 증빙 + 캡쳐 공유** — 완료 (2026-09-02, 테스트 177개 그린. base64 텍스트 백업 `GSJB1:`+gzip(공유/복사·붙여넣기 복원), JSON 파일 내보내기/가져오기(share_plus/file_picker), 자동 로컬 스냅샷 7일 회전+복원 메뉴, 월 공수확인서 PDF(pdf+printing, 나눔고딕 내장, 미리보기/공유/이미지), 달력 캡쳐 PNG 공유. 플러그인은 서비스 추상화로 테스트에서 가짜 주입)
- [x] **M5: 홈 위젯 (iOS/Android)** — 완료 (2026-09-02, 테스트 186개 그린. home_widget 0.9 + 서비스 추상화, 순수 페이로드 빌더(표시 문자열만), 값 변경 시에만 저장·갱신하는 HomeWidgetSyncer, iOS WidgetKit 확장 `ios/GongsuWidget`(xcodeproj 스크립트로 타깃 추가, App Group), Android AppWidgetProvider+RemoteViews 2×2. 네이티브 컴파일은 오너 Mac 첫 실행이 검증 게이트)
- [x] **M6: 프로 IAP + 온보딩 + 큰글씨/다크모드 마감 + 스토어 출시 준비** — 완료 (2026-09-02, 테스트 207개 그린. shared_preferences 미러 + 설정 화면(글씨 3단계·화면 모드·주 시작 요일·테마 색), 온보딩 직군 선택(미수정 시드만 교체), in_app_purchase 비소모성 `gongsu_pro` + 페이월/복원 + 게이팅(PDF·위젯·업체 4개+·테마), 앱 아이콘 코드 생성, Android 서명 설정, 개인정보처리방침/스토어 문안/출시 가이드)

각 마일스톤 완료 시 시뮬레이터/실기기 확인 방법을 비개발자 눈높이로 안내할 것. 실행 가이드: `gongsu_ledger/docs/RUN_GUIDE.md`(Mac·아이폰, M1~M6 체크리스트) / `RUN_GUIDE_WINDOWS.md`(Windows·갤럭시, APK 사이드로드·에뮬레이터 포함) / `RELEASE_GUIDE.md`(출시).

### M2에서 확정된 규칙
- 단가는 기록에 저장하지 않는다. `SiteRateHistories`에서 "날짜 이하 가장 늦은 effectiveFrom" 행으로 조회 시점 해석 (`domain/rate_resolver.dart`). 기록별 `unitRateWonOverride`가 있으면 그것이 우선
- 업체 생성 시 기본 단가는 effectiveFrom = 20000101 이력으로 저장 (과거 전체 적용). 같은 업체·같은 시작일 재설정은 갱신(중복 이력 금지)
- 부가항목 금액은 항상 0 이상, 방향은 kind('allowance'/'deduction')로. `isTaxable`은 M3 예약(기본 false)
- 세전 예상 수입 = 공수×단가(해석된 것만) + 가산 − 공제. 단가 미설정 공수는 `unpricedCenti`로 카드에 "제외" 표시. 금액 정보가 하나도 없으면 카드에 금액 줄 자체를 숨김
- 달력 점 색: 업체 붙은 기록은 업체 색(live), 아니면 프리셋 색 스냅샷
- 마지막 선택 업체는 AppSettings `last_site_id`에 저장 → 다음 입력 기본값
- 마이그레이션 테스트: `drift_schemas/drift_schema_vN.json` 덤프 커밋 + `test/data/generated_migrations/`(drift_dev schema generate) + `test/data/migration_test.dart`의 골든 데이터 테스트. 스키마 바꿀 때마다 덤프·generate 재실행 필수
- 무료 티어 "업체 3개까지" 제한은 M6 IAP와 함께 넣는다 (지금은 무제한)

### M3에서 확정된 규칙
- 세금은 저장하지 않고 조회 시점에 계산한다 (`domain/tax_engine.dart`). 업체별 `Sites.taxMode`('none'|'withholding33'|'insurance4') + `taxOptionsJson`(TaxOptions). 기본 'none' — 잘못된 공제보다 공제 없음이 안전
- 3.3% = 소득세 3% + 지방소득세(소득세의 10%). 4대보험 = 근로자 부담분(국민연금·건강·장기요양(건강보험료의 %)·고용) + 옵션 일용근로소득세(일 15만원 공제 후 6%, 세액공제 55% → 실효 2.7%, 소액부징수 1,000원, 지방소득세 10%). 국민연금·건강보험은 해당 업체 월 근무일 ≥ pensionHealthMinDays(기본 8, 0=항상)일 때만. 국민연금 기준소득은 상·하한 적용 후 천원 미만 절사. 상·하한은 매년 7월 개정 → 테이블에 1~6월(`pensionMonthlyCapWon`/`FloorWon`)·7월부터(`…FromJulyWon`) 두 벌, `pensionCapFor(month)`로 해석. 미래 연도 폴백은 최신 7월 개정치를 연중 승계
- 비율은 전부 십만분율(per100k) 정수. 요율은 연도별 상수(`domain/tax_rates.dart`, 2025/2026) + AppSettings `tax_rates_override_<year>` JSON 병합(모르는 키·음수 무시). 미래 연도는 최신 테이블 승계. **매년 초 요율 상수 갱신 필수**
- 끝전: AppSettings `tax_rounding` ('floor10' 기본 | 'exact'). 모든 공제 항목에 개별 적용
- 과세 기준 = 노무비(공수×단가) + `isTaxable` 가산 항목. 공제 항목은 과세 기준을 줄이지 않는다. 일용근로소득세는 날짜별 과세 기준으로 계산
- 기간 정산(`domain/settlement.dart`)이 월 카드·정산 화면·통계의 단일 계산 경로. 업체 미지정 묶음(siteId null)은 세금 없음. 3.3%·일용소득세 세율은 기간 종료일 연도 기준. **4대보험은 달력월 단위로 따로 계산**(21일~20일 마감 기간이면 두 달 각각): 근무일 8일 판정은 기간 밖 날짜까지 포함한 그 달 전체 근무일로, 요율·상한은 그 달의 연도·월로. 그래서 `periodSettlementProvider`는 기간을 덮는 달 전체(`_monthCoveringKey`)를 구독하고 관련 연도 테이블을 전부 받는다
- 정산 마감 주기 시작일은 AppSettings `settle_cycle_start_day`(1~28). 정산 화면 family 키는 `periodKey(from,to) = from×1e8 + to`
- 공휴일은 `domain/korean_holidays.dart` 상수(2025~2027, 2027은 잠정). API 호출 없음. 매년 월력요항 확정 시 갱신
- 통계는 연간 12개월을 정산 함수로 각각 계산해 파생 (별도 집계 로직 없음)

### M4에서 확정된 규칙
- 텍스트 백업 봉투 `GSJB1:` + base64(gzip(JSON 봉투)) (`data/backup/backup_text_codec.dart`). 복원은 GSJB1 텍스트·원시 JSON·파일 모두 `decodeBackupText`로 정규화 → `importBackupJson`(병합 전용). 메신저가 끼워 넣는 공백/줄바꿈은 제거
- 자동 스냅샷: `snapshots/snapshot_<yyyyMMdd>.gsjb`, 앱 첫 프레임 뒤 그날 파일이 없으면 생성, 백그라운드 진입(paused) 시 그날 파일 갱신, 최근 7일 회전. 임시 파일에 쓴 뒤 rename. 실패는 조용히 무시(안전망이지 전제가 아님). `SnapshotScheduler`가 홈을 감싼다
- 플러그인(share_plus/file_picker/printing/path_provider)은 `services/share_service.dart` 추상화 뒤에 두고 위젯 테스트는 가짜로 override — 플러그인을 직접 호출하는 위젯 코드 금지. 가져오기 파일은 20MB 상한(`maxBackupFileBytes`, `PlatformFile.length()`로 먼저 검사)
- 백업 봉투에 `appSettings`도 들어간다 — 단, 허용 목록만(`backupSettingKeys`: report_worker_name·tax_rounding·settle_cycle_start_day·job_kind + `tax_rates_override_*`). 화면 설정(prefs 미러 키)·pro_unlocked·last_site_id 는 기기 값이라 제외. 가져올 때 설정은 없을 때만 넣는다(기존 값 유지)
- 가져오기는 행 단위 관용: 깨진 행 하나는 건너뛰고(skipped 카운트) 나머지는 살린다. 날짜 키는 실제 달력으로 검증(`_isPlausibleDateKey`). 내보내기는 한 트랜잭션 안에서 전 테이블을 읽는다(일관 스냅샷). 텍스트 복원은 base64 문자 외 전부 제거 후 `base64.normalize` — 메신저가 끼워 넣는 어떤 문자도 허용
- 휴지통(`ui/backup/trash_page.dart`, 설정 > 기록 > 삭제된 기록): soft delete 된 공수·부가항목을 보여 주고 '되살리기'로 deletedAtMillis 를 null 로 되돌린다. DAO `watchDeleted()`가 유일한 삭제 행 읽기 경로
- DB 열기 실패 화면(`_DbErrorView`)에는 '다시 시도'(databaseProvider invalidate)와 '기록 복구'가 있다. 복구 = `data/db/db_rescue.dart`의 `quarantineDatabaseFiles`로 db/-wal/-shm 을 `gongsu.db.corrupt_<시각>.bak`으로 **이름만 바꾸고**(삭제 아님) 새 DB를 연 뒤 최신 스냅샷을 병합 복원. 파괴 경로는 여전히 없다
- 스냅샷 저장 직전 `PRAGMA wal_checkpoint(TRUNCATE)` — Android 자동 백업(`res/xml/backup_rules.xml`·`data_extraction_rules.xml`, WAL/SHM 제외)이 반쯤 쓰인 DB 를 올리지 않게
- 공수 확인서 PDF: `data/export/work_report_data.dart`(정산 결과 + 행 데이터 조립) → `work_report_pdf.dart`(pdf 패키지). 합계·공제는 반드시 정산 엔진 결과를 쓴다(화면과 숫자 일치). 한글 폰트는 `assets/fonts/NanumGothic-*.ttf`(OFL, 약 4MB) 내장 — 네트워크 폰트 금지
- 달력 캡쳐: `RepaintBoundary` → PNG → 공유. 배경은 surface 색으로 채워 투명 PNG 방지

### M5에서 확정된 규칙
- **위젯은 계산하지 않는다.** `domain/widget_payload.dart`의 `buildWidgetPayload`가 월 정산(monthSettlementProvider — 월 카드와 같은 경로)에서 표시 문자열(월 라벨·공수·근무일·금액 라벨·금액·갱신 시각)을 만들고, `ui/common/home_widget_syncer.dart`가 표시 값이 바뀔 때만 저장+갱신 신호를 보낸다. 키 이름(`WidgetKeys`)은 `ios/GongsuWidget/GongsuWidget.swift`·`android/.../GongsuWidgetProvider.kt`와 동일해야 한다 — 바꾸면 세 곳 동시 수정
- 금액 줄 규칙: 노무비·가산·공제로 실제 금액이 있을 때만(`hasPricedMoney`, 단가 없는 공수뿐이면 비움). 세금 방식이 설정된 업체가 하나라도 있으면 실수령(세후), 아니면 세전
- 플러그인은 `services/home_widget_service.dart` 추상화 뒤(M4 규칙과 동일, 테스트는 가짜 주입). App Group `group.com.gongsujangbu.gongsuLedger`, iOS kind `GongsuWidget`, Android provider `GongsuWidgetProvider`
- iOS: 확장 타깃은 `tool/ios_add_widget_target.rb`(xcodeproj gem)로 Runner.xcodeproj에 추가 — 재실행 안전. pbxproj는 ASCII 유지(표시 이름은 Info.plist에), 프레임워크는 Swift import 자동 링크(SDK 버전 박힌 경로 금지), 버전은 Flutter Generated.xcconfig 승계(`MARKETING_VERSION=$(FLUTTER_BUILD_NAME)`). 배포 타깃 iOS 15, iOS 17 containerBackground 분기
- Android: Glance 대신 `AppWidgetProvider`+RemoteViews (소형 1종엔 충분, Compose 컴파일러·의존성 없이 빌드 위험 최소). `updatePeriodMillis=0` — 주기 갱신 없이 앱이 값을 바꿀 때만 갱신. 앱/위젯 표시 이름은 `res/values/strings.xml`
- 달 바뀜: 앱이 resumed될 때 현재 달로 재구독. 앱을 안 열면 위젯은 마지막 달 라벨("9월 공수")을 그대로 보여준다(라벨에 달이 있어 오해 없음)
- 네이티브 코드(Swift/Kotlin)는 이 환경에서 컴파일 검증 불가 — 오너 Mac의 첫 `flutter run`이 검증 게이트. 위젯 프로 게이팅은 M6 IAP와 함께 넣는다(지금은 전원 사용)

### M6에서 확정된 규칙
- **첫 프레임 값은 prefs 미러에서**: 화면 설정(`text_size`·`screen_mode`·`week_start`·`theme_color`)·`onboarding_done`·`pro_unlocked`는 `LocalPrefs`(shared_preferences, 테스트는 `MemoryLocalPrefs`)와 AppSettings(DB)에 같은 키·같은 문자열로 함께 쓴다. 읽기는 prefs 만(동기). 백업 봉투에는 넣지 않는다(기기 설정이지 기록이 아님)
- 큰글씨 = 시스템 배율 × 앱 단계(100/115/130%), 상한 1.5 (`app.dart` builder). 배율은 정수 백분율로 저장(double 금지 규칙). 새 화면은 "아주 크게"에서 오버플로 없는지 위젯 테스트로 확인(`m6_flow_test` 패턴)
- 주 시작 요일은 `appearanceProvider.weekStart`가 유일한 소스 — `monthGridDateKeys`·`weekdayOrder`에 항상 넘긴다. 주말 색은 요일 기준(순서와 무관)
- 온보딩 직군 교체는 `data/seed/seed_switch.dart` 순수 계획 + `PresetRepository.applyJobSeed` 트랜잭션. 보관/복원은 updatedAt 을 건드리지 않는다(`setArchivedSilently`) — 올리면 '사용자 수정'이 되어 다시는 교체 대상이 안 된다. '직접 만들기' = 미수정 시드 전부 보관
- 프로 = 비소모성 `gongsu_pro` 하나(두 스토어 동일 ID). 검증은 스토어 응답만(서버 없음), 상태는 기기 로컬 → 다른 기기는 '이전 구매 복원'. 결제 코드는 `services/purchase_service.dart` 추상화 뒤(테스트는 가짜). 게이팅 진입점은 `ui/pro/pro_gate.dart`의 `ensurePro` 하나: 업체 4개째(`freeSiteLimit`=3), 확인서 PDF, 테마 색(id≠0), 위젯(잠김 페이로드 `widget_locked`=1 → 네이티브가 안내 문구)
- 구매 신호는 페이월 화면이 아니라 `ui/common/purchase_syncer.dart`(홈을 감쌈)가 받는다: `PurchaseService.entitlementHandler`가 `completePurchase` **전에** `proProvider.unlock()`을 끝내야 한다(실패하면 complete 를 미뤄 스토어가 다시 준다). Android 는 앱 시작 시 `reconcileAtStartup()`(restorePurchases) 로 재설치·기기 이전을 자동 반영, iOS 는 로그인 창이 뜨므로 사용자 버튼만. 페이월의 복원 대기 타이머는 `Timer`로 두고 dispose 에서 취소
- 선택형 설정 UI 는 `SegmentedButton` 대신 `ui/common/choice_chip_row.dart`(`ChoiceChipRow`, Wrap) — 360dp·아주 크게 글씨에서 넘치지 않는다. 고정폭 숫자 칸은 `FittedBox(scaleDown)`
- 프리셋·업체·마지막 업체 provider 는 `ref.keepAlive()` — 시트가 열릴 때마다 DB 를 다시 읽지 않는다. 홈 위젯 동기화는 월 기록·단가·업체 세 provider 가 모두 값을 가진 뒤에만 보낸다(로딩 중 0 공수 페이로드 금지)
- 앱 표시 버전은 `lib/app_info.dart` 상수 — pubspec `version`과 일치를 테스트로 고정. 아이콘은 `test/screenshots/app_icon_test.dart`(ICON_OUT=1)로 생성 후 `dart run flutter_launcher_icons`
- Android 릴리스 서명은 `android/key.properties`(git 제외) 있을 때만 release 키, 없으면 debug 키로 폴백(`flutter run --release` 가능). 출시 절차·스토어 문안·개인정보처리방침은 `docs/RELEASE_GUIDE.md`·`STORE_LISTING.md`·`PRIVACY_POLICY.md`(앱 내 `privacy_text.dart`와 동일 유지)

## 백로그

- 최근 커스텀 입력값을 프리셋 그리드 끝에 임시 칩으로 노출 (설계 심사 graft 제안)
- 2027년 공휴일 대체공휴일 확정치 반영 / 2027.7 국민연금 기준소득 상한 개정치(매년 7월 갱신)
- 저가 실기기(갤럭시 A 시리즈) `--profile` 콜드 스타트 측정을 마일스톤 완료 게이트로 (오너 실기기 확보 시)
- 출시 후: 실기기 프로 결제·복원 검증(샌드박스), 위젯 프로 게이팅 UX 피드백, 스토어 심사 피드백 반영
- 세금 정밀도(전체 점검에서 나온 것, 오너 결정 필요): 일용소득세 소액부징수를 '지급 건별'로 묶는 옵션(지금은 일별) / 월 60시간 미만·220만원 미만 국민연금 제외 규칙 / 같은 날 두 단가 이력의 우선순위(지금은 updatedAt 최신)
- 기술 부채: 스냅샷 gzip 인코딩을 UI isolate 밖으로(FakeAsync 테스트와 충돌해 보류) / `printing` 플러그인도 서비스 추상화 뒤로 / 온보딩 직군 변경을 `job_kind` 설정으로 전파 / 달력 날짜 셀 semantics 라벨 / iPad 지원 여부 결정(지금은 iPhone 전용 `TARGETED_DEVICE_FAMILY=1`) / `sqlite3_flutter_libs` 의존 정리

## 테스트 작성 주의 (재발 방지)

- 위젯 테스트에서 drift 스트림을 FakeAsync 안에서 직접 await(`watchX().first`)하면 이후 pumpWidget 언마운트가 영구 행업한다 — DB 검증은 `getRange` 같은 일반 쿼리 Future만 사용할 것
- 위젯 테스트 끝에는 `unmountApp(tester)` 패턴(빈 위젯 pump + 가짜 시계 1초 진행)으로 drift 정리 타이머를 소진할 것

## 개발 명령어

```bash
cd gongsu_ledger
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # drift/riverpod 코드 생성
flutter analyze
flutter test
flutter run   # 기기/시뮬레이터 연결 시
# 시뮬레이터 없이 화면 캡쳐 PNG + 확인서 PDF 샘플 뽑기 (오너 확인·스토어 스크린샷용)
flutter test test/screenshots/screenshots_test.dart --dart-define=SHOT_DIR=/절대/경로
```

## Git

- 개발 브랜치: `claude/worker-timesheet-flutter-app-6pltoc`
- 커밋 메시지는 한국어 또는 영어 명령형, 마일스톤 단위로 의미 있게 분리
