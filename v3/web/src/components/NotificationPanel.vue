<script setup>
import { ref, onMounted, computed } from 'vue'
import { Bell, X, Check, CheckCheck, Trash2, Settings, Send, Mail, MessageCircle } from 'lucide-vue-next'
import axios from 'axios'
import { useToastStore } from '../stores/toast'

const toast = useToastStore()

const props = defineProps({
  show: Boolean
})

const emit = defineEmits(['close', 'update:count'])

const notifications = ref([])
const loading = ref(false)
const showSettings = ref(false)

const config = ref({
  telegram_enabled: false,
  telegram_bot_token: '',
  telegram_chat_id: '',
  email_enabled: false,
  email_smtp: '',
  email_port: 587,
  email_user: '',
  email_password: '',
  email_to: '',
  panel_enabled: true
})

const unreadCount = computed(() => notifications.value.filter(n => !n.read).length)

const fetchNotifications = async () => {
  loading.value = true
  try {
    const res = await axios.get('/api/notifications/')
    notifications.value = res.data.notifications || []
    emit('update:count', unreadCount.value)
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
}

const fetchConfig = async () => {
  try {
    const res = await axios.get('/api/notifications/config')
    config.value = { ...config.value, ...res.data }
  } catch (e) {
    console.error(e)
  }
}

const saveConfig = async () => {
  try {
    await axios.put('/api/notifications/config', config.value)
    toast.success('Settings saved!')
  } catch (e) {
    toast.error('Failed to save settings')
  }
}

const markAsRead = async (id) => {
  try {
    await axios.post(`/api/notifications/${id}/read`)
    const notif = notifications.value.find(n => n.id === id)
    if (notif) notif.read = true
    emit('update:count', unreadCount.value)
  } catch (e) {
    console.error(e)
  }
}

const markAllAsRead = async () => {
  try {
    await axios.post('/api/notifications/read-all')
    notifications.value.forEach(n => n.read = true)
    emit('update:count', 0)
  } catch (e) {
    console.error(e)
  }
}

const clearAll = async () => {
  if (!confirm('Clear all notifications?')) return
  try {
    await axios.delete('/api/notifications/')
    notifications.value = []
    emit('update:count', 0)
  } catch (e) {
    console.error(e)
  }
}

const testTelegram = async () => {
  try {
    await axios.post('/api/notifications/test/telegram')
    toast.success('Test notification sent to Telegram!')
  } catch (e) {
    toast.error('Failed to send test notification')
  }
}

const testEmail = async () => {
  try {
    await axios.post('/api/notifications/test/email')
    toast.success('Test email sent!')
  } catch (e) {
    toast.error('Failed to send test email')
  }
}

const getTypeColor = (type) => {
  switch (type) {
    case 'success': return 'var(--color-success)'
    case 'error': return 'var(--color-error)'
    case 'warning': return 'var(--color-warning)'
    default: return 'var(--color-info)'
  }
}

const getTypeIcon = (type) => {
  switch (type) {
    case 'success': return '✅'
    case 'error': return '❌'
    case 'warning': return '⚠️'
    default: return 'ℹ️'
  }
}

onMounted(() => {
  fetchNotifications()
  fetchConfig()
})
</script>

<template>
  <Teleport to="body">
    <Transition name="slide">
      <div 
        v-if="show" 
        class="fixed inset-y-0 right-0 w-full max-w-md z-50 flex flex-col"
        style="background: var(--bg-elevated); border-left: 1px solid var(--border-color);"
      >
        <!-- Header -->
        <div class="flex items-center justify-between px-4 py-3 border-b" style="border-color: var(--border-color);">
          <div class="flex items-center gap-2">
            <Bell :size="18" style="color: var(--color-primary);" />
            <h2 class="font-semibold" style="color: var(--text-primary);">Notifications</h2>
            <span 
              v-if="unreadCount > 0"
              class="px-2 py-0.5 rounded-full text-xs font-medium"
              style="background: var(--color-primary); color: white;"
            >
              {{ unreadCount }}
            </span>
          </div>
          <div class="flex items-center gap-1">
            <button @click="showSettings = !showSettings" class="panda-btn panda-btn-ghost p-2" title="Settings">
              <Settings :size="16" />
            </button>
            <button @click="emit('close')" class="panda-btn panda-btn-ghost p-2">
              <X :size="18" />
            </button>
          </div>
        </div>

        <!-- Settings Panel -->
        <Transition name="fade">
          <div v-if="showSettings" class="p-4 border-b space-y-4" style="border-color: var(--border-color); background: var(--bg-surface);">
            <h3 class="text-sm font-semibold" style="color: var(--text-primary);">Notification Settings</h3>
            
            <!-- Telegram -->
            <div class="space-y-2">
              <label class="flex items-center gap-2 cursor-pointer">
                <input type="checkbox" v-model="config.telegram_enabled" class="rounded" />
                <MessageCircle :size="14" />
                <span class="text-sm">Telegram</span>
              </label>
              <div v-if="config.telegram_enabled" class="space-y-2 pl-6">
                <input 
                  v-model="config.telegram_bot_token" 
                  placeholder="Bot Token"
                  class="panda-input text-sm"
                />
                <input 
                  v-model="config.telegram_chat_id" 
                  placeholder="Chat ID"
                  class="panda-input text-sm"
                />
                <button @click="testTelegram" class="panda-btn panda-btn-secondary text-xs">
                  <Send :size="12" /> Test
                </button>
              </div>
            </div>

            <!-- Email -->
            <div class="space-y-2">
              <label class="flex items-center gap-2 cursor-pointer">
                <input type="checkbox" v-model="config.email_enabled" class="rounded" />
                <Mail :size="14" />
                <span class="text-sm">Email</span>
              </label>
              <div v-if="config.email_enabled" class="space-y-2 pl-6">
                <div class="grid grid-cols-2 gap-2">
                  <input v-model="config.email_smtp" placeholder="SMTP Server" class="panda-input text-sm" />
                  <input v-model.number="config.email_port" placeholder="Port" type="number" class="panda-input text-sm" />
                </div>
                <input v-model="config.email_user" placeholder="Username" class="panda-input text-sm" />
                <input v-model="config.email_password" placeholder="Password" type="password" class="panda-input text-sm" />
                <input v-model="config.email_to" placeholder="To Email" class="panda-input text-sm" />
                <button @click="testEmail" class="panda-btn panda-btn-secondary text-xs">
                  <Send :size="12" /> Test
                </button>
              </div>
            </div>

            <!-- Panel -->
            <label class="flex items-center gap-2 cursor-pointer">
              <input type="checkbox" v-model="config.panel_enabled" class="rounded" />
              <Bell :size="14" />
              <span class="text-sm">Panel Notifications</span>
            </label>

            <button @click="saveConfig" class="panda-btn panda-btn-primary w-full text-sm">
              Save Settings
            </button>
          </div>
        </Transition>

        <!-- Actions -->
        <div class="flex items-center gap-2 px-4 py-2 border-b" style="border-color: var(--border-color);">
          <button @click="markAllAsRead" class="panda-btn panda-btn-ghost text-xs" :disabled="unreadCount === 0">
            <CheckCheck :size="14" /> Mark all read
          </button>
          <button @click="clearAll" class="panda-btn panda-btn-ghost text-xs" :disabled="notifications.length === 0">
            <Trash2 :size="14" /> Clear all
          </button>
        </div>

        <!-- Notifications List -->
        <div class="flex-1 overflow-y-auto">
          <div v-if="loading" class="p-8 text-center" style="color: var(--text-muted);">
            Loading...
          </div>
          
          <div v-else-if="notifications.length === 0" class="p-8 text-center" style="color: var(--text-muted);">
            <Bell :size="40" class="mx-auto mb-2 opacity-30" />
            <p>No notifications</p>
          </div>
          
          <div v-else>
            <div 
              v-for="notif in notifications" 
              :key="notif.id"
              class="flex gap-3 p-4 border-b transition-colors cursor-pointer hover:bg-[var(--bg-hover)]"
              :class="{ 'opacity-60': notif.read }"
              style="border-color: var(--border-color);"
              @click="markAsRead(notif.id)"
            >
              <div 
                class="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 text-sm"
                :style="`background: ${getTypeColor(notif.type)}20;`"
              >
                {{ getTypeIcon(notif.type) }}
              </div>
              <div class="flex-1 min-w-0">
                <div class="flex items-start justify-between gap-2">
                  <h4 class="text-sm font-medium truncate" style="color: var(--text-primary);">
                    {{ notif.title }}
                  </h4>
                  <span 
                    v-if="!notif.read" 
                    class="w-2 h-2 rounded-full flex-shrink-0"
                    style="background: var(--color-primary);"
                  ></span>
                </div>
                <p class="text-xs mt-0.5 line-clamp-2" style="color: var(--text-muted);">
                  {{ notif.message }}
                </p>
                <p class="text-xs mt-1" style="color: var(--text-muted);">
                  {{ notif.created_at }}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.slide-enter-active,
.slide-leave-active {
  transition: transform 0.3s ease;
}
.slide-enter-from,
.slide-leave-to {
  transform: translateX(100%);
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
