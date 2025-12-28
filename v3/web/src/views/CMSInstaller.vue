<template>
  <div class="cms-installer">
    <div class="page-header">
      <h1>🚀 One-Click CMS Installer</h1>
      <p class="subtitle">Deploy popular CMS platforms in seconds</p>
    </div>

    <!-- CMS Grid -->
    <div class="cms-grid">
      <div 
        v-for="cms in cmsList" 
        :key="cms.slug"
        :class="['cms-card', { selected: selectedCMS === cms.slug }]"
        @click="selectedCMS = cms.slug"
      >
        <div class="cms-icon">{{ cms.icon }}</div>
        <div class="cms-info">
          <h3>{{ cms.name }}</h3>
          <p>{{ cms.description }}</p>
        </div>
        <div v-if="selectedCMS === cms.slug" class="check">✓</div>
      </div>
    </div>

    <!-- Install Form -->
    <div v-if="selectedCMS" class="install-form">
      <h2>Install {{ getSelectedCMS().name }}</h2>
      
      <div class="form-group">
        <label>Domain</label>
        <input 
          v-model="domain" 
          placeholder="example.com"
          :class="{ error: domainError }"
        >
        <span v-if="domainError" class="error-msg">{{ domainError }}</span>
      </div>

      <div class="cms-features">
        <h4>Features:</h4>
        <ul>
          <li>✅ Automatic database creation</li>
          <li>✅ Nginx configuration</li>
          <li>✅ File permissions setup</li>
          <li>✅ Latest version download</li>
        </ul>
      </div>

      <button 
        class="btn install-btn" 
        @click="installCMS"
        :disabled="installing || !domain"
      >
        <span v-if="installing">
          <span class="spinner"></span> Installing...
        </span>
        <span v-else>🚀 Install {{ getSelectedCMS().name }}</span>
      </button>
    </div>

    <!-- Installation Progress -->
    <div v-if="installing" class="progress-card">
      <h3>Installing {{ getSelectedCMS().name }}...</h3>
      <div class="progress-bar">
        <div class="progress-fill" :style="{ width: progress + '%' }"></div>
      </div>
      <div class="progress-steps">
        <div v-for="(step, i) in installSteps" :key="i" :class="['step', { done: i < currentStep }]">
          <span class="step-icon">{{ i < currentStep ? '✅' : '⏳' }}</span>
          {{ step }}
        </div>
      </div>
    </div>

    <!-- Success Modal -->
    <div v-if="showSuccess" class="modal-overlay" @click.self="showSuccess = false">
      <div class="modal success-modal">
        <div class="success-icon">🎉</div>
        <h2>Installation Complete!</h2>
        <div class="install-details">
          <div class="detail-row">
            <span class="label">URL:</span>
            <a :href="'http://' + domain" target="_blank">http://{{ domain }}</a>
          </div>
          <div v-if="installResult.db_name" class="detail-row">
            <span class="label">Database:</span>
            <span>{{ installResult.db_name }}</span>
          </div>
          <div v-if="installResult.db_user" class="detail-row">
            <span class="label">DB User:</span>
            <span>{{ installResult.db_user }}</span>
          </div>
          <div v-if="installResult.db_pass" class="detail-row">
            <span class="label">DB Password:</span>
            <code>{{ installResult.db_pass }}</code>
          </div>
        </div>
        <p class="note">Complete the web-based installation at the URL above.</p>
        <button class="btn primary" @click="showSuccess = false">Done</button>
      </div>
    </div>
  </div>
</template>

<script>
import axios from 'axios'

export default {
  name: 'CMSInstaller',
  data() {
    return {
      cmsList: [
        { slug: 'wordpress', name: 'WordPress', icon: '📝', description: 'Most popular CMS platform' },
        { slug: 'woocommerce', name: 'WooCommerce', icon: '🛒', description: 'E-commerce for WordPress' },
        { slug: 'joomla', name: 'Joomla', icon: '🎨', description: 'Flexible CMS platform' },
        { slug: 'drupal', name: 'Drupal', icon: '💧', description: 'Enterprise-grade CMS' },
        { slug: 'prestashop', name: 'PrestaShop', icon: '🛍️', description: 'E-commerce solution' },
        { slug: 'opencart', name: 'OpenCart', icon: '🎯', description: 'Online store platform' },
        { slug: 'mediawiki', name: 'MediaWiki', icon: '📚', description: 'Wiki platform' },
        { slug: 'phpbb', name: 'phpBB', icon: '💬', description: 'Forum software' },
        { slug: 'phpmyadmin', name: 'phpMyAdmin', icon: '🗃️', description: 'MySQL management' },
      ],
      selectedCMS: null,
      domain: '',
      domainError: '',
      installing: false,
      progress: 0,
      currentStep: 0,
      installSteps: [
        'Creating website...',
        'Setting up database...',
        'Downloading files...',
        'Configuring permissions...',
        'Finalizing...'
      ],
      showSuccess: false,
      installResult: {}
    }
  },
  methods: {
    getSelectedCMS() {
      return this.cmsList.find(c => c.slug === this.selectedCMS) || {}
    },
    validateDomain() {
      const pattern = /^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\.?[a-zA-Z]{2,}$/
      if (!this.domain) {
        this.domainError = 'Domain is required'
        return false
      }
      if (!pattern.test(this.domain)) {
        this.domainError = 'Invalid domain format'
        return false
      }
      this.domainError = ''
      return true
    },
    async installCMS() {
      if (!this.validateDomain()) return
      
      this.installing = true
      this.progress = 0
      this.currentStep = 0

      // Simulate progress
      const interval = setInterval(() => {
        if (this.progress < 90) {
          this.progress += 10
          this.currentStep = Math.floor(this.progress / 20)
        }
      }, 500)

      try {
        const res = await axios.post('/api/cms/install', {
          domain: this.domain,
          cms_type: this.selectedCMS
        })

        clearInterval(interval)
        this.progress = 100
        this.currentStep = this.installSteps.length

        setTimeout(() => {
          this.installing = false
          this.installResult = res.data
          this.showSuccess = true
          this.selectedCMS = null
          this.domain = ''
        }, 500)

      } catch (e) {
        clearInterval(interval)
        this.installing = false
        this.$toast.error(e.response?.data?.error || 'Installation failed')
      }
    }
  }
}
</script>

