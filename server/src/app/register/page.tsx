'use client';

export default function RegisterPage() {
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
        <h1 style={{ marginBottom: '0.5rem', fontSize: '1.5rem' }}>Create Account</h1>
        <p style={{ color: '#666', marginBottom: '2rem' }}>Sign up for TypeWise AI</p>

        <form id="registerForm" style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          <div>
            <label htmlFor="name" style={{ display: 'block', marginBottom: '0.5rem', fontWeight: '500' }}>
              Name (optional)
            </label>
            <input
              type="text"
              id="name"
              name="name"
              style={{
                width: '100%',
                padding: '0.75rem',
                border: '1px solid #ddd',
                borderRadius: '4px',
                fontSize: '1rem',
                boxSizing: 'border-box'
              }}
              placeholder="Your name"
            />
          </div>

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
              minLength={8}
              style={{
                width: '100%',
                padding: '0.75rem',
                border: '1px solid #ddd',
                borderRadius: '4px',
                fontSize: '1rem',
                boxSizing: 'border-box'
              }}
              placeholder="At least 8 characters"
            />
            <small style={{ color: '#666', fontSize: '0.75rem' }}>
              Must be at least 8 characters long
            </small>
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
            Create Account
          </button>
        </form>

        <p style={{ marginTop: '1.5rem', textAlign: 'center', color: '#666', fontSize: '0.875rem' }}>
          Already have an account? <a href="/login" style={{ color: '#007bff', textDecoration: 'none' }}>Sign in</a>
        </p>
      </div>

      <script dangerouslySetInnerHTML={{ __html: `
        document.getElementById('registerForm').addEventListener('submit', async (e) => {
          e.preventDefault();

          const name = document.getElementById('name').value;
          const email = document.getElementById('email').value;
          const password = document.getElementById('password').value;
          const errorDiv = document.getElementById('error');
          const submitButton = e.target.querySelector('button[type="submit"]');

          // Clear previous errors
          errorDiv.style.display = 'none';
          submitButton.disabled = true;
          submitButton.textContent = 'Creating account...';

          try {
            const response = await fetch('/api/auth/register', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ email, password, name: name || undefined })
            });

            const data = await response.json();

            if (!response.ok) {
              throw new Error(data.error || 'Registration failed');
            }

            // Redirect to Mac app with token
            window.location.href = 'ggapp://auth?token=' + encodeURIComponent(data.token);

            // Show success message in case redirect doesn't work
            submitButton.textContent = 'Success! Opening app...';
            setTimeout(() => {
              errorDiv.style.display = 'block';
              errorDiv.style.color = '#2e7d32';
              errorDiv.textContent = 'If the app did not open, copy this token: ' + data.token;
            }, 2000);

          } catch (error) {
            errorDiv.style.display = 'block';
            errorDiv.style.color = '#d32f2f';
            errorDiv.textContent = error.message;
            submitButton.disabled = false;
            submitButton.textContent = 'Create Account';
          }
        });
      `}} />
    </main>
  );
}
