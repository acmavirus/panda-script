<script setup>
import { useToastStore } from '../stores/toast'
import { CheckCircle, XCircle, AlertCircle, Info, X } from 'lucide-vue-next'

const toastStore = useToastStore()

const getIcon = (type) => {
  switch (type) {
    case 'success': return CheckCircle
    case 'error': return XCircle
    case 'warning': return AlertCircle
    default: return Info
  }
}

const getClasses = (type) => {
  switch (type) {
    case 'success': return 'bg-green-50 text-green-800 border-green-200 dark:bg-green-500/10 dark:text-green-400 dark:border-green-500/20'
    case 'error': return 'bg-red-50 text-red-800 border-red-200 dark:bg-red-500/10 dark:text-red-400 dark:border-red-500/20'
    case 'warning': return 'bg-amber-50 text-amber-800 border-amber-200 dark:bg-amber-500/10 dark:text-amber-400 dark:border-amber-500/20'
    default: return 'bg-blue-50 text-blue-800 border-blue-200 dark:bg-blue-500/10 dark:text-blue-400 dark:border-blue-500/20'
  }
}
</script>

<template>
  <Teleport to="body">
    <div class="fixed top-4 right-4 z-[999] flex flex-col gap-3 pointer-events-none">
      <TransitionGroup name="toast">
        <div 
          v-for="toast in toastStore.toasts" 
          :key="toast.id"
          class="flex items-center gap-3 px-4 py-3 rounded-xl border shadow-lg pointer-events-auto min-w-[300px] max-w-md animate-slide-in"
          :class="getClasses(toast.type)"
        >
          <component :is="getIcon(toast.type)" :size="20" class="flex-shrink-0" />
          <p class="text-sm font-medium flex-1">{{ toast.message }}</p>
          <button @click="toastStore.remove(toast.id)" class="p-1 hover:bg-black/5 dark:hover:bg-white/10 rounded-lg transition-colors">
            <X :size="16" />
          </button>
        </div>
      </TransitionGroup>
    </div>
  </Teleport>
</template>

<style scoped>
.toast-enter-active,
.toast-leave-active {
  transition: all 0.3s ease;
}
.toast-enter-from {
  opacity: 0;
  transform: translateX(30px) scale(0.9);
}
.toast-leave-to {
  opacity: 0;
  transform: translateX(30px);
}

@keyframes slide-in {
  from { transform: translateX(100%); opacity: 0; }
  to { transform: translateX(0); opacity: 1; }
}
.animate-slide-in {
  animation: slide-in 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}
</style>
