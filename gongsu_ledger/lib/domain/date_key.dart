/// 날짜 키 유틸. DB에는 타임존 영향이 없는 yyyyMMdd 정수로 저장한다.
library;

/// DateTime → yyyyMMdd 정수 키. 시각/타임존 정보는 버린다.
int dateKeyOf(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

/// yyyyMMdd 정수 키 → 로컬 DateTime(자정).
DateTime dateFromKey(int key) =>
    DateTime(key ~/ 10000, (key % 10000) ~/ 100, key % 100);

/// 해당 연/월의 [시작키, 끝키] (양끝 포함).
(int, int) monthKeyRange(int year, int month) =>
    (year * 10000 + month * 100 + 1, year * 10000 + month * 100 + 31);
