<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { Activity, HardDrive, Database, RefreshCw } from 'lucide-vue-next'
import axios from 'axios'
import { useAuthStore } from '../stores/auth'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
} from 'chart.js'
import { Line } from 'vue-chartjs'

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
)

const stats = ref({ status: 'connecting', version: '3.0.0' })
const systemStats = ref(null)
const authStore = useAuthStore()
let pollingInterval = null

// Chart Data
const maxDataPoints = 20
const cpuData = ref({
  labels: Array(maxDataPoints).fill(''),
  datasets: [{
    label: 'CPU Usage (%)',
    borderColor: '#3b82f6',
    backgroundColor: 'rgba(59, 130, 246, 0.1)',
    data: Array(maxDataPoints).fill(0),
    fill: true,
    tension: 0.4
  }]
})
const ramData = ref({
  labels: Array(maxDataPoints).fill(''),
  datasets: [{
    label: 'RAM Usage (%)',
    borderColor: '#a855f7',
    backgroundColor: 'rgba(168, 85, 247, 0.1)',
    data: Array(maxDataPoints).fill(0),
    fill: true,
    tension: 0.4
  }]
})

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      display: false
    }
  },
  scales: {
    y: {
      min: 0,
      max: 100,
      grid: {
        color: 'rgba(255, 255, 255, 0.1)'
      },
      ticks: {
        color: '#9ca3af'
      }
    },
    x: {
      grid: {
        display: false
      },
      ticks: {
        display: false
      }
    }
  }
}

const updateCharts = (cpu, ram) => {
  const newCpuData = [...cpuData.value.datasets[0].data]
  const newRamData = [...ramData.value.datasets[0].data]
  
  newCpuData.push(cpu)
  newCpuData.shift()
  
  newRamData.push(ram)
  newRamData.shift()
  
  cpuData.value = {
    ...cpuData.value,
    datasets: [{
      ...cpuData.value.datasets[0],
      data: newCpuData
    }]
  }
  
  ramData.value = {
    ...ramData.value,
    datasets: [{
      ...ramData.value.datasets[0],
      data: newRamData
    }]
  }
}

const fetchStats = async () => {
  try {
    const res = await axios.get('/api/health')
    stats.value = res.data
    
    const statsRes = await axios.get('/api/system/stats')
    systemStats.value = statsRes.data
    
    updateCharts(statsRes.data.cpu_usage, statsRes.data.memory.used_percent)
  } catch (err) {
    if (err.response && err.response.status === 401) {
      authStore.logout()
    } else {
      stats.value.status = 'error'
    }
  }
}

onMounted(() => {
  fetchStats()
  pollingInterval = setInterval(fetchStats, 3000)
})

onUnmounted(() => {
  if (pollingInterval) clearInterval(pollingInterval)
})
</script>

