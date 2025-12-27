<script setup>
import { ref } from 'vue'
import axios from 'axios'
import { useAuthStore } from '../stores/auth'
import { Lock, Save, AlertCircle, CheckCircle } from 'lucide-vue-next'

const authStore = useAuthStore()

const oldPassword = ref('')
const newPassword = ref('')
const confirmPassword = ref('')
const loading = ref(false)
const message = ref('')
const error = ref('')

const changePassword = async () => {
  error.value = ''
  message.value = ''
  
  if (newPassword.value !== confirmPassword.value) {
    error.value = "New passwords don't match"
    return
  }

  if (newPassword.value.length < 6) {
    error.value = "Password must be at least 6 characters"
    return
  }

  try {
    loading.value = true
    await axios.post('/api/user/password', {
      old_password: oldPassword.value,
      new_password: newPassword.value
    }, {
      headers: { Authorization: `Bearer ${authStore.token}` }
    })
    
    message.value = "Password updated successfully"
    oldPassword.value = ''
    newPassword.value = ''
    confirmPassword.value = ''
  } catch (err) {
    error.value = err.response?.data?.error || "Failed to update password"
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="p-6 max-w-4xl mx-auto">
    <div class="mb-8">
      <h1 class="text-2xl font-bold text-white flex items-center gap-2">
        <Lock class="w-6 h-6 text-panda-primary" /> Settings
      </h1>
      <p class="text-gray-400 mt-1">Manage your account and preferences</p>
    </div>

    <!-- Security Section -->
    <div class="bg-[#1e1e1e] rounded-xl border border-white/10 p-6">
      <h2 class="text-lg font-semibold text-white mb-6 flex items-center gap-2">
        <Lock class="w-5 h-5" /> Security
      </h2>

      <form @submit.prevent="changePassword" class="max-w-md space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-400 mb-1">Current Password</label>
          <input 
            v-model="oldPassword" 
            type="password" 
            required
            class="w-full bg-black/20 border border-white/10 rounded-lg px-4 py-2 text-white focus:border-panda-primary focus:outline-none transition-colors"
          >
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-400 mb-1">New Password</label>
          <input 
            v-model="newPassword" 
            type="password" 
            required
            class="w-full bg-black/20 border border-white/10 rounded-lg px-4 py-2 text-white focus:border-panda-primary focus:outline-none transition-colors"
          >
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-400 mb-1">Confirm New Password</label>
          <input 
            v-model="confirmPassword" 
            type="password" 
            required
            class="w-full bg-black/20 border border-white/10 rounded-lg px-4 py-2 text-white focus:border-panda-primary focus:outline-none transition-colors"
          >
        </div>

        <!-- Alerts -->
        <div v-if="error" class="bg-red-500/10 text-red-400 px-4 py-3 rounded-lg flex items-center gap-2 text-sm">
          <AlertCircle class="w-4 h-4" />
          {{ error }}
        </div>

        <div v-if="message" class="bg-green-500/10 text-green-400 px-4 py-3 rounded-lg flex items-center gap-2 text-sm">
          <CheckCircle class="w-4 h-4" />
          {{ message }}
        </div>

        <button 
          type="submit" 
          :disabled="loading"
          class="bg-panda-primary hover:bg-panda-primary/90 text-white px-6 py-2 rounded-lg flex items-center gap-2 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <Save v-if="!loading" class="w-4 h-4" />
          <div v-else class="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
          Save Changes
        </button>
      </form>
    </div>
  </div>
</template>
