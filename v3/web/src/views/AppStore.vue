<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import { Store, Download, Trash2, Check, ExternalLink } from 'lucide-vue-next'

const apps = ref([])
const loading = ref(false)
const installing = ref('')

const fetchApps = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/apps/')
    apps.value = res.data || []
  } catch (err) {
    console.error(err)
  } finally {
    loading.value = false
  }
}

const installApp = async (slug) => {
  installing.value = slug
  try {
    await axios.post(`/api/apps/${slug}/install`)
    fetchApps()
    alert('App installed successfully!')
  } catch (err) {
    alert('Failed: ' + (err.response?.data?.error || err.message))
  } finally {
    installing.value = ''
  }
}

const uninstallApp = async (slug, name) => {
  if (!confirm(`Uninstall ${name}?`)) return
  try {
    await axios.post(`/api/apps/${slug}/uninstall`)
    fetchApps()
  } catch (err) {
    alert('Failed: ' + (err.response?.data?.error || err.message))
  }
}

onMounted(fetchApps)
</script>

<template>
  <div class="p-8">
    <div class="flex items-center justify-between mb-8">
      <div>
        <h2 class="text-2xl font-bold text-white tracking-tight flex items-center gap-2">
          <Store class="text-pink-400" />
          Panda App Store
        </h2>
        <p class="text-gray-500 mt-1">One-click install popular applications</p>
      </div>
    </div>

    <div v-if="loading" class="text-center text-gray-500 py-12">Loading apps...</div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div v-for="app in apps" :key="app.slug" 
           class="bg-black/20 border border-white/5 rounded-xl p-6 hover:border-white/10 transition-all">
        <div class="flex items-start justify-between mb-4">
          <div class="text-4xl">{{ app.icon }}</div>
          <span v-if="app.installed" class="bg-green-500/10 text-green-400 border border-green-500/20 px-2 py-1 rounded text-xs">
            Installed
          </span>
        </div>
        <h3 class="text-lg font-semibold text-white mb-1">{{ app.name }}</h3>
        <p class="text-sm text-gray-500 mb-4">{{ app.description }}</p>
        <div class="text-xs text-gray-600 mb-4 font-mono">Port: {{ app.port }}</div>
        
        <div class="flex gap-2">
          <button v-if="!app.installed" 
                  @click="installApp(app.slug)" 
                  :disabled="installing === app.slug"
                  class="flex-1 py-2 bg-pink-600 hover:bg-pink-700 text-white rounded-lg flex items-center justify-center gap-2 disabled:opacity-50">
            <Download :size="16" />
            {{ installing === app.slug ? 'Installing...' : 'Install' }}
          </button>
          <template v-else>
            <a :href="'http://' + window.location.hostname + ':' + app.port" target="_blank"
               class="flex-1 py-2 bg-white/5 hover:bg-white/10 text-white rounded-lg flex items-center justify-center gap-2">
              <ExternalLink :size="16" /> Open
            </a>
            <button @click="uninstallApp(app.slug, app.name)" 
                    class="py-2 px-4 bg-red-500/10 hover:bg-red-500/20 text-red-400 rounded-lg">
              <Trash2 :size="16" />
            </button>
          </template>
        </div>
      </div>
    </div>
  </div>
</template>
