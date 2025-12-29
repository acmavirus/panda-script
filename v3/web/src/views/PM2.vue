<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import axios from 'axios'
import { Play, Square, RotateCw, Trash2, FileText, RefreshCw, Terminal, Clock, Cpu, HardDrive, AlertTriangle } from 'lucide-vue-next'
import Skeleton from '../components/Skeleton.vue'

const processes = ref([])
const loading = ref(true)
const error = ref('')
const actionLoading = ref({})
const selectedProcess = ref(null)
const logs = ref('')
const showLogs = ref(false)
const logsLoading = ref(false)

const fetchProcesses = async () => {
  loading.value = true
  error.value = ''
  try {
    const res = await axios.get('/api/nodejs/pm2')
    processes.value = res.data || []
  } catch (err) {
    if (err.response?.status === 404 || err.response?.data?.error?.includes('not installed')) {
      error.value = 'PM2 is not installed. Install Node.js + PM2 from App Store first.'
    } else {
      error.value = err.response?.data?.error || 'Failed to load PM2 processes'
    }
  } finally {
    loading.value = false
  }
}

const pm2Action = async (name, action) => {
  actionLoading.value[name] = action
  try {
    await axios.post(`/api/nodejs/pm2/${name}/${action}`)
    await fetchProcesses()
  } catch (err) {
    error.value = `Failed to ${action} ${name}: ${err.response?.data?.error || err.message}`
  } finally {
    delete actionLoading.value[name]
  }
}

const viewLogs = async (name) => {
  selectedProcess.value = name
  showLogs.value = true
  logsLoading.value = true
  logs.value = ''
  try {
    const res = await axios.get(`/api/nodejs/pm2/${name}/logs`)
    logs.value = res.data?.logs || 'No logs available'
  } catch (err) {
    logs.value = 'Failed to load logs: ' + (err.response?.data?.error || err.message)
  } finally {
    logsLoading.value = false
  }
}

const deleteProcess = async (name) => {
  if (!confirm(`Delete process "${name}"?\n\nThis will stop and remove the process from PM2.`)) return
  await pm2Action(name, 'delete')
}

const getStatusColor = (status) => {
  switch (status) {
    case 'online': return 'var(--color-success)'
    case 'stopping': return 'var(--color-warning)'
    case 'stopped': return 'var(--text-muted)'
    case 'errored': return 'var(--color-error)'
    default: return 'var(--text-muted)'
  }
}

const getStatusBg = (status) => {
  switch (status) {
    case 'online': return 'var(--color-success-subtle)'
    case 'stopping': return 'var(--color-warning-subtle)'
    case 'errored': return 'var(--color-error-subtle)'
    default: return 'var(--bg-surface)'
  }
}

const formatUptime = (uptime) => {
  if (!uptime) return '-'
  const seconds = Math.floor(uptime / 1000)
  const minutes = Math.floor(seconds / 60)
  const hours = Math.floor(minutes / 60)
  const days = Math.floor(hours / 24)
  
  if (days > 0) return `${days}d ${hours % 24}h`
  if (hours > 0) return `${hours}h ${minutes % 60}m`
  if (minutes > 0) return `${minutes}m ${seconds % 60}s`
  return `${seconds}s`
}

const formatMemory = (bytes) => {
  if (!bytes) return '-'
  const mb = bytes / (1024 * 1024)
  return `${mb.toFixed(1)} MB`
}

// Auto refresh every 10 seconds
let refreshInterval = null
onMounted(() => {
  fetchProcesses()
  refreshInterval = setInterval(fetchProcesses, 10000)
})

onUnmounted(() => {
  if (refreshInterval) clearInterval(refreshInterval)
})
</script>

