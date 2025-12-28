<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { Lock, User, ArrowRight, AlertCircle } from 'lucide-vue-next'

const username = ref('')
const password = ref('')
const error = ref('')
const loading = ref(false)
const router = useRouter()
const authStore = useAuthStore()

const handleLogin = async () => {
  error.value = ''
  loading.value = true
  
  try {
    const success = await authStore.login(username.value, password.value)
    if (success) {
      router.push('/')
    } else {
      error.value = 'Invalid username or password'
    }
  } catch (e) {
    error.value = 'Connection failed. Please try again.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen flex" style="background: var(--bg-base);">
    <!-- Left side - Branding -->
    <div class="hidden lg:flex lg:w-1/2 flex-col justify-between p-12 relative overflow-hidden" style="background: var(--bg-elevated);">
      <!-- Background Pattern -->
      <div class="absolute inset-0 opacity-5">
        <div class="absolute inset-0" style="background-image: radial-gradient(circle at 1px 1px, currentColor 1px, transparent 0); background-size: 40px 40px;"></div>
      </div>
      
      <!-- Logo -->
      <div class="relative z-10">
        <div class="flex items-center gap-3">
          <div class="w-12 h-12 rounded-xl flex items-center justify-center" style="background: var(--color-primary);">
            <span class="text-2xl">🐼</span>
          </div>
          <div>
            <h1 class="text-xl font-semibold" style="color: var(--text-primary);">Panda Panel</h1>
            <span class="text-xs font-mono" style="color: var(--color-primary);">v3.0.0</span>
          </div>
        </div>
      </div>
      
      <!-- Tagline -->
      <div class="relative z-10">
        <h2 class="text-4xl font-semibold leading-tight" style="color: var(--text-primary);">
          Server Management<br/>
          <span style="color: var(--color-primary);">Made Simple</span>
        </h2>
        <p class="mt-4 text-lg" style="color: var(--text-muted);">
          A modern, fast, and secure way to manage your Linux servers.
        </p>
        
        <!-- Features -->
        <div class="mt-8 space-y-3">
          <div v-for="feature in ['One-Click CMS Deployment', 'Real-time Monitoring', 'Automatic SSL Certificates']" 
               :key="feature"
               class="flex items-center gap-2 text-sm"
               style="color: var(--text-secondary);">
            <span style="color: var(--color-primary);">✓</span>
            {{ feature }}
          </div>
        </div>
      </div>
      
      <!-- Footer -->
      <div class="relative z-10 text-sm" style="color: var(--text-muted);">
        © 2024 Panda Panel. All rights reserved.
      </div>
    </div>
    
    <!-- Right side - Login Form -->
    <div class="w-full lg:w-1/2 flex items-center justify-center p-8">
      <div class="w-full max-w-md">
        <!-- Mobile Logo -->
        <div class="lg:hidden text-center mb-10">
          <div class="w-16 h-16 rounded-2xl flex items-center justify-center mx-auto mb-4" style="background: var(--color-primary);">
            <span class="text-3xl">🐼</span>
          </div>
          <h1 class="text-2xl font-semibold" style="color: var(--text-primary);">Panda Panel</h1>
        </div>
        
        <!-- Form Header -->
        <div class="mb-8">
          <h2 class="text-2xl font-semibold" style="color: var(--text-primary);">Sign in</h2>
          <p class="mt-2" style="color: var(--text-muted);">Enter your credentials to access the panel</p>
        </div>

        <!-- Login Form -->
        <form @submit.prevent="handleLogin" class="space-y-5">
          <!-- Username -->
          <div>
            <label class="block text-sm font-medium mb-2" style="color: var(--text-secondary);">Username</label>
            <div class="relative">
              <User class="absolute left-4 top-1/2 -translate-y-1/2" :size="18" style="color: var(--text-muted);" />
              <input 
                v-model="username" 
                type="text"
                required
                class="panda-input pl-11"
                placeholder="Enter username"
                autocomplete="username"
              >
            </div>
          </div>
          
          <!-- Password -->
          <div>
            <label class="block text-sm font-medium mb-2" style="color: var(--text-secondary);">Password</label>
            <div class="relative">
              <Lock class="absolute left-4 top-1/2 -translate-y-1/2" :size="18" style="color: var(--text-muted);" />
              <input 
                v-model="password" 
                type="password"
                required
                class="panda-input pl-11"
                placeholder="Enter password"
                autocomplete="current-password"
              >
            </div>
          </div>

          <!-- Error -->
          <Transition name="fade">
            <div 
              v-if="error" 
              class="flex items-center gap-2 px-4 py-3 rounded-lg text-sm"
              style="background: var(--color-error-subtle); color: var(--color-error);"
            >
              <AlertCircle :size="16" />
              {{ error }}
            </div>
          </Transition>

          <!-- Submit -->
          <button 
            type="submit"
            :disabled="loading"
            class="w-full panda-btn panda-btn-primary py-3 text-base"
            :class="{ 'opacity-70': loading }"
          >
            <span v-if="loading">Signing in...</span>
            <template v-else>
              Sign In
              <ArrowRight :size="18" />
            </template>
          </button>
        </form>
        
        <!-- Keyboard hint -->
        <p class="mt-6 text-center text-sm" style="color: var(--text-muted);">
          Press <kbd>Enter</kbd> to sign in
        </p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
