<script setup>
import { ref, onMounted, onUnmounted, watch } from 'vue'
import axios from 'axios'
import { FileText, RefreshCw, Pause, Play, Download } from 'lucide-vue-next'

const logs = ref([])
const selectedLog = ref(null)
const logContent = ref([])
const loading = ref(false)
const autoRefresh = ref(true)
const refreshInterval = ref(null)
const lines = ref(100)

const loadLogs = async () => {
  try {
    const res = await axios.get('/api/logs/')
    logs.value = res.data
    if (logs.value.length > 0 && !selectedLog.value) {
      selectedLog.value = logs.value[0]
    }
  } catch (err) {
    console.error(err)
  }
}

const loadContent = async () => {
  if (!selectedLog.value) return
  loading.value = true
  try {
    const res = await axios.get('/api/logs/read', {
      params: {
        path: selectedLog.value.path,
        lines: lines.value
      }
    })
    logContent.value = res.data.content || []
  } catch (err) {
    console.error(err)
  } finally {
    loading.value = false
  }
}

const selectLog = (log) => {
  selectedLog.value = log
  loadContent()
}

const toggleAutoRefresh = () => {
  autoRefresh.value = !autoRefresh.value
  if (autoRefresh.value) {
    refreshInterval.value = setInterval(loadContent, 2000)
  } else {
    clearInterval(refreshInterval.value)
  }
}

watch(selectedLog, () => {
  loadContent()
})

onMounted(() => {
  loadLogs()
  refreshInterval.value = setInterval(loadContent, 2000)
})

onUnmounted(() => {
  if (refreshInterval.value) {
    clearInterval(refreshInterval.value)
  }
})
</script>

<template>
  <div class="p-6 h-full flex flex-col">
    <div class="flex items-center justify-between mb-6">
      <h2 class="text-2xl font-bold flex items-center gap-2">
        <FileText class="text-panda-primary" />
        Log Viewer
      </h2>
      <div class="flex items-center space-x-4">
        <div class="flex items-center space-x-2 bg-black/20 rounded-lg p-1 border border-white/5">
            <button @click="lines = 100; loadContent()" :class="['px-3 py-1 rounded text-xs font-medium transition-colors', lines === 100 ? 'bg-white/10 text-white' : 'text-gray-400 hover:text-white']">100 lines</button>
            <button @click="lines = 500; loadContent()" :class="['px-3 py-1 rounded text-xs font-medium transition-colors', lines === 500 ? 'bg-white/10 text-white' : 'text-gray-400 hover:text-white']">500 lines</button>
            <button @click="lines = 1000; loadContent()" :class="['px-3 py-1 rounded text-xs font-medium transition-colors', lines === 1000 ? 'bg-white/10 text-white' : 'text-gray-400 hover:text-white']">1000 lines</button>
        </div>
        <button @click="toggleAutoRefresh" class="flex items-center space-x-2 px-4 py-2 bg-white/5 hover:bg-white/10 rounded-lg transition-colors">
          <Pause v-if="autoRefresh" :size="18" class="text-yellow-500" />
          <Play v-else :size="18" class="text-green-500" />
          <span>{{ autoRefresh ? 'Auto Refresh On' : 'Auto Refresh Off' }}</span>
        </button>
      </div>
    </div>

    <div class="flex-1 flex gap-6 overflow-hidden">
      <!-- Sidebar -->
      <div class="w-64 bg-black/20 border border-white/5 rounded-xl overflow-hidden flex flex-col">
        <div class="p-4 border-b border-white/5 font-medium text-gray-400">Log Files</div>
        <div class="flex-1 overflow-y-auto p-2 space-y-1">
          <button v-for="log in logs" :key="log.path"
                  @click="selectLog(log)"
                  :class="['w-full text-left px-4 py-3 rounded-lg text-sm transition-colors flex items-center justify-between group', 
                           selectedLog?.path === log.path ? 'bg-panda-primary/10 text-panda-primary' : 'text-gray-400 hover:bg-white/5 hover:text-gray-200']">
            <span class="truncate">{{ log.name }}</span>
          </button>
        </div>
      </div>

      <!-- Content -->
      <div class="flex-1 bg-black/40 border border-white/5 rounded-xl overflow-hidden flex flex-col relative">
        <div class="absolute top-0 right-0 p-4" v-if="loading && !autoRefresh">
            <RefreshCw class="animate-spin text-panda-primary" />
        </div>
        <div class="flex-1 overflow-y-auto p-4 font-mono text-sm space-y-1" ref="logContainer">
            <div v-for="(line, index) in logContent" :key="index" class="text-gray-300 hover:bg-white/5 px-2 py-0.5 rounded">
                {{ line }}
            </div>
            <div v-if="logContent.length === 0" class="text-gray-500 italic text-center mt-10">
                No logs to display or file is empty.
            </div>
        </div>
      </div>
    </div>
  </div>
</template>
