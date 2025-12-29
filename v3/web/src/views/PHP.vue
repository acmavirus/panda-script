<script setup>
import { ref, onMounted, watch } from 'vue'
import axios from 'axios'
import { Code, Download, Settings, RotateCw, Check, Package, Puzzle } from 'lucide-vue-next'

const versions = ref([])
const loading = ref(false)
const error = ref('')
const installing = ref(false)
const newVersion = ref('8.3')
const selectedConfig = ref(null)
const showConfig = ref(false)
const config = ref({})

// PHP Extensions
const extensions = ref([])
const loadingExtensions = ref(false)
const selectedVersionForExt = ref('8.3')
const installingExt = ref('')
const showExtensions = ref(false)

const availableVersions = ['8.4', '8.3', '8.2', '8.1', '8.0', '7.4']

const fetchVersions = async () => {
  loading.value = true
  error.value = ''
  try {
    const res = await axios.get('/api/php/versions')
    versions.value = res.data || []
    // Set default version for extensions if we have installed versions
    if (versions.value.length > 0) {
      selectedVersionForExt.value = versions.value[0].version
    }
  } catch (err) {
    error.value = err.response?.data?.error || 'Failed to load PHP versions'
  } finally {
    loading.value = false
  }
}

const fetchExtensions = async () => {
  loadingExtensions.value = true
  try {
    const res = await axios.get('/api/php/extensions', {
      params: { version: selectedVersionForExt.value }
    })
    extensions.value = res.data || []
  } catch (err) {
    console.error('Failed to load extensions:', err)
  } finally {
    loadingExtensions.value = false
  }
}

