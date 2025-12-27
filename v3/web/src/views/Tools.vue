<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import { Wrench, Download, CheckCircle, Loader, Play, Square, RotateCw } from 'lucide-vue-next'

const tools = ref([
  { id: 'wpcli', name: 'WP-CLI', desc: 'WordPress command line tool', installed: false, loading: false },
  { id: 'redis', name: 'Redis', desc: 'In-memory cache server', installed: false, loading: false },
  { id: 'memcached', name: 'Memcached', desc: 'Memory caching system', installed: false, loading: false },
  { id: 'rclone', name: 'Rclone', desc: 'Cloud backup sync', installed: false, loading: false },
  { id: 'clamav', name: 'ClamAV', desc: 'Malware scanner', installed: false, loading: false },
  { id: 'nodejs', name: 'Node.js + PM2', desc: 'JavaScript runtime', installed: false, loading: false },
])

const phpExtensions = ref([])
const loadingExt = ref(false)
const wpPath = ref('/var/www/')
const wpCommand = ref('core version')
const wpOutput = ref('')

const checkInstalled = async () => {
  // Check services status
  try {
    const res = await axios.get('/api/services/')
    const services = res.data || []
    tools.value.forEach(t => {
      if (t.id === 'redis') t.installed = services.some(s => s.name === 'redis' || s.name === 'redis-server')
      if (t.id === 'memcached') t.installed = services.some(s => s.name === 'memcached')
    })
  } catch (e) {}
}

const installTool = async (tool) => {
  tool.loading = true
  try {
    let url = ''
    switch (tool.id) {
      case 'wpcli': url = '/api/wordpress/wpcli/install'; break
      case 'redis': url = '/api/cache/redis/install'; break
      case 'memcached': url = '/api/cache/memcached/install'; break
      case 'rclone': url = '/api/rclone/install'; break
      case 'clamav': url = '/api/scan/clamav/install'; break
      case 'nodejs': url = '/api/nodejs/install'; break
    }
    await axios.post(url)
    tool.installed = true
    alert(tool.name + ' installed successfully!')
  } catch (err) {
    alert('Failed: ' + (err.response?.data?.error || err.message))
  } finally {
    tool.loading = false
  }
}

const loadPHPExtensions = async () => {
  loadingExt.value = true
  try {
    const res = await axios.get('/api/php/extensions?version=8.3')
    phpExtensions.value = res.data || []
  } catch (e) {}
  loadingExt.value = false
}

const installExtension = async (ext) => {
  try {
    await axios.post('/api/php/extensions/install', { version: '8.3', extension: ext.name })
    ext.installed = true
  } catch (err) {
    alert('Failed: ' + (err.response?.data?.error || err.message))
  }
}

const runWPCLI = async () => {
  wpOutput.value = 'Running...'
  try {
    const res = await axios.post('/api/wordpress/wpcli/execute', {
      path: wpPath.value,
      command: wpCommand.value
    })
    wpOutput.value = res.data?.output || 'No output'
  } catch (err) {
    wpOutput.value = 'Error: ' + (err.response?.data?.error || err.message)
  }
}

onMounted(() => {
  checkInstalled()
  loadPHPExtensions()
})
</script>

<template>
  <div class="p-8">
    <div class="flex items-center justify-between mb-8">
      <div>
        <h2 class="text-2xl font-bold text-white tracking-tight flex items-center gap-2">
          <Wrench class="text-amber-400" />
          Dev Tools
        </h2>
        <p class="text-gray-500 mt-1">Install and manage development tools</p>
      </div>
    </div>

    <!-- Tools Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-8">
      <div v-for="tool in tools" :key="tool.id"
           class="bg-black/20 border border-white/5 rounded-xl p-4 flex items-center gap-4">
        <div class="flex-1">
          <div class="font-medium text-white">{{ tool.name }}</div>
          <div class="text-sm text-gray-500">{{ tool.desc }}</div>
        </div>
        <button v-if="!tool.installed" @click="installTool(tool)" :disabled="tool.loading"
                class="px-4 py-2 bg-amber-600 hover:bg-amber-700 text-white rounded-lg flex items-center gap-2 disabled:opacity-50">
          <Loader v-if="tool.loading" :size="16" class="animate-spin" />
          <Download v-else :size="16" />
          Install
        </button>
        <span v-else class="px-4 py-2 bg-green-500/10 text-green-400 rounded-lg flex items-center gap-2">
          <CheckCircle :size="16" /> Installed
        </span>
      </div>
    </div>

    <!-- WP-CLI Console -->
    <div class="bg-black/20 border border-white/5 rounded-xl p-6 mb-8">
      <h3 class="text-lg font-semibold text-white mb-4">WP-CLI Console</h3>
      <div class="flex gap-4 mb-4">
        <input v-model="wpPath" type="text" placeholder="Path to WordPress" 
               class="flex-1 bg-black/30 border border-white/10 rounded-lg px-4 py-2 text-white font-mono" />
        <input v-model="wpCommand" type="text" placeholder="wp command" 
               class="flex-1 bg-black/30 border border-white/10 rounded-lg px-4 py-2 text-white font-mono" />
        <button @click="runWPCLI" class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg">
          <Play :size="16" />
        </button>
      </div>
      <pre class="bg-black/30 p-4 rounded-lg text-sm text-gray-300 font-mono max-h-48 overflow-auto">{{ wpOutput || 'Output will appear here...' }}</pre>
    </div>

    <!-- PHP Extensions -->
    <div class="bg-black/20 border border-white/5 rounded-xl p-6">
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-white">PHP Extensions</h3>
        <button @click="loadPHPExtensions" class="p-2 bg-white/5 rounded-lg hover:bg-white/10">
          <RotateCw :size="16" class="text-gray-400" :class="loadingExt ? 'animate-spin' : ''" />
        </button>
      </div>
      <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
        <div v-for="ext in phpExtensions" :key="ext.name"
             class="flex items-center justify-between bg-black/30 rounded-lg p-3">
          <span class="text-white font-mono text-sm">{{ ext.name }}</span>
          <span v-if="ext.installed" class="text-green-400 text-xs">✓</span>
          <button v-else @click="installExtension(ext)" class="text-xs text-amber-400 hover:text-amber-300">Install</button>
        </div>
      </div>
    </div>
  </div>
</template>
