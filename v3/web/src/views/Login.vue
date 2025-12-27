<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const username = ref('')
const password = ref('')
const error = ref('')
const router = useRouter()
const authStore = useAuthStore()

const handleLogin = async () => {
  error.value = ''
  const success = await authStore.login(username.value, password.value)
  if (success) {
    router.push('/')
  } else {
    error.value = 'Invalid username or password'
  }
}
</script>

<template>
  <div class="min-h-screen bg-panda-dark flex items-center justify-center p-4">
    <div class="bg-black/40 border border-white/5 p-8 rounded-2xl w-full max-w-md shadow-2xl">
      <div class="text-center mb-8">
        <div class="w-16 h-16 bg-panda-primary rounded-2xl flex items-center justify-center shadow-lg shadow-panda-primary/20 mx-auto mb-4">
          <span class="text-4xl">🐼</span>
        </div>
        <h1 class="text-2xl font-bold text-white tracking-tight">Welcome Back</h1>
        <p class="text-gray-500 mt-2">Sign in to Panda Panel</p>
      </div>

      <form @submit.prevent="handleLogin" class="space-y-6">
        <div>
          <label class="block text-sm font-medium text-gray-400 mb-2">Username</label>
          <input v-model="username" type="text" 
                 class="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white focus:border-panda-primary focus:ring-1 focus:ring-panda-primary outline-none transition-all"
                 placeholder="Enter username">
        </div>
        
        <div>
          <label class="block text-sm font-medium text-gray-400 mb-2">Password</label>
          <input v-model="password" type="password" 
                 class="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white focus:border-panda-primary focus:ring-1 focus:ring-panda-primary outline-none transition-all"
                 placeholder="Enter password">
        </div>

        <div v-if="error" class="text-red-500 text-sm text-center">
          {{ error }}
        </div>

        <button type="submit" 
                class="w-full bg-panda-primary hover:bg-panda-primary/90 text-white font-bold py-3 px-4 rounded-xl transition-all duration-200 transform active:scale-95 shadow-lg shadow-panda-primary/25">
          Sign In
        </button>
      </form>
    </div>
  </div>
</template>
