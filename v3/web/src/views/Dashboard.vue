<script setup>
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { 
  Activity, HardDrive, Database, RefreshCw, Clock, Plus, Wrench, 
  FileText, ExternalLink, Lock, Globe, ArrowRight, Zap, Shield,
  User, Monitor, Bot, AlertTriangle, CheckCircle, Smartphone
} from 'lucide-vue-next'
import axios from 'axios'
import { useAuthStore } from '../stores/auth'
import { useRouter } from 'vue-router'
import Skeleton from '../components/Skeleton.vue'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler
} from 'chart.js'
import { Line } from 'vue-chartjs'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend, Filler)

const authStore = useAuthStore()
const router = useRouter()
const systemStats = ref(null)
const recentSites = ref([])
const accessLogs = ref([])
const securityLogs = ref([])
const loading = ref(true)
const refreshing = ref(false)
let pollingInterval = null

// Chart setup
const maxDataPoints = 20
const cpuHistory = ref(Array(maxDataPoints).fill(0))
const ramHistory = ref(Array(maxDataPoints).fill(0))

const cpuData = computed(() => ({
  labels: Array(maxDataPoints).fill(''),
  datasets: [{
    label: 'CPU',
    borderColor: '#3b82f6',
    backgroundColor: 'rgba(59, 130, 246, 0.1)',
    data: cpuHistory.value,
    fill: true,
    tension: 0.4,
    pointRadius: 0,
    borderWidth: 2
  }]
}))

const ramData = computed(() => ({
  labels: Array(maxDataPoints).fill(''),
  datasets: [{
    label: 'RAM',
    borderColor: '#8b5cf6',
    backgroundColor: 'rgba(139, 92, 246, 0.1)',
    data: ramHistory.value,
    fill: true,
    tension: 0.4,
    pointRadius: 0,
    borderWidth: 2
  }]
}))

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: false },
    tooltip: {
      backgroundColor: 'rgba(17, 17, 19, 0.9)',
      borderColor: 'rgba(255, 255, 255, 0.1)',
      borderWidth: 1,
      padding: 12,
      cornerRadius: 8
    }
  },
  scales: {
    y: {
      min: 0,
      max: 100,
      grid: { color: 'rgba(255, 255, 255, 0.04)', drawBorder: false },
      ticks: { color: 'var(--text-muted)', font: { size: 11 }, callback: (v) => v + '%' }
    },
    x: { grid: { display: false }, ticks: { display: false } }
  }
}

const fetchStats = async (showRefresh = false) => {
  if (showRefresh) refreshing.value = true
  
  try {
    const [statsRes, sitesRes, accessRes, securityRes] = await Promise.all([
      axios.get('/api/system/stats'),
      axios.get('/api/websites/'),
      axios.get('/api/logs/access?limit=6'),
      axios.get('/api/logs/security?limit=6')
    ])
    
    systemStats.value = statsRes.data
    recentSites.value = (sitesRes.data || []).slice(0, 5)
    accessLogs.value = accessRes.data || []
    securityLogs.value = securityRes.data || []
    
    cpuHistory.value = [...cpuHistory.value.slice(1), statsRes.data.cpu_usage]
    ramHistory.value = [...ramHistory.value.slice(1), statsRes.data.memory.used_percent]
    
    loading.value = false
  } catch (err) {
    if (err.response?.status === 401) authStore.logout()
  } finally {
    refreshing.value = false
  }
}

const formatBytes = (bytes) => (bytes / 1024 / 1024 / 1024).toFixed(1) + ' GB'
const formatUptime = (seconds) => {
  const days = Math.floor(seconds / 86400)
  const hours = Math.floor((seconds % 86400) / 3600)
  return days > 0 ? `${days}d ${hours}h` : `${hours}h ${Math.floor((seconds % 3600) / 60)}m`
}

