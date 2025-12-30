<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import { Box, Play, Square, RotateCw, Activity, Terminal } from 'lucide-vue-next'
import { useToastStore } from '../stores/toast'
const toast = useToastStore()

const containers = ref([])
const loading = ref(false)
const error = ref('')

const fetchContainers = async () => {
  loading.value = true
  error.value = ''
  try {
    const res = await axios.get('/api/docker/containers')
    containers.value = res.data || []
  } catch (err) {
    error.value = err.response?.data?.error || 'Failed to load containers'
  } finally {
    loading.value = false
  }
}

const containerAction = async (id, action) => {
  try {
    await axios.post(`/api/docker/containers/${id}/${action}`)
    fetchContainers()
  } catch (err) {
    toast.error(`Failed to ${action} container: ` + (err.response?.data?.error || err.message))
  }
}

onMounted(() => {
  fetchContainers()
})
</script>

<template>
  <div class="p-8">
    <div class="flex items-center justify-between mb-8">
      <div>
        <h2 class="text-2xl font-bold text-white tracking-tight flex items-center gap-2">
          <Box class="text-blue-400" />
          Docker Containers
        </h2>
        <p class="text-gray-500 mt-1">Manage your Docker containers</p>
      </div>
      <button @click="fetchContainers" class="p-2 bg-white/5 rounded-lg hover:bg-white/10 transition-colors">
        <RotateCw :size="20" class="text-gray-400" />
      </button>
    </div>

    <div v-if="error" class="bg-red-500/10 border border-red-500/20 text-red-400 p-4 rounded-xl mb-6">
      {{ error }}
    </div>

    <div class="bg-black/20 border border-white/5 rounded-xl overflow-hidden">
      <div class="grid grid-cols-12 gap-4 p-4 border-b border-white/5 text-xs font-medium text-gray-500 uppercase tracking-wider">
        <div class="col-span-3">Name</div>
        <div class="col-span-3">Image</div>
        <div class="col-span-2">Status</div>
        <div class="col-span-2">State</div>
        <div class="col-span-2 text-right">Actions</div>
      </div>

      <div v-if="loading" class="p-8 text-center text-gray-500">Loading...</div>
      <div v-else-if="containers.length === 0" class="p-8 text-center text-gray-500">No containers found</div>

      <div v-for="container in containers" :key="container.id" 
           class="grid grid-cols-12 gap-4 p-4 items-center border-b border-white/5 last:border-0 hover:bg-white/5 transition-colors">
        <div class="col-span-3 font-medium text-white truncate" :title="container.names">{{ container.names }}</div>
        <div class="col-span-3 text-gray-400 truncate" :title="container.image">{{ container.image }}</div>
        <div class="col-span-2 text-sm text-gray-400">{{ container.status }}</div>
        <div class="col-span-2">
          <span :class="container.state === 'running' ? 'bg-green-500/10 text-green-400 border-green-500/20' : 'bg-gray-500/10 text-gray-400 border-gray-500/20'"
                class="px-2 py-1 rounded-md text-xs border font-medium uppercase">
            {{ container.state }}
          </span>
        </div>
        <div class="col-span-2 flex items-center justify-end space-x-2">
          <button v-if="container.state !== 'running'" @click="containerAction(container.id, 'start')" 
                  class="p-1.5 hover:bg-green-500/10 rounded-lg text-gray-400 hover:text-green-500 transition-colors" title="Start">
            <Play :size="16" />
          </button>
          <button v-if="container.state === 'running'" @click="containerAction(container.id, 'stop')" 
                  class="p-1.5 hover:bg-red-500/10 rounded-lg text-gray-400 hover:text-red-500 transition-colors" title="Stop">
            <Square :size="16" />
          </button>
          <button @click="containerAction(container.id, 'restart')" 
                  class="p-1.5 hover:bg-blue-500/10 rounded-lg text-gray-400 hover:text-blue-500 transition-colors" title="Restart">
            <RotateCw :size="16" />
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
