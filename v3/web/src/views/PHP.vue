<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import { Code, Download, Settings, RotateCw, Check } from 'lucide-vue-next'

const versions = ref([])
const loading = ref(false)
const error = ref('')
const installing = ref(false)
const newVersion = ref('8.3')
const selectedConfig = ref(null)
const showConfig = ref(false)
const config = ref({})

const availableVersions = ['8.4', '8.3', '8.2', '8.1', '8.0', '7.4']

const fetchVersions = async () => {
  loading.value = true
  error.value = ''
  try {
    const res = await axios.get('/api/php/versions')
    versions.value = res.data || []
  } catch (err) {
    error.value = err.response?.data?.error || 'Failed to load PHP versions'
  } finally {
    loading.value = false
  }
}

const installVersion = async () => {
  installing.value = true
  try {
    await axios.post('/api/php/install', { version: newVersion.value })
    fetchVersions()
    alert('PHP ' + newVersion.value + ' installed successfully!')
  } catch (err) {
    alert('Failed to install PHP: ' + (err.response?.data?.error || err.message))
  } finally {
    installing.value = false
  }
}

const switchVersion = async (version) => {
  try {
    await axios.post('/api/php/switch', { version })
    fetchVersions()
  } catch (err) {
    alert('Failed to switch PHP: ' + (err.response?.data?.error || err.message))
  }
}

const restartFPM = async (version) => {
  try {
    await axios.post(`/api/php/restart/${version}`)
    fetchVersions()
  } catch (err) {
    alert('Failed to restart PHP-FPM: ' + (err.response?.data?.error || err.message))
  }
}

const viewConfig = async (version) => {
  selectedConfig.value = version
  showConfig.value = true
  try {
    const res = await axios.get(`/api/php/config/${version}`)
    config.value = res.data || {}
  } catch (err) {
    config.value = { error: err.response?.data?.error || 'Failed to load config' }
  }
}

const getStatusColor = (status) => {
  if (status === 'running') return 'bg-green-500/10 text-green-400 border-green-500/20'
  if (status === 'stopped') return 'bg-yellow-500/10 text-yellow-400 border-yellow-500/20'
  return 'bg-gray-500/10 text-gray-400 border-gray-500/20'
}

onMounted(() => {
  fetchVersions()
})
</script>

<template>
  <div class="p-8">
    <div class="flex items-center justify-between mb-8">
      <div>
        <h2 class="text-2xl font-bold text-white tracking-tight flex items-center gap-2">
          <Code class="text-indigo-400" />
          PHP Management
        </h2>
        <p class="text-gray-500 mt-1">Install and manage PHP versions</p>
      </div>
      <button @click="fetchVersions" class="p-2 bg-white/5 rounded-lg hover:bg-white/10 transition-colors">
        <RotateCw :size="20" class="text-gray-400" />
      </button>
    </div>

    <!-- Install PHP -->
    <div class="bg-black/20 border border-white/5 rounded-xl p-6 mb-6">
      <h3 class="text-lg font-semibold text-white mb-4">Install PHP Version</h3>
      <div class="flex gap-4">
        <select v-model="newVersion" class="flex-1 bg-black/30 border border-white/10 rounded-lg px-4 py-2 text-white">
          <option v-for="v in availableVersions" :key="v" :value="v">PHP {{ v }}</option>
        </select>
        <button @click="installVersion" :disabled="installing"
                class="px-6 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg transition-colors disabled:opacity-50 flex items-center gap-2">
          <Download :size="16" />
          {{ installing ? 'Installing...' : 'Install' }}
        </button>
      </div>
    </div>

    <div v-if="error" class="bg-red-500/10 border border-red-500/20 text-red-400 p-4 rounded-xl mb-6">
      {{ error }}
    </div>

    <div class="bg-black/20 border border-white/5 rounded-xl overflow-hidden">
      <div class="grid grid-cols-12 gap-4 p-4 border-b border-white/5 text-xs font-medium text-gray-500 uppercase tracking-wider">
        <div class="col-span-2">Version</div>
        <div class="col-span-2">Status</div>
        <div class="col-span-2">Default</div>
        <div class="col-span-4">FPM Socket</div>
        <div class="col-span-2 text-right">Actions</div>
      </div>

      <div v-if="loading" class="p-8 text-center text-gray-500">Loading...</div>
      <div v-else-if="versions.length === 0" class="p-8 text-center text-gray-500">No PHP versions installed</div>

      <div v-for="v in versions" :key="v.version" 
           class="grid grid-cols-12 gap-4 p-4 items-center border-b border-white/5 last:border-0 hover:bg-white/5 transition-colors">
        <div class="col-span-2 font-medium text-white">PHP {{ v.version }}</div>
        <div class="col-span-2">
          <span :class="getStatusColor(v.status)" class="px-2 py-1 rounded-md text-xs border font-medium uppercase">
            {{ v.status }}
          </span>
        </div>
        <div class="col-span-2">
          <Check v-if="v.is_default" class="text-green-400" :size="16" />
          <span v-else class="text-gray-500">-</span>
        </div>
        <div class="col-span-4 text-gray-400 text-sm truncate">{{ v.fpm_socket }}</div>
        <div class="col-span-2 flex items-center justify-end space-x-2">
          <button v-if="!v.is_default" @click="switchVersion(v.version)" 
                  class="px-2 py-1 text-xs bg-white/5 hover:bg-white/10 rounded text-gray-300" title="Set Default">
            Default
          </button>
          <button @click="restartFPM(v.version)" 
                  class="p-1.5 hover:bg-blue-500/10 rounded-lg text-gray-400 hover:text-blue-500 transition-colors" title="Restart FPM">
            <RotateCw :size="16" />
          </button>
          <button @click="viewConfig(v.version)" 
                  class="p-1.5 hover:bg-purple-500/10 rounded-lg text-gray-400 hover:text-purple-500 transition-colors" title="Config">
            <Settings :size="16" />
          </button>
        </div>
      </div>
    </div>

    <!-- Config Modal -->
    <div v-if="showConfig" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50" @click.self="showConfig = false">
      <div class="bg-gray-900 border border-white/10 rounded-xl w-96 p-6">
        <h3 class="text-lg font-bold text-white mb-4">PHP {{ selectedConfig }} Configuration</h3>
        <div class="space-y-3 text-sm">
          <div class="flex justify-between"><span class="text-gray-400">Memory Limit</span><span class="text-white">{{ config.memory_limit }}</span></div>
          <div class="flex justify-between"><span class="text-gray-400">Max Execution Time</span><span class="text-white">{{ config.max_execution_time }}s</span></div>
          <div class="flex justify-between"><span class="text-gray-400">Upload Max Size</span><span class="text-white">{{ config.upload_max_filesize }}</span></div>
          <div class="flex justify-between"><span class="text-gray-400">Post Max Size</span><span class="text-white">{{ config.post_max_size }}</span></div>
          <div class="flex justify-between"><span class="text-gray-400">OPcache</span><span class="text-white">{{ config.opcache_enabled ? 'Enabled' : 'Disabled' }}</span></div>
        </div>
        <button @click="showConfig = false" class="mt-6 w-full py-2 bg-white/10 hover:bg-white/20 rounded-lg text-white">Close</button>
      </div>
    </div>
  </div>
</template>
