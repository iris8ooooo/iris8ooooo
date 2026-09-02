/// 무료/프로 경계. 프로 = 일회성 비소모성 구매(구독 아님).
library;

/// 스토어 상품 ID (App Store Connect / Play Console 에 같은 ID 로 등록).
const String proProductId = 'gongsu_pro';

/// 무료 티어 업체 수 상한.
const int freeSiteLimit = 3;

/// 정가 표시용 (스토어 가격을 못 받아올 때만 사용).
const String proListPriceLabel = '6,600원';

bool canAddSite({required int activeSites, required bool isPro}) =>
    isPro || activeSites < freeSiteLimit;

/// 프로 전용 기능 이름 (페이월 안내문에 사용).
enum ProFeature {
  pdf('공수 확인서 PDF'),
  widget('홈 위젯'),
  sites('업체 4개 이상'),
  theme('테마 색상');

  const ProFeature(this.label);

  final String label;
}
