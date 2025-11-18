// Background Service Worker for TypeWise AI Chrome Extension
// Handles API communication with the server

const DEFAULT_SERVER_URL = 'http://localhost:3001';

// Storage keys
const STORAGE_KEYS = {
  AUTH_TOKEN: 'authToken',
  SERVER_URL: 'serverUrl',
  SETTINGS: 'settings'
};

// Default settings
const DEFAULT_SETTINGS = {
  autoTrigger: true,
  minTextLength: 10,
  suggestionDelay: 2000,
  maxSuggestions: 5,
  serverUrl: DEFAULT_SERVER_URL
};

// Initialize extension
chrome.runtime.onInstalled.addListener(() => {
  console.log('TypeWise AI Extension installed');

  // Set default settings if not already set
  chrome.storage.sync.get([STORAGE_KEYS.SETTINGS], (result) => {
    if (!result[STORAGE_KEYS.SETTINGS]) {
      chrome.storage.sync.set({ [STORAGE_KEYS.SETTINGS]: DEFAULT_SETTINGS });
    }
  });
});

// Message handler from content scripts and popup
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  console.log('Background received message:', request.action);

  switch (request.action) {
    case 'login':
      handleLogin(request.data, sendResponse);
      return true; // Keep channel open for async response

    case 'register':
      handleRegister(request.data, sendResponse);
      return true;

    case 'logout':
      handleLogout(sendResponse);
      return true;

    case 'checkAuth':
      checkAuth(sendResponse);
      return true;

    case 'generateSuggestions':
      generateSuggestions(request.data, sendResponse);
      return true;

    case 'improveGrammar':
      improveGrammar(request.data, sendResponse);
      return true;

    case 'rewriteText':
      rewriteText(request.data, sendResponse);
      return true;

    case 'getSettings':
      getSettings(sendResponse);
      return true;

    case 'updateSettings':
      updateSettings(request.data, sendResponse);
      return true;
  }
});

// Authentication Functions

async function handleLogin(data, sendResponse) {
  try {
    const settings = await getStoredSettings();
    const serverUrl = settings.serverUrl || DEFAULT_SERVER_URL;

    const response = await fetch(`${serverUrl}/api/auth/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        email: data.email,
        password: data.password
      })
    });

    const result = await response.json();

    if (response.ok && result.token) {
      // Store token
      await chrome.storage.sync.set({ [STORAGE_KEYS.AUTH_TOKEN]: result.token });

      sendResponse({
        success: true,
        user: result.user,
        message: result.message
      });
    } else {
      sendResponse({
        success: false,
        error: result.error || 'Login failed'
      });
    }
  } catch (error) {
    console.error('Login error:', error);
    sendResponse({
      success: false,
      error: error.message || 'Network error during login'
    });
  }
}

async function handleRegister(data, sendResponse) {
  try {
    const settings = await getStoredSettings();
    const serverUrl = settings.serverUrl || DEFAULT_SERVER_URL;

    const response = await fetch(`${serverUrl}/api/auth/register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        email: data.email,
        password: data.password,
        name: data.name
      })
    });

    const result = await response.json();

    if (response.ok && result.token) {
      // Store token
      await chrome.storage.sync.set({ [STORAGE_KEYS.AUTH_TOKEN]: result.token });

      sendResponse({
        success: true,
        user: result.user,
        message: result.message
      });
    } else {
      sendResponse({
        success: false,
        error: result.error || 'Registration failed'
      });
    }
  } catch (error) {
    console.error('Register error:', error);
    sendResponse({
      success: false,
      error: error.message || 'Network error during registration'
    });
  }
}

