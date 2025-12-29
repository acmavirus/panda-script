<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import { Plus, Trash2, Globe, ExternalLink, Lock, Shield, FolderOpen, RefreshCw } from 'lucide-vue-next'
import Skeleton from '../components/Skeleton.vue'

const websites = ref([])
const showCreateModal = ref(false)
const newWebsite = ref({
  domain: '',
  port: 80,
  root: '/home',
  ssl: false
})
const loading = ref(true)
const creating = ref(false)
const creatingSSL = ref([]) // Queue of domains waiting for SSL
const error = ref('')
const success = ref('')

const fetchWebsites = async () => {
  try {
    loading.value = true
    const response = await axios.get('/api/websites')
    websites.value = response.data || []
  } catch (err) {
    console.error('Failed to fetch websites:', err)
    error.value = 'Failed to load websites'
  } finally {
    loading.value = false
  }
}

const createWebsite = async () => {
  try {
    creating.value = true
    newWebsite.value.port = parseInt(newWebsite.value.port)
    
    // Optimistic UI - add immediately
    const tempSite = { ...newWebsite.value, _creating: true }
    websites.value.unshift(tempSite)
    showCreateModal.value = false
    
    await axios.post('/api/websites', newWebsite.value)
    success.value = `Website ${newWebsite.value.domain} created successfully!`
    newWebsite.value = { domain: '', port: 80, root: '/home', ssl: false }
    await fetchWebsites()
  } catch (err) {
    // Remove optimistic entry on error
    websites.value = websites.value.filter(w => !w._creating)
    error.value = err.response?.data?.error || 'Failed to create website'
  } finally {
    creating.value = false
  }
}

const createSSL = async (domain) => {
  if (!confirm(`Create SSL certificate for ${domain}?\n\nThis will use Let's Encrypt to generate a free SSL certificate.`)) return
  
  if (creatingSSL.value.includes(domain)) return
  creatingSSL.value.push(domain)
  
  try {
    await axios.post(`/api/websites/${domain}/ssl`)
    success.value = `SSL certificate created for ${domain}!`
    await fetchWebsites()
  } catch (err) {
    error.value = err.response?.data?.error || 'Failed to create SSL certificate'
  } finally {
    creatingSSL.value = creatingSSL.value.filter(d => d !== domain)
  }
}

const deleteWebsite = async (domain) => {
  if (!confirm(`Delete ${domain}?\n\nNote: Web files will NOT be deleted.`)) return
  
  // Optimistic UI - mark as deleting
  const site = websites.value.find(w => w.domain === domain)
  if (site) site._deleting = true
  
  try {
    await axios.delete(`/api/websites/${domain}`)
    websites.value = websites.value.filter(w => w.domain !== domain)
  } catch (err) {
    if (site) site._deleting = false
    error.value = 'Failed to delete website'
  }
}

onMounted(fetchWebsites)
</script>

