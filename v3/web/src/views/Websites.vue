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
    // Ensure port is an integer
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

onMounted(() => {
  fetchWebsites()
})
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h2 class="text-2xl font-bold text-white">Websites</h2>
        <p class="text-gray-400">Manage your Nginx virtual hosts</p>
      </div>
      <button @click="showCreateModal = true" 
              class="flex items-center space-x-2 px-4 py-2 bg-panda-primary text-white rounded-xl hover:bg-panda-primary/90 transition-colors">
        <Plus :size="20" />
        <span>Add Website</span>
      </button>
    </div>

    <!-- Error Alert -->
    <div v-if="error" class="bg-red-500/10 border border-red-500/20 text-red-400 px-4 py-3 rounded-xl flex justify-between items-center">
      <span>{{ error }}</span>
      <button @click="error = ''" class="hover:text-white">&times;</button>
    </div>

    <!-- Website List -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div v-for="site in websites" :key="site.domain" 
           class="bg-white/5 border border-white/5 rounded-2xl p-6 hover:border-panda-primary/50 transition-all group">
        <div class="flex justify-between items-start mb-4">
          <div class="w-12 h-12 rounded-xl bg-panda-primary/10 flex items-center justify-center text-panda-primary">
            <Globe :size="24" />
          </div>
          <button @click="deleteWebsite(site.domain)" 
                  class="text-gray-500 hover:text-red-400 p-2 rounded-lg hover:bg-white/5 transition-colors opacity-0 group-hover:opacity-100">
            <Trash2 :size="18" />
          </button>
        </div>
        
        <h3 class="text-lg font-bold text-white mb-1">{{ site.domain }}</h3>
        <div class="space-y-2 text-sm text-gray-400">
          <div class="flex items-center space-x-2">
            <Server :size="14" />
            <span>Port: {{ site.port }}</span>
          </div>
          <div class="flex items-center space-x-2">
            <Folder :size="14" />
            <span class="truncate">{{ site.root }}</span>
          </div>
          <div class="flex items-center space-x-2">
            <span class="w-2 h-2 rounded-full" :class="site.ssl ? 'bg-green-400' : 'bg-gray-600'"></span>
            <span>{{ site.ssl ? 'SSL Enabled' : 'No SSL' }}</span>
          </div>
        </div>
      </div>

      <!-- Empty State -->
      <div v-if="websites.length === 0 && !loading" class="col-span-full flex flex-col items-center justify-center py-12 text-gray-500">
        <Globe :size="48" class="mb-4 opacity-20" />
        <p>No websites found. Create one to get started.</p>
      </div>
    </div>

    <!-- Create Modal -->
    <div v-if="showCreateModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm">
      <div class="bg-panda-dark border border-white/10 rounded-2xl w-full max-w-md p-6 shadow-2xl">
        <h3 class="text-xl font-bold text-white mb-6">Add New Website</h3>
        
        <form @submit.prevent="createWebsite" class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-400 mb-1">Domain</label>
            <input v-model="newWebsite.domain" type="text" required placeholder="example.com"
                   class="w-full bg-black/20 border border-white/10 rounded-xl px-4 py-2.5 text-white focus:border-panda-primary/50 outline-none transition-colors">
          </div>
          
          <div>
            <label class="block text-sm font-medium text-gray-400 mb-1">Port</label>
            <input v-model="newWebsite.port" type="number" required placeholder="80"
                   class="w-full bg-black/20 border border-white/10 rounded-xl px-4 py-2.5 text-white focus:border-panda-primary/50 outline-none transition-colors">
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-400 mb-1">Root Directory</label>
            <input v-model="newWebsite.root" type="text" required placeholder="/var/www/html"
                   class="w-full bg-black/20 border border-white/10 rounded-xl px-4 py-2.5 text-white focus:border-panda-primary/50 outline-none transition-colors">
          </div>

          <div class="flex items-center space-x-3 pt-2">
            <input v-model="newWebsite.ssl" type="checkbox" id="ssl"
                   class="w-5 h-5 rounded bg-black/20 border-white/10 text-panda-primary focus:ring-panda-primary/50">
            <label for="ssl" class="text-white">Enable SSL</label>
          </div>

          <div class="flex space-x-3 pt-4">
            <button type="button" @click="showCreateModal = false" 
                    class="flex-1 px-4 py-2.5 bg-white/5 text-white rounded-xl hover:bg-white/10 transition-colors">
              Cancel
            </button>
            <button type="submit" :disabled="loading"
                    class="flex-1 px-4 py-2.5 bg-panda-primary text-white rounded-xl hover:bg-panda-primary/90 transition-colors disabled:opacity-50">
              {{ loading ? 'Creating...' : 'Create Website' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>
