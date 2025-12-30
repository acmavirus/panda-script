<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import { Clock, Plus, Trash2, Edit2, Play, Pause, RefreshCw, X, Calendar } from 'lucide-vue-next'

const crons = ref([])
const loading = ref(true)
const showModal = ref(false)
const editingCron = ref(null)
const formData = ref({
  name: '',
  expression: '',
  command: '',
  description: ''
})
const error = ref('')
const success = ref('')

const fetchCrons = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/cron/')
    crons.value = res.data || []
  } catch (err) {
    error.value = 'Failed to load cron jobs'
  } finally {
    loading.value = false
  }
}

const openCreateModal = () => {
  editingCron.value = null
  formData.value = { name: '', expression: '', command: '', description: '' }
  showModal.value = true
}

const openEditModal = (cron) => {
  editingCron.value = cron
  formData.value = { ...cron }
  showModal.value = true
}

const saveCron = async () => {
  try {
    if (editingCron.value) {
      await axios.put(`/api/cron/${editingCron.value.id}`, formData.value)
      success.value = 'Cron job updated successfully'
    } else {
      await axios.post('/api/cron/', formData.value)
      success.value = 'Cron job created successfully'
    }
    showModal.value = false
    fetchCrons()
    setTimeout(() => { success.value = '' }, 3000)
  } catch (err) {
    error.value = err.response?.data?.error || 'Failed to save cron job'
  }
}

const deleteCron = async (id) => {
  if (!confirm('Are you sure you want to delete this cron job?')) return
  try {
    await axios.delete(`/api/cron/${id}`)
    fetchCrons()
  } catch (err) {
    error.value = 'Failed to delete cron job'
  }
}

const toggleEnabled = async (cron) => {
  try {
    await axios.put(`/api/cron/${cron.id}`, { enabled: !cron.enabled })
    cron.enabled = !cron.enabled
  } catch (err) {
    error.value = 'Failed to toggle status'
  }
}

onMounted(fetchCrons)
</script>

