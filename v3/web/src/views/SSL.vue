<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import { Lock, Plus, RotateCw, Trash2, AlertCircle, CheckCircle } from 'lucide-vue-next'

const certificates = ref([])
const loading = ref(false)
const error = ref('')
const showObtain = ref(false)
const newDomain = ref('')
const newEmail = ref('')
const obtaining = ref(false)

const fetchCertificates = async () => {
  loading.value = true
  error.value = ''
  try {
    const res = await axios.get('/api/ssl/')
    certificates.value = res.data || []
  } catch (err) {
    error.value = err.response?.data?.error || 'Failed to load certificates'
  } finally {
    loading.value = false
  }
}

const obtainCertificate = async () => {
  if (!newDomain.value) return
  obtaining.value = true
  try {
    await axios.post('/api/ssl/obtain', { domain: newDomain.value, email: newEmail.value })
    newDomain.value = ''
    newEmail.value = ''
    showObtain.value = false
    fetchCertificates()
    alert('Certificate obtained successfully!')
  } catch (err) {
    alert('Failed: ' + (err.response?.data?.error || err.message))
  } finally {
    obtaining.value = false
  }
}

const renewCertificate = async (domain) => {
  try {
    await axios.post(`/api/ssl/renew/${domain}`)
    fetchCertificates()
    alert('Certificate renewed!')
  } catch (err) {
    alert('Failed: ' + (err.response?.data?.error || err.message))
  }
}

const renewAll = async () => {
  try {
    await axios.post('/api/ssl/renew-all')
    fetchCertificates()
    alert('All certificates renewed!')
  } catch (err) {
    alert('Failed: ' + (err.response?.data?.error || err.message))
  }
}

const revokeCertificate = async (domain) => {
  if (!confirm(`Revoke certificate for ${domain}?`)) return
  try {
    await axios.delete(`/api/ssl/${domain}`)
    fetchCertificates()
  } catch (err) {
    alert('Failed: ' + (err.response?.data?.error || err.message))
  }
}

const getDaysColor = (days) => {
  if (days > 30) return 'text-green-400'
  if (days > 7) return 'text-yellow-400'
  return 'text-red-400'
}

onMounted(() => {
  fetchCertificates()
})
</script>

<template>
  <div class="p-8">
    <div class="flex items-center justify-between mb-8">
      <div>
        <h2 class="text-2xl font-bold text-white tracking-tight flex items-center gap-2">
          <Lock class="text-green-400" />
          SSL Certificates
        </h2>
        <p class="text-gray-500 mt-1">Manage Let's Encrypt SSL certificates</p>
      </div>
      <div class="flex gap-2">
        <button @click="renewAll" class="px-4 py-2 bg-white/5 hover:bg-white/10 rounded-lg text-gray-300 flex items-center gap-2">
          <RotateCw :size="16" /> Renew All
        </button>
        <button @click="showObtain = true" class="px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg flex items-center gap-2">
          <Plus :size="16" /> New Certificate
        </button>
      </div>
    </div>

    <div v-if="error" class="bg-red-500/10 border border-red-500/20 text-red-400 p-4 rounded-xl mb-6">
      {{ error }}
    </div>

    <div class="bg-black/20 border border-white/5 rounded-xl overflow-hidden">
      <div class="grid grid-cols-12 gap-4 p-4 border-b border-white/5 text-xs font-medium text-gray-500 uppercase tracking-wider">
        <div class="col-span-3">Domain</div>
        <div class="col-span-3">Issuer</div>
        <div class="col-span-2">Expires</div>
        <div class="col-span-2">Days Left</div>
        <div class="col-span-2 text-right">Actions</div>
      </div>

      <div v-if="loading" class="p-8 text-center text-gray-500">Loading...</div>
      <div v-else-if="certificates.length === 0" class="p-8 text-center text-gray-500">No certificates found</div>

      <div v-for="cert in certificates" :key="cert.domain" 
           class="grid grid-cols-12 gap-4 p-4 items-center border-b border-white/5 last:border-0 hover:bg-white/5 transition-colors">
        <div class="col-span-3 font-medium text-white flex items-center gap-2">
          <CheckCircle v-if="cert.is_valid" class="text-green-400" :size="16" />
          <AlertCircle v-else class="text-red-400" :size="16" />
          {{ cert.domain }}
        </div>
        <div class="col-span-3 text-gray-400 truncate">{{ cert.issuer }}</div>
        <div class="col-span-2 text-gray-400 text-sm">{{ new Date(cert.expires_at).toLocaleDateString() }}</div>
        <div class="col-span-2">
          <span :class="getDaysColor(cert.days_left)" class="font-medium">{{ cert.days_left }} days</span>
        </div>
        <div class="col-span-2 flex items-center justify-end space-x-2">
          <button @click="renewCertificate(cert.domain)" 
                  class="p-1.5 hover:bg-blue-500/10 rounded-lg text-gray-400 hover:text-blue-500 transition-colors" title="Renew">
            <RotateCw :size="16" />
          </button>
          <button @click="revokeCertificate(cert.domain)" 
                  class="p-1.5 hover:bg-red-500/10 rounded-lg text-gray-400 hover:text-red-500 transition-colors" title="Revoke">
            <Trash2 :size="16" />
          </button>
        </div>
      </div>
    </div>

    <!-- Obtain Modal -->
    <div v-if="showObtain" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50" @click.self="showObtain = false">
      <div class="bg-gray-900 border border-white/10 rounded-xl w-96 p-6">
        <h3 class="text-lg font-bold text-white mb-4">Obtain SSL Certificate</h3>
        <div class="space-y-4">
          <div>
            <label class="block text-sm text-gray-400 mb-1">Domain</label>
            <input v-model="newDomain" type="text" placeholder="example.com" class="w-full bg-black/30 border border-white/10 rounded-lg px-4 py-2 text-white" />
          </div>
          <div>
            <label class="block text-sm text-gray-400 mb-1">Email (optional)</label>
            <input v-model="newEmail" type="email" placeholder="admin@example.com" class="w-full bg-black/30 border border-white/10 rounded-lg px-4 py-2 text-white" />
          </div>
        </div>
        <div class="flex gap-3 mt-6">
          <button @click="showObtain = false" class="flex-1 py-2 bg-white/10 hover:bg-white/20 rounded-lg text-white">Cancel</button>
          <button @click="obtainCertificate" :disabled="obtaining" class="flex-1 py-2 bg-green-600 hover:bg-green-700 rounded-lg text-white disabled:opacity-50">
            {{ obtaining ? 'Obtaining...' : 'Obtain' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