const installExtension = async (extName) => {
  installingExt.value = extName
  try {
    await axios.post('/api/php/extensions/install', {
      version: selectedVersionForExt.value,
      extension: extName
    })
    alert(`${extName} installed successfully for PHP ${selectedVersionForExt.value}!`)
    fetchExtensions()
  } catch (err) {
    alert('Failed to install extension: ' + (err.response?.data?.error || err.message))
  } finally {
    installingExt.value = ''
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

const openExtensionsPanel = (version) => {
  selectedVersionForExt.value = version
  showExtensions.value = true
  fetchExtensions()
}

const getStatusColor = (status) => {
  if (status === 'running') return 'bg-green-500/10 text-green-400 border-green-500/20'
  if (status === 'stopped') return 'bg-yellow-500/10 text-yellow-400 border-yellow-500/20'
  return 'bg-gray-500/10 text-gray-400 border-gray-500/20'
}

const getExtIcon = (extName) => {
  const icons = {
    'redis': '🔴',
    'memcached': '🟢',
    'imagick': '🖼️',
    'gd': '🎨',
    'mysql': '🐬',
    'mysqli': '🐬',
    'pdo': '🔌',
    'curl': '🌐',
    'zip': '📦',
    'opcache': '⚡',
    'xdebug': '🐛',
    'intl': '🌍',
    'mbstring': '📝',
  }
  return icons[extName] || '📦'
}

// Watch for version change
watch(selectedVersionForExt, () => {
  if (showExtensions.value) {
    fetchExtensions()
  }
})

onMounted(() => {
  fetchVersions()
})
</script>

<template>
  <div class="p-4 lg:p-8">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between mb-8 gap-4">
      <div>
        <h2 class="text-xl lg:text-2xl font-bold text-white tracking-tight flex items-center gap-2">
          <Code class="text-indigo-400" :size="24" />
          PHP Management
        </h2>
        <p class="text-xs lg:text-sm text-gray-500 mt-1">Install and manage PHP versions</p>
      </div>
      <button @click="fetchVersions" class="p-3 sm:p-2 bg-white/5 rounded-lg hover:bg-white/10 transition-colors flex items-center justify-center">
        <RotateCw :size="18" :class="{'animate-spin': loading}" class="text-gray-400" />
      </button>
    </div>

    <!-- Install PHP -->
    <div class="bg-black/20 border border-white/5 rounded-xl p-4 lg:p-6 mb-6">
      <h3 class="text-base lg:text-lg font-bold text-white mb-4">Install PHP Version</h3>
      <div class="flex flex-col sm:flex-row gap-3">
        <select v-model="newVersion" class="flex-1 bg-black/30 border border-white/10 rounded-lg px-4 py-2.5 text-white text-sm">
          <option v-for="v in availableVersions" :key="v" :value="v">PHP {{ v }}</option>
        </select>
        <button @click="installVersion" :disabled="installing"
                class="px-6 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg transition-colors disabled:opacity-50 flex items-center justify-center gap-2 text-sm font-bold">
          <Download :size="16" />
          {{ installing ? 'Installing...' : 'Install Now' }}
        </button>
      </div>
    </div>

    <div v-if="error" class="bg-red-500/10 border border-red-500/20 text-red-400 p-3 rounded-xl mb-6 text-xs">
      {{ error }}
    </div>

    <div class="bg-black/20 border border-white/5 rounded-xl overflow-hidden">
      <!-- Horizontal Scroll Wrapper -->
      <div class="overflow-x-auto">
        <div class="min-w-[800px]">
          <!-- Header -->
          <div class="grid grid-cols-12 gap-4 p-4 border-b border-white/5 text-[10px] lg:text-xs font-bold text-gray-500 uppercase tracking-widest bg-white/2">
            <div class="col-span-2">Version</div>
            <div class="col-span-2">Status</div>
            <div class="col-span-2">Default</div>
            <div class="col-span-4">FPM Socket Path</div>
            <div class="col-span-2 text-right">Actions</div>
          </div>

          <div v-if="loading && versions.length === 0" class="p-16 text-center text-gray-500 flex flex-col items-center gap-3">
            <div class="animate-spin w-6 h-6 border-2 border-indigo-500 border-t-transparent rounded-full"></div>
            <p class="text-xs font-mono">Loading PHP versions...</p>
          </div>
          <div v-else-if="versions.length === 0" class="p-16 text-center text-gray-500 text-sm italic">No PHP versions installed</div>

          <div v-for="v in versions" :key="v.version" 
               class="grid grid-cols-12 gap-4 p-4 items-center border-b border-white/5 last:border-0 hover:bg-white/5 transition-colors">
            <div class="col-span-2 font-bold text-gray-200">PHP {{ v.version }}</div>
            <div class="col-span-2">
              <span :class="getStatusColor(v.status)" class="px-2 py-0.5 rounded-md text-[10px] border font-bold uppercase tracking-wide">
                {{ v.status }}
              </span>
            </div>
            <div class="col-span-2">
              <Check v-if="v.is_default" class="text-green-500" :size="18" />
              <span v-else class="text-gray-600 font-mono text-xs">-</span>
            </div>
            <div class="col-span-4 text-gray-500 text-[11px] font-mono truncate" :title="v.fpm_socket">{{ v.fpm_socket }}</div>
            <div class="col-span-2 flex items-center justify-end space-x-1">
              <button v-if="!v.is_default" @click="switchVersion(v.version)" 
                      class="px-2 py-1 text-[10px] bg-white/5 hover:bg-white/10 rounded-md text-gray-300 font-bold uppercase tracking-tighter" title="Set as System Default">
                Def
              </button>
              <button @click="openExtensionsPanel(v.version)" 
                      class="p-2 hover:bg-amber-500/10 rounded-lg text-gray-500 hover:text-amber-500 transition-colors" title="Extensions">
                <Puzzle :size="16" />
              </button>
              <button @click="restartFPM(v.version)" 
                      class="p-2 hover:bg-blue-500/10 rounded-lg text-gray-500 hover:text-blue-500 transition-colors" title="Restart FPM">
                <RotateCw :size="16" />
              </button>
              <button @click="viewConfig(v.version)" 
                      class="p-2 hover:bg-purple-500/10 rounded-lg text-gray-500 hover:text-purple-500 transition-colors" title="Settings">
                <Settings :size="16" />
              </button>
            </div>
          </div>
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

    <!-- Extensions Modal -->
    <div v-if="showExtensions" class="fixed inset-0 bg-black/70 flex items-center justify-center z-50 p-4" @click.self="showExtensions = false">
      <div class="bg-gray-900 border border-white/10 rounded-xl w-full max-w-2xl max-h-[80vh] flex flex-col">
        <!-- Header -->
        <div class="p-6 border-b border-white/10">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-lg font-bold text-white flex items-center gap-2">
                <Puzzle class="text-amber-400" :size="20" />
                PHP {{ selectedVersionForExt }} Extensions
              </h3>
              <p class="text-xs text-gray-500 mt-1">Install and manage PHP extensions</p>
            </div>
            <select v-model="selectedVersionForExt" class="bg-black/30 border border-white/10 rounded-lg px-3 py-2 text-white text-sm">
              <option v-for="v in versions" :key="v.version" :value="v.version">PHP {{ v.version }}</option>
            </select>
          </div>
        </div>
        
        <!-- Extensions Grid -->
        <div class="flex-1 overflow-y-auto p-6">
          <div v-if="loadingExtensions" class="flex items-center justify-center py-12">
            <div class="animate-spin w-6 h-6 border-2 border-amber-500 border-t-transparent rounded-full"></div>
          </div>
          
          <div v-else class="grid grid-cols-2 sm:grid-cols-3 gap-3">
            <div v-for="ext in extensions" :key="ext.name" 
                 class="bg-black/30 border rounded-lg p-3 transition-all"
                 :class="ext.installed ? 'border-green-500/30' : 'border-white/10 hover:border-amber-500/30'">
              <div class="flex items-center justify-between">
                <div class="flex items-center gap-2">
                  <span class="text-lg">{{ getExtIcon(ext.name) }}</span>
                  <div>
                    <p class="text-sm font-medium text-white">{{ ext.name }}</p>
                    <span v-if="ext.installed" class="text-[10px] text-green-400 font-bold uppercase">Installed</span>
                    <span v-else class="text-[10px] text-gray-500 uppercase">Not Installed</span>
                  </div>
                </div>
                <button v-if="!ext.installed" 
                        @click="installExtension(ext.name)"
                        :disabled="installingExt === ext.name"
                        class="px-2 py-1 bg-amber-500/20 hover:bg-amber-500/30 border border-amber-500/30 rounded text-amber-400 text-[10px] font-bold uppercase transition-colors disabled:opacity-50">
                  {{ installingExt === ext.name ? '...' : 'Install' }}
                </button>
                <Check v-else class="text-green-500" :size="18" />
              </div>
            </div>
          </div>
          
          <!-- Quick Install Popular -->
          <div class="mt-6 p-4 bg-amber-500/10 border border-amber-500/20 rounded-lg">
            <h4 class="text-sm font-bold text-amber-400 mb-2">💡 Quick Tip</h4>
            <p class="text-xs text-gray-400">For WordPress with Redis caching, install: <strong class="text-white">redis</strong>, <strong class="text-white">opcache</strong>, <strong class="text-white">imagick</strong></p>
          </div>
        </div>
        
        <!-- Footer -->
        <div class="p-4 border-t border-white/10">
          <button @click="showExtensions = false" class="w-full py-2.5 bg-white/10 hover:bg-white/20 rounded-lg text-white font-bold transition-colors">Close</button>
        </div>
      </div>
    </div>
  </div>
</template>
