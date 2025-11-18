'use client';

export default function LoginPage() {
  return (
    <main style={{
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      backgroundColor: '#f5f5f5',
      fontFamily: 'system-ui, sans-serif'
    }}>
      <div style={{
        backgroundColor: 'white',
        padding: '2rem',
        borderRadius: '8px',
        boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
        width: '100%',
        maxWidth: '400px'
      }}>
        <h1 style={{ marginBottom: '0.5rem', fontSize: '1.5rem' }}>Welcome to TypeWise AI</h1>
        <p style={{ color: '#666', marginBottom: '2rem' }}>Sign in to continue to your writing assistant</p>

        <form id="loginForm" style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          <div>
            <label htmlFor="email" style={{ display: 'block', marginBottom: '0.5rem', fontWeight: '500' }}>
              Email
            </label>
            <input
              type="email"
              id="email"
              name="email"
              required
              style={{
                width: '100%',
                padding: '0.75rem',
                border: '1px solid #ddd',
                borderRadius: '4px',
                fontSize: '1rem',
                boxSizing: 'border-box'
              }}
              placeholder="you@example.com"
            />
          </div>

          <div>
            <label htmlFor="password" style={{ display: 'block', marginBottom: '0.5rem', fontWeight: '500' }}>
              Password
            </label>
            <input
              type="password"
              id="password"
              name="password"
              required
              style={{
                width: '100%',
                padding: '0.75rem',
                border: '1px solid #ddd',
                borderRadius: '4px',
                fontSize: '1rem',
                boxSizing: 'border-box'
              }}
              placeholder="••••••••"
            />
          </div>

          <div id="error" style={{
            color: '#d32f2f',
            fontSize: '0.875rem',
            display: 'none'
          }}></div>

          <button
            type="submit"
            style={{
              backgroundColor: '#007bff',
              color: 'white',
              padding: '0.75rem',
              border: 'none',
              borderRadius: '4px',
              fontSize: '1rem',
              fontWeight: '500',
              cursor: 'pointer',
              transition: 'background-color 0.2s'
            }}
            onMouseOver={(e) => e.currentTarget.style.backgroundColor = '#0056b3'}
            onMouseOut={(e) => e.currentTarget.style.backgroundColor = '#007bff'}
          >
            Sign In
          </button>
        </form>

        <p style={{ marginTop: '1.5rem', textAlign: 'center', color: '#666', fontSize: '0.875rem' }}>
          Don't have an account? <a href="/register" style={{ color: '#007bff', textDecoration: 'none' }}>Sign up</a>
        </p>
      </div>

      <script dangerouslySetInnerHTML={{ __html: `
        document.getElementById('loginForm').addEventListener('submit', async (e) => {
          e.preventDefault();

          const email = document.getElementById('email').value;
          const password = document.getElementById('password').value;
          const errorDiv = document.getElementById('error');
          const submitButton = e.target.querySelector('button[type="submit"]');

          // Clear previous errors
          errorDiv.style.display = 'none';
          submitButton.disabled = true;
          submitButton.textContent = 'Signing in...';

          try {
            const response = await fetch('/api/auth/login', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ email, password })
            });

            const data = await response.json();

            if (!response.ok) {
              throw new Error(data.error || 'Login failed');
            }

            // Redirect to success page which will handle app opening and troubleshooting
            window.location.href = '/auth-success?token=' + encodeURIComponent(data.token);

          } catch (error) {
            errorDiv.style.display = 'block';
            errorDiv.style.color = '#d32f2f';
            errorDiv.textContent = error.message;
            submitButton.disabled = false;
            submitButton.textContent = 'Sign In';
          }
        });
      `}} />
    </main>
  );
}
