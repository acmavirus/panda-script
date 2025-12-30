<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import { Shield, Lock, Unlock, Plus, Trash2, RotateCw } from 'lucide-vue-next'
import { useToastStore } from '../stores/toast'
const toast = useToastStore()

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
    toast.error('Failed: ' + (err.response?.data?.error || err.message))
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
    toast.error('Failed: ' + (err.response?.data?.error || err.message))
  }
}

const deleteRule = async (id) => {
  if (!confirm('Delete this rule?')) return
  try {
    await axios.delete(`/api/security/rule/${id}`)
    fetchFirewall()
  } catch (err) {
    toast.error('Failed: ' + (err.response?.data?.error || err.message))
  }
}

const changeSSHPort = async () => {
  const port = prompt('Enter new SSH port:', sshPort.value)
  if (!port) return
  try {
    await axios.put('/api/security/ssh-port', { port: parseInt(port) })
    sshPort.value = parseInt(port)
    toast.success('SSH port changed to ' + port)
  } catch (err) {
    toast.error('Failed: ' + (err.response?.data?.error || err.message))
  }
}

onMounted(() => {
  fetchFirewall()
})
</script>

<template>
  <div class="p-4 lg:p-8">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between mb-8 gap-4">
      <div>
        <h2 class="text-xl lg:text-2xl font-bold text-white tracking-tight flex items-center gap-2">
          <Shield class="text-orange-400" :size="24" />
          Security & Firewall
        </h2>
        <p class="text-xs lg:text-sm text-gray-400 mt-1 uppercase tracking-widest font-bold">System protection</p>
      </div>
      <button @click="fetchFirewall" class="p-3 sm:p-2 bg-white/5 rounded-lg hover:bg-white/10 transition-colors flex items-center justify-center">
        <RotateCw :size="18" :class="{'animate-spin': loading}" class="text-gray-400" />
      </button>
    </div>

    <div v-if="error" class="bg-red-500/10 border border-red-500/20 text-red-400 p-3 rounded-xl mb-6 text-xs">
      {{ error }}
    </div>

    <!-- Status Cards -->
    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 lg:gap-6 mb-6">
      <div class="bg-black/20 border border-white/5 rounded-2xl p-6 shadow-xl">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-gray-500 text-[10px] uppercase font-bold tracking-widest mb-1">Firewall Status</h3>
            <p class="text-2xl font-black italic tracking-tighter" :class="firewall.enabled ? 'text-green-500' : 'text-red-500'">
              {{ firewall.enabled ? 'ACTIVE' : 'INACTIVE' }}
            </p>
          </div>
          <button @click="toggleFirewall" 
                  :class="firewall.enabled ? 'bg-red-500/10 hover:bg-red-500/20 text-red-400 border-red-500/20' : 'bg-green-500/10 hover:bg-green-500/20 text-green-400 border-green-500/20'"
                  class="p-3 rounded-xl transition-all border shadow-lg">
            <Lock v-if="!firewall.enabled" :size="22" />
            <Unlock v-else :size="22" />
          </button>
        </div>
      </div>
      <div class="bg-black/20 border border-white/5 rounded-2xl p-6 shadow-xl">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-gray-500 text-[10px] uppercase font-bold tracking-widest mb-1">SSH Access Port</h3>
            <p class="text-2xl font-black text-white italic tracking-tighter">{{ sshPort }}</p>
          </div>
          <button @click="changeSSHPort" class="px-4 py-2 bg-white/5 hover:bg-white/10 rounded-xl text-gray-300 transition-all border border-white/5 text-sm font-bold">
            Change
          </button>
        </div>
      </div>
    </div>

    <!-- Firewall Rules -->
    <div class="bg-black/20 border border-white/5 rounded-2xl overflow-hidden shadow-2xl">
      <div class="flex items-center justify-between p-4 border-b border-white/10 bg-white/2">
        <h3 class="text-base font-bold text-white flex items-center gap-2">
           <Shield :size="18" class="text-orange-400" /> Firewall Rules
        </h3>
        <button @click="showWhitelist = true" class="px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-xl flex items-center gap-2 text-sm font-bold shadow-lg shadow-green-600/20">
          <Plus :size="16" /> Add IP
        </button>
      </div>

      <!-- Horizontal Scroll Wrapper -->
      <div class="overflow-x-auto">
        <div class="min-w-[800px]">
          <!-- Header -->
          <div class="grid grid-cols-12 gap-4 p-4 border-b border-white/5 text-[10px] lg:text-xs font-medium text-gray-500 uppercase tracking-widest bg-white/2">
            <div class="col-span-1">#</div>
            <div class="col-span-4">Target (To)</div>
            <div class="col-span-3">Policy</div>
            <div class="col-span-3">Source (From)</div>
            <div class="col-span-1 text-right pr-4">Kill</div>
          </div>

          <div v-if="loading && (!firewall.rules || firewall.rules.length === 0)" class="p-16 text-center text-gray-500">
             <div class="animate-spin inline-block w-6 h-6 border-2 border-orange-500 border-t-transparent rounded-full mb-3"></div>
             <p class="text-xs font-mono">Analyzing rules...</p>
          </div>
          <div v-else-if="!firewall.rules || firewall.rules.length === 0" class="p-16 text-center text-gray-500 text-sm italic">No active firewall rules</div>

          <div v-for="rule in firewall.rules" :key="rule.id" 
               class="grid grid-cols-12 gap-4 p-4 items-center border-b border-white/5 last:border-0 hover:bg-white/5 transition-colors">
            <div class="col-span-1 text-gray-600 font-mono text-xs">{{ rule.id }}</div>
            <div class="col-span-4 font-mono text-gray-200 text-xs">{{ rule.to }}</div>
            <div class="col-span-3">
              <span :class="rule.action === 'ALLOW' ? 'bg-green-500/10 text-green-400 border-green-500/20' : 'bg-red-500/10 text-red-400 border-red-500/20'" 
                    class="px-2 py-0.5 rounded text-[10px] font-bold border uppercase tracking-wider">
                {{ rule.action }}
              </span>
            </div>
            <div class="col-span-3 text-gray-400 text-xs truncate">{{ rule.from }}</div>
            <div class="col-span-1 flex justify-end pr-2">
              <button @click="deleteRule(rule.id)" class="p-2 hover:bg-red-500/10 rounded-lg text-gray-500 hover:text-red-500 transition-colors">
                <Trash2 :size="16" />
              </button>
            </div>
          </div>
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
