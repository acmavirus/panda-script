<template>
  <div class="projects-view">
    <div class="page-header">
      <h1>📦 Project Manager</h1>
      <p class="subtitle">Manage Node.js, Python, Java projects and deployments</p>
    </div>

    <!-- Stats Cards -->
    <div class="stats-grid">
      <div class="stat-card nodejs">
        <div class="stat-icon">🟢</div>
        <div class="stat-info">
          <span class="stat-value">{{ stats.nodejs_projects || 0 }}</span>
          <span class="stat-label">Node.js Projects</span>
        </div>
      </div>
      <div class="stat-card python">
        <div class="stat-icon">🐍</div>
        <div class="stat-info">
          <span class="stat-value">{{ stats.python_projects || 0 }}</span>
          <span class="stat-label">Python Projects</span>
        </div>
      </div>
      <div class="stat-card java">
        <div class="stat-icon">☕</div>
        <div class="stat-info">
          <span class="stat-value">{{ stats.java_projects || 0 }}</span>
          <span class="stat-label">Java Projects</span>
        </div>
      </div>
      <div class="stat-card deploy">
        <div class="stat-icon">🔄</div>
        <div class="stat-info">
          <span class="stat-value">{{ stats.deployments || 0 }}</span>
          <span class="stat-label">Deployments</span>
        </div>
      </div>
    </div>

    <!-- Tabs -->
    <div class="tabs">
      <button 
        v-for="tab in tabs" 
        :key="tab.id"
        :class="['tab', { active: activeTab === tab.id }]"
        @click="activeTab = tab.id"
      >
        {{ tab.icon }} {{ tab.label }}
      </button>
    </div>

    <!-- Node.js Projects -->
    <div v-if="activeTab === 'nodejs'" class="tab-content">
      <div class="section-header">
        <h2>🟢 Node.js Projects</h2>
        <button class="btn primary" @click="showCreateNodejs = true">+ New Project</button>
      </div>
      
      <div class="projects-table">
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Framework</th>
              <th>Port</th>
              <th>Domain</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="project in nodejsProjects" :key="project.name">
              <td>{{ project.name }}</td>
              <td>{{ project.framework || 'express' }}</td>
              <td>{{ project.port }}</td>
              <td>{{ project.domain || '-' }}</td>
              <td>
                <span :class="['status', project.status]">{{ project.status }}</span>
              </td>
              <td class="actions">
                <button class="btn small success" @click="manageProject('nodejs', project.name, 'restart')">
                  Restart
                </button>
                <button class="btn small warning" @click="manageProject('nodejs', project.name, 'stop')">
                  Stop
                </button>
              </td>
            </tr>
            <tr v-if="nodejsProjects.length === 0">
              <td colspan="6" class="empty">No Node.js projects found</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Python Projects -->
    <div v-if="activeTab === 'python'" class="tab-content">
      <div class="section-header">
        <h2>🐍 Python Projects</h2>
        <button class="btn primary" @click="showCreatePython = true">+ New Project</button>
      </div>
      
      <div class="projects-table">
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Framework</th>
              <th>Port</th>
              <th>Domain</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="project in pythonProjects" :key="project.name">
              <td>{{ project.name }}</td>
              <td>{{ project.framework }}</td>
              <td>{{ project.port }}</td>
              <td>{{ project.domain || '-' }}</td>
              <td>
                <span :class="['status', project.status]">{{ project.status }}</span>
              </td>
              <td class="actions">
                <button class="btn small success" @click="manageProject('python', project.name, 'restart')">
                  Restart
                </button>
                <button class="btn small warning" @click="manageProject('python', project.name, 'stop')">
                  Stop
                </button>
                <button class="btn small danger" @click="deleteProject('python', project.name)">
                  Delete
                </button>
              </td>
            </tr>
            <tr v-if="pythonProjects.length === 0">
              <td colspan="6" class="empty">No Python projects found</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Java Projects -->
    <div v-if="activeTab === 'java'" class="tab-content">
      <div class="section-header">
        <h2>☕ Java Projects</h2>
        <button class="btn primary" @click="showCreateJava = true">+ New Project</button>
      </div>
      
      <div class="projects-table">
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Type</th>
              <th>Port</th>
              <th>Domain</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="project in javaProjects" :key="project.name">
              <td>{{ project.name }}</td>
              <td>{{ project.type || 'spring-boot' }}</td>
              <td>{{ project.port }}</td>
              <td>{{ project.domain || '-' }}</td>
              <td>
                <span :class="['status', project.status]">{{ project.status }}</span>
              </td>
              <td class="actions">
                <button class="btn small success" @click="manageProject('java', project.name, 'restart')">
                  Restart
                </button>
                <button class="btn small warning" @click="manageProject('java', project.name, 'stop')">
                  Stop
                </button>
              </td>
            </tr>
            <tr v-if="javaProjects.length === 0">
              <td colspan="6" class="empty">No Java projects found</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Deployments -->
    <div v-if="activeTab === 'deploy'" class="tab-content">
      <div class="section-header">
        <h2>🔄 Deployment Workflow</h2>
        <button class="btn primary" @click="showCreateDeploy = true">+ New Deployment</button>
      </div>
      
      <div class="projects-table">
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Type</th>
              <th>Branch</th>
              <th>Auto-Deploy</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="deploy in deployments" :key="deploy.name">
              <td>{{ deploy.name }}</td>
              <td>{{ deploy.project_type }}</td>
              <td>{{ deploy.branch }}</td>
              <td>
                <span :class="['badge', deploy.auto_deploy ? 'success' : 'warning']">
                  {{ deploy.auto_deploy ? 'Enabled' : 'Disabled' }}
                </span>
              </td>
              <td class="actions">
                <button class="btn small primary" @click="triggerDeploy(deploy.name)">
                  🚀 Deploy
                </button>
                <button class="btn small" @click="viewLogs(deploy.name)">
                  📝 Logs
                </button>
                <button class="btn small danger" @click="deleteDeploy(deploy.name)">
                  Delete
                </button>
              </td>
            </tr>
            <tr v-if="deployments.length === 0">
              <td colspan="5" class="empty">No deployments configured</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Clone from GitHub -->
    <div v-if="activeTab === 'clone'" class="tab-content">
      <div class="section-header">
        <h2>📥 Clone from GitHub</h2>
      </div>
      
      <div class="form-card">
        <div class="form-group">
          <label>Repository URL</label>
          <input v-model="cloneForm.repo_url" placeholder="https://github.com/user/repo.git">
        </div>
        <div class="form-group">
          <label>Project Name</label>
          <input v-model="cloneForm.project_name" placeholder="my-project">
        </div>
        <div class="form-row">
          <div class="form-group">
            <label>Project Type</label>
            <select v-model="cloneForm.project_type">
              <option value="nodejs">Node.js</option>
              <option value="python">Python</option>
              <option value="java">Java</option>
            </select>
          </div>
          <div class="form-group">
            <label>Port</label>
            <input v-model.number="cloneForm.port" type="number" placeholder="3000">
          </div>
        </div>
        <div class="form-group">
          <label>Domain (optional)</label>
          <input v-model="cloneForm.domain" placeholder="example.com">
        </div>
        <button class="btn primary" @click="cloneFromGithub" :disabled="cloning">
          {{ cloning ? 'Cloning...' : '📥 Clone & Setup' }}
        </button>
      </div>
    </div>

    <!-- Modals -->
    <div v-if="showLogs" class="modal-overlay" @click.self="showLogs = false">
      <div class="modal">
        <div class="modal-header">
          <h3>Deployment Logs: {{ logsName }}</h3>
          <button class="close" @click="showLogs = false">&times;</button>
        </div>
        <div class="modal-body">
          <pre class="logs">{{ logs }}</pre>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import axios from 'axios'

