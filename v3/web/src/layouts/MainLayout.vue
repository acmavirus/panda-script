<script setup>
import { ref, onMounted, computed } from 'vue'
import { 
  LayoutDashboard, Globe, Database, HardDrive, Terminal, Settings, 
  Bell, Search, User, LogOut, Server, Code, Lock, Shield, 
  Archive, Cpu, Users, Store, Stethoscope, Wrench, Sun, Moon, Menu, X, 
  Package, Rocket, ChevronDown, ChevronRight, FolderOpen, Clock,
  Activity, Container, FileText
} from 'lucide-vue-next'
import { useAuthStore } from '../stores/auth'
import { useThemeStore } from '../stores/theme'
import { useRouter } from 'vue-router'
import CommandPalette from '../components/CommandPalette.vue'
import NotificationPanel from '../components/NotificationPanel.vue'

const authStore = useAuthStore()
const themeStore = useThemeStore()
const router = useRouter()
const sidebarOpen = ref(false)
const commandPaletteRef = ref(null)
const notificationPanelOpen = ref(false)
const unreadNotificationCount = ref(0)

// Collapsible menu groups
const expandedGroups = ref({
  deployment: true,
  management: false,
  environment: false,
  infrastructure: false
})

const toggleGroup = (group) => {
  expandedGroups.value[group] = !expandedGroups.value[group]
}

// Grouped Menu Structure (4 Pillars)
const menuGroups = [
  {
    id: 'deployment',
    label: 'Deployment',
    icon: Rocket,
    items: [
      { icon: Globe, label: 'Websites', path: '/websites' },
      { icon: Database, label: 'Databases', path: '/databases' },
      { icon: Container, label: 'Docker', path: '/docker' },
      { icon: Rocket, label: 'PM2 Manager', path: '/pm2' },
    ]
  },
  {
    id: 'management',
    label: 'Management',
    icon: FolderOpen,
    items: [
      { icon: HardDrive, label: 'Files', path: '/files' },
      { icon: Archive, label: 'Backups', path: '/backup' },
      { icon: Clock, label: 'Cron Jobs', path: '/cron' },
    ]
  },
  {
    id: 'environment',
    label: 'Environment',
    icon: Wrench,
    items: [
      { icon: Code, label: 'PHP Manager', path: '/php' },
      { icon: Server, label: 'Nginx', path: '/nginx' },
      { icon: Store, label: 'App Store', path: '/apps' },
    ]
  },
  {
    id: 'infrastructure',
    label: 'Infrastructure',
    icon: Shield,
    items: [
      { icon: Shield, label: 'Security', path: '/security' },
      { icon: Activity, label: 'System Health', path: '/health' },
      { icon: FileText, label: 'Logs', path: '/logs' },
      { icon: Terminal, label: 'Terminal', path: '/terminal' },
      { icon: Settings, label: 'Settings', path: '/settings' },
    ]
  }
]

// System health status
const systemHealth = ref('healthy')

const handleLogout = () => {
  authStore.logout()
  router.push('/login')
}

const closeSidebar = () => {
  sidebarOpen.value = false
}

const openCommandPalette = () => {
  commandPaletteRef.value?.open()
}

// Check if any item in group is active
const isGroupActive = (group) => {
  return group.items.some(item => router.currentRoute.value.path === item.path)
}

onMounted(() => {
  themeStore.loadTheme()
  
  // Auto-expand group containing active route
  menuGroups.forEach(group => {
    if (isGroupActive(group)) {
      expandedGroups.value[group.id] = true
    }
  })
})
</script>