async function handleLogout(sendResponse) {
  try {
    const token = await getAuthToken();

    if (token) {
      const settings = await getStoredSettings();
      const serverUrl = settings.serverUrl || DEFAULT_SERVER_URL;

      // Call server logout endpoint
      await fetch(`${serverUrl}/api/auth/logout`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
    }

    // Remove token from storage
    await chrome.storage.sync.remove([STORAGE_KEYS.AUTH_TOKEN]);

    sendResponse({ success: true });
  } catch (error) {
    console.error('Logout error:', error);
    sendResponse({ success: false, error: error.message });
  }
}

async function checkAuth(sendResponse) {
  try {
    const token = await getAuthToken();
    sendResponse({
      isAuthenticated: !!token,
      token: token
    });
  } catch (error) {
    sendResponse({
      isAuthenticated: false,
      error: error.message
    });
  }
}

// AI Suggestion Functions

async function generateSuggestions(data, sendResponse) {
  try {
    const token = await getAuthToken();
    if (!token) {
      sendResponse({ success: false, error: 'Not authenticated' });
      return;
    }

    const settings = await getStoredSettings();
    const serverUrl = settings.serverUrl || DEFAULT_SERVER_URL;

    const response = await fetch(`${serverUrl}/api/suggestions/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        text: data.text,
        context: data.context,
        maxSuggestions: data.maxSuggestions || settings.maxSuggestions
      })
    });

    const result = await response.json();

    if (response.ok) {
      sendResponse({
        success: true,
        suggestions: result.suggestions,
        processingTime: result.processingTime
      });
    } else {
      sendResponse({
        success: false,
        error: result.error || 'Failed to generate suggestions'
      });
    }
  } catch (error) {
    console.error('Generate suggestions error:', error);
    sendResponse({
      success: false,
      error: error.message || 'Network error'
    });
  }
}

async function improveGrammar(data, sendResponse) {
  try {
    const token = await getAuthToken();
    if (!token) {
      sendResponse({ success: false, error: 'Not authenticated' });
      return;
    }

    const settings = await getStoredSettings();
    const serverUrl = settings.serverUrl || DEFAULT_SERVER_URL;

    const response = await fetch(`${serverUrl}/api/suggestions/improve-grammar`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        text: data.text
      })
    });

    const result = await response.json();

    if (response.ok) {
      sendResponse({
        success: true,
        original: result.original,
        improved: result.improved,
        changes: result.changes,
        processingTime: result.processingTime
      });
    } else {
      sendResponse({
        success: false,
        error: result.error || 'Failed to improve grammar'
      });
    }
  } catch (error) {
    console.error('Improve grammar error:', error);
    sendResponse({
      success: false,
      error: error.message || 'Network error'
    });
  }
}

async function rewriteText(data, sendResponse) {
  try {
    const token = await getAuthToken();
    if (!token) {
      sendResponse({ success: false, error: 'Not authenticated' });
      return;
    }

    const settings = await getStoredSettings();
    const serverUrl = settings.serverUrl || DEFAULT_SERVER_URL;

    const response = await fetch(`${serverUrl}/api/suggestions/rewrite`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        text: data.text,
        style: data.style
      })
    });

    const result = await response.json();

    if (response.ok) {
      sendResponse({
        success: true,
        original: result.original,
        rewritten: result.rewritten,
        style: result.style,
        processingTime: result.processingTime
      });
    } else {
      sendResponse({
        success: false,
        error: result.error || 'Failed to rewrite text'
      });
    }
  } catch (error) {
    console.error('Rewrite text error:', error);
    sendResponse({
      success: false,
      error: error.message || 'Network error'
    });
  }
}

// Settings Functions

async function getSettings(sendResponse) {
  try {
    const settings = await getStoredSettings();
    sendResponse({ success: true, settings });
  } catch (error) {
    sendResponse({ success: false, error: error.message });
  }
}

async function updateSettings(data, sendResponse) {
  try {
    const currentSettings = await getStoredSettings();
    const newSettings = { ...currentSettings, ...data };

    await chrome.storage.sync.set({ [STORAGE_KEYS.SETTINGS]: newSettings });

    sendResponse({ success: true, settings: newSettings });
  } catch (error) {
    sendResponse({ success: false, error: error.message });
  }
}

// Helper Functions

async function getAuthToken() {
  const result = await chrome.storage.sync.get([STORAGE_KEYS.AUTH_TOKEN]);
  return result[STORAGE_KEYS.AUTH_TOKEN] || null;
}

async function getStoredSettings() {
  const result = await chrome.storage.sync.get([STORAGE_KEYS.SETTINGS]);
  return result[STORAGE_KEYS.SETTINGS] || DEFAULT_SETTINGS;
}