export default {
  name: 'Projects',
  data() {
    return {
      activeTab: 'nodejs',
      tabs: [
        { id: 'nodejs', label: 'Node.js', icon: '🟢' },
        { id: 'python', label: 'Python', icon: '🐍' },
        { id: 'java', label: 'Java', icon: '☕' },
        { id: 'deploy', label: 'Deployments', icon: '🔄' },
        { id: 'clone', label: 'Clone GitHub', icon: '📥' },
      ],
      stats: {},
      nodejsProjects: [],
      pythonProjects: [],
      javaProjects: [],
      deployments: [],
      cloneForm: {
        repo_url: '',
        project_name: '',
        project_type: 'nodejs',
        port: 3000,
        domain: ''
      },
      cloning: false,
      showLogs: false,
      logs: '',
      logsName: '',
      showCreateNodejs: false,
      showCreatePython: false,
      showCreateJava: false,
      showCreateDeploy: false,
    }
  },
  mounted() {
    this.loadStats()
    this.loadProjects()
  },
  methods: {
    async loadStats() {
      try {
        const res = await axios.get('/api/projects/stats')
        this.stats = res.data
      } catch (e) {
        console.error('Failed to load stats:', e)
      }
    },
    async loadProjects() {
      try {
        const [nodejs, python, java, deploy] = await Promise.all([
          axios.get('/api/nodejs/pm2'),
          axios.get('/api/python/projects'),
          axios.get('/api/java/projects'),
          axios.get('/api/deploy/')
        ])
        this.nodejsProjects = nodejs.data.processes || []
        this.pythonProjects = python.data.projects || []
        this.javaProjects = java.data.projects || []
        this.deployments = deploy.data.deployments || []
      } catch (e) {
        console.error('Failed to load projects:', e)
      }
    },
    async manageProject(type, name, action) {
      try {
        await axios.post(`/api/${type}/projects/${name}/${action}`)
        this.$toast.success(`Project ${action}ed successfully`)
        this.loadProjects()
      } catch (e) {
        this.$toast.error(e.response?.data?.error || 'Action failed')
      }
    },
    async deleteProject(type, name) {
      if (!confirm(`Delete project ${name}?`)) return
      try {
        await axios.delete(`/api/${type}/projects/${name}`)
        this.$toast.success('Project deleted')
        this.loadProjects()
        this.loadStats()
      } catch (e) {
        this.$toast.error('Failed to delete project')
      }
    },
    async triggerDeploy(name) {
      try {
        await axios.post(`/api/deploy/${name}/trigger`)
        this.$toast.success('Deployment triggered')
      } catch (e) {
        this.$toast.error('Deployment failed')
      }
    },
    async viewLogs(name) {
      try {
        const res = await axios.get(`/api/deploy/${name}/logs`)
        this.logs = res.data.logs
        this.logsName = name
        this.showLogs = true
      } catch (e) {
        this.$toast.error('No logs found')
      }
    },
    async deleteDeploy(name) {
      if (!confirm(`Delete deployment ${name}?`)) return
      try {
        await axios.delete(`/api/deploy/${name}`)
        this.$toast.success('Deployment removed')
        this.loadProjects()
        this.loadStats()
      } catch (e) {
        this.$toast.error('Failed to delete')
      }
    },
    async cloneFromGithub() {
      if (!this.cloneForm.repo_url || !this.cloneForm.project_name) {
        this.$toast.error('Repository URL and project name required')
        return
      }
      this.cloning = true
      try {
        await axios.post('/api/clone', this.cloneForm)
        this.$toast.success('Project cloned successfully!')
        this.cloneForm = { repo_url: '', project_name: '', project_type: 'nodejs', port: 3000, domain: '' }
        this.loadProjects()
        this.loadStats()
      } catch (e) {
        this.$toast.error(e.response?.data?.error || 'Clone failed')
      } finally {
        this.cloning = false
      }
    }
  }
}
</script>

