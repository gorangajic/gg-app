// TypeWise AI Popup Script

document.addEventListener('DOMContentLoaded', () => {
  initializePopup();
});

async function initializePopup() {
  showView('loadingView');

  // Check authentication status
  chrome.runtime.sendMessage({ action: 'checkAuth' }, (response) => {
    if (response && response.isAuthenticated) {
      showAuthenticatedView();
    } else {
      showAuthView();
    }
  });

  // Set up event listeners
  setupEventListeners();
}

function setupEventListeners() {
  // Login form
  document.getElementById('loginFormElement').addEventListener('submit', handleLogin);

  // Register form
  document.getElementById('registerFormElement').addEventListener('submit', handleRegister);

  // Toggle between login and register
  document.getElementById('showRegister').addEventListener('click', () => {
    document.getElementById('loginForm').classList.add('hidden');
    document.getElementById('registerForm').classList.remove('hidden');
  });

  document.getElementById('showLogin').addEventListener('click', () => {
    document.getElementById('registerForm').classList.add('hidden');
    document.getElementById('loginForm').classList.remove('hidden');
  });

  // Logout button
  document.getElementById('logoutBtn').addEventListener('click', handleLogout);

  // Settings button
  document.getElementById('openOptions').addEventListener('click', () => {
    chrome.runtime.openOptionsPage();
  });
}

async function handleLogin(e) {
  e.preventDefault();

  const email = document.getElementById('loginEmail').value;
  const password = document.getElementById('loginPassword').value;
  const errorElement = document.getElementById('loginError');

  errorElement.textContent = '';

  chrome.runtime.sendMessage(
    {
      action: 'login',
      data: { email, password }
    },
    (response) => {
      if (response && response.success) {
        showAuthenticatedView();
      } else {
        errorElement.textContent = response?.error || 'Login failed. Please try again.';
      }
    }
  );
}

async function handleRegister(e) {
  e.preventDefault();

  const name = document.getElementById('registerName').value;
  const email = document.getElementById('registerEmail').value;
  const password = document.getElementById('registerPassword').value;
  const errorElement = document.getElementById('registerError');

  errorElement.textContent = '';

  chrome.runtime.sendMessage(
    {
      action: 'register',
      data: { name, email, password }
    },
    (response) => {
      if (response && response.success) {
        showAuthenticatedView();
      } else {
        errorElement.textContent = response?.error || 'Registration failed. Please try again.';
      }
    }
  );
}

async function handleLogout() {
  chrome.runtime.sendMessage({ action: 'logout' }, (response) => {
    if (response && response.success) {
      showAuthView();
      // Reset forms
      document.getElementById('loginFormElement').reset();
      document.getElementById('registerFormElement').reset();
    }
  });
}

function showView(viewId) {
  // Hide all views
  document.querySelectorAll('.view').forEach(view => {
    view.classList.add('hidden');
  });

  // Show requested view
  document.getElementById(viewId).classList.remove('hidden');
}

function showAuthView() {
  showView('authView');
  document.getElementById('loginForm').classList.remove('hidden');
  document.getElementById('registerForm').classList.add('hidden');
}

function showAuthenticatedView() {
  showView('authenticatedView');
}
