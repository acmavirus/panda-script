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
  <div class="p-4 lg:p-8">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between mb-8 gap-4">
      <div>
        <h2 class="text-xl lg:text-2xl font-bold text-white tracking-tight flex items-center gap-2">
          <Lock class="text-green-400" :size="24" />
          SSL Certificates
        </h2>
        <p class="text-xs lg:text-sm text-gray-500 mt-1 uppercase tracking-widest font-bold">Let's Encrypt CA</p>
      </div>
      <div class="flex items-center gap-2">
        <button @click="renewAll" class="flex-1 sm:flex-none px-4 py-2 bg-white/5 hover:bg-white/10 rounded-xl text-gray-300 flex items-center justify-center gap-2 text-sm transition-all border border-white/5">
          <RotateCw :size="16" /> <span class="hidden sm:inline">Renew All</span><span class="sm:hidden">Renew</span>
        </button>
        <button @click="showObtain = true" class="flex-1 sm:flex-none px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-xl flex items-center justify-center gap-2 text-sm transition-all shadow-lg shadow-green-600/20">
          <Plus :size="16" /> Create
        </button>
      </div>
    </div>

    <div v-if="error" class="bg-red-500/10 border border-red-500/20 text-red-400 p-3 rounded-xl mb-6 text-xs shadow-lg">
      {{ error }}
    </div>

    <div class="bg-black/20 border border-white/5 rounded-xl overflow-hidden">
      <!-- Horizontal Scroll Wrapper -->
      <div class="overflow-x-auto">
        <div class="min-w-[850px]">
          <!-- Header -->
          <div class="grid grid-cols-12 gap-4 p-4 border-b border-white/5 text-[10px] lg:text-xs font-bold text-gray-500 uppercase tracking-widest bg-white/2">
            <div class="col-span-3">Domain</div>
            <div class="col-span-3">Issuer</div>
            <div class="col-span-2 text-center">Expiry Date</div>
            <div class="col-span-2 text-center">Remaining</div>
            <div class="col-span-2 text-right pr-4">Actions</div>
          </div>

          <div v-if="loading && certificates.length === 0" class="p-16 text-center text-gray-500 flex flex-col items-center gap-3">
             <div class="animate-spin w-6 h-6 border-2 border-green-500 border-t-transparent rounded-full"></div>
             <p class="text-xs font-mono">Scanning certificates...</p>
          </div>
          <div v-else-if="certificates.length === 0" class="p-16 text-center text-gray-500 text-sm italic">No SSL certificates found</div>

          <div v-for="cert in certificates" :key="cert.domain" 
               class="grid grid-cols-12 gap-4 p-4 items-center border-b border-white/5 last:border-0 hover:bg-white/5 transition-colors">
            <div class="col-span-3 font-bold text-gray-200 flex items-center gap-3">
              <div :class="cert.is_valid ? 'bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.4)]' : 'bg-red-500 shadow-[0_0_8px_rgba(239,68,68,0.4)]'" class="w-2 h-2 rounded-full shrink-0"></div>
              <span class="truncate">{{ cert.domain }}</span>
            </div>
            <div class="col-span-3 text-gray-400 text-xs truncate italic" :title="cert.issuer">{{ cert.issuer }}</div>
            <div class="col-span-2 text-center text-gray-500 text-xs font-mono">{{ new Date(cert.expires_at).toLocaleDateString() }}</div>
            <div class="col-span-2 text-center">
              <span :class="getDaysColor(cert.days_left)" class="text-xs font-bold font-mono px-2 py-0.5 rounded-md bg-white/5 border border-white/5">
                {{ cert.days_left }}d
              </span>
            </div>
            <div class="col-span-2 flex items-center justify-end space-x-2 pr-2">
              <button @click="renewCertificate(cert.domain)" 
                      class="p-2 hover:bg-blue-500/10 rounded-lg text-gray-500 hover:text-blue-500 transition-colors" title="Renew Individual">
                <RotateCw :size="16" />
              </button>
              <button @click="revokeCertificate(cert.domain)" 
                      class="p-2 hover:bg-red-500/10 rounded-lg text-gray-500 hover:text-red-500 transition-colors" title="Revoke">
                <Trash2 :size="16" />
              </button>
            </div>
          </div>
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