const formatTime = (timeStr) => {
  if (!timeStr) return ''
  const date = new Date(timeStr)
  return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

// Quick Actions
const quickActions = [
  { icon: Plus, label: 'New Website', action: () => router.push('/websites'), color: 'primary' },
  { icon: Wrench, label: 'Fix Permissions', action: () => fixPermissions(), color: 'warning' },
  { icon: FileText, label: 'View Logs', action: () => router.push('/health'), color: 'info' },
  { icon: RefreshCw, label: 'Restart Services', action: () => router.push('/services'), color: 'success' },
]

const fixPermissions = async () => {
  try {
    await axios.post('/api/system/fix-permissions')
    alert('Permissions fixed!')
  } catch (e) {
    alert('Failed to fix permissions')
  }
}

const enableSSL = async (domain) => {
  try {
    await axios.post('/api/ssl/obtain', { domain })
    fetchStats()
  } catch (e) {
    alert('Failed to enable SSL')
  }
}

onMounted(() => {
  fetchStats()
  pollingInterval = setInterval(() => fetchStats(false), 8000) // Polling every 8 seconds
})

onUnmounted(() => {
  if (pollingInterval) clearInterval(pollingInterval)
})
</script>

<template>
  <div class="space-y-6 max-w-7xl mx-auto">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-semibold" style="color: var(--text-primary);">Dashboard</h1>
        <p class="text-sm mt-1" style="color: var(--text-muted);">Welcome back! Here's your server overview.</p>
      </div>
      <button 
        @click="fetchStats(true)"
        :disabled="refreshing"
        class="panda-btn panda-btn-secondary"
      >
        <RefreshCw :size="16" :class="{ 'animate-spin': refreshing }" />
        <span>Refresh</span>
      </button>
    </div>

    <!-- Stats Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-5">
      <!-- CPU -->
      <Skeleton :loading="loading" type="stats">
        <div class="panda-card">
          <div class="flex justify-between items-start mb-3">
            <div class="p-2.5 rounded-xl" style="background: var(--color-info-subtle);">
              <Activity :size="18" style="color: var(--color-info);" />
            </div>
            <span class="text-xs font-mono" style="color: var(--text-muted);">{{ systemStats?.cpus }} Cores</span>
          </div>
          <h3 class="text-sm" style="color: var(--text-secondary);">CPU</h3>
          <p class="text-2xl font-semibold font-mono" style="color: var(--text-primary);">{{ systemStats?.cpu_usage.toFixed(1) }}%</p>
          <div class="panda-progress mt-3">
            <div class="panda-progress-bar" :style="{ width: systemStats?.cpu_usage + '%', background: 'var(--color-info)' }"></div>
          </div>
        </div>
      </Skeleton>

      <!-- RAM -->
      <Skeleton :loading="loading" type="stats">
        <div class="panda-card">
          <div class="flex justify-between items-start mb-3">
            <div class="p-2.5 rounded-xl" style="background: rgba(139, 92, 246, 0.1);">
              <HardDrive :size="18" style="color: #8b5cf6;" />
            </div>
            <span class="text-xs font-mono" style="color: var(--text-muted);">{{ formatBytes(systemStats?.memory.total) }}</span>
          </div>
          <h3 class="text-sm" style="color: var(--text-secondary);">Memory</h3>
          <p class="text-2xl font-semibold font-mono" style="color: var(--text-primary);">{{ systemStats?.memory.used_percent.toFixed(1) }}%</p>
          <div class="panda-progress mt-3">
            <div class="panda-progress-bar" :style="{ width: systemStats?.memory.used_percent + '%', background: '#8b5cf6' }"></div>
          </div>
        </div>
      </Skeleton>

      <!-- Disk -->
      <Skeleton :loading="loading" type="stats">
        <div class="panda-card">
          <div class="flex justify-between items-start mb-3">
            <div class="p-2.5 rounded-xl" style="background: var(--color-warning-subtle);">
              <Database :size="18" style="color: var(--color-warning);" />
            </div>
            <span class="text-xs font-mono" style="color: var(--text-muted);">{{ formatBytes(systemStats?.disk.total) }}</span>
          </div>
          <h3 class="text-sm" style="color: var(--text-secondary);">Disk</h3>
          <p class="text-2xl font-semibold font-mono" style="color: var(--text-primary);">{{ systemStats?.disk.used_percent.toFixed(1) }}%</p>
          <div class="panda-progress mt-3">
            <div class="panda-progress-bar" :style="{ width: systemStats?.disk.used_percent + '%', background: 'var(--color-warning)' }"></div>
          </div>
        </div>
      </Skeleton>

      <!-- Uptime -->
      <Skeleton :loading="loading" type="stats">
        <div class="panda-card">
          <div class="flex justify-between items-start mb-3">
            <div class="p-2.5 rounded-xl" style="background: var(--color-success-subtle);">
              <Clock :size="18" style="color: var(--color-success);" />
            </div>
            <span class="status-indicator online"></span>
          </div>
          <h3 class="text-sm" style="color: var(--text-secondary);">Uptime</h3>
          <p class="text-2xl font-semibold font-mono" style="color: var(--text-primary);">{{ formatUptime(systemStats?.uptime) }}</p>
          <div class="mt-3 text-xs font-mono" style="color: var(--text-muted);">{{ systemStats?.os }} {{ systemStats?.arch }}</div>
        </div>
      </Skeleton>
    </div>

    <!-- Quick Actions -->
    <div class="panda-card">
      <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
        <button 
          v-for="action in quickActions" 
          :key="action.label"
          @click="action.action"
          class="flex items-center gap-3 p-4 rounded-xl border transition-all hover:-translate-y-1 hover:shadow-lg text-left"
          style="border-color: var(--border-color); background: var(--bg-surface);"
        >
          <div 
            class="w-10 h-10 rounded-lg flex items-center justify-center"
            :style="`background: var(--color-${action.color}-subtle);`"
          >
            <component :is="action.icon" :size="18" :style="`color: var(--color-${action.color});`" />
          </div>
          <span class="text-sm font-medium" style="color: var(--text-primary);">{{ action.label }}</span>
        </button>
      </div>
    </div>

    <!-- Real-time Monitoring & Security (New Section) -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Access Logs (User/Bots) -->
      <div class="panda-card overflow-hidden flex flex-col">
        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-2">
            <Monitor :size="18" style="color: var(--color-info);" />
            <h2 class="text-base font-semibold" style="color: var(--text-primary);">Live Traffic</h2>
          </div>
          <div class="flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-blue-500/10 border border-blue-500/20">
            <span class="w-1.5 h-1.5 rounded-full bg-blue-500 animate-pulse"></span>
            <span class="text-[10px] font-bold text-blue-400 uppercase tracking-widest">Real-time</span>
          </div>
        </div>

        <div v-if="accessLogs.length" class="flex-1 space-y-1">
          <div 
            v-for="(log, idx) in accessLogs" 
            :key="idx"
            class="group flex items-center gap-3 p-2.5 rounded-lg hover:bg-[var(--bg-hover)] transition-colors border border-transparent hover:border-[var(--border-color)]"
          >
            <div class="w-9 h-9 rounded-full flex items-center justify-center bg-[var(--bg-surface)] border border-[var(--border-color)]">
              <Bot v-if="log.is_bot" :size="14" class="text-amber-500" />
              <Smartphone v-else :size="14" class="text-blue-500" />
            </div>
            
            <div class="flex-1 min-w-0">
              <div class="flex items-center justify-between gap-2">
                <span class="text-sm font-mono font-medium truncate" style="color: var(--text-primary);">{{ log.ip }}</span>
                <span class="text-[10px] font-mono text-[var(--text-muted)]">{{ formatTime(log.time) }}</span>
              </div>
              <div class="flex items-center gap-2 mt-0.5">
                <span class="text-[10px] uppercase font-bold px-1.5 py-0.5 rounded" 
                      :class="log.status >= 400 ? 'bg-red-500/10 text-red-500' : 'bg-green-500/10 text-green-500'">
                  {{ log.method }} {{ log.status }}
                </span>
                <span class="text-xs truncate text-[var(--text-muted)]">{{ log.path }}</span>
              </div>
            </div>
          </div>
        </div>
        <div v-else class="flex-1 flex flex-col items-center justify-center py-12 text-center opacity-40">
          <Monitor :size="48" class="mb-2" />
          <p class="text-sm">No live traffic detected</p>
        </div>
      </div>

      <!-- Security Events (SSH/Hackers) -->
      <div class="panda-card overflow-hidden flex flex-col">
        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-2">
            <Shield :size="18" style="color: var(--color-error);" />
            <h2 class="text-base font-semibold" style="color: var(--text-primary);">Security Events</h2>
          </div>
          <button @click="router.push('/security')" class="text-xs font-bold text-[var(--color-primary)] uppercase tracking-widest hover:underline">
            Manage Firewall
          </button>
        </div>

        <div v-if="securityLogs.length" class="flex-1 space-y-1">
          <div 
            v-for="(log, idx) in securityLogs" 
            :key="idx"
            class="flex items-start gap-3 p-2.5 rounded-lg bg-[var(--bg-surface)] border border-[var(--border-color)] shadow-sm"
          >
            <div class="mt-1 p-1.5 rounded-lg" :class="log.status === 'Failed' ? 'bg-red-500/10 text-red-500' : 'bg-green-500/10 text-green-500'">
              <AlertTriangle v-if="log.status === 'Failed'" :size="14" />
              <CheckCircle v-else :size="14" />
            </div>
            
            <div class="flex-1 min-w-0">
              <div class="flex items-center justify-between mb-1">
                <span class="text-[11px] font-bold uppercase tracking-wider" :class="log.status === 'Failed' ? 'text-red-400' : 'text-green-400'">
                  {{ log.type }} {{ log.status }}
                </span>
                <span class="text-[10px] font-mono text-[var(--text-muted)]">{{ log.time }}</span>
              </div>
              <p class="text-xs font-medium" style="color: var(--text-primary);">{{ log.message }}</p>
              <div class="flex items-center gap-2 mt-1.5">
                <span class="text-[10px] font-mono px-1.5 py-0.5 bg-black/30 rounded text-gray-400">User: {{ log.user }}</span>
                <span class="text-[10px] font-mono px-1.5 py-0.5 bg-black/30 rounded text-gray-400">IP: {{ log.ip }}</span>
              </div>
            </div>
          </div>
        </div>
        <div v-else class="flex-1 flex flex-col items-center justify-center py-12 text-center opacity-40">
          <Shield :size="48" class="mb-2" />
          <p class="text-sm">Server is secured. No major events.</p>
        </div>
      </div>
    </div>

    <!-- Charts & Sites -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <div class="lg:col-span-2 panda-card">
        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-2">
            <Globe :size="18" style="color: var(--color-primary);" />
            <h2 class="text-base font-semibold" style="color: var(--text-primary);">Recent Sites</h2>
          </div>
        </div>
        <div v-if="recentSites.length" class="space-y-2">
          <div v-for="site in recentSites" :key="site.domain" class="flex items-center justify-between p-3 rounded-lg hover:bg-[var(--bg-hover)]">
            <div class="flex items-center gap-3">
              <div class="w-8 h-8 rounded-lg flex items-center justify-center bg-[var(--color-primary-subtle)]">
                <Globe :size="14" class="text-[var(--color-primary)]" />
              </div>
              <span class="text-sm font-medium">{{ site.domain }}</span>
            </div>
            <div class="flex items-center gap-2">
              <span class="panda-badge panda-badge-success" v-if="site.ssl">SSL</span>
              <a :href="'http://' + site.domain" target="_blank" class="p-1.5 hover:text-white transition-colors">
                <ExternalLink :size="14" />
              </a>
            </div>
          </div>
        </div>
      </div>

      <div class="space-y-4">
        <div class="panda-card !p-4">
          <p class="text-xs font-semibold text-[var(--text-muted)] uppercase mb-2">CPU History</p>
          <div class="h-20">
            <Line v-if="!loading" :data="cpuData" :options="chartOptions" />
          </div>
        </div>
        <div class="panda-card !p-4">
          <p class="text-xs font-semibold text-[var(--text-muted)] uppercase mb-2">RAM History</p>
          <div class="h-20">
            <Line v-if="!loading" :data="ramData" :options="chartOptions" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
