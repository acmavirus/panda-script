<script setup>
import { onMounted } from 'vue'
import { useThemeStore } from './stores/theme'

const themeStore = useThemeStore()

// Initialize theme on app mount
onMounted(() => {
  themeStore.loadTheme()
  
  // Add keyboard shortcuts
  window.addEventListener('keydown', (e) => {
    // Ctrl/Cmd + T = Toggle Theme
    if ((e.ctrlKey || e.metaKey) && e.key === 't') {
      e.preventDefault()
      themeStore.toggleTheme()
    }
  })
})
</script>

<template>
  <router-view></router-view>
</template>

<style>
/* Page transition animations */
.page-enter-active,
.page-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}

.page-enter-from {
  opacity: 0;
  transform: translateY(8px);
}

.page-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}
</style>
