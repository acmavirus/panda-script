<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import { Server, Play, Square, RotateCw, Power, FileText } from 'lucide-vue-next'

const services = ref([])
const loading = ref(false)
const error = ref('')
const selectedService = ref(null)
const logs = ref('')
const showLogs = ref(false)

const fetchServices = async () => {
  loading.value = true
  error.value = ''
  try {
    const res = await axios.get('/api/services/')
    services.value = res.data || []
  } catch (err) {
    error.value = err.response?.data?.error || 'Failed to load services'
  } finally {
    loading.value = false
  }
}

const serviceAction = async (name, action) => {
  try {
    await axios.post(`/api/services/${name}/${action}`)
    fetchServices()
  } catch (err) {
    alert(`Failed to ${action} ${name}: ` + (err.response?.data?.error || err.message))
  }
}

const viewLogs = async (name) => {
  selectedService.value = name
  showLogs.value = true
  try {
    const res = await axios.get(`/api/services/${name}/logs?lines=100`)
    logs.value = res.data?.logs || 'No logs available'
  } catch (err) {
    logs.value = 'Failed to load logs: ' + (err.response?.data?.error || err.message)
  }
}

const getStatusColor = (status) => {
  if (status === 'active' || status === 'running') return 'bg-green-500/10 text-green-400 border-green-500/20'
  if (status === 'failed') return 'bg-red-500/10 text-red-400 border-red-500/20'
  return 'bg-gray-500/10 text-gray-400 border-gray-500/20'
}

onMounted(() => {
  fetchServices()
})
</script>

<template>
  <div class="p-4 lg:p-8">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between mb-8 gap-4">
      <div>
        <h2 class="text-xl lg:text-2xl font-bold text-white tracking-tight flex items-center gap-2">
          <Server class="text-purple-400" :size="24" />
          System Services
        </h2>
        <p class="text-xs lg:text-sm text-gray-400 mt-1">Manage nginx, php-fpm, mysql, etc.</p>
      </div>
      <button @click="fetchServices" class="sm:p-2 p-3 bg-white/5 rounded-lg hover:bg-white/10 transition-colors flex items-center justify-center gap-2">
        <RotateCw :size="18" :class="{'animate-spin': loading}" class="text-gray-400" />
        <span class="sm:hidden text-xs text-gray-400 font-medium font-mono uppercase tracking-widest">Refresh</span>
      </button>
    </div>

    <div v-if="error" class="bg-red-500/10 border border-red-500/20 text-red-400 p-3 rounded-xl mb-6 text-xs">
      {{ error }}
    </div>

    <div class="bg-black/20 border border-white/5 rounded-xl overflow-hidden">
      <!-- Horizontal Scroll Wrapper -->
      <div class="overflow-x-auto">
        <div class="min-w-[800px]">
          <!-- Header -->
          <div class="grid grid-cols-12 gap-4 p-4 border-b border-white/5 text-[10px] lg:text-xs font-medium text-gray-500 uppercase tracking-widest bg-white/2">
            <div class="col-span-3">Service</div>
            <div class="col-span-2">Status</div>
            <div class="col-span-2">Enabled</div>
            <div class="col-span-3">Description</div>
            <div class="col-span-2 text-right pr-4">Actions</div>
          </div>

          <div v-if="loading && services.length === 0" class="p-20 text-center text-gray-500 flex flex-col items-center gap-3">
            <div class="animate-spin w-6 h-6 border-2 border-purple-500 border-t-transparent rounded-full"></div>
            <p class="text-xs font-mono">Fetching services...</p>
          </div>
          <div v-else-if="services.length === 0" class="p-20 text-center text-gray-500 text-sm">No services found</div>

          <div v-for="svc in services" :key="svc.name" 
               class="grid grid-cols-12 gap-4 p-4 items-center border-b border-white/5 last:border-0 hover:bg-white/5 transition-colors">
            <div class="col-span-3 font-bold text-gray-200 text-sm flex items-center gap-2">
               <div class="w-1.5 h-1.5 rounded-full" :class="svc.status === 'active' || svc.status === 'running' ? 'bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.5)]' : 'bg-red-500'"></div>
               {{ svc.name }}
            </div>
            <div class="col-span-2">
              <span :class="getStatusColor(svc.status)" class="px-2 py-0.5 rounded-md text-[10px] border font-bold uppercase tracking-wide">
                {{ svc.status }}
              </span>
            </div>
            <div class="col-span-2 text-gray-400 text-xs font-mono">{{ svc.enabled ? 'ENABLED' : 'DISABLED' }}</div>
            <div class="col-span-3 text-gray-500 text-xs truncate italic" :title="svc.description">{{ svc.description }}</div>
            <div class="col-span-2 flex items-center justify-end space-x-2 pr-2">
              <button v-if="svc.status !== 'active' && svc.status !== 'running'" @click="serviceAction(svc.name, 'start')" 
                      class="p-2 hover:bg-green-500/10 rounded-lg text-gray-500 hover:text-green-500 transition-colors" title="Start">
                <Play :size="14" />
              </button>
              <button v-else @click="serviceAction(svc.name, 'stop')" 
                      class="p-2 hover:bg-red-500/10 rounded-lg text-gray-500 hover:text-red-500 transition-colors" title="Stop">
                <Square :size="14" />
              </button>
              <button @click="serviceAction(svc.name, 'restart')" 
                      class="p-2 hover:bg-blue-500/10 rounded-lg text-gray-500 hover:text-blue-500 transition-colors" title="Restart">
                <RotateCw :size="14" />
              </button>
              <button @click="viewLogs(svc.name)" 
                      class="p-2 hover:bg-purple-500/10 rounded-lg text-gray-400 hover:text-purple-500 transition-colors" title="Logs">
                <FileText :size="14" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Logs Modal -->
    <div v-if="showLogs" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50" @click.self="showLogs = false">
      <div class="bg-gray-900 border border-white/10 rounded-xl w-4/5 h-4/5 flex flex-col">
        <div class="flex items-center justify-between p-4 border-b border-white/10">
          <h3 class="text-lg font-bold text-white">Logs: {{ selectedService }}</h3>
          <button @click="showLogs = false" class="text-gray-400 hover:text-white">&times;</button>
        </div>
        <pre class="flex-1 p-4 text-sm text-gray-300 overflow-auto font-mono bg-black/30">{{ logs }}</pre>
      </div>
    </div>
  </div>
</template>
