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
const wpPath = ref('/home/')
const wpCommand = ref('core version')
const wpOutput = ref('')

const checkInstalled = async () => {
  // Check main tools status from our new endpoint
  try {
    const res = await axios.get('/api/tools/status')
    const status = res.data || {}
    tools.value.forEach(t => {
      if (status[t.id] !== undefined) {
        t.installed = status[t.id]
      }
    })
  } catch (e) {
    console.error('Failed to fetch dev tools status', e)
  }

  // Check redis/memcached specifically via services
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
  <div class="p-4 lg:p-8">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between mb-8 gap-4">
      <div>
        <h2 class="text-xl lg:text-2xl font-bold text-white tracking-tight flex items-center gap-2">
          <Wrench class="text-amber-400" :size="24" />
          Dev Tools & Extensions
        </h2>
        <p class="text-xs lg:text-sm text-gray-400 mt-1 uppercase tracking-widest font-bold">Enhance your stack</p>
      </div>
      <button @click="checkInstalled" class="p-3 sm:p-2 bg-white/5 rounded-lg hover:bg-white/10 transition-colors flex items-center justify-center">
        <RotateCw :size="18" class="text-gray-400" />
      </button>
    </div>

    <!-- Tools Grid -->
    <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4 mb-8">
      <div v-for="tool in tools" :key="tool.id"
           class="bg-black/20 border border-white/5 rounded-2xl p-5 flex items-center gap-4 hover:border-amber-500/20 transition-all shadow-xl">
        <div class="flex-1">
          <div class="font-bold text-white text-sm lg:text-base">{{ tool.name }}</div>
          <div class="text-[10px] lg:text-xs text-gray-500 uppercase font-medium tracking-tight mt-0.5">{{ tool.desc }}</div>
        </div>
        <button v-if="!tool.installed" @click="installTool(tool)" :disabled="tool.loading"
                class="px-4 py-2 bg-amber-600 hover:bg-amber-700 text-white rounded-xl flex items-center gap-2 disabled:opacity-50 text-xs font-bold transition-all shadow-lg shadow-amber-600/20">
          <Loader v-if="tool.loading" :size="14" class="animate-spin" />
          <Download v-else :size="14" />
          Install
        </button>
        <span v-else class="px-3 py-1.5 bg-green-500/10 text-green-400 rounded-lg flex items-center gap-2 text-[10px] font-black uppercase tracking-widest border border-green-500/20 shadow-lg shadow-green-500/10">
          <CheckCircle :size="14" /> Ready
        </span>
      </div>
    </div>

    <!-- WP-CLI Console -->
                    class="w-full bg-black/40 border border-white/10 rounded-xl px-4 py-2.5 text-white font-mono text-sm focus:border-blue-500/50 outline-none transition-all" />
             <button @click="runWPCLI" class="absolute right-1 top-1 h-8 w-12 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-all flex items-center justify-center">
               <Play :size="14" />
             </button>
           </div>
        </div>
      </div>
      <div class="relative group">
        <div class="absolute top-2 right-4 text-[10px] font-bold text-gray-600 uppercase tracking-widest z-10">Output Log</div>
        <pre class="bg-black/50 p-5 rounded-2xl text-[11px] text-gray-400 font-mono max-h-60 overflow-auto border border-white/5 scrollbar-thin scrollbar-thumb-white/10">{{ wpOutput || 'Wating for command input...' }}</pre>
      </div>
    </div>

    <!-- PHP Extensions -->
    <div class="bg-black/20 border border-white/5 rounded-2xl p-4 lg:p-6 shadow-2xl">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h3 class="text-base font-bold text-white uppercase tracking-widest">PHP Extensions</h3>
          <p class="text-[10px] text-gray-500 mt-0.5">Manage modules for current version</p>
        </div>
        <button @click="loadPHPExtensions" class="p-2 bg-white/5 rounded-xl hover:bg-white/10 transition-all border border-white/5">
          <RotateCw :size="16" class="text-gray-400" :class="loadingExt ? 'animate-spin' : ''" />
        </button>
      </div>
      <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
        <div v-for="ext in phpExtensions" :key="ext.name"
             class="flex items-center justify-between bg-black/30 rounded-xl p-3 border border-white/5 hover:border-white/10 transition-all">
          <div class="flex flex-col">
            <span class="text-gray-200 font-mono text-xs font-bold">{{ ext.name }}</span>
            <span class="text-[8px] text-gray-500 uppercase font-black">Module</span>
          </div>
          <span v-if="ext.installed" class="w-2 h-2 rounded-full bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.4)]" title="Active"></span>
          <button v-else @click="installExtension(ext)" class="px-2 py-1 bg-amber-500/10 hover:bg-amber-500/20 text-amber-500 text-[10px] font-black rounded-lg uppercase tracking-tighter border border-amber-500/20">
            Fix
          </button>
        </div>
      </div>
    </div>
  </div>

</template>
