<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import { Shield, Lock, Unlock, Plus, Trash2, RotateCw } from 'lucide-vue-next'

const firewall = ref({ enabled: false, rules: [] })
const sshPort = ref(22)
const loading = ref(false)
const error = ref('')
const showWhitelist = ref(false)
const newIP = ref('')
const newPort = ref('')

const fetchFirewall = async () => {
  loading.value = true
  error.value = ''
  try {
    const res = await axios.get('/api/security/firewall')
    firewall.value = res.data || { enabled: false, rules: [] }
    const sshRes = await axios.get('/api/security/ssh-port')
    sshPort.value = sshRes.data?.port || 22
  } catch (err) {
    error.value = err.response?.data?.error || 'Failed to load firewall status'
  } finally {
    loading.value = false
  }
}

const toggleFirewall = async () => {
  try {
    const action = firewall.value.enabled ? 'disable' : 'enable'
    await axios.post(`/api/security/firewall/${action}`)
    fetchFirewall()
  } catch (err) {
    alert('Failed: ' + (err.response?.data?.error || err.message))
  }
}

const whitelistIP = async () => {
  if (!newIP.value) return
  try {
    await axios.post('/api/security/whitelist', { ip: newIP.value, port: parseInt(newPort.value) || 0 })
    newIP.value = ''
    newPort.value = ''
    showWhitelist.value = false
    fetchFirewall()
  } catch (err) {
    alert('Failed: ' + (err.response?.data?.error || err.message))
  }
}

const deleteRule = async (id) => {
  if (!confirm('Delete this rule?')) return
  try {
    await axios.delete(`/api/security/rule/${id}`)
    fetchFirewall()
  } catch (err) {
    alert('Failed: ' + (err.response?.data?.error || err.message))
  }
}

const changeSSHPort = async () => {
  const port = prompt('Enter new SSH port:', sshPort.value)
  if (!port) return
  try {
    await axios.put('/api/security/ssh-port', { port: parseInt(port) })
    sshPort.value = parseInt(port)
    alert('SSH port changed to ' + port)
  } catch (err) {
    alert('Failed: ' + (err.response?.data?.error || err.message))
  }
}

onMounted(() => {
  fetchFirewall()
})
</script>

<template>
  <div class="p-8">
    <div class="flex items-center justify-between mb-8">
      <div>
        <h2 class="text-2xl font-bold text-white tracking-tight flex items-center gap-2">
          <Shield class="text-orange-400" />
          Security & Firewall
        </h2>
        <p class="text-gray-500 mt-1">Manage firewall rules and SSH settings</p>
      </div>
      <button @click="fetchFirewall" class="p-2 bg-white/5 rounded-lg hover:bg-white/10 transition-colors">
        <RotateCw :size="20" class="text-gray-400" />
      </button>
    </div>

    <div v-if="error" class="bg-red-500/10 border border-red-500/20 text-red-400 p-4 rounded-xl mb-6">
      {{ error }}
    </div>

    <!-- Status Cards -->
    <div class="grid grid-cols-2 gap-6 mb-6">
      <div class="bg-black/20 border border-white/5 rounded-xl p-6">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-gray-400 text-sm">Firewall Status</h3>
            <p class="text-2xl font-bold" :class="firewall.enabled ? 'text-green-400' : 'text-red-400'">
              {{ firewall.enabled ? 'ACTIVE' : 'INACTIVE' }}
            </p>
          </div>
          <button @click="toggleFirewall" 
                  :class="firewall.enabled ? 'bg-red-500/10 hover:bg-red-500/20 text-red-400' : 'bg-green-500/10 hover:bg-green-500/20 text-green-400'"
                  class="p-3 rounded-lg transition-colors">
            <Lock v-if="!firewall.enabled" :size="24" />
            <Unlock v-else :size="24" />
          </button>
        </div>
      </div>
      <div class="bg-black/20 border border-white/5 rounded-xl p-6">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-gray-400 text-sm">SSH Port</h3>
            <p class="text-2xl font-bold text-white">{{ sshPort }}</p>
          </div>
          <button @click="changeSSHPort" class="px-4 py-2 bg-white/5 hover:bg-white/10 rounded-lg text-gray-300 transition-colors">
            Change
          </button>
        </div>
      </div>
    </div>

    <!-- Firewall Rules -->
    <div class="bg-black/20 border border-white/5 rounded-xl overflow-hidden">
      <div class="flex items-center justify-between p-4 border-b border-white/5">
        <h3 class="text-lg font-semibold text-white">Firewall Rules</h3>
        <button @click="showWhitelist = true" class="px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg flex items-center gap-2">
          <Plus :size="16" /> Add IP
        </button>
      </div>

      <div class="grid grid-cols-12 gap-4 p-4 border-b border-white/5 text-xs font-medium text-gray-500 uppercase tracking-wider">
        <div class="col-span-1">#</div>
        <div class="col-span-4">To</div>
        <div class="col-span-3">Action</div>
        <div class="col-span-3">From</div>
        <div class="col-span-1"></div>
      </div>

      <div v-if="loading" class="p-8 text-center text-gray-500">Loading...</div>
      <div v-else-if="!firewall.rules || firewall.rules.length === 0" class="p-8 text-center text-gray-500">No rules configured</div>

      <div v-for="rule in firewall.rules" :key="rule.id" 
           class="grid grid-cols-12 gap-4 p-4 items-center border-b border-white/5 last:border-0 hover:bg-white/5 transition-colors">
        <div class="col-span-1 text-gray-500">{{ rule.id }}</div>
        <div class="col-span-4 font-mono text-white">{{ rule.to }}</div>
        <div class="col-span-3">
          <span :class="rule.action === 'ALLOW' ? 'text-green-400' : 'text-red-400'" class="font-medium">{{ rule.action }}</span>
        </div>
        <div class="col-span-3 text-gray-400">{{ rule.from }}</div>
        <div class="col-span-1">
          <button @click="deleteRule(rule.id)" class="p-1.5 hover:bg-red-500/10 rounded text-gray-400 hover:text-red-500">
            <Trash2 :size="16" />
          </button>
        </div>
      </div>
    </div>

    <!-- Whitelist Modal -->
    <div v-if="showWhitelist" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50" @click.self="showWhitelist = false">
      <div class="bg-gray-900 border border-white/10 rounded-xl w-96 p-6">
        <h3 class="text-lg font-bold text-white mb-4">Whitelist IP</h3>
        <div class="space-y-4">
          <div>
            <label class="block text-sm text-gray-400 mb-1">IP Address</label>
            <input v-model="newIP" type="text" placeholder="192.168.1.1" class="w-full bg-black/30 border border-white/10 rounded-lg px-4 py-2 text-white" />
          </div>
          <div>
            <label class="block text-sm text-gray-400 mb-1">Port (optional)</label>
            <input v-model="newPort" type="number" placeholder="22" class="w-full bg-black/30 border border-white/10 rounded-lg px-4 py-2 text-white" />
          </div>
        </div>
        <div class="flex gap-3 mt-6">
          <button @click="showWhitelist = false" class="flex-1 py-2 bg-white/10 hover:bg-white/20 rounded-lg text-white">Cancel</button>
          <button @click="whitelistIP" class="flex-1 py-2 bg-green-600 hover:bg-green-700 rounded-lg text-white">Add</button>
        </div>
      </div>
    </div>
  </div>
</template>
