<script setup>
import { ref, onMounted } from 'vue'
import { LayoutDashboard, Globe, Database, HardDrive, Terminal, Settings, Bell, Search, User, Activity, LogOut, Server, Code, Lock, Shield, Archive, Cpu, Users, Store, Stethoscope, Wrench, Sun, Moon, Menu, X } from 'lucide-vue-next'
import { useAuthStore } from '../stores/auth'
import { useThemeStore } from '../stores/theme'
import { useRouter } from 'vue-router'

const authStore = useAuthStore()
const themeStore = useThemeStore()
const router = useRouter()
const sidebarOpen = ref(false)

const menuItems = [
  { icon: LayoutDashboard, label: 'Dashboard', path: '/' },
  { icon: Globe, label: 'Websites', path: '/websites' },
  { icon: Database, label: 'Databases', path: '/databases' },
  { icon: HardDrive, label: 'Files', path: '/files' },
  { icon: Activity, label: 'Docker', path: '/docker' },
  { icon: Terminal, label: 'Terminal', path: '/terminal' },
  { icon: Server, label: 'Services', path: '/services' },
  { icon: Cpu, label: 'Processes', path: '/processes' },
  { icon: Code, label: 'PHP', path: '/php' },
  { icon: Lock, label: 'SSL', path: '/ssl' },
  { icon: Shield, label: 'Security', path: '/security' },
  { icon: Archive, label: 'Backup', path: '/backup' },
  { icon: Store, label: 'Apps', path: '/apps' },
  { icon: Wrench, label: 'Tools', path: '/tools' },
  { icon: Stethoscope, label: 'Health', path: '/health' },
  { icon: Users, label: 'Users', path: '/users' },
  { icon: Settings, label: 'Settings', path: '/settings' },
]

const handleLogout = () => {
  authStore.logout()
  router.push('/login')
}

const closeSidebar = () => {
  sidebarOpen.value = false
}

onMounted(() => {
  themeStore.loadTheme()
})
</script>

<template>
  <div class="flex h-screen overflow-hidden bg-panda-dark text-white">
    <!-- Mobile Overlay -->
    <div v-if="sidebarOpen" @click="closeSidebar" class="fixed inset-0 bg-black/50 z-40 lg:hidden"></div>
    
    <!-- Sidebar -->
    <aside :class="[
      'fixed lg:static inset-y-0 left-0 z-50 w-56 bg-black/90 lg:bg-black/40 border-r border-white/5 flex flex-col p-4 transition-transform duration-300',
      sidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
    ]">
      <!-- Logo -->
      <div class="flex items-center justify-between mb-4">
        <div class="flex items-center space-x-2">
          <div class="w-8 h-8 bg-panda-primary rounded-lg flex items-center justify-center">
            <span class="text-lg">🐼</span>
          </div>
          <div>
            <h1 class="font-bold text-sm">Panda Panel</h1>
            <span class="text-[9px] text-panda-primary font-mono">v3.0.0</span>
          </div>
        </div>
        <button @click="closeSidebar" class="lg:hidden p-1 hover:bg-white/10 rounded">
          <X :size="18" />
        </button>
      </div>

      <!-- Nav -->
      <nav class="flex-1 space-y-0.5 overflow-y-auto">
        <router-link v-for="item in menuItems" :key="item.label" :to="item.path" @click="closeSidebar"
           class="flex items-center space-x-2 px-3 py-2 rounded-lg transition-all text-xs"
           :class="$route.path === item.path ? 'bg-panda-primary/10 text-panda-primary' : 'text-gray-400 hover:bg-white/5 hover:text-white'">
          <component :is="item.icon" :size="16" />
          <span class="font-medium">{{ item.label }}</span>
        </router-link>
      </nav>

      <!-- Logout -->
      <div class="pt-3 border-t border-white/5 mt-2">
        <button @click="handleLogout" class="flex items-center space-x-2 px-3 py-2 w-full rounded-lg text-red-400 hover:bg-red-500/10 text-xs">
          <LogOut :size="16" />
          <span class="font-medium">Logout</span>
        </button>
      </div>
    </aside>

    <!-- Main Content -->
    <main class="flex-1 overflow-y-auto flex flex-col min-w-0">
      <!-- Top Header -->
      <header class="h-14 border-b border-white/5 px-4 lg:px-6 flex items-center justify-between sticky top-0 bg-panda-dark/95 backdrop-blur z-10">
        <!-- Mobile menu button -->
        <button @click="sidebarOpen = true" class="lg:hidden p-2 hover:bg-white/10 rounded-lg">
          <Menu :size="20" class="text-gray-400" />
        </button>
        
        <!-- Search (hidden on mobile) -->
        <div class="hidden md:block relative w-64 lg:w-80">
          <Search class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500" :size="16" />
          <input type="text" placeholder="Search..." 
                 class="w-full bg-white/5 border border-white/5 rounded-lg py-2 pl-9 pr-3 outline-none text-xs text-white">
        </div>
        
        <div class="flex-1 lg:hidden"></div>

        <div class="flex items-center space-x-2">
          <button @click="themeStore.toggleTheme" class="p-2 rounded-lg hover:bg-white/5">
            <Sun v-if="themeStore.theme === 'dark'" :size="18" class="text-gray-400" />
            <Moon v-else :size="18" class="text-gray-400" />
          </button>
          <button class="p-2 rounded-lg hover:bg-white/5 relative">
            <Bell :size="18" class="text-gray-400" />
            <span class="absolute top-2 right-2 w-1.5 h-1.5 bg-panda-primary rounded-full"></span>
          </button>
          <div class="hidden sm:flex items-center space-x-2 pl-2 border-l border-white/10">
            <div class="w-7 h-7 rounded-lg bg-gradient-to-tr from-panda-primary to-blue-500 flex items-center justify-center">
              <User :size="14" class="text-white" />
            </div>
            <span class="text-xs font-medium hidden lg:block">Admin</span>
          </div>
        </div>
      </header>

      <!-- Page Content -->
      <div class="flex-1 p-4 lg:p-6">
        <router-view></router-view>
      </div>
    </main>
  </div>
</template>