<template>
  <div class="flex h-screen overflow-hidden" style="background: var(--bg-base); color: var(--text-primary);">
    <!-- Command Palette -->
    <CommandPalette ref="commandPaletteRef" />
    
    <!-- Mobile Overlay -->
    <Transition name="fade">
      <div v-if="sidebarOpen" @click="closeSidebar" class="fixed inset-0 bg-black/60 backdrop-blur-sm z-40 lg:hidden"></div>
    </Transition>
    
    <!-- Sidebar - Grouped Structure -->
    <aside :class="[
      'fixed lg:static inset-y-0 left-0 z-50 w-60 flex flex-col transition-transform duration-300',
      'border-r border-[var(--border-color)]',
      sidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
    ]" style="background: var(--bg-elevated);">
      
      <!-- Logo -->
      <div class="h-14 flex items-center justify-between px-4 border-b border-[var(--border-color)]">
        <router-link to="/" class="flex items-center gap-2">
          <div class="w-8 h-8 rounded-lg flex items-center justify-center" style="background: var(--color-primary);">
            <span class="text-lg">🐼</span>
          </div>
          <div>
            <h1 class="font-semibold text-sm" style="color: var(--text-primary);">Panda Panel</h1>
            <span class="text-[10px] font-mono" style="color: var(--color-primary);">v3.1.0</span>
          </div>
        </router-link>
        <button @click="closeSidebar" class="lg:hidden p-1.5 rounded-md hover:bg-[var(--bg-hover)] transition-colors">
          <X :size="18" style="color: var(--text-muted);" />
        </button>
      </div>

      <!-- Dashboard Link -->
      <div class="px-2 py-3">
        <router-link 
          to="/" 
          @click="closeSidebar"
          class="flex items-center gap-2.5 px-3 py-2 rounded-lg text-[13px] font-medium transition-all"
          :class="$route.path === '/' 
            ? 'bg-[var(--color-primary-subtle)] text-[var(--color-primary)]' 
            : 'text-[var(--text-secondary)] hover:bg-[var(--bg-hover)] hover:text-[var(--text-primary)]'"
        >
          <LayoutDashboard :size="16" />
          <span>Dashboard</span>
        </router-link>
      </div>

      <!-- Grouped Navigation -->
      <nav class="flex-1 overflow-y-auto px-2 pb-3">
        <div v-for="group in menuGroups" :key="group.id" class="mb-1">
          <!-- Group Header -->
          <button 
            @click="toggleGroup(group.id)"
            class="w-full flex items-center justify-between px-3 py-2 rounded-lg text-[11px] font-semibold uppercase tracking-wider transition-colors"
            :class="isGroupActive(group) ? 'text-[var(--color-primary)]' : 'text-[var(--text-muted)] hover:text-[var(--text-secondary)]'"
          >
            <div class="flex items-center gap-2">
              <component :is="group.icon" :size="14" />
              <span>{{ group.label }}</span>
            </div>
            <ChevronDown 
              :size="14" 
              class="transition-transform duration-200"
              :class="{ 'rotate-180': !expandedGroups[group.id] }"
            />
          </button>
          
          <!-- Group Items -->
          <Transition name="slide">
            <div v-if="expandedGroups[group.id]" class="mt-1 space-y-0.5 pl-2">
              <router-link 
                v-for="item in group.items"
                :key="item.path"
                :to="item.path" 
                @click="closeSidebar"
                class="flex items-center gap-2.5 px-3 py-2 rounded-lg text-[13px] font-medium transition-all"
                :class="$route.path === item.path 
                  ? 'bg-[var(--color-primary-subtle)] text-[var(--color-primary)]' 
                  : 'text-[var(--text-secondary)] hover:bg-[var(--bg-hover)] hover:text-[var(--text-primary)]'"
              >
                <component :is="item.icon" :size="15" class="flex-shrink-0" />
                <span class="flex-1">{{ item.label }}</span>
                <span v-if="item.badge" class="panda-badge panda-badge-new text-[9px]">{{ item.badge }}</span>
              </router-link>
            </div>
          </Transition>
        </div>
      </nav>

      <!-- Logout -->
      <div class="p-2 border-t border-[var(--border-color)]">
        <button 
          @click="handleLogout" 
          class="w-full flex items-center gap-2.5 px-3 py-2 rounded-lg text-[13px] font-medium transition-colors hover:bg-[var(--color-error-subtle)]"
          style="color: var(--color-error);"
        >
          <LogOut :size="16" />
          <span>Logout</span>
        </button>
      </div>
    </aside>

    <!-- Main Content -->
    <main class="flex-1 overflow-y-auto flex flex-col min-w-0">
      
      <!-- Top Header -->
      <header 
        class="h-14 flex items-center justify-between px-4 lg:px-6 sticky top-0 z-10 border-b border-[var(--border-color)]"
        style="background: var(--bg-elevated);"
      >
        <!-- Left: Mobile menu + Search -->
        <div class="flex items-center gap-3">
          <button @click="sidebarOpen = true" class="p-2 rounded-lg hover:bg-[var(--bg-hover)] transition-colors lg:hidden">
            <Menu :size="20" style="color: var(--text-muted);" />
          </button>
          
          <!-- Global Search (Ctrl+K) -->
          <button 
            @click="openCommandPalette"
            class="hidden md:flex items-center gap-3 w-64 lg:w-80 px-3 py-2 rounded-lg border transition-colors hover:border-[var(--border-color-hover)]"
            style="background: var(--bg-surface); border-color: var(--border-color);"
          >
            <Search :size="16" style="color: var(--text-muted);" />
            <span class="flex-1 text-left text-sm" style="color: var(--text-muted);">Search...</span>
            <div class="flex items-center gap-1">
              <kbd>⌘</kbd>
              <kbd>K</kbd>
            </div>
          </button>
        </div>

        <!-- Right: Actions -->
        <div class="flex items-center gap-2">
          <!-- System Health Badge -->
          <div 
            class="hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-medium cursor-pointer"
            :class="{
              'bg-[var(--color-success-subtle)] text-[var(--color-success)]': systemHealth === 'healthy',
              'bg-[var(--color-warning-subtle)] text-[var(--color-warning)]': systemHealth === 'warning',
              'bg-[var(--color-error-subtle)] text-[var(--color-error)]': systemHealth === 'critical'
            }"
            @click="$router.push('/health')"
          >
            <span class="status-indicator" :class="systemHealth === 'healthy' ? 'online' : systemHealth"></span>
            <span>{{ systemHealth === 'healthy' ? 'All Systems' : systemHealth === 'warning' ? 'Warning' : 'Critical' }}</span>
          </div>
          
          <!-- Theme Toggle -->
          <button 
            @click="themeStore.toggleTheme" 
            class="p-2 rounded-lg transition-colors hover:bg-[var(--bg-hover)]"
            data-tooltip="Toggle Theme (⌘T)"
          >
            <Sun v-if="themeStore.theme === 'dark'" :size="18" style="color: var(--text-muted);" />
            <Moon v-else :size="18" style="color: var(--text-muted);" />
          </button>
          
          <!-- Notifications -->
          <button @click="notificationPanelOpen = true" class="relative p-2 rounded-lg transition-colors hover:bg-[var(--bg-hover)]">
            <Bell :size="18" style="color: var(--text-muted);" />
            <span 
              v-if="unreadNotificationCount > 0"
              class="absolute -top-0.5 -right-0.5 min-w-[18px] h-[18px] px-1 rounded-full flex items-center justify-center text-[10px] font-bold text-white"
              style="background: var(--color-primary);"
            >
              {{ unreadNotificationCount > 9 ? '9+' : unreadNotificationCount }}
            </span>
          </button>
          
          <!-- User -->
          <div class="hidden sm:flex items-center gap-2 pl-2 ml-1 border-l border-[var(--border-color)]">
            <div 
              class="w-8 h-8 rounded-lg flex items-center justify-center"
              style="background: linear-gradient(135deg, var(--color-primary), #3b82f6);"
            >
              <User :size="14" class="text-white" />
            </div>
            <span class="text-sm font-medium hidden lg:block">Admin</span>
          </div>
        </div>
      </header>

      <!-- Page Content -->
      <div class="flex-1 p-4 lg:p-8">
        <router-view></router-view>
      </div>
    </main>
    
    <!-- Notification Panel -->
    <NotificationPanel 
      :show="notificationPanelOpen" 
      @close="notificationPanelOpen = false"
      @update:count="unreadNotificationCount = $event"
    />
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

.slide-enter-active,
.slide-leave-active {
  transition: all 0.2s ease;
}
.slide-enter-from,
.slide-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}
</style>
