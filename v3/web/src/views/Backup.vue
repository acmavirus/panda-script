<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import { Archive, Download, Upload, Trash2, RotateCw, HardDrive, Database } from 'lucide-vue-next'

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
    alert('Website backup created!')
  } catch (err) {
    alert('Failed: ' + (err.response?.data?.error || err.message))
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
    alert('Database backup created!')
  } catch (err) {
    alert('Failed: ' + (err.response?.data?.error || err.message))
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
    alert('Full backup created!')
  } catch (err) {
    alert('Failed: ' + (err.response?.data?.error || err.message))
  } finally {
    backingUp.value = false
  }
}

const restoreBackup = async (path) => {
  if (!confirm(`Restore from ${path}?`)) return
  try {
    await axios.post('/api/backup/restore', { path })
    alert('Backup restored successfully!')
  } catch (err) {
    alert('Failed: ' + (err.response?.data?.error || err.message))
  }
}

const cleanupBackups = async () => {
  const days = prompt('Delete backups older than (days):', '7')
  if (!days) return
  try {
    const res = await axios.delete(`/api/backup/cleanup?days=${days}`)
    alert(`Deleted ${res.data?.deleted || 0} old backups`)
    fetchBackups()
  } catch (err) {
    alert('Failed: ' + (err.response?.data?.error || err.message))
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
  <div class="p-8">
    <div class="flex items-center justify-between mb-8">
      <div>
        <h2 class="text-2xl font-bold text-white tracking-tight flex items-center gap-2">
          <Archive class="text-cyan-400" />
          Backup & Restore
        </h2>
        <p class="text-gray-500 mt-1">Manage system backups</p>
      </div>
      <button @click="fetchBackups" class="p-2 bg-white/5 rounded-lg hover:bg-white/10 transition-colors">
        <RotateCw :size="20" class="text-gray-400" />
      </button>
    </div>

    <!-- Backup Actions -->
    <div class="grid grid-cols-4 gap-4 mb-6">
      <button @click="backupWebsite" :disabled="backingUp"
              class="bg-black/20 border border-white/5 rounded-xl p-4 hover:bg-white/5 transition-colors text-left">
        <HardDrive class="text-green-400 mb-2" :size="24" />
        <div class="font-medium text-white">Backup Website</div>
        <div class="text-sm text-gray-500">Single site backup</div>
      </button>
      <button @click="backupDatabase" :disabled="backingUp"
              class="bg-black/20 border border-white/5 rounded-xl p-4 hover:bg-white/5 transition-colors text-left">
        <Database class="text-blue-400 mb-2" :size="24" />
        <div class="font-medium text-white">Backup Database</div>
        <div class="text-sm text-gray-500">Single DB backup</div>
      </button>
      <button @click="backupFull" :disabled="backingUp"
              class="bg-black/20 border border-white/5 rounded-xl p-4 hover:bg-white/5 transition-colors text-left">
        <Archive class="text-purple-400 mb-2" :size="24" />
        <div class="font-medium text-white">Full Backup</div>
        <div class="text-sm text-gray-500">Complete system</div>
      </button>
      <button @click="cleanupBackups"
              class="bg-black/20 border border-white/5 rounded-xl p-4 hover:bg-white/5 transition-colors text-left">
        <Trash2 class="text-red-400 mb-2" :size="24" />
        <div class="font-medium text-white">Cleanup</div>
        <div class="text-sm text-gray-500">Delete old backups</div>
      </button>
    </div>

    <div v-if="error" class="bg-red-500/10 border border-red-500/20 text-red-400 p-4 rounded-xl mb-6">
      {{ error }}
    </div>

    <div class="bg-black/20 border border-white/5 rounded-xl overflow-hidden">
      <div class="grid grid-cols-12 gap-4 p-4 border-b border-white/5 text-xs font-medium text-gray-500 uppercase tracking-wider">
        <div class="col-span-4">Name</div>
        <div class="col-span-2">Type</div>
        <div class="col-span-2">Size</div>
        <div class="col-span-2">Date</div>
        <div class="col-span-2 text-right">Actions</div>
      </div>

      <div v-if="loading" class="p-8 text-center text-gray-500">Loading...</div>
      <div v-else-if="backups.length === 0" class="p-8 text-center text-gray-500">No backups found</div>

      <div v-for="backup in backups" :key="backup.name" 
           class="grid grid-cols-12 gap-4 p-4 items-center border-b border-white/5 last:border-0 hover:bg-white/5 transition-colors">
        <div class="col-span-4 font-medium text-white truncate" :title="backup.name">{{ backup.name }}</div>
        <div class="col-span-2">
          <span :class="getTypeColor(backup.type)" class="px-2 py-1 rounded-md text-xs border font-medium uppercase">
            {{ backup.type }}
          </span>
        </div>
        <div class="col-span-2 text-gray-400">{{ formatSize(backup.size) }}</div>
        <div class="col-span-2 text-gray-400 text-sm">{{ new Date(backup.created_at).toLocaleDateString() }}</div>
        <div class="col-span-2 flex items-center justify-end space-x-2">
          <button @click="restoreBackup(backup.path)" 
                  class="p-1.5 hover:bg-green-500/10 rounded-lg text-gray-400 hover:text-green-500 transition-colors" title="Restore">
            <Upload :size="16" />
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
