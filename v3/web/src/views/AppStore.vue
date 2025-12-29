<script setup>
import { ref, onMounted, computed } from 'vue'
import axios from 'axios'
import { Store, Download, Trash2, Check, ExternalLink, AlertTriangle, Package, Server, Container } from 'lucide-vue-next'
import { useAuthStore } from '../stores/auth'

const authStore = useAuthStore()
const apps = ref([])
const loading = ref(false)
const installing = ref('')
const dockerInstalled = ref(true)
const installingDocker = ref(false)
const activeTab = ref('system') // 'system' or 'docker'

// Get hostname for app URLs
const hostname = computed(() => {
  if (typeof window !== 'undefined' && window.location) {
    return window.location.hostname
  }
  return 'localhost'
})

// Filter apps by type
const systemApps = computed(() => apps.value.filter(app => app.docker_image === 'system'))
const dockerApps = computed(() => apps.value.filter(app => app.docker_image !== 'system'))

const fetchApps = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/apps/', {
      headers: { Authorization: `Bearer ${authStore.token}` }
    })
    apps.value = res.data || []
    dockerInstalled.value = true
  } catch (err) {
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
    await axios.post('/api/system/install-docker', {}, {
      headers: { Authorization: `Bearer ${authStore.token}` }
    })
    alert('Docker installed successfully! Refreshing...')
    fetchApps()
  } catch (err) {
    alert('Failed to install Docker: ' + (err.response?.data?.error || err.message))
  } finally {
    installingDocker.value = false
  }
}

