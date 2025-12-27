<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import { Stethoscope, RotateCw, CheckCircle, AlertTriangle, XCircle } from 'lucide-vue-next'

const report = ref(null)
const loading = ref(false)

const runHealthCheck = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/health/check')
    report.value = res.data
  } catch (err) {
    console.error(err)
  } finally {
    loading.value = false
  }
}

const getStatusIcon = (status) => {
  if (status === 'ok') return CheckCircle
  if (status === 'warning') return AlertTriangle
  return XCircle
}

const getStatusColor = (status) => {
  if (status === 'ok') return 'text-green-400'
  if (status === 'warning') return 'text-yellow-400'
  return 'text-red-400'
}

const getScoreColor = (score) => {
  if (score >= 80) return 'text-green-400'
  if (score >= 50) return 'text-yellow-400'
  return 'text-red-400'
}

onMounted(runHealthCheck)
</script>

<template>
  <div class="p-8">
    <div class="flex items-center justify-between mb-8">
      <div>
        <h2 class="text-2xl font-bold text-white tracking-tight flex items-center gap-2">
          <Stethoscope class="text-emerald-400" />
          Panda Doctor
        </h2>
        <p class="text-gray-500 mt-1">System health check and diagnostics</p>
      </div>
      <button @click="runHealthCheck" :disabled="loading" 
              class="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg flex items-center gap-2 disabled:opacity-50">
        <RotateCw :size="16" :class="loading ? 'animate-spin' : ''" /> Run Check
      </button>
    </div>

    <div v-if="loading" class="text-center text-gray-500 py-12">Running health checks...</div>

    <div v-else-if="report">
      <!-- Score Card -->
      <div class="bg-black/20 border border-white/5 rounded-xl p-8 mb-6 text-center">
        <div class="text-6xl font-bold mb-2" :class="getScoreColor(report.score)">{{ report.score }}</div>
        <div class="text-gray-400">Health Score</div>
        <div class="mt-4 text-sm text-gray-500">Last checked: {{ new Date(report.generated_at).toLocaleString() }}</div>
      </div>

      <!-- Score Bar -->
      <div class="h-4 bg-white/5 rounded-full mb-8 overflow-hidden">
        <div class="h-full transition-all duration-500"
             :class="report.score >= 80 ? 'bg-green-500' : report.score >= 50 ? 'bg-yellow-500' : 'bg-red-500'"
             :style="{width: report.score + '%'}"></div>
      </div>

      <!-- Checks Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div v-for="check in report.checks" :key="check.name + check.category"
             class="bg-black/20 border border-white/5 rounded-xl p-4 flex items-center gap-4 hover:bg-white/5 transition-colors">
          <component :is="getStatusIcon(check.status)" :size="24" :class="getStatusColor(check.status)" />
          <div class="flex-1">
            <div class="text-sm text-gray-500">{{ check.category }}</div>
            <div class="font-medium text-white">{{ check.name }}</div>
            <div class="text-sm text-gray-400">{{ check.message }}</div>
          </div>
          <div class="text-right">
            <div class="font-mono text-lg" :class="getStatusColor(check.status)">{{ check.value }}</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
