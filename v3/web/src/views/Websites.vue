<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import { Plus, Trash2, Globe, ExternalLink, Lock, FolderOpen, Settings, MoreHorizontal } from 'lucide-vue-next'
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
const error = ref('')

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

const deleteWebsite = async (domain) => {
  if (!confirm(`Delete ${domain}?`)) return
  
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
        <p class="text-sm mt-1" style="color: var(--text-muted);">Manage your Nginx virtual hosts</p>
      </div>
      <button @click="showCreateModal = true" class="panda-btn panda-btn-primary">
        <Plus :size="16" />
        <span>Add Site</span>
      </button>
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
            <th class="w-24"></th>
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
                  style="background: var(--color-primary-subtle);"
                >
                  <Globe :size="16" style="color: var(--color-primary);" />
                </div>
                <div>
                  <div class="font-medium" style="color: var(--text-primary);">{{ site.domain }}</div>
                  <div class="text-xs" style="color: var(--text-muted);">Port {{ site.port }}</div>
                </div>
              </div>
            </td>
            <td class="hidden md:table-cell">
              <code class="text-xs px-2 py-1 rounded" style="background: var(--bg-surface); color: var(--text-secondary);">
                {{ site.root }}
              </code>
            </td>
            <td class="hidden sm:table-cell">
              <span 
                v-if="site.ssl"
                class="panda-badge panda-badge-success"
              >
                <Lock :size="10" class="mr-1" /> Secured
              </span>
              <span v-else class="panda-badge" style="background: var(--bg-surface); color: var(--text-muted);">
                No SSL
              </span>
            </td>
            <td>
              <!-- Contextual Actions - Hidden until hover -->
              <div class="contextual-actions flex items-center gap-1 justify-end">
                <a 
                  :href="(site.ssl ? 'https://' : 'http://') + site.domain" 
                  target="_blank"
                  class="panda-btn panda-btn-ghost p-2"
                  data-tooltip="Visit"
                >
                  <ExternalLink :size="14" />
                </a>
                <button class="panda-btn panda-btn-ghost p-2" data-tooltip="Files">
                  <FolderOpen :size="14" />
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
            <th class="w-24"></th>
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
                  >
                </div>
              </div>

              <div class="flex items-center gap-3 py-2">
                <label class="relative inline-flex items-center cursor-pointer">
                  <input type="checkbox" v-model="newWebsite.ssl" class="sr-only peer">
                  <div class="w-10 h-5 rounded-full peer peer-checked:after:translate-x-5 after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:rounded-full after:h-4 after:w-4 after:transition-all" 
                       style="background: var(--bg-surface);"
                       :style="newWebsite.ssl ? 'background: var(--color-primary);' : ''">
                    <div class="absolute top-[2px] left-[2px] w-4 h-4 rounded-full transition-transform" 
                         :style="{ background: 'white', transform: newWebsite.ssl ? 'translateX(20px)' : 'translateX(0)' }"></div>
                  </div>
                </label>
                <span class="text-sm" style="color: var(--text-secondary);">Enable SSL (Let's Encrypt)</span>
              </div>
            </form>
            
            <!-- Modal Footer -->
            <div class="px-6 py-4 flex gap-3 border-t" style="border-color: var(--border-color); background: var(--bg-surface);">
              <button @click="showCreateModal = false" class="flex-1 panda-btn panda-btn-secondary">
                Cancel
              </button>
              <button @click="createWebsite" :disabled="creating" class="flex-1 panda-btn panda-btn-primary">
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
