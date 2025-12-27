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
  <div class="p-8">
    <div class="flex items-center justify-between mb-8">
      <div>
        <h2 class="text-2xl font-bold text-white tracking-tight flex items-center gap-2">
          <Server class="text-purple-400" />
          System Services
        </h2>
        <p class="text-gray-500 mt-1">Manage system services (nginx, php-fpm, mysql...)</p>
      </div>
      <button @click="fetchServices" class="p-2 bg-white/5 rounded-lg hover:bg-white/10 transition-colors">
        <RotateCw :size="20" class="text-gray-400" />
      </button>
    </div>

    <div v-if="error" class="bg-red-500/10 border border-red-500/20 text-red-400 p-4 rounded-xl mb-6">
      {{ error }}
    </div>

    <div class="bg-black/20 border border-white/5 rounded-xl overflow-hidden">
      <div class="grid grid-cols-12 gap-4 p-4 border-b border-white/5 text-xs font-medium text-gray-500 uppercase tracking-wider">
        <div class="col-span-3">Service</div>
        <div class="col-span-2">Status</div>
        <div class="col-span-2">Enabled</div>
        <div class="col-span-3">Description</div>
        <div class="col-span-2 text-right">Actions</div>
      </div>

      <div v-if="loading" class="p-8 text-center text-gray-500">Loading...</div>
      <div v-else-if="services.length === 0" class="p-8 text-center text-gray-500">No services found</div>

      <div v-for="svc in services" :key="svc.name" 
           class="grid grid-cols-12 gap-4 p-4 items-center border-b border-white/5 last:border-0 hover:bg-white/5 transition-colors">
        <div class="col-span-3 font-medium text-white">{{ svc.name }}</div>
        <div class="col-span-2">
          <span :class="getStatusColor(svc.status)" class="px-2 py-1 rounded-md text-xs border font-medium uppercase">
            {{ svc.status }}
          </span>
        </div>
        <div class="col-span-2 text-gray-400">{{ svc.enabled ? 'Yes' : 'No' }}</div>
        <div class="col-span-3 text-gray-400 text-sm truncate" :title="svc.description">{{ svc.description }}</div>
        <div class="col-span-2 flex items-center justify-end space-x-2">
          <button v-if="svc.status !== 'active' && svc.status !== 'running'" @click="serviceAction(svc.name, 'start')" 
                  class="p-1.5 hover:bg-green-500/10 rounded-lg text-gray-400 hover:text-green-500 transition-colors" title="Start">
            <Play :size="16" />
          </button>
          <button v-if="svc.status === 'active' || svc.status === 'running'" @click="serviceAction(svc.name, 'stop')" 
                  class="p-1.5 hover:bg-red-500/10 rounded-lg text-gray-400 hover:text-red-500 transition-colors" title="Stop">
            <Square :size="16" />
          </button>
          <button @click="serviceAction(svc.name, 'restart')" 
                  class="p-1.5 hover:bg-blue-500/10 rounded-lg text-gray-400 hover:text-blue-500 transition-colors" title="Restart">
            <RotateCw :size="16" />
          </button>
          <button @click="viewLogs(svc.name)" 
                  class="p-1.5 hover:bg-purple-500/10 rounded-lg text-gray-400 hover:text-purple-500 transition-colors" title="Logs">
            <FileText :size="16" />
          </button>
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
