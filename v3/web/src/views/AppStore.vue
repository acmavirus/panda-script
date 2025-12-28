<script setup>
import { ref, onMounted, computed } from 'vue'
import axios from 'axios'
import { Store, Download, Trash2, Check, ExternalLink, AlertTriangle, Package } from 'lucide-vue-next'
import { useAuthStore } from '../stores/auth'

const authStore = useAuthStore()
const apps = ref([])
const loading = ref(false)
const installing = ref('')
const dockerInstalled = ref(true)
const installingDocker = ref(false)

const fetchApps = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/apps/')
    apps.value = res.data || []
    dockerInstalled.value = true
  } catch (err) {
    // If error contains docker-related message, Docker is not installed
    if (err.response?.data?.error?.toLowerCase().includes('docker')) {
      dockerInstalled.value = false
    }
    console.error(err)
  } finally {
    loading.value = false
  }
}

const installDocker = async () => {
  installingDocker.value = true
  try {
    // Call a simple endpoint or just try to install
    await axios.post('/api/system/install-docker')
    alert('Docker installed successfully! Refreshing...')
    fetchApps()
  } catch (err) {
    alert('Failed to install Docker: ' + (err.response?.data?.error || err.message))
  } finally {
    installingDocker.value = false
  }
}

const installApp = async (slug) => {
  if (!dockerInstalled.value) {
    alert('Please install Docker first!')
    return
  }
  installing.value = slug
  try {
    await axios.post(`/api/apps/${slug}/install`)
    fetchApps()
    alert('App installed successfully!')
  } catch (err) {
    const errorMsg = err.response?.data?.error || err.message
    if (errorMsg.toLowerCase().includes('docker')) {
      dockerInstalled.value = false
      alert('Docker is not installed. Please install Docker first.')
    } else {
      alert('Failed: ' + errorMsg)
    }
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
  <div class="p-4 lg:p-8 space-y-6 max-w-7xl mx-auto">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h2 class="text-xl lg:text-2xl font-bold tracking-tight flex items-center gap-2" style="color: var(--text-primary);">
          <Store class="text-pink-400" :size="24" />
          Panda App Store
        </h2>
        <p class="text-sm mt-1" style="color: var(--text-muted);">One-click install popular applications via Docker</p>
      </div>
    </div>

    <!-- Docker Not Installed Warning -->
    <div v-if="!dockerInstalled" class="panda-card !border-amber-500/30 !bg-amber-500/5">
      <div class="flex items-start gap-4">
        <div class="p-3 rounded-xl bg-amber-500/10">
          <AlertTriangle :size="24" class="text-amber-500" />
        </div>
        <div class="flex-1">
          <h3 class="text-base font-semibold text-amber-400 mb-1">Docker Required</h3>
          <p class="text-sm text-gray-400 mb-4">
            App Store requires Docker to install and run applications. Docker is not currently installed on this server.
          </p>
          <button 
            @click="installDocker"
            :disabled="installingDocker"
            class="px-4 py-2 bg-amber-600 hover:bg-amber-700 text-white rounded-lg font-medium text-sm flex items-center gap-2 disabled:opacity-50"
          >
            <Download v-if="!installingDocker" :size="16" />
            <Package v-else :size="16" class="animate-pulse" />
            {{ installingDocker ? 'Installing Docker...' : 'Install Docker Now' }}
          </button>
        </div>
      </div>
    </div>

    <div v-if="loading" class="text-center py-16 opacity-50">
      <Package :size="48" class="mx-auto mb-4 animate-pulse" />
      <p class="text-sm">Loading apps...</p>
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
      <div v-for="app in apps" :key="app.slug" 
           class="panda-card hover:border-pink-500/30 transition-all group"
           :class="{ 'opacity-50': !dockerInstalled }">
        <div class="flex items-start justify-between mb-4">
          <div class="text-4xl">{{ app.icon }}</div>
          <span v-if="app.installed" class="panda-badge panda-badge-success text-[10px]">
            Installed
          </span>
        </div>
        <h3 class="text-lg font-semibold mb-1" style="color: var(--text-primary);">{{ app.name }}</h3>
        <p class="text-sm mb-4" style="color: var(--text-muted);">{{ app.description }}</p>
        <div class="text-xs font-mono px-2 py-1 rounded bg-black/20 inline-block mb-4" style="color: var(--text-muted);">
          Port: {{ app.port }}
        </div>
        
        <div class="flex gap-2">
          <button v-if="!app.installed" 
                  @click="installApp(app.slug)" 
                  :disabled="installing === app.slug || !dockerInstalled"
                  class="flex-1 py-2.5 bg-pink-600 hover:bg-pink-700 text-white rounded-lg flex items-center justify-center gap-2 disabled:opacity-50 text-sm font-medium transition-all">
            <Download :size="16" />
            {{ installing === app.slug ? 'Installing...' : 'Install' }}
          </button>
          <template v-else>
            <a :href="'http://' + window.location.hostname + ':' + app.port" target="_blank"
               class="flex-1 py-2.5 bg-white/5 hover:bg-white/10 rounded-lg flex items-center justify-center gap-2 text-sm font-medium transition-all" style="color: var(--text-primary);">
              <ExternalLink :size="16" /> Open
            </a>
            <button @click="uninstallApp(app.slug, app.name)" 
                    class="py-2.5 px-4 bg-red-500/10 hover:bg-red-500/20 text-red-400 rounded-lg transition-all">
              <Trash2 :size="16" />
            </button>
          </template>
        </div>
      </div>

      <!-- Empty state when no apps -->
      <div v-if="apps.length === 0 && !loading" class="col-span-full text-center py-16 opacity-40">
        <Store :size="48" class="mx-auto mb-4" />
        <p class="text-sm">No apps available</p>
      </div>
    </div>
  </div>
</template>
