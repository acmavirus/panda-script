<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import { Plus, Trash2, Globe, Server, Folder } from 'lucide-vue-next'

const websites = ref([])
const showCreateModal = ref(false)
const newWebsite = ref({
  domain: '',
  port: 80,
  root: '/var/www/html',
  ssl: false
})
const loading = ref(false)
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
    loading.value = true
    newWebsite.value.port = parseInt(newWebsite.value.port)
    await axios.post('/api/websites', newWebsite.value)
    showCreateModal.value = false
    newWebsite.value = { domain: '', port: 80, root: '/var/www/html', ssl: false }
    await fetchWebsites()
  } catch (err) {
    console.error('Failed to create website:', err)
    error.value = err.response?.data?.error || 'Failed to create website'
  } finally {
    loading.value = false
  }
}

const deleteWebsite = async (domain) => {
  if (!confirm(`Are you sure you want to delete ${domain}?`)) return
  try {
    loading.value = true
    await axios.delete(`/api/websites/${domain}`)
    await fetchWebsites()
  } catch (err) {
    console.error('Failed to delete website:', err)
    error.value = 'Failed to delete website'
  } finally {
    loading.value = false
  }
}

onMounted(fetchWebsites)
</script>

<template>
  <div class="p-4 lg:p-8 space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h2 class="text-xl lg:text-2xl font-bold text-white tracking-tight flex items-center gap-2">
          <Globe class="text-panda-primary" :size="24" />
          Websites
        </h2>
        <p class="text-xs lg:text-sm text-gray-400">Manage your Nginx virtual hosts</p>
      </div>
      <button @click="showCreateModal = true" 
              class="w-full sm:w-auto flex items-center justify-center space-x-2 px-4 py-2 bg-panda-primary text-white rounded-xl hover:bg-panda-primary/90 transition-colors shadow-lg shadow-panda-primary/20">
        <Plus :size="18" />
        <span class="text-sm font-medium">Add Website</span>
      </button>
    </div>

    <!-- Error Alert -->
    <div v-if="error" class="bg-red-500/10 border border-red-500/20 text-red-400 px-4 py-3 rounded-xl flex justify-between items-center text-xs">
      <span>{{ error }}</span>
      <button @click="error = ''" class="hover:text-white">&times;</button>
    </div>

    <!-- Website List -->
    <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4 lg:gap-6">
      <div v-for="site in websites" :key="site.domain" 
           class="bg-white/5 border border-white/5 rounded-2xl p-5 lg:p-6 hover:border-panda-primary/50 transition-all group relative">
        <div class="flex justify-between items-start mb-4">
          <div class="w-10 h-10 lg:w-12 lg:h-12 rounded-xl bg-panda-primary/10 flex items-center justify-center text-panda-primary">
            <Globe :size="20" />
          </div>
          <button @click="deleteWebsite(site.domain)" 
                  class="text-gray-500 hover:text-red-400 p-2 rounded-lg hover:bg-white/5 transition-colors md:opacity-0 group-hover:opacity-100">
            <Trash2 :size="18" />
          </button>
        </div>
        
        <h3 class="text-lg font-bold text-white mb-1 truncate pr-8" :title="site.domain">{{ site.domain }}</h3>
        <div class="space-y-2.5 text-xs lg:text-sm text-gray-400 mt-4">
          <div class="flex items-center space-x-2">
            <Server :size="14" class="text-gray-500" />
            <span>Port: <span class="text-white">{{ site.port }}</span></span>
          </div>
          <div class="flex items-center space-x-2">
            <Folder :size="14" class="text-gray-500" />
            <span class="truncate" :title="site.root">{{ site.root }}</span>
          </div>
          <div class="flex items-center space-x-2 pt-1">
            <span class="w-2 h-2 rounded-full" :class="site.ssl ? 'bg-green-400 shadow-[0_0_8px_rgba(74,222,128,0.5)]' : 'bg-gray-600'"></span>
            <span :class="site.ssl ? 'text-green-400 font-medium' : 'text-gray-500'">{{ site.ssl ? 'SSL Secured' : 'No SSL' }}</span>
          </div>
        </div>
      </div>

      <!-- Empty State -->
      <div v-if="websites.length === 0 && !loading" class="col-span-full flex flex-col items-center justify-center py-20 text-gray-500 border border-dashed border-white/5 rounded-3xl bg-white/2">
        <Globe :size="48" class="mb-4 opacity-10" />
        <p class="text-sm">No websites configured yet</p>
      </div>
    </div>

    <!-- Create Modal -->
    <div v-if="showCreateModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-4">
      <div class="bg-panda-dark border border-white/10 rounded-2xl w-full max-w-md p-6 shadow-2xl">
        <h3 class="text-xl font-bold text-white mb-6">Add New Website</h3>
        
        <form @submit.prevent="createWebsite" class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-400 mb-1.5">Domain Name</label>
            <input v-model="newWebsite.domain" type="text" required placeholder="example.com"
                   class="w-full bg-black/20 border border-white/10 rounded-xl px-4 py-3 text-white focus:border-panda-primary/50 outline-none transition-colors text-sm">
          </div>
          
          <div class="grid grid-cols-3 gap-4">
            <div class="col-span-1">
              <label class="block text-sm font-medium text-gray-400 mb-1.5">Port</label>
              <input v-model="newWebsite.port" type="number" required placeholder="80"
                     class="w-full bg-black/20 border border-white/10 rounded-xl px-4 py-3 text-white focus:border-panda-primary/50 outline-none transition-colors text-sm">
            </div>
            <div class="col-span-2 text-xs text-gray-500 flex items-end pb-3 italic">
              * Default is 80 (HTTP)
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-400 mb-1.5">Root Directory</label>
            <input v-model="newWebsite.root" type="text" required placeholder="/var/www/html"
                   class="w-full bg-black/20 border border-white/10 rounded-xl px-4 py-3 text-white focus:border-panda-primary/50 outline-none transition-colors text-sm">
          </div>

          <div class="flex items-center space-x-3 py-2">
            <label class="relative inline-flex items-center cursor-pointer">
              <input type="checkbox" v-model="newWebsite.ssl" class="sr-only peer">
              <div class="w-11 h-6 bg-white/10 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-panda-primary"></div>
              <span class="ml-3 text-sm font-medium text-gray-300">Auto-configure SSL</span>
            </label>
          </div>

          <div class="flex space-x-3 pt-6">
            <button type="button" @click="showCreateModal = false" 
                    class="flex-1 px-4 py-3 bg-white/5 text-white rounded-xl hover:bg-white/10 transition-colors text-sm font-medium">
              Cancel
            </button>
            <button type="submit" :disabled="loading"
                    class="flex-1 px-4 py-3 bg-panda-primary text-white rounded-xl hover:bg-panda-primary/90 transition-all font-medium text-sm disabled:opacity-50">
              {{ loading ? 'Configuring...' : 'Create VHost' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>
