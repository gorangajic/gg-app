// TypeWise AI Content Script
// Monitors text fields and provides AI-powered suggestions

class TypeWiseAI {
  constructor() {
    this.settings = null;
    this.isAuthenticated = false;
    this.activeElement = null;
    this.textBuffer = '';
    this.previousText = '';
    this.previousCursorPosition = 0;
    this.typingTimer = null;
    this.suggestionOverlay = null;
    this.currentSuggestions = [];
    this.mutationObserver = null;
    this.eventHandlers = {
      focusin: null,
      focusout: null,
      input: null,
      keydown: null
    };

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
    const response = await chrome.runtime.sendMessage({ action: 'getSettings' });
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
  }

  async checkAuth() {
    const response = await chrome.runtime.sendMessage({ action: 'checkAuth' });
    this.isAuthenticated = response && response.isAuthenticated;
  }

  setupTextFieldMonitoring() {
    // Store event handlers for cleanup
    this.eventHandlers.focusin = (e) => this.handleFocusIn(e);
    this.eventHandlers.focusout = (e) => this.handleFocusOut(e);
    this.eventHandlers.input = (e) => this.handleInput(e);
    this.eventHandlers.keydown = (e) => this.handleKeyDown(e);

    // Monitor all input fields, textareas, and contenteditable elements
    document.addEventListener('focusin', this.eventHandlers.focusin, true);
    document.addEventListener('focusout', this.eventHandlers.focusout, true);
    document.addEventListener('input', this.eventHandlers.input, true);
    document.addEventListener('keydown', this.eventHandlers.keydown, true);

    // Monitor dynamically added elements
    this.mutationObserver = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        mutation.addedNodes.forEach((node) => {
          if (node.nodeType === Node.ELEMENT_NODE) {
            this.attachToNewElements(node);
          }
        });
      });
    });

    this.mutationObserver.observe(document.body, {
      childList: true,
      subtree: true
    });
  }

  cleanup() {
    // Remove event listeners
    if (this.eventHandlers.focusin) {
      document.removeEventListener('focusin', this.eventHandlers.focusin, true);
    }
    if (this.eventHandlers.focusout) {
      document.removeEventListener('focusout', this.eventHandlers.focusout, true);
    }
    if (this.eventHandlers.input) {
      document.removeEventListener('input', this.eventHandlers.input, true);
    }
    if (this.eventHandlers.keydown) {
      document.removeEventListener('keydown', this.eventHandlers.keydown, true);
    }

    // Disconnect mutation observer
    if (this.mutationObserver) {
      this.mutationObserver.disconnect();
      this.mutationObserver = null;
    }

    // Clear timers
    if (this.typingTimer) {
      clearTimeout(this.typingTimer);
      this.typingTimer = null;
    }

    // Remove overlay
    if (this.suggestionOverlay && this.suggestionOverlay.parentNode) {
      this.suggestionOverlay.parentNode.removeChild(this.suggestionOverlay);
      this.suggestionOverlay = null;
    }

    console.log('TypeWise AI: Cleaned up');
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

  getCursorPosition(element) {
    if (!element) return 0;

    if (element.tagName.toLowerCase() === 'input' || element.tagName.toLowerCase() === 'textarea') {
      return element.selectionStart || 0;
    } else if (element.contentEditable === 'true') {
      const selection = window.getSelection();
      if (selection.rangeCount > 0) {
        const range = selection.getRangeAt(0);
        const preCaretRange = range.cloneRange();
        preCaretRange.selectNodeContents(element);
        preCaretRange.setEnd(range.endContainer, range.endOffset);
        return preCaretRange.toString().length;
      }
    }

    return 0;
  }

  setCursorPosition(element, position) {
    if (!element) return;

    if (element.tagName.toLowerCase() === 'input' || element.tagName.toLowerCase() === 'textarea') {
      element.setSelectionRange(position, position);
    } else if (element.contentEditable === 'true') {
      const range = document.createRange();
      const selection = window.getSelection();

      let currentPos = 0;
      let found = false;

      const walk = (node) => {
        if (found) return;

        if (node.nodeType === Node.TEXT_NODE) {
          const length = node.textContent.length;
          if (currentPos + length >= position) {
            range.setStart(node, position - currentPos);
            range.setEnd(node, position - currentPos);
            found = true;
            return;
          }
          currentPos += length;
        } else {
          for (let i = 0; i < node.childNodes.length; i++) {
            walk(node.childNodes[i]);
            if (found) return;
          }
        }
      };

      walk(element);

      if (found) {
        selection.removeAllRanges();
        selection.addRange(range);
      }
    }
  }

  setElementText(element, text, preserveCursor = true) {
    if (!element) return;

    const cursorPosition = preserveCursor ? this.getCursorPosition(element) : 0;

    if (element.tagName.toLowerCase() === 'input' || element.tagName.toLowerCase() === 'textarea') {
      element.value = text;
      element.dispatchEvent(new Event('input', { bubbles: true }));

      if (preserveCursor) {
        // Adjust cursor position if text length changed
        const newPosition = Math.min(cursorPosition, text.length);
        this.setCursorPosition(element, newPosition);
      }
    } else if (element.contentEditable === 'true') {
      element.textContent = text;
      element.dispatchEvent(new Event('input', { bubbles: true }));

      if (preserveCursor) {
        const newPosition = Math.min(cursorPosition, text.length);
        this.setCursorPosition(element, newPosition);
      }
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
        <button class="typewise-undo-button hidden" aria-label="Undo">↶ Undo</button>
        <span class="typewise-hint">Use ↑↓ to navigate, Enter to apply, Esc to close</span>
      </div>
    `;

    document.body.appendChild(this.suggestionOverlay);

    // Set up close button
    this.suggestionOverlay.querySelector('.typewise-overlay-close').addEventListener('click', () => {
      this.hideSuggestions();
    });

    // Set up undo button
    this.suggestionOverlay.querySelector('.typewise-undo-button').addEventListener('click', () => {
      this.undoLastSuggestion();
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
    const viewportWidth = window.innerWidth;
    const viewportHeight = window.innerHeight;

    // Constants
    const PADDING = 10;
    const MIN_WIDTH = 280;
    const MAX_WIDTH = 400;

    // Calculate responsive width
    const availableWidth = viewportWidth - (2 * PADDING);
    const width = Math.min(MAX_WIDTH, Math.max(MIN_WIDTH, availableWidth));
    this.suggestionOverlay.style.width = `${width}px`;

    // Recalculate overlay dimensions after width adjustment
    const updatedOverlayRect = this.suggestionOverlay.getBoundingClientRect();

    // Position below the active element by default
    let top = rect.bottom + window.scrollY + PADDING;
    let left = rect.left + window.scrollX;

    // Ensure overlay stays within horizontal bounds
    if (left + updatedOverlayRect.width > viewportWidth - PADDING) {
      left = viewportWidth - updatedOverlayRect.width - PADDING;
    }
    if (left < PADDING) {
      left = PADDING;
    }

    // Check if there's enough space below
    const spaceBelow = viewportHeight - rect.bottom;
    const spaceAbove = rect.top;

    // If not enough space below and more space above, position above
    if (spaceBelow < updatedOverlayRect.height + PADDING && spaceAbove > spaceBelow) {
      top = rect.top + window.scrollY - updatedOverlayRect.height - PADDING;
    }

    // Ensure overlay doesn't go above viewport
    if (top < window.scrollY + PADDING) {
      top = window.scrollY + PADDING;
    }

    // Ensure overlay doesn't go below viewport
    const maxTop = window.scrollY + viewportHeight - updatedOverlayRect.height - PADDING;
    if (top > maxTop) {
      top = Math.max(window.scrollY + PADDING, maxTop);
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

    // Save current state for undo
    this.previousText = this.getElementText(this.activeElement);
    this.previousCursorPosition = this.getCursorPosition(this.activeElement);

    const suggestion = this.currentSuggestions[index];
    this.setElementText(this.activeElement, suggestion.suggestion, false);
    this.textBuffer = suggestion.suggestion;

    // Show undo button
    const undoButton = this.suggestionOverlay.querySelector('.typewise-undo-button');
    if (undoButton) {
      undoButton.classList.remove('hidden');
    }

    this.hideSuggestions();

    console.log('TypeWise AI: Applied suggestion:', suggestion);
  }

  undoLastSuggestion() {
    if (!this.activeElement || !this.previousText) {
      console.log('TypeWise AI: No previous text to restore');
      return;
    }

    // Restore previous text and cursor position
    this.setElementText(this.activeElement, this.previousText, false);
    this.setCursorPosition(this.activeElement, this.previousCursorPosition);
    this.textBuffer = this.previousText;

    // Hide undo button
    const undoButton = this.suggestionOverlay.querySelector('.typewise-undo-button');
    if (undoButton) {
      undoButton.classList.add('hidden');
    }

    // Clear previous state
    this.previousText = '';
    this.previousCursorPosition = 0;

    console.log('TypeWise AI: Undone last suggestion');
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