<template>
  <div class="space-y-6 max-w-7xl mx-auto">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-2xl font-semibold" style="color: var(--text-primary);">Sites</h1>
        <p class="text-sm mt-1" style="color: var(--text-muted);">Manage your Nginx virtual hosts with SSL</p>
      </div>
      <div class="flex gap-2">
        <button @click="fetchWebsites" class="panda-btn panda-btn-secondary">
          <RefreshCw :size="16" :class="{ 'animate-spin': loading }" />
        </button>
        <button @click="showCreateModal = true" class="panda-btn panda-btn-primary">
          <Plus :size="16" />
          <span>Add Site</span>
        </button>
      </div>
    </div>

    <!-- Success Alert -->
    <div 
      v-if="success" 
      class="flex items-center justify-between px-4 py-3 rounded-lg text-sm"
      style="background: var(--color-success-subtle); color: var(--color-success);"
    >
      <span>{{ success }}</span>
      <button @click="success = ''" class="hover:opacity-70">&times;</button>
    </div>

    <!-- Error Alert -->
    <div 
      v-if="error" 
      class="flex items-center justify-between px-4 py-3 rounded-lg text-sm"
      style="background: var(--color-error-subtle); color: var(--color-error);"
    >
      <span>{{ error }}</span>
      <button @click="error = ''" class="hover:opacity-70">&times;</button>
    </div>

    <!-- Websites Table (Minimal, Border-less) -->
    <div class="panda-card !p-0 overflow-hidden" v-if="!loading">
      <table class="panda-table">
        <thead>
          <tr>
            <th>Domain</th>
            <th class="hidden md:table-cell">Root</th>
            <th class="hidden sm:table-cell">SSL</th>
            <th class="w-32"></th>
          </tr>
        </thead>
        <tbody>
          <tr 
            v-for="site in websites" 
            :key="site.domain"
            :class="{ 'opacity-50': site._deleting, 'animate-pulse': site._creating }"
          >
            <td>
              <div class="flex items-center gap-3">
                <div 
                  class="w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0"
                  :style="site.ssl ? 'background: rgba(34, 197, 94, 0.1);' : 'background: var(--color-primary-subtle);'"
                >
                  <Lock v-if="site.ssl" :size="16" style="color: #22c55e;" />
                  <Globe v-else :size="16" style="color: var(--color-primary);" />
                </div>
                <div>
                  <div class="font-medium" style="color: var(--text-primary);">{{ site.domain }}</div>
                  <div class="text-xs" style="color: var(--text-muted);">
                    {{ site.ssl ? 'HTTPS' : 'HTTP' }} • Port {{ site.port }}
                  </div>
                </div>
              </div>
            </td>
            <td class="hidden md:table-cell">
              <code class="text-xs px-2 py-1 rounded" style="background: var(--bg-surface); color: var(--text-secondary);">
                {{ site.root }}
              </code>
            </td>
            <td class="hidden sm:table-cell">
              <div v-if="site.ssl" class="flex flex-col">
                <span class="panda-badge panda-badge-success">
                  <Lock :size="10" class="mr-1" /> Secured
                </span>
                <span v-if="site.ssl_expiry" class="text-[10px] mt-1" style="color: var(--text-muted);">
                  {{ site.ssl_expiry }}
                </span>
              </div>
              <button 
                v-else
                @click="createSSL(site.domain)"
                :disabled="creatingSSL.includes(site.domain)"
                class="panda-btn panda-btn-ghost text-xs px-3 py-1.5 gap-1"
                style="color: var(--color-warning);"
              >
                <Shield :size="12" />
                <span v-if="creatingSSL.includes(site.domain)">
                  {{ creatingSSL[0] === site.domain ? 'Creating...' : 'Waiting...' }}
                </span>
                <span v-else>Add SSL</span>
              </button>
            </td>
            <td>
              <!-- Actions - Always Visible -->
              <div class="flex items-center gap-1 justify-end">
                <a 
                  :href="(site.ssl ? 'https://' : 'http://') + site.domain" 
                  target="_blank"
                  class="panda-btn panda-btn-ghost p-2"
                  data-tooltip="Visit"
                >
                  <ExternalLink :size="14" />
                </a>
                <router-link 
                  :to="'/panda/files?path=/home/' + site.domain"
                  class="panda-btn panda-btn-ghost p-2"
                  data-tooltip="Files"
                >
                  <FolderOpen :size="14" />
                </router-link>
                <button 
                  v-if="!site.ssl"
                  @click="createSSL(site.domain)"
                  :disabled="creatingSSL.includes(site.domain)"
                  class="panda-btn panda-btn-ghost p-2 sm:hidden"
                  data-tooltip="Add SSL"
                >
                  <Shield :size="14" style="color: var(--color-warning);" />
                </button>
                <button 
                  @click="deleteWebsite(site.domain)"
                  class="panda-btn panda-btn-danger p-2"
                  data-tooltip="Delete"
                >
                  <Trash2 :size="14" />
                </button>
              </div>
            </td>
          </tr>
          
          <!-- Empty State -->
          <tr v-if="websites.length === 0">
            <td colspan="4" class="text-center py-16">
              <Globe :size="40" class="mx-auto mb-3 opacity-20" />
              <p style="color: var(--text-muted);">No sites configured</p>
              <button @click="showCreateModal = true" class="panda-btn panda-btn-secondary mt-4">
                <Plus :size="14" />
                Add your first site
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Loading Skeleton -->
    <div v-if="loading" class="panda-card !p-0 overflow-hidden">
      <table class="panda-table">
        <thead>
          <tr>
            <th>Domain</th>
            <th class="hidden md:table-cell">Root</th>
            <th class="hidden sm:table-cell">SSL</th>
            <th class="w-32"></th>
          </tr>
        </thead>
        <tbody>
          <Skeleton v-for="n in 3" :key="n" :loading="true" type="table-row" :columns="4" />
        </tbody>
      </table>
    </div>

    <!-- Create Modal -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="showCreateModal" class="fixed inset-0 z-50 flex items-center justify-center p-4" style="background: rgba(0,0,0,0.6); backdrop-filter: blur(4px);">
          <div 
            class="w-full max-w-md rounded-xl overflow-hidden"
            style="background: var(--bg-elevated); border: 1px solid var(--border-color);"
            @click.stop
          >
            <!-- Modal Header -->
            <div class="px-6 py-4 border-b" style="border-color: var(--border-color);">
              <h3 class="text-lg font-semibold" style="color: var(--text-primary);">New Site</h3>
            </div>
            
            <!-- Modal Body -->
            <form @submit.prevent="createWebsite" class="p-6 space-y-5">
              <div>
                <label class="block text-sm font-medium mb-2" style="color: var(--text-secondary);">Domain</label>
                <input 
                  v-model="newWebsite.domain" 
                  type="text" 
                  required 
                  placeholder="example.com"
                  class="panda-input"
                  autofocus
                >
              </div>
              
              <div class="grid grid-cols-3 gap-4">
                <div>
                  <label class="block text-sm font-medium mb-2" style="color: var(--text-secondary);">Port</label>
                  <input 
                    v-model="newWebsite.port" 
                    type="number" 
                    required
                    class="panda-input"
                  >
                </div>
                <div class="col-span-2">
                  <label class="block text-sm font-medium mb-2" style="color: var(--text-secondary);">Root</label>
                  <input 
                    v-model="newWebsite.root" 
                    type="text" 
                    required
                    class="panda-input"
                    :placeholder="'/home/' + (newWebsite.domain || 'example.com')"
                  >
                </div>
              </div>

              <div class="flex items-center gap-3 p-3 rounded-lg" style="background: var(--bg-surface);">
                <label class="relative inline-flex items-center cursor-pointer">
                  <input type="checkbox" v-model="newWebsite.ssl" class="sr-only peer">
                  <div class="w-10 h-5 rounded-full peer peer-checked:after:translate-x-5 after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:rounded-full after:h-4 after:w-4 after:transition-all" 
                       style="background: var(--bg-active);"
                       :style="newWebsite.ssl ? 'background: var(--color-success);' : ''">
                    <div class="absolute top-[2px] left-[2px] w-4 h-4 rounded-full transition-transform" 
                         :style="{ background: 'white', transform: newWebsite.ssl ? 'translateX(20px)' : 'translateX(0)' }"></div>
                  </div>
                </label>
                <div>
                  <span class="text-sm font-medium" style="color: var(--text-primary);">Enable SSL</span>
                  <p class="text-xs" style="color: var(--text-muted);">Automatically generate Let's Encrypt certificate</p>
                </div>
              </div>
            </form>
            
            <!-- Modal Footer -->
            <div class="px-6 py-4 flex gap-3 border-t" style="border-color: var(--border-color); background: var(--bg-surface);">
              <button @click="showCreateModal = false" class="flex-1 panda-btn panda-btn-secondary">
                Cancel
              </button>
              <button @click="createWebsite" :disabled="creating || !newWebsite.domain" class="flex-1 panda-btn panda-btn-primary">
                {{ creating ? 'Creating...' : 'Create Site' }}
              </button>
            </div>
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