<template>
  <div class="space-y-8 max-w-7xl mx-auto w-full text-left">
    <div class="flex items-center justify-between">
      <div class="flex flex-col">
        <h2 class="text-2xl font-bold tracking-tight text-white">System Overview</h2>
        <p class="text-sm text-gray-500">Real-time monitoring and resource management</p>
      </div>
      <button class="flex items-center space-x-2 px-4 py-2 bg-white/5 hover:bg-white/10 rounded-lg text-sm transition-colors border border-white/5" @click="fetchStats">
        <RefreshCw :size="16" />
        <span>Refresh</span>
      </button>
    </div>

    <!-- Stats Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6" v-if="systemStats">
      <!-- CPU -->
      <div class="bg-black/20 border border-white/5 rounded-2xl p-6 hover:border-panda-primary/30 transition-colors group">
        <div class="flex justify-between items-start mb-4">
          <div class="p-3 bg-blue-500/10 rounded-xl text-blue-400 group-hover:bg-blue-500/20 transition-colors">
            <Activity :size="24" />
          </div>
          <span class="text-xs font-mono text-gray-500">{{ systemStats.cpus }} Cores</span>
        </div>
        <div class="space-y-1">
          <h3 class="text-sm text-gray-400">CPU Usage</h3>
          <p class="text-2xl font-bold font-mono">{{ systemStats.cpu_usage.toFixed(1) }}%</p>
        </div>
        <div class="mt-4 h-1.5 w-full bg-white/5 rounded-full overflow-hidden">
          <div class="h-full bg-blue-500 transition-all duration-500" :style="{ width: systemStats.cpu_usage + '%' }"></div>
        </div>
      </div>

      <!-- RAM -->
      <div class="bg-black/20 border border-white/5 rounded-2xl p-6 hover:border-panda-primary/30 transition-colors group">
        <div class="flex justify-between items-start mb-4">
          <div class="p-3 bg-purple-500/10 rounded-xl text-purple-400 group-hover:bg-purple-500/20 transition-colors">
            <HardDrive :size="24" />
          </div>
          <span class="text-xs font-mono text-gray-500">{{ (systemStats.memory.total / 1024 / 1024 / 1024).toFixed(1) }} GB Total</span>
        </div>
        <div class="space-y-1">
          <h3 class="text-sm text-gray-400">RAM Usage</h3>
          <p class="text-2xl font-bold font-mono">{{ systemStats.memory.used_percent.toFixed(1) }}%</p>
        </div>
        <div class="mt-4 h-1.5 w-full bg-white/5 rounded-full overflow-hidden">
          <div class="h-full bg-purple-500 transition-all duration-500" :style="{ width: systemStats.memory.used_percent + '%' }"></div>
        </div>
      </div>

       <!-- Disk -->
       <div class="bg-black/20 border border-white/5 rounded-2xl p-6 hover:border-panda-primary/30 transition-colors group">
        <div class="flex justify-between items-start mb-4">
          <div class="p-3 bg-orange-500/10 rounded-xl text-orange-400 group-hover:bg-orange-500/20 transition-colors">
            <Database :size="24" />
          </div>
          <span class="text-xs font-mono text-gray-500">{{ (systemStats.disk.total / 1024 / 1024 / 1024).toFixed(0) }} GB Total</span>
        </div>
        <div class="space-y-1">
          <h3 class="text-sm text-gray-400">Disk Usage</h3>
          <p class="text-2xl font-bold font-mono">{{ systemStats.disk.used_percent.toFixed(1) }}%</p>
        </div>
        <div class="mt-4 h-1.5 w-full bg-white/5 rounded-full overflow-hidden">
          <div class="h-full bg-orange-500 transition-all duration-500" :style="{ width: systemStats.disk.used_percent + '%' }"></div>
        </div>
      </div>

      <!-- Uptime -->
      <div class="bg-black/20 border border-white/5 rounded-2xl p-6 hover:border-panda-primary/30 transition-colors group">
        <div class="flex justify-between items-start mb-4">
          <div class="p-3 bg-green-500/10 rounded-xl text-green-400 group-hover:bg-green-500/20 transition-colors">
            <Activity :size="24" />
          </div>
          <span class="text-xs font-mono text-gray-500">System</span>
        </div>
        <div class="space-y-1">
          <h3 class="text-sm text-gray-400">Uptime</h3>
          <p class="text-lg font-bold font-mono">{{ (systemStats.uptime / 3600).toFixed(1) }} Hrs</p>
        </div>
         <div class="mt-4 text-xs text-gray-500">
            OS: {{ systemStats.os }} {{ systemStats.arch }}
        </div>
      </div>
    </div>

    <!-- Charts -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6" v-if="systemStats">
      <div class="bg-black/20 border border-white/5 rounded-2xl p-6">
        <h3 class="text-lg font-bold text-white mb-4">CPU History</h3>
        <div class="h-64">
          <Line :data="cpuData" :options="chartOptions" />
        </div>
      </div>
      
      <div class="bg-black/20 border border-white/5 rounded-2xl p-6">
        <h3 class="text-lg font-bold text-white mb-4">RAM History</h3>
        <div class="h-64">
          <Line :data="ramData" :options="chartOptions" />
        </div>
      </div>
    </div>
  </div>
</template>
