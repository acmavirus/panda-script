<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import { Archive, Download, Upload, Trash2, RotateCw, HardDrive, Database } from 'lucide-vue-next'
import { useToastStore } from '../stores/toast'
const toast = useToastStore()

const backups = ref([])
const loading = ref(false)
const error = ref('')
const backingUp = ref(false)

const fetchBackups = async () => {
  loading.value = true
  error.value = ''
  try {
    const res = await axios.get('/api/backup/')
    backups.value = res.data || []
  } catch (err) {
    error.value = err.response?.data?.error || 'Failed to load backups'
  } finally {
    loading.value = false
  }
}

const backupWebsite = async () => {
  const domain = prompt('Enter domain to backup:')
  if (!domain) return
  backingUp.value = true
  try {
    await axios.post(`/api/backup/website/${domain}`)
    fetchBackups()
    toast.success('Website backup created!')
  } catch (err) {
    toast.error('Failed: ' + (err.response?.data?.error || err.message))
  } finally {
    backingUp.value = false
  }
}

const backupDatabase = async () => {
  const name = prompt('Enter database name to backup:')
  if (!name) return
  backingUp.value = true
  try {
    await axios.post(`/api/backup/database/${name}`)
    fetchBackups()
    toast.success('Database backup created!')
  } catch (err) {
    toast.error('Failed: ' + (err.response?.data?.error || err.message))
  } finally {
    backingUp.value = false
  }
}

const backupFull = async () => {
  if (!confirm('Create full system backup? This may take a while.')) return
  backingUp.value = true
  try {
    await axios.post('/api/backup/full')
    fetchBackups()
    toast.success('Full backup created!')
  } catch (err) {
    toast.error('Failed: ' + (err.response?.data?.error || err.message))
  } finally {
    backingUp.value = false
  }
}

const restoreBackup = async (path) => {
  if (!confirm(`Restore from ${path}?`)) return
  try {
    await axios.post('/api/backup/restore', { path })
    toast.success('Backup restored successfully!')
  } catch (err) {
    toast.error('Failed: ' + (err.response?.data?.error || err.message))
  }
}

const cleanupBackups = async () => {
  const days = prompt('Delete backups older than (days):', '7')
  if (!days) return
  try {
    const res = await axios.delete(`/api/backup/cleanup?days=${days}`)
    toast.success(`Deleted ${res.data?.deleted || 0} old backups`)
    fetchBackups()
  } catch (err) {
    toast.error('Failed: ' + (err.response?.data?.error || err.message))
  }
}

const formatSize = (bytes) => {
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
  if (bytes < 1024 * 1024 * 1024) return (bytes / 1024 / 1024).toFixed(1) + ' MB'
  return (bytes / 1024 / 1024 / 1024).toFixed(1) + ' GB'
}

const getTypeIcon = (type) => {
  if (type === 'database') return Database
  return HardDrive
}

const getTypeColor = (type) => {
  if (type === 'full') return 'bg-purple-500/10 text-purple-400 border-purple-500/20'
  if (type === 'database') return 'bg-blue-500/10 text-blue-400 border-blue-500/20'
  if (type === 'config') return 'bg-yellow-500/10 text-yellow-400 border-yellow-500/20'
  return 'bg-green-500/10 text-green-400 border-green-500/20'
}

onMounted(() => {
  fetchBackups()
})
</script>