const installApp = async (slug, isSystem = false) => {
  // Only check Docker for non-system apps
  if (!isSystem && !dockerInstalled.value) {
    alert('Please install Docker first!')
    return
  }
  installing.value = slug
  try {
    await axios.post(`/api/apps/${slug}/install`, {}, {
      headers: { Authorization: `Bearer ${authStore.token}` }
    })
    fetchApps()
    alert('Installation completed successfully!')
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
    await axios.post(`/api/apps/${slug}/uninstall`, {}, {
      headers: { Authorization: `Bearer ${authStore.token}` }
    })
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
        <p class="text-sm mt-1" style="color: var(--text-muted);">One-click install system tools and Docker applications</p>
      </div>
    </div>

    <!-- Tabs -->
    <div class="flex gap-2 border-b border-white/10 pb-0">
      <button 
        @click="activeTab = 'system'"
        class="flex items-center gap-2 px-4 py-3 text-sm font-medium transition-all border-b-2 -mb-px"
        :class="activeTab === 'system' 
          ? 'border-green-500 text-green-400' 
          : 'border-transparent text-gray-400 hover:text-white'"
      >
        <Server :size="16" />
        System Tools
        <span class="ml-1 px-1.5 py-0.5 text-xs rounded-full bg-green-500/20 text-green-400">{{ systemApps.length }}</span>
      </button>
      <button 
        @click="activeTab = 'docker'"
        class="flex items-center gap-2 px-4 py-3 text-sm font-medium transition-all border-b-2 -mb-px"
        :class="activeTab === 'docker' 
          ? 'border-blue-500 text-blue-400' 
          : 'border-transparent text-gray-400 hover:text-white'"
      >
        <Container :size="16" />
        Docker Apps
        <span class="ml-1 px-1.5 py-0.5 text-xs rounded-full bg-blue-500/20 text-blue-400">{{ dockerApps.length }}</span>
      </button>
    </div>

    <!-- Docker Not Installed Warning (only on Docker tab) -->
    <div v-if="activeTab === 'docker' && !dockerInstalled" class="panda-card !border-amber-500/30 !bg-amber-500/5">
      <div class="flex items-start gap-4">
        <div class="p-3 rounded-xl bg-amber-500/10">
          <AlertTriangle :size="24" class="text-amber-500" />
        </div>
        <div class="flex-1">
          <h3 class="text-base font-semibold text-amber-400 mb-1">Docker Required</h3>
          <p class="text-sm text-gray-400 mb-4">
            Docker Apps require Docker to be installed on this server.
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

    <!-- System Tools Tab -->
    <div v-else-if="activeTab === 'system'" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
      <div v-for="app in systemApps" :key="app.slug" 
           class="panda-card hover:border-green-500/30 transition-all group">
        <div class="flex items-start justify-between mb-4">
          <div class="text-4xl">{{ app.icon }}</div>
          <span v-if="app.installed" class="panda-badge panda-badge-success text-[10px]">
            Installed
          </span>
          <span v-else class="text-xs px-2 py-1 rounded bg-green-500/10 text-green-400 font-medium">
            System
          </span>
        </div>
        <h3 class="text-lg font-semibold mb-1" style="color: var(--text-primary);">{{ app.name }}</h3>
        <p class="text-sm mb-4" style="color: var(--text-muted);">{{ app.description }}</p>
        
        <div v-if="app.port > 0" class="text-xs font-mono px-2 py-1 rounded bg-black/20 inline-block mb-4" style="color: var(--text-muted);">
          Port: {{ app.port }}
        </div>
        
        <div class="flex gap-2">
          <button v-if="!app.installed" 
                  @click="installApp(app.slug, true)" 
                  :disabled="installing === app.slug"
                  class="flex-1 py-2.5 bg-green-600 hover:bg-green-700 text-white rounded-lg flex items-center justify-center gap-2 disabled:opacity-50 text-sm font-medium transition-all">
            <Download :size="16" />
            {{ installing === app.slug ? 'Installing...' : 'Install' }}
          </button>
          <template v-else>
            <div class="flex-1 py-2.5 bg-green-500/10 rounded-lg flex items-center justify-center gap-2 text-sm font-medium text-green-400">
              <Check :size="16" /> Installed
            </div>
          </template>
        </div>
      </div>

      <div v-if="systemApps.length === 0 && !loading" class="col-span-full text-center py-16 opacity-40">
        <Server :size="48" class="mx-auto mb-4" />
        <p class="text-sm">No system tools available</p>
      </div>
    </div>

    <!-- Docker Apps Tab -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
      <div v-for="app in dockerApps" :key="app.slug" 
           class="panda-card hover:border-blue-500/30 transition-all group"
           :class="{ 'opacity-50': !dockerInstalled }">
        <div class="flex items-start justify-between mb-4">
          <div class="text-4xl">{{ app.icon }}</div>
          <span v-if="app.installed" class="panda-badge panda-badge-success text-[10px]">
            Installed
          </span>
          <span v-else class="text-xs px-2 py-1 rounded bg-blue-500/10 text-blue-400 font-medium">
            Docker
          </span>
        </div>
        <h3 class="text-lg font-semibold mb-1" style="color: var(--text-primary);">{{ app.name }}</h3>
        <p class="text-sm mb-4" style="color: var(--text-muted);">{{ app.description }}</p>
        <div class="text-xs font-mono px-2 py-1 rounded bg-black/20 inline-block mb-4" style="color: var(--text-muted);">
          Port: {{ app.port }}
        </div>
        
        <div class="flex gap-2">
          <button v-if="!app.installed" 
                  @click="installApp(app.slug, false)" 
                  :disabled="installing === app.slug || !dockerInstalled"
                  class="flex-1 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg flex items-center justify-center gap-2 disabled:opacity-50 text-sm font-medium transition-all">
            <Download :size="16" />
            {{ installing === app.slug ? 'Installing...' : 'Install' }}
          </button>
          <template v-else>
            <a :href="'http://' + hostname + ':' + app.port" target="_blank"
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

      <div v-if="dockerApps.length === 0 && !loading" class="col-span-full text-center py-16 opacity-40">
        <Container :size="48" class="mx-auto mb-4" />
        <p class="text-sm">No Docker apps available</p>
      </div>
    </div>
  </div>
</template>