<template>
  <div class="space-y-6 max-w-7xl mx-auto">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-2xl font-semibold" style="color: var(--text-primary);">Cron Jobs</h1>
        <p class="text-sm mt-1" style="color: var(--text-muted);">Schedule automated tasks and scripts</p>
      </div>
      <div class="flex gap-2">
        <button @click="fetchCrons" class="panda-btn panda-btn-secondary">
          <RefreshCw :size="16" :class="{ 'animate-spin': loading }" />
        </button>
        <button @click="openCreateModal" class="panda-btn panda-btn-primary">
          <Plus :size="16" />
          <span>Add Task</span>
        </button>
      </div>
    </div>

    <!-- Alerts -->
    <div v-if="success" class="panda-alert panda-alert-success flex items-center justify-between">
      <span>{{ success }}</span>
      <button @click="success = ''"><X :size="14" /></button>
    </div>
    <div v-if="error" class="panda-alert panda-alert-error flex items-center justify-between">
      <span>{{ error }}</span>
      <button @click="error = ''"><X :size="14" /></button>
    </div>

    <!-- Content -->
    <div class="panda-card !p-0 overflow-hidden" v-if="!loading">
      <table class="panda-table">
        <thead>
          <tr>
            <th class="w-12">#</th>
            <th>Name</th>
            <th class="hidden md:table-cell">Expression</th>
            <th class="hidden sm:table-cell">Command</th>
            <th class="w-24 text-center">Status</th>
            <th class="w-32 text-right">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(cron, index) in crons" :key="cron.id">
            <td class="text-xs text-[var(--text-muted)] font-mono">{{ index + 1 }}</td>
            <td>
              <div class="flex items-center gap-3">
                <div class="w-9 h-9 rounded-lg flex items-center justify-center bg-[var(--color-primary-subtle)]">
                  <Clock :size="16" style="color: var(--color-primary);" />
                </div>
                <div>
                  <div class="font-medium" style="color: var(--text-primary);">{{ cron.name }}</div>
                  <div class="text-xs hidden sm:block" style="color: var(--text-muted);">{{ cron.description || 'No description' }}</div>
                </div>
              </div>
            </td>
            <td class="hidden md:table-cell">
              <code class="text-xs px-2 py-1 rounded bg-[var(--bg-surface)] text-[var(--color-primary)] font-mono">
                {{ cron.expression }}
              </code>
            </td>
            <td class="hidden sm:table-cell">
              <code class="text-xs px-2 py-1 rounded bg-[var(--bg-surface)] text-[var(--text-secondary)] font-mono truncate max-w-[200px] inline-block">
                {{ cron.command }}
              </code>
            </td>
            <td class="text-center">
              <button @click="toggleEnabled(cron)" class="focus:outline-none">
                <span v-if="cron.enabled" class="panda-badge panda-badge-success cursor-pointer">
                  <Play :size="10" class="mr-1" /> Active
                </span>
                <span v-else class="panda-badge panda-badge-error cursor-pointer">
                  <Pause :size="10" class="mr-1" /> Paused
                </span>
              </button>
            </td>
            <td>
              <div class="flex items-center gap-1 justify-end">
                <button @click="openEditModal(cron)" class="panda-btn panda-btn-ghost p-2" title="Edit">
                  <Edit2 :size="14" />
                </button>
                <button @click="deleteCron(cron.id)" class="panda-btn panda-btn-danger p-2" title="Delete">
                  <Trash2 :size="14" />
                </button>
              </div>
            </td>
          </tr>
          <tr v-if="crons.length === 0">
            <td colspan="6" class="text-center py-20">
              <Calendar :size="48" class="mx-auto mb-4 opacity-10" />
              <p style="color: var(--text-muted);">No scheduled tasks found</p>
              <button @click="openCreateModal" class="panda-btn panda-btn-secondary mt-4">
                Create your first cron job
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Skeleton Loading -->
    <div v-else class="space-y-4">
      <div v-for="i in 3" :key="i" class="h-16 rounded-xl animate-pulse bg-[var(--bg-surface)]"></div>
    </div>

    <!-- Modal -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
          <div class="w-full max-w-lg panda-card overflow-hidden shadow-2xl border-[var(--border-color)]">
            <div class="px-6 py-4 border-b border-[var(--border-color)] flex items-center justify-between">
              <h3 class="text-lg font-semibold">{{ editingCron ? 'Edit Cron Job' : 'New Cron Job' }}</h3>
              <button @click="showModal = false" class="text-[var(--text-muted)] hover:text-[var(--text-primary)]">
                <X :size="20" />
              </button>
            </div>
            
            <form @submit.prevent="saveCron" class="p-6 space-y-4">
              <div>
                <label class="block text-sm font-medium mb-1.5 text-[var(--text-secondary)]">Task Name</label>
                <input v-model="formData.name" type="text" required placeholder="Daily Backup" class="panda-input">
              </div>
              
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium mb-1.5 text-[var(--text-secondary)]">Schedule (Cron Expression)</label>
                  <input v-model="formData.expression" type="text" required placeholder="0 0 * * *" class="panda-input font-mono">
                  <p class="text-[10px] mt-1 text-[var(--text-muted)]">Format: min hour day month dow</p>
                </div>
                <div>
                  <label class="block text-sm font-medium mb-1.5 text-[var(--text-secondary)]">Quick Presets</label>
                  <select @change="(e) => formData.expression = e.target.value" class="panda-input text-xs">
                    <option value="">Custom...</option>
                    <option value="* * * * *">Every Minute</option>
                    <option value="0 * * * *">Every Hour</option>
                    <option value="0 0 * * *">Every Day at Midnight</option>
                    <option value="0 0 * * 0">Every Sunday</option>
                    <option value="0 0 1 * *">Every 1st of Month</option>
                  </select>
                </div>
              </div>

              <div>
                <label class="block text-sm font-medium mb-1.5 text-[var(--text-secondary)]">Command</label>
                <textarea v-model="formData.command" required rows="3" placeholder="/usr/bin/php /var/www/site/artisan schedule:run" class="panda-input font-mono"></textarea>
              </div>

              <div>
                <label class="block text-sm font-medium mb-1.5 text-[var(--text-secondary)]">Description (Optional)</label>
                <input v-model="formData.description" type="text" placeholder="Runs Laravel scheduler" class="panda-input">
              </div>

              <div class="pt-4 flex gap-3">
                <button type="button" @click="showModal = false" class="flex-1 panda-btn panda-btn-secondary">Cancel</button>
                <button type="submit" class="flex-1 panda-btn panda-btn-primary">
                  {{ editingCron ? 'Update Task' : 'Create Task' }}
                </button>
              </div>
            </form>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<style scoped>
.fade-enter-active, .fade-leave-active { transition: opacity 0.2s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }
</style>
