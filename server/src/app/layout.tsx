import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'GG Server API',
  description: 'Server API for GG App',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