<style scoped>
.projects-view {
  padding: 20px;
}

.page-header {
  margin-bottom: 30px;
}

.page-header h1 {
  margin: 0;
  font-size: 28px;
}

.subtitle {
  color: var(--text-secondary);
  margin-top: 5px;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.stat-card {
  background: var(--card-bg);
  border-radius: 12px;
  padding: 20px;
  display: flex;
  align-items: center;
  gap: 15px;
  border: 1px solid var(--border-color);
}

.stat-card.nodejs { border-left: 4px solid #68a063; }
.stat-card.python { border-left: 4px solid #3776ab; }
.stat-card.java { border-left: 4px solid #f89820; }
.stat-card.deploy { border-left: 4px solid #6366f1; }

.stat-icon {
  font-size: 32px;
}

.stat-value {
  display: block;
  font-size: 24px;
  font-weight: bold;
}

.stat-label {
  color: var(--text-secondary);
  font-size: 14px;
}

.tabs {
  display: flex;
  gap: 10px;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.tab {
  padding: 10px 20px;
  background: var(--card-bg);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.tab:hover {
  background: var(--hover-bg);
}

.tab.active {
  background: var(--primary);
  color: white;
  border-color: var(--primary);
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.projects-table {
  background: var(--card-bg);
  border-radius: 12px;
  overflow: hidden;
  border: 1px solid var(--border-color);
}

table {
  width: 100%;
  border-collapse: collapse;
}

th, td {
  padding: 12px 16px;
  text-align: left;
  border-bottom: 1px solid var(--border-color);
}

th {
  background: var(--hover-bg);
  font-weight: 600;
}

.status {
  padding: 4px 10px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 500;
}

.status.active, .status.online, .status.running {
  background: rgba(34, 197, 94, 0.1);
  color: #22c55e;
}

.status.inactive, .status.stopped {
  background: rgba(239, 68, 68, 0.1);
  color: #ef4444;
}

.actions {
  display: flex;
  gap: 8px;
}

.btn {
  padding: 8px 16px;
  border-radius: 6px;
  border: none;
  cursor: pointer;
  font-size: 14px;
  transition: all 0.2s;
}

.btn.primary { background: var(--primary); color: white; }
.btn.success { background: #22c55e; color: white; }
.btn.warning { background: #f59e0b; color: white; }
.btn.danger { background: #ef4444; color: white; }
.btn.small { padding: 5px 10px; font-size: 12px; }

.btn:hover { opacity: 0.9; transform: translateY(-1px); }
.btn:disabled { opacity: 0.5; cursor: not-allowed; }

.empty {
  text-align: center;
  color: var(--text-secondary);
  padding: 40px !important;
}

.badge {
  padding: 4px 10px;
  border-radius: 20px;
  font-size: 12px;
}

.badge.success { background: rgba(34, 197, 94, 0.1); color: #22c55e; }
.badge.warning { background: rgba(245, 158, 11, 0.1); color: #f59e0b; }

.form-card {
  background: var(--card-bg);
  border-radius: 12px;
  padding: 24px;
  border: 1px solid var(--border-color);
  max-width: 600px;
}

.form-group {
  margin-bottom: 16px;
}

.form-group label {
  display: block;
  margin-bottom: 6px;
  font-weight: 500;
}

.form-group input, .form-group select {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid var(--border-color);
  border-radius: 6px;
  background: var(--input-bg);
  color: var(--text-primary);
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  background: var(--card-bg);
  border-radius: 12px;
  width: 90%;
  max-width: 800px;
  max-height: 80vh;
  overflow: hidden;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  border-bottom: 1px solid var(--border-color);
}

.modal-header h3 { margin: 0; }
.modal-header .close {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
  color: var(--text-secondary);
}

.modal-body {
  padding: 20px;
  overflow-y: auto;
  max-height: 60vh;
}

.logs {
  background: #1a1a2e;
  color: #0f0;
  padding: 16px;
  border-radius: 8px;
  font-family: monospace;
  font-size: 13px;
  white-space: pre-wrap;
  overflow-x: auto;
}
</style>
