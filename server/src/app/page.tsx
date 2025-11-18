export default function Home() {
  return (
    <main style={{ padding: '2rem', fontFamily: 'system-ui, sans-serif' }}>
      <h1>GG Server API</h1>
      <p>Server is running. API endpoints available at /api/*</p>
      <ul>
        <li><code>POST /api/auth/register</code> - User registration</li>
        <li><code>POST /api/auth/login</code> - User login</li>
        <li><code>POST /api/llm/chat</code> - LLM chat proxy</li>
      </ul>
    </main>
  );
}
