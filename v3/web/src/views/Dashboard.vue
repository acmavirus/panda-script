<script setup>
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { Activity, HardDrive, Database, RefreshCw, Clock, Server, ArrowUpRight, ArrowDownRight } from 'lucide-vue-next'
import axios from 'axios'
import { useAuthStore } from '../stores/auth'
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

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler
)

const authStore = useAuthStore()
const systemStats = ref(null)
const loading = ref(true)
const refreshing = ref(false)
let pollingInterval = null

// Chart Data
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
      mode: 'index',
      intersect: false,
      backgroundColor: 'rgba(17, 17, 19, 0.9)',
      borderColor: 'rgba(255, 255, 255, 0.1)',
      borderWidth: 1,
      titleFont: { family: 'Inter' },
      bodyFont: { family: 'Inter' },
      padding: 12,
      cornerRadius: 8
    }
  },
  scales: {
    y: {
      min: 0,
      max: 100,
      grid: { color: 'rgba(255, 255, 255, 0.04)', drawBorder: false },
      ticks: { 
        color: 'var(--text-muted)', 
        font: { size: 11 },
        callback: (v) => v + '%'
      }
    },
    x: {
      grid: { display: false },
      ticks: { display: false }
    }
  },
  interaction: {
    mode: 'nearest',
    axis: 'x',
    intersect: false
  }
}

const fetchStats = async (showRefresh = false) => {
  if (showRefresh) refreshing.value = true
  
  try {
    const res = await axios.get('/api/system/stats')
    systemStats.value = res.data
    
    // Update history
    cpuHistory.value = [...cpuHistory.value.slice(1), res.data.cpu_usage]
    ramHistory.value = [...ramHistory.value.slice(1), res.data.memory.used_percent]
    
    loading.value = false
  } catch (err) {
    if (err.response?.status === 401) {
      authStore.logout()
    }
  } finally {
    refreshing.value = false
  }
}

const formatBytes = (bytes) => {
  const gb = bytes / 1024 / 1024 / 1024
  return gb.toFixed(1) + ' GB'
}

const formatUptime = (seconds) => {
  const days = Math.floor(seconds / 86400)
  const hours = Math.floor((seconds % 86400) / 3600)
  if (days > 0) return `${days}d ${hours}h`
  return `${hours}h ${Math.floor((seconds % 3600) / 60)}m`
}

onMounted(() => {
  fetchStats()
  pollingInterval = setInterval(() => fetchStats(false), 3000)
})

onUnmounted(() => {
  if (pollingInterval) clearInterval(pollingInterval)
})
</script>

