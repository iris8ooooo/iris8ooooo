import "./globals.css";

export const metadata = {
  title: "Mobile Handoff App",
  description: "PC와 모바일에서 연계 개발하는 Next.js 예제 앱",
};

export default function RootLayout({ children }) {
  return (
    <html lang="ko">
      <body>{children}</body>
    </html>
  );
}
