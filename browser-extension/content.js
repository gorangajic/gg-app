// TypeWise AI Content Script
// Monitors text fields and provides AI-powered suggestions

class TypeWiseAI {
  constructor() {
    this.settings = null;
    this.isAuthenticated = false;
    this.activeElement = null;
    this.textBuffer = '';
    this.typingTimer = null;
    this.suggestionOverlay = null;
    this.currentSuggestions = [];

    this.init();
  }

  async init() {
    console.log('TypeWise AI: Initializing...');

    // Load settings and auth status
    await this.loadSettings();
    await this.checkAuth();

    if (!this.isAuthenticated) {
      console.log('TypeWise AI: Not authenticated, skipping initialization');
      return;
    }

    // Set up DOM monitoring
    this.setupTextFieldMonitoring();

    // Create suggestion overlay
    this.createSuggestionOverlay();

    console.log('TypeWise AI: Initialized successfully');
  }

  async loadSettings() {
    return new Promise((resolve) => {
      chrome.runtime.sendMessage({ action: 'getSettings' }, (response) => {
        if (response && response.success) {
          this.settings = response.settings;
        } else {
          // Default settings
          this.settings = {
            autoTrigger: true,
            minTextLength: 10,
            suggestionDelay: 2000,
            maxSuggestions: 5
          };
        }
        resolve();
      });
    });
  }

  async checkAuth() {
    return new Promise((resolve) => {
      chrome.runtime.sendMessage({ action: 'checkAuth' }, (response) => {
        this.isAuthenticated = response && response.isAuthenticated;
        resolve();
      });
    });
  }