<template>
  <div class="space-y-8 max-w-7xl mx-auto">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-semibold" style="color: var(--text-primary);">Dashboard</h1>
        <p class="text-sm mt-1" style="color: var(--text-muted);">Real-time system monitoring</p>
      </div>
      <button 
        @click="fetchStats(true)"
        :disabled="refreshing"
        class="panda-btn panda-btn-secondary"
        :class="{ 'optimistic-loading': refreshing }"
      >
        <RefreshCw :size="16" :class="{ 'animate-spin': refreshing }" />
        <span>Refresh</span>
      </button>
    </div>

    <!-- Stats Grid with Skeleton -->
    <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-5">
      <!-- CPU Card -->
      <Skeleton :loading="loading" type="stats">
        <div class="panda-card group">
          <div class="flex justify-between items-start mb-4">
            <div class="p-2.5 rounded-xl transition-colors" style="background: var(--color-info-subtle);">
              <Activity :size="20" style="color: var(--color-info);" />
            </div>
            <span class="text-xs font-mono" style="color: var(--text-muted);">
              {{ systemStats?.cpus }} Cores
            </span>
          </div>
          <div>
            <h3 class="text-sm font-medium" style="color: var(--text-secondary);">CPU Usage</h3>
            <p class="text-2xl font-semibold font-mono mt-1" style="color: var(--text-primary);">
              {{ systemStats?.cpu_usage.toFixed(1) }}%
            </p>
          </div>
          <div class="panda-progress mt-4">
            <div 
              class="panda-progress-bar" 
              :style="{ width: systemStats?.cpu_usage + '%', background: 'var(--color-info)' }"
            ></div>
          </div>
        </div>
      </Skeleton>

      <!-- RAM Card -->
      <Skeleton :loading="loading" type="stats">
        <div class="panda-card group">
          <div class="flex justify-between items-start mb-4">
            <div class="p-2.5 rounded-xl transition-colors" style="background: rgba(139, 92, 246, 0.1);">
              <HardDrive :size="20" style="color: #8b5cf6;" />
            </div>
            <span class="text-xs font-mono" style="color: var(--text-muted);">
              {{ formatBytes(systemStats?.memory.total) }}
            </span>
          </div>
          <div>
            <h3 class="text-sm font-medium" style="color: var(--text-secondary);">Memory</h3>
            <p class="text-2xl font-semibold font-mono mt-1" style="color: var(--text-primary);">
              {{ systemStats?.memory.used_percent.toFixed(1) }}%
            </p>
          </div>
          <div class="panda-progress mt-4">
            <div 
              class="panda-progress-bar" 
              :style="{ width: systemStats?.memory.used_percent + '%', background: '#8b5cf6' }"
            ></div>
          </div>
        </div>
      </Skeleton>

      <!-- Disk Card -->
      <Skeleton :loading="loading" type="stats">
        <div class="panda-card group">
          <div class="flex justify-between items-start mb-4">
            <div class="p-2.5 rounded-xl transition-colors" style="background: var(--color-warning-subtle);">
              <Database :size="20" style="color: var(--color-warning);" />
            </div>
            <span class="text-xs font-mono" style="color: var(--text-muted);">
              {{ formatBytes(systemStats?.disk.total) }}
            </span>
          </div>
          <div>
            <h3 class="text-sm font-medium" style="color: var(--text-secondary);">Disk</h3>
            <p class="text-2xl font-semibold font-mono mt-1" style="color: var(--text-primary);">
              {{ systemStats?.disk.used_percent.toFixed(1) }}%
            </p>
          </div>
          <div class="panda-progress mt-4">
            <div 
              class="panda-progress-bar" 
              :style="{ width: systemStats?.disk.used_percent + '%', background: 'var(--color-warning)' }"
            ></div>
          </div>
        </div>
      </Skeleton>

      <!-- Uptime Card -->
      <Skeleton :loading="loading" type="stats">
        <div class="panda-card group">
          <div class="flex justify-between items-start mb-4">
            <div class="p-2.5 rounded-xl transition-colors" style="background: var(--color-success-subtle);">
              <Clock :size="20" style="color: var(--color-success);" />
            </div>
            <span class="status-indicator online"></span>
          </div>
          <div>
            <h3 class="text-sm font-medium" style="color: var(--text-secondary);">Uptime</h3>
            <p class="text-2xl font-semibold font-mono mt-1" style="color: var(--text-primary);">
              {{ formatUptime(systemStats?.uptime) }}
            </p>
          </div>
          <div class="mt-4 text-xs font-mono" style="color: var(--text-muted);">
            {{ systemStats?.os }} {{ systemStats?.arch }}
          </div>
        </div>
      </Skeleton>
    </div>

    <!-- Charts -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-5" v-if="!loading">
      <div class="panda-card">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-base font-semibold" style="color: var(--text-primary);">CPU History</h3>
          <span class="text-sm font-mono" style="color: var(--color-info);">
            {{ systemStats?.cpu_usage.toFixed(1) }}%
          </span>
        </div>
        <div class="h-48">
          <Line :data="cpuData" :options="chartOptions" />
        </div>
      </div>
      
      <div class="panda-card">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-base font-semibold" style="color: var(--text-primary);">Memory History</h3>
          <span class="text-sm font-mono" style="color: #8b5cf6;">
            {{ systemStats?.memory.used_percent.toFixed(1) }}%
          </span>
        </div>
        <div class="h-48">
          <Line :data="ramData" :options="chartOptions" />
        </div>
      </div>
    </div>

    <!-- Quick Links -->
    <div class="panda-card" v-if="!loading">
      <h3 class="text-base font-semibold mb-4" style="color: var(--text-primary);">Quick Actions</h3>
      <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
        <router-link 
          v-for="link in [
            { label: 'New Website', path: '/websites', icon: '🌐' },
            { label: 'Terminal', path: '/terminal', icon: '💻' },
            { label: 'SSL Certs', path: '/ssl', icon: '🔒' },
            { label: 'Backup', path: '/backup', icon: '💾' }
          ]"
          :key="link.path"
          :to="link.path"
          class="flex items-center gap-3 p-3 rounded-lg border transition-all hover:-translate-y-0.5"
          style="border-color: var(--border-color); background: var(--bg-surface);"
        >
          <span class="text-xl">{{ link.icon }}</span>
          <span class="text-sm font-medium" style="color: var(--text-primary);">{{ link.label }}</span>
        </router-link>
      </div>
    </div>
  </div>
</template>