<style scoped>
.cms-installer {
  padding: 20px;
  max-width: 1200px;
  margin: 0 auto;
}

.page-header {
  text-align: center;
  margin-bottom: 40px;
}

.page-header h1 {
  font-size: 32px;
  margin-bottom: 8px;
}

.subtitle {
  color: var(--text-secondary);
  font-size: 16px;
}

.cms-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 20px;
  margin-bottom: 40px;
}

.cms-card {
  background: var(--card-bg);
  border: 2px solid var(--border-color);
  border-radius: 16px;
  padding: 24px;
  cursor: pointer;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  gap: 16px;
  position: relative;
}

.cms-card:hover {
  border-color: var(--primary);
  transform: translateY(-4px);
  box-shadow: 0 10px 30px rgba(0,0,0,0.1);
}

.cms-card.selected {
  border-color: var(--primary);
  background: linear-gradient(135deg, rgba(99, 102, 241, 0.1), rgba(139, 92, 246, 0.1));
}

.cms-icon {
  font-size: 48px;
  flex-shrink: 0;
}

.cms-info h3 {
  margin: 0 0 4px 0;
  font-size: 18px;
}

.cms-info p {
  margin: 0;
  color: var(--text-secondary);
  font-size: 14px;
}

.check {
  position: absolute;
  top: 12px;
  right: 12px;
  width: 24px;
  height: 24px;
  background: var(--primary);
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
}

.install-form {
  background: var(--card-bg);
  border-radius: 16px;
  padding: 32px;
  border: 1px solid var(--border-color);
  max-width: 500px;
  margin: 0 auto;
}

.install-form h2 {
  margin-top: 0;
  margin-bottom: 24px;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-weight: 600;
}

.form-group input {
  width: 100%;
  padding: 12px 16px;
  border: 2px solid var(--border-color);
  border-radius: 10px;
  font-size: 16px;
  background: var(--input-bg);
  color: var(--text-primary);
  transition: border-color 0.2s;
}

.form-group input:focus {
  border-color: var(--primary);
  outline: none;
}

.form-group input.error {
  border-color: #ef4444;
}

.error-msg {
  color: #ef4444;
  font-size: 13px;
  margin-top: 4px;
  display: block;
}

.cms-features {
  background: var(--hover-bg);
  border-radius: 10px;
  padding: 16px;
  margin-bottom: 24px;
}

.cms-features h4 {
  margin: 0 0 12px 0;
  font-size: 14px;
  color: var(--text-secondary);
}

.cms-features ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

.cms-features li {
  padding: 4px 0;
  font-size: 14px;
}

.install-btn {
  width: 100%;
  padding: 16px;
  font-size: 18px;
  background: linear-gradient(135deg, #6366f1, #8b5cf6);
  color: white;
  border: none;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s;
}

.install-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 8px 20px rgba(99, 102, 241, 0.3);
}

.install-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.spinner {
  display: inline-block;
  width: 18px;
  height: 18px;
  border: 2px solid rgba(255,255,255,0.3);
  border-top-color: white;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin { to { transform: rotate(360deg); } }

.progress-card {
  background: var(--card-bg);
  border-radius: 16px;
  padding: 32px;
  border: 1px solid var(--border-color);
  max-width: 500px;
  margin: 40px auto 0;
  text-align: center;
}

.progress-bar {
  height: 8px;
  background: var(--border-color);
  border-radius: 4px;
  overflow: hidden;
  margin: 20px 0;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #6366f1, #8b5cf6);
  transition: width 0.3s;
}

.progress-steps {
  text-align: left;
}

.step {
  padding: 8px 0;
  color: var(--text-secondary);
  display: flex;
  align-items: center;
  gap: 8px;
}

.step.done {
  color: #22c55e;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0,0,0,0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.success-modal {
  background: var(--card-bg);
  border-radius: 20px;
  padding: 40px;
  text-align: center;
  max-width: 450px;
  width: 90%;
}

.success-icon {
  font-size: 64px;
  margin-bottom: 16px;
}

.success-modal h2 {
  margin: 0 0 24px 0;
}

.install-details {
  background: var(--hover-bg);
  border-radius: 12px;
  padding: 16px;
  margin-bottom: 20px;
  text-align: left;
}

.detail-row {
  display: flex;
  justify-content: space-between;
  padding: 8px 0;
  border-bottom: 1px solid var(--border-color);
}

.detail-row:last-child {
  border-bottom: none;
}

.detail-row .label {
  color: var(--text-secondary);
}

.detail-row code {
  background: var(--card-bg);
  padding: 2px 8px;
  border-radius: 4px;
  font-family: monospace;
}

.note {
  color: var(--text-secondary);
  font-size: 14px;
  margin-bottom: 20px;
}

.btn.primary {
  padding: 12px 32px;
  background: var(--primary);
  color: white;
  border: none;
  border-radius: 10px;
  cursor: pointer;
  font-size: 16px;
}
</style>
