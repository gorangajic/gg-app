// TypeWise AI Options Page Script

const DEFAULT_SETTINGS = {
  autoTrigger: true,
  minTextLength: 10,
  suggestionDelay: 2000,
  maxSuggestions: 5,
  serverUrl: 'http://localhost:3001'
};

document.addEventListener('DOMContentLoaded', () => {
  loadSettings();
  loadAccountInfo();
  setupEventListeners();
});

function setupEventListeners() {
  document.getElementById('saveBtn').addEventListener('click', saveSettings);
  document.getElementById('resetBtn').addEventListener('click', resetSettings);
}

async function loadSettings() {
  chrome.runtime.sendMessage({ action: 'getSettings' }, (response) => {
    if (response && response.success) {
      const settings = response.settings;
      populateForm(settings);
    } else {
      populateForm(DEFAULT_SETTINGS);
    }
  });
}

function populateForm(settings) {
  document.getElementById('serverUrl').value = settings.serverUrl || DEFAULT_SETTINGS.serverUrl;
  document.getElementById('autoTrigger').checked = settings.autoTrigger !== false;
  document.getElementById('minTextLength').value = settings.minTextLength || DEFAULT_SETTINGS.minTextLength;
  document.getElementById('suggestionDelay').value = settings.suggestionDelay || DEFAULT_SETTINGS.suggestionDelay;
  document.getElementById('maxSuggestions').value = settings.maxSuggestions || DEFAULT_SETTINGS.maxSuggestions;
}

async function loadAccountInfo() {
  chrome.runtime.sendMessage({ action: 'checkAuth' }, (response) => {
    const accountInfo = document.getElementById('accountInfo');

    if (response && response.isAuthenticated) {
      accountInfo.innerHTML = `
        <p><strong>Status:</strong> Authenticated ✓</p>
        <p style="margin-top: 8px; font-size: 12px; color: #718096;">
          You are signed in and TypeWise AI is active
        </p>
      `;
    } else {
      accountInfo.innerHTML = `
        <p><strong>Status:</strong> Not authenticated</p>
        <p style="margin-top: 8px; font-size: 12px; color: #718096;">
          Please sign in through the extension popup to use TypeWise AI
        </p>
      `;
    }
  });
}

async function saveSettings() {
  const settings = {
    serverUrl: document.getElementById('serverUrl').value,
    autoTrigger: document.getElementById('autoTrigger').checked,
    minTextLength: parseInt(document.getElementById('minTextLength').value),
    suggestionDelay: parseInt(document.getElementById('suggestionDelay').value),
    maxSuggestions: parseInt(document.getElementById('maxSuggestions').value)
  };

  // Validate settings
  if (!settings.serverUrl) {
    showMessage('Please enter a server URL', 'error');
    return;
  }

  if (settings.minTextLength < 1 || settings.minTextLength > 1000) {
    showMessage('Minimum text length must be between 1 and 1000', 'error');
    return;
  }

  if (settings.suggestionDelay < 100 || settings.suggestionDelay > 10000) {
    showMessage('Suggestion delay must be between 100 and 10000 ms', 'error');
    return;
  }

  if (settings.maxSuggestions < 1 || settings.maxSuggestions > 10) {
    showMessage('Maximum suggestions must be between 1 and 10', 'error');
    return;
  }

  chrome.runtime.sendMessage(
    {
      action: 'updateSettings',
      data: settings
    },
    (response) => {
      if (response && response.success) {
        showMessage('Settings saved successfully!', 'success');
      } else {
        showMessage('Failed to save settings. Please try again.', 'error');
      }
    }
  );
}

async function resetSettings() {
  if (!confirm('Are you sure you want to reset all settings to defaults?')) {
    return;
  }

  chrome.runtime.sendMessage(
    {
      action: 'updateSettings',
      data: DEFAULT_SETTINGS
    },
    (response) => {
      if (response && response.success) {
        populateForm(DEFAULT_SETTINGS);
        showMessage('Settings reset to defaults', 'success');
      } else {
        showMessage('Failed to reset settings. Please try again.', 'error');
      }
    }
  );
}

function showMessage(message, type) {
  const messageElement = document.getElementById('saveMessage');
  messageElement.textContent = message;
  messageElement.className = `save-message ${type}`;

  setTimeout(() => {
    messageElement.textContent = '';
    messageElement.className = 'save-message';
  }, 3000);
}
