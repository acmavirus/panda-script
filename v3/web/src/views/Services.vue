<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import { Server, Play, Square, RotateCw, FileText, RefreshCw } from 'lucide-vue-next'
import Skeleton from '../components/Skeleton.vue'
import StatusIndicator from '../components/StatusIndicator.vue'

const services = ref([])
const loading = ref(true)
const error = ref('')
const selectedService = ref(null)
const logs = ref('')
const showLogs = ref(false)
const actionLoading = ref({})

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
  // Optimistic UI
  actionLoading.value[name] = action
  const svc = services.value.find(s => s.name === name)
  const previousStatus = svc?.status
  
  if (svc) {
    if (action === 'start') svc.status = 'active'
    else if (action === 'stop') svc.status = 'inactive'
    else if (action === 'restart') svc.status = 'restarting'
  }
  
  try {
    await axios.post(`/api/services/${name}/${action}`)
    // Refresh after a short delay to get real status
    setTimeout(fetchServices, 500)
  } catch (err) {
    // Revert on error
    if (svc) svc.status = previousStatus
    error.value = `Failed to ${action} ${name}`
  } finally {
    delete actionLoading.value[name]
  }
}

const viewLogs = async (name) => {
  selectedService.value = name
  showLogs.value = true
  logs.value = 'Loading...'
  try {
    const res = await axios.get(`/api/services/${name}/logs?lines=100`)
    logs.value = res.data?.logs || 'No logs available'
  } catch (err) {
    logs.value = 'Failed to load logs'
  }
}

const getStatusType = (status) => {
  if (status === 'active' || status === 'running') return 'online'
  if (status === 'restarting') return 'pending'
  if (status === 'failed') return 'offline'
  return 'stopped'
}

onMounted(fetchServices)
</script>

<template>
  <div class="space-y-6 max-w-7xl mx-auto">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-2xl font-semibold" style="color: var(--text-primary);">Services</h1>
        <p class="text-sm mt-1" style="color: var(--text-muted);">Manage system services (nginx, php-fpm, mysql...)</p>
      </div>
      <button @click="fetchServices" class="panda-btn panda-btn-secondary">
        <RefreshCw :size="16" :class="{ 'animate-spin': loading }" />
        <span>Refresh</span>
      </button>
    </div>

    <!-- Error -->
    <div v-if="error" class="flex items-center justify-between px-4 py-3 rounded-lg" style="background: var(--color-error-subtle); color: var(--color-error);">
      <span class="text-sm">{{ error }}</span>
      <button @click="error = ''">&times;</button>
    </div>

    <!-- Services Table -->
    <div class="panda-card !p-0 overflow-hidden">
      <table class="panda-table">
        <thead>
          <tr>
            <th>Service</th>
            <th>Status</th>
            <th class="hidden md:table-cell">Enabled</th>
            <th class="hidden lg:table-cell">Description</th>
            <th class="w-32"></th>
          </tr>
        </thead>
        <tbody>
          <!-- Loading Skeleton -->
          <Skeleton v-if="loading" v-for="n in 5" :key="n" :loading="true" type="table-row" :columns="5" />
          
          <!-- Services -->
          <tr v-else v-for="svc in services" :key="svc.name" :class="{ 'opacity-50': actionLoading[svc.name] }">
            <td>
              <div class="flex items-center gap-3">
                <div class="w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0" style="background: rgba(139, 92, 246, 0.1);">
                  <Server :size="16" style="color: #8b5cf6;" />
                </div>
                <span class="font-medium" style="color: var(--text-primary);">{{ svc.name }}</span>
              </div>
            </td>
            <td>
              <div class="flex items-center gap-2">
                <StatusIndicator :status="getStatusType(svc.status)" />
                <span 
                  class="text-xs font-medium uppercase"
                  :style="{
                    color: svc.status === 'active' || svc.status === 'running' ? 'var(--color-success)' : 
                           svc.status === 'restarting' ? 'var(--color-warning)' :
                           svc.status === 'failed' ? 'var(--color-error)' : 'var(--text-muted)'
                  }"
                >
                  {{ svc.status }}
                </span>
              </div>
            </td>
            <td class="hidden md:table-cell">
              <span 
                class="panda-badge"
                :class="svc.enabled ? 'panda-badge-success' : ''"
                :style="!svc.enabled ? 'background: var(--bg-surface); color: var(--text-muted);' : ''"
              >
                {{ svc.enabled ? 'Enabled' : 'Disabled' }}
              </span>
            </td>
            <td class="hidden lg:table-cell">
              <span class="text-sm truncate max-w-xs block" style="color: var(--text-muted);">{{ svc.description }}</span>
            </td>
            <td>
              <!-- Service Actions - Always Visible -->
              <div class="flex items-center gap-1 justify-end">
                <button 
                  v-if="svc.status !== 'active' && svc.status !== 'running'"
                  @click="serviceAction(svc.name, 'start')"
                  class="panda-btn panda-btn-ghost p-2"
                  :disabled="actionLoading[svc.name]"
                  data-tooltip="Start"
                >
                  <Play :size="14" style="color: var(--color-success);" />
                </button>
                <button 
                  v-else
                  @click="serviceAction(svc.name, 'stop')"
                  class="panda-btn panda-btn-ghost p-2"
                  :disabled="actionLoading[svc.name]"
                  data-tooltip="Stop"
                >
                  <Square :size="14" style="color: var(--color-error);" />
                </button>
                <button 
                  @click="serviceAction(svc.name, 'restart')"
                  class="panda-btn panda-btn-ghost p-2"
                  :disabled="actionLoading[svc.name]"
                  :class="{ 'animate-spin': actionLoading[svc.name] === 'restart' }"
                  data-tooltip="Restart"
                >
                  <RotateCw :size="14" style="color: var(--color-info);" />
                </button>
                <button 
                  @click="viewLogs(svc.name)"
                  class="panda-btn panda-btn-ghost p-2"
                  data-tooltip="Logs"
                >
                  <FileText :size="14" />
                </button>
              </div>
            </td>
          </tr>
          
          <!-- Empty State -->
          <tr v-if="!loading && services.length === 0">
            <td colspan="5" class="text-center py-16">
              <Server :size="40" class="mx-auto mb-3 opacity-20" />
              <p style="color: var(--text-muted);">No services found</p>
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
                <FileText :size="18" style="color: var(--color-primary);" />
                <h3 class="text-lg font-semibold" style="color: var(--text-primary);">{{ selectedService }}</h3>
              </div>
              <button @click="showLogs = false" class="panda-btn panda-btn-ghost p-2" style="font-size: 20px;">&times;</button>
            </div>
            <pre class="flex-1 p-4 overflow-auto text-sm font-mono" style="background: var(--bg-base); color: var(--text-secondary);">{{ logs }}</pre>
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
