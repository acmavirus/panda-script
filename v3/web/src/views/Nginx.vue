<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import { Server, Play, Square, RotateCw, FileText, Settings, RefreshCw, Save, X, Globe } from 'lucide-vue-next'
import Skeleton from '../components/Skeleton.vue'

const status = ref('unknown')
const loading = ref(true)
const config = ref('')
const selectedVhost = ref('')
const vhosts = ref([])
const showConfigModal = ref(false)
const saving = ref(false)

const fetchStatus = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/nginx/status')
    status.value = res.data?.status || 'inactive'
    
    const vhostsRes = await axios.get('/api/nginx/vhosts')
    vhosts.value = vhostsRes.data || []
  } catch (err) {
    console.error(err)
  } finally {
    loading.value = false
  }
}

const action = async (act) => {
  try {
    await axios.post(`/api/nginx/${act}`)
    fetchStatus()
  } catch (err) {
    alert('Action failed: ' + (err.response?.data?.error || err.message))
  }
}

const editConfig = async (domain = '') => {
  selectedVhost.value = domain
  showConfigModal.value = true
  config.value = 'Loading...'
  try {
    const res = domain 
      ? await axios.get(`/api/nginx/vhosts/${domain}`)
      : await axios.get('/api/nginx/config') // Main config if domain empty
    config.value = res.data?.content || ''
  } catch (err) {
    config.value = 'Error loading configuration'
  }
}

const saveConfig = async () => {
  saving.value = true
  try {
    if (selectedVhost.value) {
      await axios.post(`/api/nginx/vhosts`, { 
        domain: selectedVhost.value, 
        content: config.value 
      })
    } else {
      await axios.post('/api/nginx/config', { content: config.value })
    }
    showConfigModal.value = false
    alert('Configuration saved successfully!')
  } catch (err) {
    alert('Failed to save: ' + (err.response?.data?.error || err.message))
  } finally {
    saving.value = false
  }
}

onMounted(fetchStatus)
</script>

<template>
  <div class="space-y-6 max-w-7xl mx-auto">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-2xl font-semibold" style="color: var(--text-primary);">Nginx Manager</h1>
        <p class="text-sm mt-1" style="color: var(--text-muted);">Manage Web Server, Virtual Hosts and Configuration.</p>
      </div>
      <div class="flex items-center gap-2">
        <button @click="fetchStatus" class="panda-btn panda-btn-secondary">
          <RefreshCw :size="16" :class="{ 'animate-spin': loading }" />
        </button>
        <button @click="action('reload')" class="panda-btn panda-btn-primary">
          <RotateCw :size="16" class="mr-2" /> Reload Nginx
        </button>
      </div>
    </div>

    <!-- Stats & Status -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div class="panda-card">
        <div class="flex items-center justify-between mb-2">
          <span class="text-sm font-medium" style="color: var(--text-secondary);">Service Status</span>
          <div class="flex items-center gap-2">
            <span class="w-2 h-2 rounded-full" :class="status === 'active' ? 'bg-green-500' : 'bg-red-500'"></span>
            <span class="text-xs font-bold uppercase tracking-wider" :style="{ color: status === 'active' ? 'var(--color-success)' : 'var(--color-error)' }">
              {{ status }}
            </span>
          </div>
        </div>
        <div class="flex gap-2 mt-4">
          <button @click="action('start')" v-if="status !== 'active'" class="flex-1 py-2 bg-green-500/10 text-green-400 rounded-lg text-xs font-bold hover:bg-green-500/20">START</button>
          <button @click="action('stop')" v-else class="flex-1 py-2 bg-red-500/10 text-red-400 rounded-lg text-xs font-bold hover:bg-red-500/20">STOP</button>
          <button @click="action('restart')" class="flex-1 py-2 bg-blue-500/10 text-blue-400 rounded-lg text-xs font-bold hover:bg-blue-500/20">RESTART</button>
        </div>
      </div>

      <div class="panda-card">
        <span class="text-sm font-medium" style="color: var(--text-secondary);">Total Virtual Hosts</span>
        <p class="text-2xl font-bold mt-1" style="color: var(--text-primary);">{{ vhosts.length }}</p>
      </div>

      <div class="panda-card">
        <span class="text-sm font-medium" style="color: var(--text-secondary);">Main Settings</span>
        <button @click="editConfig()" class="w-full mt-3 py-2 bg-white/5 hover:bg-white/10 rounded-lg text-xs font-bold flex items-center justify-center gap-2 transition-all">
          <Settings :size="14" /> EDIT nginx.conf
        </button>
      </div>
    </div>

    <!-- Virtual Hosts List -->
    <div class="panda-card !p-0 overflow-hidden">
      <div class="px-6 py-4 border-b border-[var(--border-color)] flex items-center justify-between">
        <h3 class="text-sm font-bold uppercase tracking-widest" style="color: var(--text-muted);">Virtual Hosts (vHosts)</h3>
      </div>
      <table class="panda-table">
        <thead>
          <tr>
            <th>Domain</th>
            <th>Type</th>
            <th class="w-24">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="v in vhosts" :key="v.domain">
            <td>
              <div class="flex items-center gap-3">
                <Globe :size="16" class="text-blue-500" />
                <span class="font-medium">{{ v.domain }}</span>
              </div>
            </td>
            <td>
              <span class="text-xs px-2 py-1 rounded bg-white/5 text-gray-400">Standard</span>
            </td>
            <td>
              <div class="contextual-actions flex items-center gap-1">
                <button @click="editConfig(v.domain)" class="panda-btn panda-btn-ghost p-2" data-tooltip="Edit Config">
                  <FileText :size="14" />
                </button>
              </div>
            </td>
          </tr>
          <tr v-if="!loading && vhosts.length === 0">
            <td colspan="3" class="text-center py-12 opacity-30">No virtual hosts found.</td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Config Editor Modal -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="showConfigModal" class="fixed inset-0 z-50 flex items-center justify-center p-4" style="background: rgba(0,0,0,0.8); backdrop-filter: blur(8px);">
          <div class="w-full max-w-5xl h-[90vh] flex flex-col rounded-2xl overflow-hidden shadow-2xl" style="background: var(--bg-elevated); border: 1px solid var(--border-color);">
            <div class="flex items-center justify-between px-6 py-4 border-b" style="border-color: var(--border-color);">
              <div class="flex items-center gap-3">
                <FileText :size="18" style="color: var(--color-primary);" />
                <div>
                  <h3 class="text-lg font-semibold" style="color: var(--text-primary);">Config Editor</h3>
                  <p class="text-xs text-gray-500">{{ selectedVhost || 'nginx.conf' }}</p>
                </div>
              </div>
              <button @click="showConfigModal = false" class="p-2 hover:bg-white/5 rounded-full transition-colors text-gray-400 hover:text-white">
                <X :size="24" />
              </button>
            </div>
            <textarea 
              v-model="config" 
              class="flex-1 p-6 font-mono text-sm leading-relaxed outline-none resize-none" 
              style="background: var(--bg-base); color: #cbd5e1; white-space: pre-wrap;"
              spellcheck="false"
            ></textarea>
            <div class="px-6 py-4 border-t flex justify-end gap-3" style="border-color: var(--border-color); background: var(--bg-surface);">
              <button @click="showConfigModal = false" class="panda-btn panda-btn-secondary">Cancel</button>
              <button @click="saveConfig" :disabled="saving" class="panda-btn panda-btn-primary">
                <Save v-if="!saving" :size="16" class="mr-2" />
                <RefreshCw v-else :size="16" class="mr-2 animate-spin" />
                {{ saving ? 'Saving...' : 'Save Configuration' }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>
