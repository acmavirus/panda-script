<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import { Users, Plus, Trash2, Shield, User } from 'lucide-vue-next'

const users = ref([])
const loading = ref(false)
const showCreate = ref(false)
const newUser = ref({ username: '', password: '', role: 'user' })

const fetchUsers = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/users/')
    users.value = res.data || []
  } catch (err) {
    console.error(err)
  } finally {
    loading.value = false
  }
}

const createUser = async () => {
  try {
    await axios.post('/api/users/', newUser.value)
    showCreate.value = false
    newUser.value = { username: '', password: '', role: 'user' }
    fetchUsers()
  } catch (err) {
    alert('Failed: ' + (err.response?.data?.error || err.message))
  }
}

const deleteUser = async (id, username) => {
  if (!confirm(`Delete user ${username}?`)) return
  try {
    await axios.delete(`/api/users/${id}`)
    fetchUsers()
  } catch (err) {
    alert('Failed: ' + (err.response?.data?.error || err.message))
  }
}

const changeRole = async (id, currentRole) => {
  const newRole = currentRole === 'admin' ? 'user' : 'admin'
  try {
    await axios.put(`/api/users/${id}/role`, { role: newRole })
    fetchUsers()
  } catch (err) {
    alert('Failed: ' + (err.response?.data?.error || err.message))
  }
}

onMounted(fetchUsers)
</script>

<template>
  <div class="p-8">
    <div class="flex items-center justify-between mb-8">
      <div>
        <h2 class="text-2xl font-bold text-white tracking-tight flex items-center gap-2">
          <Users class="text-cyan-400" />
          User Management
        </h2>
        <p class="text-gray-500 mt-1">Manage panel users and roles</p>
      </div>
      <button @click="showCreate = true" class="px-4 py-2 bg-cyan-600 hover:bg-cyan-700 text-white rounded-lg flex items-center gap-2">
        <Plus :size="16" /> Add User
      </button>
    </div>

    <div class="bg-black/20 border border-white/5 rounded-xl overflow-hidden">
      <div class="grid grid-cols-12 gap-4 p-4 border-b border-white/5 text-xs font-medium text-gray-500 uppercase tracking-wider">
        <div class="col-span-1">ID</div>
        <div class="col-span-4">Username</div>
        <div class="col-span-2">Role</div>
        <div class="col-span-2">2FA</div>
        <div class="col-span-3 text-right">Actions</div>
      </div>

      <div v-if="loading" class="p-8 text-center text-gray-500">Loading...</div>
      <div v-else-if="users.length === 0" class="p-8 text-center text-gray-500">No users found</div>

      <div v-for="user in users" :key="user.id" 
           class="grid grid-cols-12 gap-4 p-4 items-center border-b border-white/5 last:border-0 hover:bg-white/5 transition-colors">
        <div class="col-span-1 text-gray-500">{{ user.id }}</div>
        <div class="col-span-4 font-medium text-white flex items-center gap-2">
          <User :size="16" class="text-gray-400" />
          {{ user.username }}
        </div>
        <div class="col-span-2">
          <span :class="user.role === 'admin' ? 'bg-purple-500/10 text-purple-400 border-purple-500/20' : 'bg-gray-500/10 text-gray-400 border-gray-500/20'"
                class="px-2 py-1 rounded-md text-xs border font-medium uppercase">
            {{ user.role }}
          </span>
        </div>
        <div class="col-span-2">
          <span v-if="user.two_factor_enabled" class="text-green-400">Enabled</span>
          <span v-else class="text-gray-500">Disabled</span>
        </div>
        <div class="col-span-3 flex items-center justify-end space-x-2">
          <button v-if="user.username !== 'admin'" @click="changeRole(user.id, user.role)" 
                  class="px-2 py-1 text-xs bg-white/5 hover:bg-white/10 rounded text-gray-300">
            {{ user.role === 'admin' ? 'Demote' : 'Promote' }}
          </button>
          <button v-if="user.username !== 'admin'" @click="deleteUser(user.id, user.username)" 
                  class="p-1.5 hover:bg-red-500/10 rounded text-gray-400 hover:text-red-500">
            <Trash2 :size="16" />
          </button>
        </div>
      </div>
    </div>

    <!-- Create Modal -->
    <div v-if="showCreate" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50" @click.self="showCreate = false">
      <div class="bg-gray-900 border border-white/10 rounded-xl w-96 p-6">
        <h3 class="text-lg font-bold text-white mb-4">Create User</h3>
        <div class="space-y-4">
          <div>
            <label class="block text-sm text-gray-400 mb-1">Username</label>
            <input v-model="newUser.username" type="text" class="w-full bg-black/30 border border-white/10 rounded-lg px-4 py-2 text-white" />
          </div>
          <div>
            <label class="block text-sm text-gray-400 mb-1">Password</label>
            <input v-model="newUser.password" type="password" class="w-full bg-black/30 border border-white/10 rounded-lg px-4 py-2 text-white" />
          </div>
          <div>
            <label class="block text-sm text-gray-400 mb-1">Role</label>
            <select v-model="newUser.role" class="w-full bg-black/30 border border-white/10 rounded-lg px-4 py-2 text-white">
              <option value="user">User</option>
              <option value="admin">Admin</option>
            </select>
          </div>
        </div>
        <div class="flex gap-3 mt-6">
          <button @click="showCreate = false" class="flex-1 py-2 bg-white/10 hover:bg-white/20 rounded-lg text-white">Cancel</button>
          <button @click="createUser" class="flex-1 py-2 bg-cyan-600 hover:bg-cyan-700 rounded-lg text-white">Create</button>
        </div>
      </div>
    </div>
  </div>
</template>
