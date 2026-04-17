export default function HomePage() {
  return (
    <main className="container">
      <h1>PC + Mobile 연계 앱</h1>
      <p>
        이 페이지가 보이면 앱 실행은 정상입니다. 이제 PC와 모바일에서 같은 저장소를
        동기화하며 이어서 개발할 수 있습니다.
      </p>
      <ol>
        <li>PC에서 커밋 후 push</li>
        <li>모바일에서 pull 후 수정</li>
        <li>모바일에서 커밋 후 push</li>
        <li>PC에서 pull 후 계속 작업</li>
      </ol>
    </main>
  );
}
