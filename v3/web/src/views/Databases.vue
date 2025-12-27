<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import { Database, Plus, Trash2, Play, Table, Archive, RotateCcw } from 'lucide-vue-next'
import { useAuthStore } from '../stores/auth'

const dbs = ref([])
const showModal = ref(false)
const showQueryModal = ref(false)
const showBackupModal = ref(false)
const newDbName = ref('')
const authStore = useAuthStore()

const currentDb = ref(null)
const backups = ref([])
const query = ref('SELECT * FROM test;')
const queryResults = ref(null)
const queryError = ref('')

const fetchDbs = async () => {
  try {
    const res = await axios.get('/api/databases/', {
      headers: { Authorization: `Bearer ${authStore.token}` }
    })
    dbs.value = res.data || []
  } catch (error) {
    console.error('Failed to fetch databases:', error)
  }
}

const createDb = async () => {
  try {
    await axios.post('/api/databases/', { name: newDbName.value }, {
      headers: { Authorization: `Bearer ${authStore.token}` }
    })
    showModal.value = false
    newDbName.value = ''
    fetchDbs()
  } catch (error) {
    console.error('Failed to create database:', error)
  }
}

const deleteDb = async (name) => {
  if (!confirm(`Are you sure you want to delete ${name}?`)) return
  try {
    await axios.delete(`/api/databases/?name=${name}`, {
      headers: { Authorization: `Bearer ${authStore.token}` }
    })
    fetchDbs()
  } catch (error) {
    console.error('Failed to delete database:', error)
  }
}

const openQuery = (db) => {
  currentDb.value = db
  showQueryModal.value = true
  queryResults.value = null
  queryError.value = ''
}

const executeQuery = async () => {
  if (!currentDb.value) return
  queryError.value = ''
  queryResults.value = null
  try {
    const res = await axios.post('/api/databases/query', {
      name: currentDb.value.name,
      query: query.value
    }, {
      headers: { Authorization: `Bearer ${authStore.token}` }
    })
    queryResults.value = res.data
  } catch (error) {
    queryError.value = error.response?.data?.error || error.message
  }
}

onMounted(fetchDbs)
</script>

<template>
  <div class="p-6">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold text-white flex items-center gap-2">
        <Database class="w-6 h-6 text-orange-400" /> Database Manager
      </h1>
      <button 
        @click="showModal = true"
        class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg flex items-center gap-2"
      >
        <Plus class="w-4 h-4" /> Add Database
      </button>
    </div>

    <!-- Databases Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div v-for="db in dbs" :key="db.name" class="bg-[#1e1e1e] p-6 rounded-xl border border-white/10 hover:border-orange-500/50 transition-colors">
        <div class="flex justify-between items-start mb-4">
          <div>
            <h3 class="text-lg font-semibold text-white">{{ db.name }}</h3>
            <p class="text-gray-400 text-sm flex items-center gap-1">
              SQLite
            </p>
          </div>
          <button @click="deleteDb(db.name)" class="text-red-400 hover:text-red-300 p-2 hover:bg-white/5 rounded-lg">
            <Trash2 class="w-5 h-5" />
          </button>
        </div>
        
        <div class="space-y-2 text-sm text-gray-400">
          <div class="flex justify-between">
            <span>Size:</span>
            <span class="text-white">{{ (db.size / 1024).toFixed(2) }} KB</span>
          </div>
        </div>

        <div class="mt-4 pt-4 border-t border-white/10 flex justify-end">
          <button @click="openQuery(db)" class="text-orange-400 hover:text-orange-300 flex items-center gap-1 text-sm">
            <Play class="w-4 h-4" /> Query
          </button>
        </div>
      </div>
    </div>

    <!-- Backup Modal -->
    <div v-if="showBackupModal" class="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
      <div class="bg-[#1e1e1e] p-6 rounded-xl w-full max-w-md border border-white/10">
        <h2 class="text-xl font-bold text-white mb-4">Restore Database: {{ currentDb?.name }}</h2>
        
        <div class="space-y-2 max-h-64 overflow-y-auto">
          <div v-if="backups.length === 0" class="text-gray-400 text-sm">No backups found.</div>
          <div v-for="backup in backups" :key="backup" class="flex justify-between items-center bg-black/20 p-3 rounded-lg border border-white/5">
            <span class="text-gray-300 text-sm truncate">{{ backup }}</span>
            <button @click="restoreDb(backup)" class="text-green-400 hover:text-green-300 text-sm flex items-center gap-1">
              <RotateCcw class="w-4 h-4" /> Restore
            </button>
          </div>
        </div>

        <div class="flex justify-end mt-6">
          <button @click="showBackupModal = false" class="px-4 py-2 text-gray-400 hover:text-white">Close</button>
        </div>
      </div>
    </div>

    <!-- Add Modal -->
    <div v-if="showModal" class="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
      <div class="bg-[#1e1e1e] p-6 rounded-xl w-full max-w-md border border-white/10">
        <h2 class="text-xl font-bold text-white mb-4">Add New Database</h2>
        
        <div class="space-y-4">
          <div>
            <label class="block text-sm text-gray-400 mb-1">Database Name</label>
            <input v-model="newDbName" type="text" placeholder="my_app" class="w-full bg-black/20 border border-white/10 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-blue-500">
          </div>
        </div>

        <div class="flex justify-end gap-3 mt-6">
          <button @click="showModal = false" class="px-4 py-2 text-gray-400 hover:text-white">Cancel</button>
          <button @click="createDb" class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg">Create</button>
        </div>
      </div>
    </div>

    <!-- Query Modal -->
    <div v-if="showQueryModal" class="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
      <div class="bg-[#1e1e1e] p-6 rounded-xl w-full max-w-4xl border border-white/10 h-[80vh] flex flex-col">
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-xl font-bold text-white flex items-center gap-2">
            <Table class="w-5 h-5 text-orange-400" /> Query: {{ currentDb?.name }}
          </h2>
          <button @click="showQueryModal = false" class="text-gray-400 hover:text-white">Close</button>
        </div>

        <div class="flex-1 flex flex-col gap-4 overflow-hidden">
          <div class="flex gap-2">
            <textarea v-model="query" class="flex-1 bg-black/20 border border-white/10 rounded-lg p-4 text-white font-mono text-sm focus:outline-none focus:border-orange-500 h-32 resize-none"></textarea>
            <button @click="executeQuery" class="bg-orange-600 hover:bg-orange-700 text-white px-4 rounded-lg flex items-center gap-2">
              <Play class="w-4 h-4" /> Run
            </button>
          </div>

          <div class="flex-1 bg-black/20 border border-white/10 rounded-lg overflow-auto p-4">
            <div v-if="queryError" class="text-red-400 font-mono text-sm">{{ queryError }}</div>
            <table v-else-if="queryResults && queryResults.length > 0" class="w-full text-left text-sm text-gray-400">
              <thead>
                <tr class="border-b border-white/10">
                  <th v-for="(val, key) in queryResults[0]" :key="key" class="p-2 text-white font-medium">{{ key }}</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(row, i) in queryResults" :key="i" class="border-b border-white/5 hover:bg-white/5">
                  <td v-for="(val, key) in row" :key="key" class="p-2">{{ val }}</td>
                </tr>
              </tbody>
            </table>
            <div v-else-if="queryResults" class="text-gray-500 italic">No results or empty set.</div>
            <div v-else class="text-gray-500 italic">Run a query to see results.</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
