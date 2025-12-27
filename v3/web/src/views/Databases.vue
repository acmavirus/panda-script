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
  <div class="p-4 lg:p-8 space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h2 class="text-xl lg:text-2xl font-bold text-white tracking-tight flex items-center gap-2">
          <Database class="text-orange-400" :size="24" />
          Databases
        </h2>
        <p class="text-xs lg:text-sm text-gray-500 mt-1">Manage SQLite database files</p>
      </div>
      <button @click="showModal = true" class="w-full sm:w-auto bg-orange-600 hover:bg-orange-700 text-white px-4 py-2 rounded-xl flex items-center justify-center gap-2 text-sm transition-all shadow-lg shadow-orange-600/20">
        <Plus :size="18" /> Add Database
      </button>
    </div>

    <!-- Databases Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4 lg:gap-6">
      <div v-for="db in dbs" :key="db.name" class="bg-white/5 p-5 lg:p-6 rounded-2xl border border-white/5 hover:border-orange-500/50 transition-all group relative">
        <div class="flex justify-between items-start mb-4">
          <div class="flex items-center gap-3">
             <div class="w-10 h-10 lg:w-12 lg:h-12 rounded-xl bg-orange-500/10 flex items-center justify-center text-orange-500">
               <Database :size="20" />
             </div>
             <div>
               <h3 class="text-base lg:text-lg font-bold text-white truncate max-w-[150px]" :title="db.name">{{ db.name }}</h3>
               <p class="text-[10px] text-gray-500 font-mono uppercase tracking-widest">SQLite 3</p>
             </div>
          </div>
          <button @click="deleteDb(db.name)" class="text-gray-500 hover:text-red-400 p-2 hover:bg-white/5 rounded-lg transition-colors md:opacity-0 group-hover:opacity-100">
            <Trash2 :size="18" />
          </button>
        </div>
        
        <div class="space-y-2 text-xs lg:text-sm text-gray-400 mt-6">
          <div class="flex justify-between items-center pb-2 border-b border-white/5">
            <span class="text-gray-500">File Size:</span>
            <span class="text-white font-mono">{{ (db.size / 1024).toFixed(1) }} KB</span>
          </div>
        </div>

        <div class="mt-4 pt-4 flex justify-end gap-3">
          <button @click="openQuery(db)" class="flex-1 lg:flex-none justify-center px-3 py-2 bg-orange-500/10 hover:bg-orange-500/20 text-orange-400 rounded-lg flex items-center gap-1.5 text-xs font-medium transition-colors">
            <Play :size="14" /> Run Query
          </button>
        </div>
      </div>

      <!-- Empty State -->
      <div v-if="dbs.length === 0" class="col-span-full border-2 border-dashed border-white/5 rounded-3xl py-20 flex flex-col items-center justify-center text-gray-500 bg-white/1">
        <Database :size="48" class="opacity-10 mb-4" />
        <p class="text-sm">No databases found</p>
      </div>
    </div>

    <!-- Add Modal -->
    <div v-if="showModal" class="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4 z-50">
      <div class="bg-panda-dark p-6 rounded-2xl w-full max-w-md border border-white/10 shadow-2xl">
        <h2 class="text-xl font-bold text-white mb-6">Create Database</h2>
        
        <div class="space-y-4">
          <div>
            <label class="block text-sm text-gray-400 mb-1.5 font-medium">Database Name</label>
            <input v-model="newDbName" type="text" placeholder="e.g. users_db" class="w-full bg-black/30 border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-orange-500 transition-colors text-sm">
            <p class="text-[10px] text-gray-500 mt-2 italic px-1">* .db extension will be added automatically</p>
          </div>
        </div>

        <div class="flex justify-end gap-3 mt-8">
          <button @click="showModal = false" class="flex-1 py-3 text-sm font-medium text-gray-400 hover:text-white bg-white/5 hover:bg-white/10 rounded-xl transition-colors">Cancel</button>
          <button @click="createDb" class="flex-1 py-3 bg-orange-600 hover:bg-orange-700 text-white rounded-xl text-sm font-medium transition-all shadow-lg shadow-orange-600/20">Create Database</button>
        </div>
      </div>
    </div>

    <!-- Query Modal -->
    <div v-if="showQueryModal" class="fixed inset-0 bg-black/90 backdrop-blur flex items-center justify-center p-0 sm:p-4 lg:p-10 z-50">
      <div class="bg-gray-900 w-full h-full sm:h-auto sm:max-h-full sm:rounded-2xl border border-white/10 flex flex-col shadow-3xl overflow-hidden">
        <div class="flex justify-between items-center p-4 border-b border-white/10 bg-black/20">
          <h2 class="text-base lg:text-lg font-bold text-white flex items-center gap-2">
            <Table class="w-5 h-5 text-orange-400" /> {{ currentDb?.name }} Viewer
          </h2>
          <button @click="showQueryModal = false" class="p-2 text-gray-400 hover:text-white hover:bg-white/5 rounded-lg transition-colors">
             <Trash2 :size="20" class="rotate-45" /> 
          </button>
        </div>

        <div class="flex-1 flex flex-col gap-4 p-4 overflow-hidden">
          <div class="flex flex-col lg:flex-row gap-3">
            <textarea v-model="query" class="flex-1 bg-black/40 border border-white/10 rounded-xl p-3 text-white font-mono text-xs lg:text-sm focus:outline-none focus:border-orange-500 h-24 lg:h-32 resize-none transition-colors shadow-inner"></textarea>
            <button @click="executeQuery" class="lg:w-32 bg-orange-600 hover:bg-orange-700 text-white px-6 py-3 rounded-xl flex items-center justify-center gap-2 font-bold text-sm transition-all shadow-lg shadow-orange-600/20">
              <Play :size="16" /> RUN
            </button>
          </div>

          <div class="flex-1 bg-black/30 border border-white/10 rounded-xl overflow-auto custom-scrollbar shadow-inner relative">
            <div v-if="queryError" class="p-4 text-red-400 font-mono text-xs">{{ queryError }}</div>
            
            <div v-else-if="queryResults && queryResults.length > 0" class="p-0">
               <div class="overflow-x-auto">
                <table class="w-full text-left text-[11px] lg:text-xs text-gray-400">
                  <thead class="sticky top-0 bg-gray-800/95 backdrop-blur z-10">
                    <tr class="border-b border-white/10">
                      <th v-for="(val, key) in queryResults[0]" :key="key" class="px-4 py-3 text-white font-bold uppercase tracking-wider">{{ key }}</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="(row, i) in queryResults" :key="i" class="border-b border-white/5 hover:bg-white/5 transition-colors">
                      <td v-for="(val, key) in row" :key="key" class="px-4 py-3 font-mono">{{ val }}</td>
                    </tr>
                  </tbody>
                </table>
               </div>
            </div>
            
            <div v-else-if="queryResults" class="h-full flex items-center justify-center text-gray-500 italic text-sm">
                Empty result set
            </div>
            <div v-else class="h-full flex flex-col items-center justify-center text-gray-500 gap-3">
                <Archive :size="40" class="opacity-10" />
                <span class="text-xs uppercase tracking-widest font-bold">SQL Output Console</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 6px;
  height: 6px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 10px;
}
.custom-scrollbar::-webkit-scrollbar-thumb:hover {
  background: rgba(234, 88, 12, 0.3);
}
</style>
