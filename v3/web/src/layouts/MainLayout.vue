<script setup>
import { ref, onMounted, computed } from 'vue'
import { 
  LayoutDashboard, Globe, Database, HardDrive, Terminal, Settings, 
  Bell, Search, User, Activity, LogOut, Server, Code, Lock, Shield, 
  Archive, Cpu, Users, Store, Stethoscope, Wrench, Sun, Moon, Menu, X, 
  Package, Rocket, ChevronDown, Command
} from 'lucide-vue-next'
import { useAuthStore } from '../stores/auth'
import { useThemeStore } from '../stores/theme'
import { useRouter } from 'vue-router'
import CommandPalette from '../components/CommandPalette.vue'

const authStore = useAuthStore()
const themeStore = useThemeStore()
const router = useRouter()
const sidebarOpen = ref(false)
const commandPaletteRef = ref(null)

// Simplified menu - "Know How to Refuse" philosophy
const menuItems = [
  { icon: LayoutDashboard, label: 'Dashboard', path: '/' },
  { icon: Globe, label: 'Sites', path: '/websites' },
  { icon: Database, label: 'Databases', path: '/databases' },
  { icon: HardDrive, label: 'Files', path: '/files' },
  { icon: Terminal, label: 'Terminal', path: '/terminal' },
  { divider: true },
  { icon: Server, label: 'Services', path: '/services' },
  { icon: Code, label: 'PHP', path: '/php' },
  { icon: Lock, label: 'SSL', path: '/ssl' },
  { icon: Shield, label: 'Security', path: '/security' },
  { icon: Archive, label: 'Backup', path: '/backup' },
  { divider: true },
  { icon: Package, label: 'Projects', path: '/projects', badge: 'NEW' },
  { icon: Rocket, label: 'CMS', path: '/cms', badge: 'NEW' },
  { icon: Store, label: 'Apps', path: '/apps' },
  { icon: Wrench, label: 'Tools', path: '/tools' },
  { divider: true },
  { icon: Stethoscope, label: 'Health', path: '/health' },
  { icon: Users, label: 'Users', path: '/users' },
  { icon: Settings, label: 'Settings', path: '/settings' },
]

// System health status
const systemHealth = ref('healthy') // healthy, warning, critical

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

onMounted(() => {
  themeStore.loadTheme()
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
    
    <!-- Sidebar - Minimal & Clean -->
    <aside :class="[
      'fixed lg:static inset-y-0 left-0 z-50 w-56 flex flex-col transition-transform duration-300',
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
            <span class="text-[10px] font-mono" style="color: var(--color-primary);">v3.0.0</span>
          </div>
        </router-link>
        <button @click="closeSidebar" class="lg:hidden p-1.5 rounded-md hover:bg-[var(--bg-hover)] transition-colors">
          <X :size="18" style="color: var(--text-muted);" />
        </button>
      </div>

      <!-- Navigation -->
      <nav class="flex-1 overflow-y-auto py-3 px-2">
        <template v-for="(item, index) in menuItems" :key="index">
          <!-- Divider -->
          <div v-if="item.divider" class="my-2 border-t border-[var(--border-color)]"></div>
          
          <!-- Menu Item -->
          <router-link 
            v-else
            :to="item.path" 
            @click="closeSidebar"
            class="group flex items-center gap-2.5 px-3 py-2 rounded-lg text-[13px] font-medium transition-all duration-150"
            :class="$route.path === item.path 
              ? 'bg-[var(--color-primary-subtle)] text-[var(--color-primary)]' 
              : 'text-[var(--text-secondary)] hover:bg-[var(--bg-hover)] hover:text-[var(--text-primary)]'"
          >
            <component :is="item.icon" :size="16" class="flex-shrink-0" />
            <span class="flex-1">{{ item.label }}</span>
            <span v-if="item.badge" class="panda-badge panda-badge-new text-[9px]">{{ item.badge }}</span>
          </router-link>
        </template>
      </nav>

      <!-- Logout -->
      <div class="p-2 border-t border-[var(--border-color)]">
        <button 
          @click="handleLogout" 
          class="w-full flex items-center gap-2.5 px-3 py-2 rounded-lg text-[13px] font-medium transition-colors"
          style="color: var(--color-error);"
          :class="'hover:bg-[var(--color-error-subtle)]'"
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
          <button @click="sidebarOpen = true" class="lg:hidden p-2 rounded-lg hover:bg-[var(--bg-hover)] transition-colors">
            <Menu :size="20" style="color: var(--text-muted);" />
          </button>
          
          <!-- Global Search (Ctrl+K) -->
          <button 
            @click="openCommandPalette"
            class="hidden md:flex items-center gap-3 w-64 lg:w-80 px-3 py-2 rounded-lg border transition-colors"
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
            class="hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-medium"
            :class="{
              'bg-[var(--color-success-subtle)] text-[var(--color-success)]': systemHealth === 'healthy',
              'bg-[var(--color-warning-subtle)] text-[var(--color-warning)]': systemHealth === 'warning',
              'bg-[var(--color-error-subtle)] text-[var(--color-error)]': systemHealth === 'critical'
            }"
          >
            <span class="status-indicator" :class="systemHealth === 'healthy' ? 'online' : systemHealth"></span>
            <span>{{ systemHealth === 'healthy' ? 'All Systems' : systemHealth === 'warning' ? 'Warning' : 'Critical' }}</span>
          </div>
          
          <!-- Theme Toggle -->
          <button 
            @click="themeStore.toggleTheme" 
            class="p-2 rounded-lg transition-colors hover:bg-[var(--bg-hover)]"
            data-tooltip="Toggle Theme"
          >
            <Sun v-if="themeStore.theme === 'dark'" :size="18" style="color: var(--text-muted);" />
            <Moon v-else :size="18" style="color: var(--text-muted);" />
          </button>
          
          <!-- Notifications -->
          <button class="relative p-2 rounded-lg transition-colors hover:bg-[var(--bg-hover)]">
            <Bell :size="18" style="color: var(--text-muted);" />
            <span class="absolute top-1.5 right-1.5 w-2 h-2 rounded-full" style="background: var(--color-primary);"></span>
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

      <!-- Page Content - Generous White Space -->
      <div class="flex-1 p-4 lg:p-8">
        <router-view></router-view>
      </div>
    </main>
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