  setupTextFieldMonitoring() {
    // Monitor all input fields, textareas, and contenteditable elements
    document.addEventListener('focusin', (e) => this.handleFocusIn(e), true);
    document.addEventListener('focusout', (e) => this.handleFocusOut(e), true);
    document.addEventListener('input', (e) => this.handleInput(e), true);
    document.addEventListener('keydown', (e) => this.handleKeyDown(e), true);

    // Monitor dynamically added elements
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        mutation.addedNodes.forEach((node) => {
          if (node.nodeType === Node.ELEMENT_NODE) {
            this.attachToNewElements(node);
          }
        });
      });
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true
    });
  }

  attachToNewElements(element) {
    // Check if element itself is a text field
    if (this.isTextFieldElement(element)) {
      this.attachToElement(element);
    }

    // Check children
    const textFields = element.querySelectorAll('input[type="text"], input[type="email"], input:not([type]), textarea, [contenteditable="true"]');
    textFields.forEach((field) => this.attachToElement(field));
  }

  attachToElement(element) {
    // Avoid attaching multiple times
    if (element.dataset.typewiseAttached) return;
    element.dataset.typewiseAttached = 'true';
  }

  isTextFieldElement(element) {
    if (!element || !element.tagName) return false;

    const tagName = element.tagName.toLowerCase();

    // Check for input fields
    if (tagName === 'input') {
      const type = (element.type || 'text').toLowerCase();
      return ['text', 'email', 'search', 'url', ''].includes(type);
    }

    // Check for textarea
    if (tagName === 'textarea') return true;

    // Check for contenteditable
    if (element.contentEditable === 'true') return true;

    return false;
  }

  handleFocusIn(e) {
    const element = e.target;

    if (this.isTextFieldElement(element)) {
      this.activeElement = element;
      this.textBuffer = this.getElementText(element);
      console.log('TypeWise AI: Text field focused', element);
    }
  }

  handleFocusOut(e) {
    if (this.activeElement === e.target) {
      this.activeElement = null;
      this.textBuffer = '';
      this.hideSuggestions();
      console.log('TypeWise AI: Text field blurred');
    }
  }

  handleInput(e) {
    const element = e.target;

    if (!this.isTextFieldElement(element)) return;
    if (!this.activeElement || this.activeElement !== element) return;

    // Update text buffer
    this.textBuffer = this.getElementText(element);

    // Clear existing timer
    if (this.typingTimer) {
      clearTimeout(this.typingTimer);
    }

    // Set new timer for auto-trigger
    if (this.settings.autoTrigger && this.textBuffer.length >= this.settings.minTextLength) {
      this.typingTimer = setTimeout(() => {
        this.triggerSuggestions();
      }, this.settings.suggestionDelay);
    }
  }

  handleKeyDown(e) {
    // Trigger on sentence endings
    if (this.settings.autoTrigger && (e.key === '.' || e.key === '!' || e.key === '?')) {
      clearTimeout(this.typingTimer);
      this.typingTimer = setTimeout(() => {
        this.triggerSuggestions();
      }, 500);
    }

    // Manual trigger with keyboard shortcut (Ctrl+Shift+Space or Cmd+Shift+Space)
    if (e.key === ' ' && e.shiftKey && (e.ctrlKey || e.metaKey)) {
      e.preventDefault();
      this.triggerSuggestions();
    }

    // Navigate suggestions with arrow keys
    if (this.suggestionOverlay && !this.suggestionOverlay.classList.contains('hidden')) {
      if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
        e.preventDefault();
        this.navigateSuggestions(e.key === 'ArrowDown' ? 1 : -1);
      } else if (e.key === 'Enter') {
        e.preventDefault();
        this.applySelectedSuggestion();
      } else if (e.key === 'Escape') {
        this.hideSuggestions();
      }
    }
  }

  getElementText(element) {
    if (!element) return '';

    if (element.tagName.toLowerCase() === 'input' || element.tagName.toLowerCase() === 'textarea') {
      return element.value || '';
    } else if (element.contentEditable === 'true') {
      return element.textContent || '';
    }

    return '';
  }

  setElementText(element, text) {
    if (!element) return;

    if (element.tagName.toLowerCase() === 'input' || element.tagName.toLowerCase() === 'textarea') {
      element.value = text;
      element.dispatchEvent(new Event('input', { bubbles: true }));
    } else if (element.contentEditable === 'true') {
      element.textContent = text;
      element.dispatchEvent(new Event('input', { bubbles: true }));
    }
  }

  async triggerSuggestions() {
    if (!this.activeElement || !this.textBuffer) return;

    const text = this.textBuffer.trim();
    if (text.length < this.settings.minTextLength) return;

    console.log('TypeWise AI: Generating suggestions for:', text);

    // Get context
    const context = this.getContext();

    // Show loading state
    this.showLoadingState();

    // Request suggestions from background script
    chrome.runtime.sendMessage(
      {
        action: 'generateSuggestions',
        data: {
          text: text,
          context: context,
          maxSuggestions: this.settings.maxSuggestions
        }
      },
      (response) => {
        if (response && response.success) {
          this.displaySuggestions(response.suggestions);
        } else {
          console.error('TypeWise AI: Failed to generate suggestions:', response?.error);
          this.hideSuggestions();
        }
      }
    );
  }

  getContext() {
    if (!this.activeElement) return {};

    return {
      url: window.location.href,
      domain: window.location.hostname,
      fieldType: this.activeElement.tagName.toLowerCase(),
      fieldId: this.activeElement.id || '',
      fieldName: this.activeElement.name || '',
      textLength: this.textBuffer.length
    };
  }

  createSuggestionOverlay() {
    // Create overlay container
    this.suggestionOverlay = document.createElement('div');
    this.suggestionOverlay.id = 'typewise-suggestion-overlay';
    this.suggestionOverlay.className = 'typewise-overlay hidden';
    this.suggestionOverlay.innerHTML = `
      <div class="typewise-overlay-header">
        <span class="typewise-overlay-title">TypeWise AI Suggestions</span>
        <button class="typewise-overlay-close" aria-label="Close">×</button>
      </div>
      <div class="typewise-overlay-content">
        <div class="typewise-loading">
          <div class="typewise-spinner"></div>
          <p>Generating suggestions...</p>
        </div>
        <div class="typewise-suggestions"></div>
      </div>
      <div class="typewise-overlay-footer">
        <span class="typewise-hint">Use ↑↓ to navigate, Enter to apply, Esc to close</span>
      </div>
    `;

    document.body.appendChild(this.suggestionOverlay);

    // Set up close button
    this.suggestionOverlay.querySelector('.typewise-overlay-close').addEventListener('click', () => {
      this.hideSuggestions();
    });
  }

  showLoadingState() {
    if (!this.suggestionOverlay) return;

    this.positionOverlay();
    this.suggestionOverlay.classList.remove('hidden');
    this.suggestionOverlay.querySelector('.typewise-loading').style.display = 'block';
    this.suggestionOverlay.querySelector('.typewise-suggestions').style.display = 'none';
  }

  displaySuggestions(suggestions) {
    if (!this.suggestionOverlay || !suggestions || suggestions.length === 0) {
      this.hideSuggestions();
      return;
    }

    this.currentSuggestions = suggestions;

    const suggestionsContainer = this.suggestionOverlay.querySelector('.typewise-suggestions');
    suggestionsContainer.innerHTML = '';

    suggestions.forEach((suggestion, index) => {
      const item = document.createElement('div');
      item.className = 'typewise-suggestion-item';
      item.dataset.index = index;

      const typeIcon = this.getSuggestionIcon(suggestion.type);
      const confidenceColor = this.getConfidenceColor(suggestion.confidence);

      item.innerHTML = `
        <div class="typewise-suggestion-header">
          <span class="typewise-suggestion-type">${typeIcon} ${suggestion.type}</span>
          <span class="typewise-suggestion-confidence" style="color: ${confidenceColor}">
            ${Math.round(suggestion.confidence * 100)}%
          </span>
        </div>
        <div class="typewise-suggestion-text">${this.escapeHtml(suggestion.suggestion)}</div>
        <div class="typewise-suggestion-reason">${this.escapeHtml(suggestion.reason)}</div>
      `;

      item.addEventListener('click', () => this.applySuggestion(index));
      suggestionsContainer.appendChild(item);
    });

    // Hide loading, show suggestions
    this.suggestionOverlay.querySelector('.typewise-loading').style.display = 'none';
    suggestionsContainer.style.display = 'block';

    // Position overlay near active element
    this.positionOverlay();
  }

  positionOverlay() {
    if (!this.suggestionOverlay || !this.activeElement) return;

    const rect = this.activeElement.getBoundingClientRect();
    const overlayRect = this.suggestionOverlay.getBoundingClientRect();

    // Position below the active element by default
    let top = rect.bottom + window.scrollY + 10;
    let left = rect.left + window.scrollX;

    // If overlay goes off-screen to the right, align to right edge
    if (left + overlayRect.width > window.innerWidth) {
      left = window.innerWidth - overlayRect.width - 20;
    }

    // If overlay goes off-screen at the bottom, position above
    if (top + overlayRect.height > window.innerHeight + window.scrollY) {
      top = rect.top + window.scrollY - overlayRect.height - 10;
    }

    this.suggestionOverlay.style.top = `${top}px`;
    this.suggestionOverlay.style.left = `${left}px`;
  }

  hideSuggestions() {
    if (this.suggestionOverlay) {
      this.suggestionOverlay.classList.add('hidden');
    }
    this.currentSuggestions = [];
  }

  navigateSuggestions(direction) {
    const items = this.suggestionOverlay.querySelectorAll('.typewise-suggestion-item');
    if (items.length === 0) return;

    const currentIndex = Array.from(items).findIndex(item => item.classList.contains('selected'));
    const newIndex = currentIndex + direction;

    if (newIndex >= 0 && newIndex < items.length) {
      items.forEach(item => item.classList.remove('selected'));
      items[newIndex].classList.add('selected');
      items[newIndex].scrollIntoView({ block: 'nearest', behavior: 'smooth' });
    }
  }

  applySelectedSuggestion() {
    const selectedItem = this.suggestionOverlay.querySelector('.typewise-suggestion-item.selected');
    if (selectedItem) {
      const index = parseInt(selectedItem.dataset.index);
      this.applySuggestion(index);
    } else {
      // Apply first suggestion if none selected
      this.applySuggestion(0);
    }
  }

  applySuggestion(index) {
    if (!this.currentSuggestions[index] || !this.activeElement) return;

    const suggestion = this.currentSuggestions[index];
    this.setElementText(this.activeElement, suggestion.suggestion);
    this.textBuffer = suggestion.suggestion;
    this.hideSuggestions();

    console.log('TypeWise AI: Applied suggestion:', suggestion);
  }

  getSuggestionIcon(type) {
    const icons = {
      'grammar': '📝',
      'style': '✨',
      'clarity': '💡',
      'tone': '🎭',
      'spelling': '📖',
      'conciseness': '⚡'
    };
    return icons[type.toLowerCase()] || '💬';
  }

  getConfidenceColor(confidence) {
    if (confidence >= 0.8) return '#48bb78'; // green
    if (confidence >= 0.6) return '#ed8936'; // orange
    return '#e53e3e'; // red
  }

  escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }
}

// Initialize TypeWise AI when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    new TypeWiseAI();
  });
} else {
  new TypeWiseAI();
}