<template>
  <div class="space-y-6 max-w-7xl mx-auto">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-2xl font-semibold" style="color: var(--text-primary);">PM2 Manager</h1>
        <p class="text-sm mt-1" style="color: var(--text-muted);">Manage Node.js processes with PM2</p>
      </div>
      <button @click="fetchProcesses" class="panda-btn panda-btn-secondary">
        <RefreshCw :size="16" :class="{ 'animate-spin': loading }" />
        <span>Refresh</span>
      </button>
    </div>

    <!-- Error -->
    <div v-if="error" class="panda-card !border-amber-500/30 !bg-amber-500/5">
      <div class="flex items-start gap-4">
        <div class="p-3 rounded-xl bg-amber-500/10">
          <AlertTriangle :size="24" class="text-amber-500" />
        </div>
        <div class="flex-1">
          <h3 class="text-base font-semibold text-amber-400 mb-1">{{ error.includes('not installed') ? 'PM2 Not Installed' : 'Error' }}</h3>
          <p class="text-sm text-gray-400 mb-4">{{ error }}</p>
          <router-link v-if="error.includes('not installed')" to="/apps" class="panda-btn panda-btn-primary">
            Go to App Store
          </router-link>
        </div>
      </div>
    </div>

    <!-- Stats Summary -->
    <div v-if="!error && processes.length > 0" class="grid grid-cols-2 md:grid-cols-4 gap-4">
      <div class="panda-card !p-4">
        <div class="flex items-center gap-3">
          <div class="p-2 rounded-lg" style="background: var(--color-success-subtle);">
            <Play :size="16" style="color: var(--color-success);" />
          </div>
          <div>
            <div class="text-2xl font-bold" style="color: var(--text-primary);">
              {{ processes.filter(p => p.status === 'online').length }}
            </div>
            <div class="text-xs" style="color: var(--text-muted);">Running</div>
          </div>
        </div>
      </div>
      <div class="panda-card !p-4">
        <div class="flex items-center gap-3">
          <div class="p-2 rounded-lg" style="background: var(--color-error-subtle);">
            <Square :size="16" style="color: var(--color-error);" />
          </div>
          <div>
            <div class="text-2xl font-bold" style="color: var(--text-primary);">
              {{ processes.filter(p => p.status !== 'online').length }}
            </div>
            <div class="text-xs" style="color: var(--text-muted);">Stopped</div>
          </div>
        </div>
      </div>
      <div class="panda-card !p-4">
        <div class="flex items-center gap-3">
          <div class="p-2 rounded-lg" style="background: var(--color-info-subtle);">
            <Cpu :size="16" style="color: var(--color-info);" />
          </div>
          <div>
            <div class="text-2xl font-bold" style="color: var(--text-primary);">
              {{ processes.reduce((a, p) => a + (p.cpu || 0), 0).toFixed(1) }}%
            </div>
            <div class="text-xs" style="color: var(--text-muted);">Total CPU</div>
          </div>
        </div>
      </div>
      <div class="panda-card !p-4">
        <div class="flex items-center gap-3">
          <div class="p-2 rounded-lg" style="background: var(--color-warning-subtle);">
            <HardDrive :size="16" style="color: var(--color-warning);" />
          </div>
          <div>
            <div class="text-2xl font-bold" style="color: var(--text-primary);">
              {{ formatMemory(processes.reduce((a, p) => a + (p.memory || 0), 0)) }}
            </div>
            <div class="text-xs" style="color: var(--text-muted);">Total Memory</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Processes Table -->
    <div class="panda-card !p-0 overflow-hidden">
      <table class="panda-table">
        <thead>
          <tr>
            <th>Process</th>
            <th>Status</th>
            <th class="hidden md:table-cell">CPU</th>
            <th class="hidden md:table-cell">Memory</th>
            <th class="hidden lg:table-cell">Uptime</th>
            <th class="hidden lg:table-cell">Restarts</th>
            <th class="w-36"></th>
          </tr>
        </thead>
        <tbody>
          <!-- Loading Skeleton -->
          <Skeleton v-if="loading" v-for="n in 3" :key="n" :loading="true" type="table-row" :columns="7" />
          
          <!-- Processes -->
          <tr v-else v-for="proc in processes" :key="proc.name" :class="{ 'opacity-50': actionLoading[proc.name] }">
            <td>
              <div class="flex items-center gap-3">
                <div class="w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0" style="background: rgba(34, 197, 94, 0.1);">
                  <Terminal :size="16" style="color: #22c55e;" />
                </div>
                <div>
                  <div class="font-medium" style="color: var(--text-primary);">{{ proc.name }}</div>
                  <div class="text-xs font-mono" style="color: var(--text-muted);">PID: {{ proc.pid || '-' }}</div>
                </div>
              </div>
            </td>
            <td>
              <span 
                class="px-2 py-1 rounded-full text-xs font-medium uppercase"
                :style="{ background: getStatusBg(proc.status), color: getStatusColor(proc.status) }"
              >
                {{ proc.status }}
              </span>
            </td>
            <td class="hidden md:table-cell">
              <div class="flex items-center gap-2">
                <div class="w-16 h-1.5 rounded-full overflow-hidden" style="background: var(--bg-surface);">
                  <div class="h-full rounded-full" :style="{ width: `${Math.min(proc.cpu || 0, 100)}%`, background: 'var(--color-info)' }"></div>
                </div>
                <span class="text-xs font-mono" style="color: var(--text-muted);">{{ (proc.cpu || 0).toFixed(1) }}%</span>
              </div>
            </td>
            <td class="hidden md:table-cell">
              <span class="text-sm font-mono" style="color: var(--text-secondary);">{{ formatMemory(proc.memory) }}</span>
            </td>
            <td class="hidden lg:table-cell">
              <div class="flex items-center gap-1.5 text-sm" style="color: var(--text-muted);">
                <Clock :size="12" />
                {{ formatUptime(proc.uptime) }}
              </div>
            </td>
            <td class="hidden lg:table-cell">
              <span class="text-sm font-mono" :style="{ color: (proc.restarts || 0) > 5 ? 'var(--color-warning)' : 'var(--text-muted)' }">
                {{ proc.restarts || 0 }}
              </span>
            </td>
            <td>
              <div class="flex items-center gap-1 justify-end">
                <button 
                  v-if="proc.status !== 'online'"
                  @click="pm2Action(proc.name, 'start')"
                  class="panda-btn panda-btn-ghost p-2"
                  :disabled="actionLoading[proc.name]"
                  data-tooltip="Start"
                >
                  <Play :size="14" style="color: var(--color-success);" />
                </button>
                <button 
                  v-else
                  @click="pm2Action(proc.name, 'stop')"
                  class="panda-btn panda-btn-ghost p-2"
                  :disabled="actionLoading[proc.name]"
                  data-tooltip="Stop"
                >
                  <Square :size="14" style="color: var(--color-error);" />
                </button>
                <button 
                  @click="pm2Action(proc.name, 'restart')"
                  class="panda-btn panda-btn-ghost p-2"
                  :disabled="actionLoading[proc.name]"
                  data-tooltip="Restart"
                >
                  <RotateCw :size="14" :class="{ 'animate-spin': actionLoading[proc.name] === 'restart' }" style="color: var(--color-info);" />
                </button>
                <button 
                  @click="viewLogs(proc.name)"
                  class="panda-btn panda-btn-ghost p-2"
                  data-tooltip="Logs"
                >
                  <FileText :size="14" />
                </button>
                <button 
                  @click="deleteProcess(proc.name)"
                  class="panda-btn panda-btn-danger p-2"
                  :disabled="actionLoading[proc.name]"
                  data-tooltip="Delete"
                >
                  <Trash2 :size="14" />
                </button>
              </div>
            </td>
          </tr>
          
          <!-- Empty State -->
          <tr v-if="!loading && !error && processes.length === 0">
            <td colspan="7" class="text-center py-16">
              <Terminal :size="40" class="mx-auto mb-3 opacity-20" />
              <p style="color: var(--text-muted);">No PM2 processes running</p>
              <p class="text-xs mt-2" style="color: var(--text-muted);">
                Use <code class="px-1.5 py-0.5 rounded" style="background: var(--bg-surface);">pm2 start app.js</code> to start a process
              </p>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Logs Modal -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="showLogs" class="fixed inset-0 z-50 flex items-center justify-center p-4" style="background: rgba(0,0,0,0.6); backdrop-filter: blur(4px);" @click.self="showLogs = false">
          <div class="w-full max-w-4xl h-[80vh] flex flex-col rounded-xl overflow-hidden" style="background: var(--bg-elevated); border: 1px solid var(--border-color);">
            <div class="flex items-center justify-between px-6 py-4 border-b" style="border-color: var(--border-color);">
              <div class="flex items-center gap-3">
                <FileText :size="18" style="color: var(--color-success);" />
                <h3 class="text-lg font-semibold" style="color: var(--text-primary);">{{ selectedProcess }} - Logs</h3>
              </div>
              <button @click="showLogs = false" class="panda-btn panda-btn-ghost p-2" style="font-size: 20px;">&times;</button>
            </div>
            <div v-if="logsLoading" class="flex-1 flex items-center justify-center">
              <RefreshCw :size="24" class="animate-spin" style="color: var(--text-muted);" />
            </div>
            <pre v-else class="flex-1 p-4 overflow-auto text-sm font-mono whitespace-pre-wrap" style="background: var(--bg-base); color: var(--text-secondary);">{{ logs }}</pre>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.15s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
