# Mobile Handoff App

PC에서 작업하던 앱을 모바일에서도 이어서 개발할 수 있도록 만든 최소 Next.js 앱입니다.

## 1) 로컬(PC) 실행

```bash
npm install
npm run dev
```

브라우저에서 `http://localhost:3000` 접속

## 2) 모바일 연계 작업 순서

1. PC에서 작업 후 커밋/푸시
   ```bash
   git add .
   git commit -m "작업 내용"
   git push
   ```
2. 모바일에서 같은 저장소 열기
   - GitHub 앱/웹 + Codespaces 권장
3. 같은 브랜치 체크아웃 후 이어서 수정
4. 모바일에서 커밋/푸시
5. PC로 돌아와 `git pull` 해서 이어서 작업

## 3) 권장 모바일 개발 방식

- 가장 쉬움: **GitHub Codespaces**
  - 모바일 브라우저만으로 터미널/에디터 사용 가능
  - 별도 설치 최소화

## 4) 배포 전 확인

```bash
npm run build
npm run start
```

문제가 없으면 PR 생성 후 병합하면 됩니다.
