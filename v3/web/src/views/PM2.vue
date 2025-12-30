<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import axios from 'axios'
import { Rocket, Play, Square, RotateCw, Trash2, FileText, Activity, RefreshCw } from 'lucide-vue-next'
import { useToastStore } from '../stores/toast'
const toast = useToastStore()

const processes = ref([])
const loading = ref(false)
const error = ref('')
const selectedProcess = ref(null)
const logs = ref('')
const showLogs = ref(false)
let interval = null

const fetchProcesses = async () => {
  loading.value = true
  error.value = ''
  try {
    const res = await axios.get('/api/pm2/')
    processes.value = res.data || []
  } catch (err) {
    error.value = err.response?.data?.error || 'Failed to load PM2 processes'
  } finally {
    loading.value = false
  }
}

const pm2Action = async (name, action) => {
  if (action === 'delete' && !confirm(`Delete PM2 process ${name}?`)) return
  try {
    await axios.post(`/api/pm2/${name}/${action}`)
    fetchProcesses()
  } catch (err) {
    toast.error(`Failed to ${action} process: ` + (err.response?.data?.error || err.message))
  }
}

const viewLogs = async (name) => {
  selectedProcess.value = name
  showLogs.value = true
  logs.value = 'Loading logs...'
  try {
    const res = await axios.get(`/api/pm2/${name}/logs`)
    logs.value = res.data?.logs || 'No logs available'
  } catch (err) {
    logs.value = 'Failed to load logs'
  }
}

const formatMemory = (bytes) => {
  if (!bytes) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

const getStatusClass = (status) => {
  switch (status) {
    case 'online': return 'bg-green-500/10 text-green-400 border-green-500/20'
    case 'stopping': return 'bg-yellow-500/10 text-yellow-400 border-yellow-500/20'
    case 'stopped': return 'bg-red-500/10 text-red-400 border-red-500/20'
    case 'errored': return 'bg-red-600/10 text-red-500 border-red-600/20'
    default: return 'bg-gray-500/10 text-gray-400 border-gray-500/20'
  }
}

onMounted(() => {
  fetchProcesses()
  interval = setInterval(fetchProcesses, 10000)
})

onUnmounted(() => {
  if (interval) clearInterval(interval)
})
</script>

<template>
  <div class="p-4 lg:p-8 space-y-6 max-w-7xl mx-auto">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold flex items-center gap-2" style="color: var(--text-primary);">
          <Rocket class="text-green-400" :size="28" />
          PM2 Manager
        </h1>
        <p class="text-sm mt-1" style="color: var(--text-muted);">Manage Node.js applications and processes</p>
      </div>
      <button @click="fetchProcesses" class="panda-btn panda-btn-secondary">
        <RefreshCw :size="16" :class="{ 'animate-spin': loading }" />
        <span>Refresh</span>
      </button>
    </div>

    <!-- Error -->
    <div v-if="error" class="bg-red-500/10 border border-red-500/20 text-red-400 p-4 rounded-xl">
      {{ error }}
    </div>

    <!-- PM2 Table -->
    <div class="panda-card !p-0 overflow-hidden">
      <div class="overflow-x-auto">
        <table class="panda-table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Status</th>
              <th>CPU</th>
              <th>Memory</th>
              <th>Restarts</th>
              <th class="text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading && processes.length === 0">
              <td colspan="6" class="text-center py-12 text-gray-500">Loading processes...</td>
            </tr>
            <tr v-else-if="processes.length === 0">
              <td colspan="6" class="text-center py-12 text-gray-500">No PM2 processes found</td>
            </tr>
            <tr v-for="proc in processes" :key="proc.name">
              <td class="font-medium text-white">{{ proc.name }} <span class="text-xs text-gray-500 ml-1">#{{ proc.pid }}</span></td>
              <td>
                <span class="px-2 py-0.5 rounded text-[10px] font-bold uppercase border" :class="getStatusClass(proc.status)">
                  {{ proc.status }}
                </span>
              </td>
              <td class="font-mono text-xs text-gray-400">{{ proc.cpu }}%</td>
              <td class="font-mono text-xs text-gray-400">{{ formatMemory(proc.memory) }}</td>
              <td class="text-xs text-gray-400">{{ proc.restarts }}</td>
              <td>
                <div class="flex items-center justify-end gap-1">
                  <button v-if="proc.status !== 'online'" @click="pm2Action(proc.name, 'start')" 
                          class="p-2 hover:bg-green-500/10 rounded-lg text-gray-400 hover:text-green-500 transition-colors" title="Start">
                    <Play :size="16" />
                  </button>
                  <button v-else @click="pm2Action(proc.name, 'stop')" 
                          class="p-2 hover:bg-red-500/10 rounded-lg text-gray-400 hover:text-red-500 transition-colors" title="Stop">
                    <Square :size="16" />
                  </button>
                  <button @click="pm2Action(proc.name, 'restart')" 
                          class="p-2 hover:bg-blue-500/10 rounded-lg text-gray-400 hover:text-blue-500 transition-colors" title="Restart">
                    <RotateCw :size="16" />
                  </button>
                  <button @click="viewLogs(proc.name)" 
                          class="p-2 hover:bg-white/5 rounded-lg text-gray-400 hover:text-white transition-colors" title="Logs">
                    <FileText :size="16" />
                  </button>
                  <button @click="pm2Action(proc.name, 'delete')" 
                          class="p-2 hover:bg-red-500/10 rounded-lg text-gray-400 hover:text-red-500 transition-colors" title="Delete">
                    <Trash2 :size="16" />
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Logs Modal -->
    <div v-if="showLogs" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm" @click.self="showLogs = false">
      <div class="w-full max-w-4xl h-[70vh] bg-[#1a1b1e] border border-white/10 rounded-2xl flex flex-col shadow-2xl">
        <div class="p-4 border-b border-white/10 flex items-center justify-between">
          <h3 class="font-bold text-white flex items-center gap-2">
            <FileText :size="18" class="text-blue-400" />
            Logs: {{ selectedProcess }}
          </h3>
          <button @click="showLogs = false" class="text-gray-500 hover:text-white text-2xl">&times;</button>
        </div>
        <div class="flex-1 p-4 overflow-auto font-mono text-xs text-gray-300 bg-black/40 whitespace-pre-wrap">
          {{ logs }}
        </div>
      </div>
    </div>
  </div>
</template>
