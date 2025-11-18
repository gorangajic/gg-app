export default function Home() {
  return (
    <main style={{ padding: '2rem', fontFamily: 'system-ui, sans-serif' }}>
      <h1>GG Server API</h1>
      <p>TypeWise AI Server - Intelligent Writing Assistant API</p>

      <h2>Authentication Endpoints</h2>
      <ul>
        <li><code>POST /api/auth/register</code> - User registration</li>
        <li><code>POST /api/auth/login</code> - User login</li>
        <li><code>POST /api/auth/logout</code> - User logout</li>
      </ul>

      <h2>AI Writing Assistant Endpoints</h2>
      <ul>
        <li><code>POST /api/suggestions/generate</code> - Generate writing suggestions</li>
        <li><code>POST /api/suggestions/improve-grammar</code> - Improve grammar and clarity</li>
        <li><code>POST /api/suggestions/rewrite</code> - Rewrite text in different styles</li>
      </ul>

      <p style={{ marginTop: '2rem', color: '#666' }}>
        All AI endpoints require authentication via Bearer token.
      </p>
    </main>
  );
}