<template>
  <div class="p-4 lg:p-8">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between mb-8 gap-4">
      <div>
        <h2 class="text-xl lg:text-2xl font-bold text-white tracking-tight flex items-center gap-2">
          <Archive class="text-cyan-400" :size="24" />
          Backup & Restore
        </h2>
        <p class="text-xs lg:text-sm text-gray-400 mt-1 uppercase tracking-widest font-bold">Data recovery center</p>
      </div>
      <button @click="fetchBackups" class="p-3 sm:p-2 bg-white/5 rounded-lg hover:bg-white/10 transition-colors flex items-center justify-center">
        <RotateCw :size="18" :class="{'animate-spin': loading}" class="text-gray-400" />
      </button>
    </div>

    <!-- Backup Actions -->
    <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
      <button @click="backupWebsite" :disabled="backingUp"
              class="bg-black/20 border border-white/5 rounded-2xl p-4 hover:bg-white/5 transition-all text-left shadow-xl hover:scale-[1.02]">
        <HardDrive class="text-green-400 mb-2" :size="22" />
        <div class="font-bold text-white text-sm">Websites</div>
        <div class="text-[10px] text-gray-500 uppercase tracking-tighter">Single site</div>
      </button>
      <button @click="backupDatabase" :disabled="backingUp"
              class="bg-black/20 border border-white/5 rounded-2xl p-4 hover:bg-white/5 transition-all text-left shadow-xl hover:scale-[1.02]">
        <Database class="text-blue-400 mb-2" :size="22" />
        <div class="font-bold text-white text-sm">Databases</div>
        <div class="text-[10px] text-gray-500 uppercase tracking-tighter">MySQL Dump</div>
      </button>
      <button @click="backupFull" :disabled="backingUp"
              class="bg-black/20 border border-white/5 rounded-2xl p-4 hover:bg-white/5 transition-all text-left shadow-xl hover:scale-[1.02]">
        <Archive class="text-purple-400 mb-2" :size="22" />
        <div class="font-bold text-white text-sm">Full System</div>
        <div class="text-[10px] text-gray-500 uppercase tracking-tighter">Everything</div>
      </button>
      <button @click="cleanupBackups"
              class="bg-black/20 border border-white/5 rounded-2xl p-4 hover:bg-white/5 transition-all text-left shadow-xl hover:scale-[1.02]">
        <Trash2 class="text-red-400 mb-2" :size="22" />
        <div class="font-bold text-white text-sm">Cleanup</div>
        <div class="text-[10px] text-gray-500 uppercase tracking-tighter">Auto-delete</div>
      </button>
    </div>

    <div v-if="error" class="bg-red-500/10 border border-red-500/20 text-red-400 p-3 rounded-xl mb-6 text-xs">
      {{ error }}
    </div>

    <div class="bg-black/20 border border-white/5 rounded-2xl overflow-hidden shadow-2xl">
      <!-- Horizontal Scroll Wrapper -->
      <div class="overflow-x-auto">
        <div class="min-w-[850px]">
          <!-- Header -->
          <div class="grid grid-cols-12 gap-4 p-4 border-b border-white/5 text-[10px] lg:text-xs font-bold text-gray-500 uppercase tracking-widest bg-white/2">
            <div class="col-span-4">Item Name</div>
            <div class="col-span-2 text-center">Type</div>
            <div class="col-span-2 text-center">Data Size</div>
            <div class="col-span-2 text-center">Created At</div>
            <div class="col-span-2 text-right pr-4">Actions</div>
          </div>

          <div v-if="loading && backups.length === 0" class="p-16 text-center text-gray-500 flex flex-col items-center gap-3">
             <div class="animate-spin w-6 h-6 border-2 border-cyan-500 border-t-transparent rounded-full"></div>
             <p class="text-xs font-mono">Indexing archives...</p>
          </div>
          <div v-else-if="backups.length === 0" class="p-16 text-center text-gray-500 text-sm italic">No backup archives found</div>

          <div v-for="backup in backups" :key="backup.name" 
               class="grid grid-cols-12 gap-4 p-4 items-center border-b border-white/5 last:border-0 hover:bg-white/5 transition-colors">
            <div class="col-span-4 font-bold text-gray-200 text-xs truncate flex items-center gap-2" :title="backup.name">
               <div class="w-1.5 h-1.5 rounded-full bg-cyan-500 shadow-[0_0_8px_rgba(6,182,212,0.4)] shrink-0"></div>
               {{ backup.name }}
            </div>
            <div class="col-span-2 text-center">
              <span :class="getTypeColor(backup.type)" class="px-2 py-0.5 rounded-md text-[10px] border font-bold uppercase tracking-wide">
                {{ backup.type }}
              </span>
            </div>
            <div class="col-span-2 text-center text-gray-400 text-xs font-mono">{{ formatSize(backup.size) }}</div>
            <div class="col-span-2 text-center text-gray-500 text-xs font-mono">{{ new Date(backup.created_at).toLocaleDateString() }}</div>
            <div class="col-span-2 flex items-center justify-end space-x-2 pr-2">
              <button @click="restoreBackup(backup.path)" 
                      class="p-2 hover:bg-green-500/10 rounded-lg text-gray-500 hover:text-green-500 transition-colors" title="Restore Data">
                <Upload :size="16" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
