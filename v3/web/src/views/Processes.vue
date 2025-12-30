<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import axios from 'axios'
import { Cpu, RotateCw, XCircle } from 'lucide-vue-next'
import { useToastStore } from '../stores/toast'
const toast = useToastStore()

const processes = ref([])
const loading = ref(false)
const error = ref('')
let interval = null

const fetchProcesses = async () => {
  loading.value = true
  error.value = ''
  try {
    const res = await axios.get('/api/processes/')
    processes.value = res.data || []
  } catch (err) {
    error.value = err.response?.data?.error || 'Failed to load processes'
  } finally {
    loading.value = false
  }
}

const killProcess = async (pid) => {
  if (!confirm(`Kill process ${pid}?`)) return
  try {
    await axios.delete(`/api/processes/${pid}`)
    fetchProcesses()
  } catch (err) {
    toast.error('Failed: ' + (err.response?.data?.error || err.message))
  }
}

onMounted(() => {
  fetchProcesses()
  interval = setInterval(fetchProcesses, 5000)
})

onUnmounted(() => {
  clearInterval(interval)
})
</script>

<template>
  <div class="p-4 lg:p-8">
    <div class="flex items-center justify-between mb-8">
      <div>
        <h2 class="text-2xl font-bold text-white tracking-tight flex items-center gap-2">
          <Cpu class="text-red-400" />
          Top Processes
        </h2>
        <p class="text-gray-500 mt-1 text-sm">Real-time monitoring (auto-refresh 5s)</p>
      </div>
      <button @click="fetchProcesses" class="p-2 bg-white/5 rounded-lg hover:bg-white/10 transition-colors">
        <RotateCw :size="20" :class="{'animate-spin': loading}" class="text-gray-400" />
      </button>
    </div>

    <div v-if="error" class="bg-red-500/10 border border-red-500/20 text-red-400 p-4 rounded-xl mb-6">
      {{ error }}
    </div>

    <div class="bg-black/20 border border-white/5 rounded-xl overflow-hidden">
      <!-- Horizontal Scroll Wrapper -->
      <div class="overflow-x-auto">
        <div class="min-w-[850px]">
          <!-- Header -->
          <div class="grid grid-cols-12 gap-4 p-4 border-b border-white/5 text-xs font-medium text-gray-500 uppercase tracking-wider bg-white/2">
            <div class="col-span-1">PID</div>
            <div class="col-span-2">User</div>
            <div class="col-span-2">CPU %</div>
            <div class="col-span-2">Memory %</div>
            <div class="col-span-4">Command</div>
            <div class="col-span-1 text-right pr-4">Kill</div>
          </div>

          <div v-if="loading && processes.length === 0" class="p-8 text-center text-gray-500">
            <div class="animate-spin inline-block w-6 h-6 border-2 border-red-500 border-t-transparent rounded-full mr-2"></div>
            Loading metrics...
          </div>
          <div v-else-if="processes.length === 0" class="p-8 text-center text-gray-500">No processes found</div>

          <!-- Rows -->
          <div v-for="proc in processes" :key="proc.pid" 
               class="grid grid-cols-12 gap-4 p-3 items-center border-b border-white/5 last:border-0 hover:bg-white/5 transition-colors">
            <div class="col-span-1 font-mono text-gray-500 text-xs">#{{ proc.pid }}</div>
            <div class="col-span-2 text-gray-400 text-xs truncate">{{ proc.user }}</div>
            <div class="col-span-2">
              <div class="flex items-center gap-2">
                <div class="w-16 h-1.5 bg-white/10 rounded-full overflow-hidden">
                  <div class="h-full bg-red-500" :style="{width: Math.min(proc.cpu, 100) + '%'}"></div>
                </div>
                <span class="text-white font-mono text-xs w-8">{{ proc.cpu.toFixed(1) }}%</span>
              </div>
            </div>
            <div class="col-span-2">
              <div class="flex items-center gap-2">
                <div class="w-16 h-1.5 bg-white/10 rounded-full overflow-hidden">
                  <div class="h-full bg-blue-500" :style="{width: Math.min(proc.memory, 100) + '%'}"></div>
                </div>
                <span class="text-white font-mono text-xs w-8">{{ proc.memory.toFixed(1) }}%</span>
              </div>
            </div>
            <div class="col-span-4 text-gray-400 text-xs truncate font-mono bg-black/30 p-1.5 rounded" :title="proc.command">
              {{ proc.command }}
            </div>
            <div class="col-span-1 flex justify-end pr-2">
              <button @click="killProcess(proc.pid)" 
                      class="p-1.5 hover:bg-red-500/10 rounded-lg text-gray-400 hover:text-red-500 transition-colors" title="Kill">
                <XCircle :size="16" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
