<script setup>
import { onMounted } from 'vue'
import { LayoutDashboard, Globe, Database, HardDrive, Terminal, Settings, Bell, Search, User, Activity, LogOut, Server, Code, Lock, Shield, Archive, Cpu, Users, Store, Stethoscope, Wrench, Sun, Moon } from 'lucide-vue-next'
import { useAuthStore } from '../stores/auth'
import { useThemeStore } from '../stores/theme'
import { useRouter } from 'vue-router'

const authStore = useAuthStore()
const themeStore = useThemeStore()
const router = useRouter()

const menuItems = [
  { icon: LayoutDashboard, label: 'Dashboard', path: '/' },
  { icon: Globe, label: 'Websites', path: '/websites' },
  { icon: Database, label: 'Databases', path: '/databases' },
  { icon: HardDrive, label: 'FileManager', path: '/files' },
  { icon: Activity, label: 'Docker', path: '/docker' },
  { icon: Terminal, label: 'Terminal', path: '/terminal' },
  { icon: Server, label: 'Services', path: '/services' },
  { icon: Cpu, label: 'Processes', path: '/processes' },
  { icon: Code, label: 'PHP', path: '/php' },
  { icon: Lock, label: 'SSL', path: '/ssl' },
  { icon: Shield, label: 'Security', path: '/security' },
  { icon: Archive, label: 'Backup', path: '/backup' },
  { icon: Store, label: 'App Store', path: '/apps' },
  { icon: Wrench, label: 'Tools', path: '/tools' },
  { icon: Stethoscope, label: 'Health', path: '/health' },
  { icon: Users, label: 'Users', path: '/users' },
  { icon: Settings, label: 'Settings', path: '/settings' },
]

const handleLogout = () => {
  authStore.logout()
  router.push('/login')
}

onMounted(() => {
  themeStore.loadTheme()
})
</script>

<template>
  <div class="flex h-screen overflow-hidden bg-panda-dark text-white">
    <!-- Sidebar -->
    <aside class="w-64 bg-black/40 border-r border-white/5 flex flex-col p-6 space-y-8">
      <div class="flex items-center space-x-3">
        <div class="w-10 h-10 bg-panda-primary rounded-xl flex items-center justify-center shadow-lg shadow-panda-primary/20">
          <span class="text-2xl">🐼</span>
        </div>
        <div>
          <h1 class="font-bold text-lg tracking-tight">Panda Panel</h1>
          <span class="text-[10px] text-panda-primary font-mono uppercase tracking-widest">v3.0.0</span>
        </div>
      </div>

      <nav class="flex-1 space-y-1">
        <router-link v-for="item in menuItems" :key="item.label" :to="item.path" 
           class="flex items-center space-x-3 px-4 py-3 rounded-xl transition-all duration-200 group"
           :class="$route.path === item.path ? 'bg-panda-primary/10 text-panda-primary' : 'text-gray-400 hover:bg-white/5 hover:text-white'">
          <component :is="item.icon" :size="20" class="transition-transform group-hover:scale-110" />
          <span class="font-medium">{{ item.label }}</span>
        </router-link>
      </nav>

      <div class="pt-6 border-t border-white/5">
        <button @click="handleLogout" class="flex items-center space-x-3 px-4 py-3 w-full rounded-xl text-red-400 hover:bg-red-500/10 transition-colors">
          <LogOut :size="20" />
          <span class="font-medium">Logout</span>
        </button>
      </div>
    </aside>

    <!-- Main Content -->
    <main class="flex-1 overflow-y-auto flex flex-col">
      <!-- Top Header -->
      <header class="h-20 border-b border-white/5 px-8 flex items-center justify-between sticky top-0 bg-panda-dark/95 backdrop-blur z-10">
        <div class="relative w-96 group">
          <Search class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 group-focus-within:text-panda-primary transition-colors" :size="18" />
          <input type="text" placeholder="Search (Ctrl + K)" 
                 class="w-full bg-white/5 border border-white/5 rounded-xl py-2.5 pl-12 pr-4 outline-none focus:border-panda-primary/50 transition-all text-sm text-white">
        </div>

        <div class="flex items-center space-y-0 space-x-4">
          <button @click="themeStore.toggleTheme" class="p-2.5 rounded-xl hover:bg-white/5 transition-colors" title="Toggle theme">
            <Sun v-if="themeStore.theme === 'dark'" :size="20" class="text-gray-400" />
            <Moon v-else :size="20" class="text-gray-400" />
          </button>
          <button class="p-2.5 rounded-xl hover:bg-white/5 transition-colors relative">
            <Bell :size="20" class="text-gray-400" />
            <span class="absolute top-2.5 right-2.5 w-2 h-2 bg-panda-primary rounded-full border-2 border-panda-dark"></span>
          </button>
          <div class="h-8 w-[1px] bg-white/10 mx-2"></div>
          <button class="flex items-center space-x-3 hover:bg-white/5 p-1.5 pr-4 rounded-xl transition-colors">
            <div class="w-8 h-8 rounded-lg bg-gradient-to-tr from-panda-primary to-blue-500 flex items-center justify-center text-white font-bold text-sm">
              <User :size="16" />
            </div>
            <div class="text-left hidden md:block">
              <div class="text-sm font-medium text-white">Admin User</div>
              <div class="text-[10px] text-gray-500 uppercase">Super Admin</div>
            </div>
          </button>
        </div>
      </header>

      <!-- Page Content -->
      <div class="p-8">
        <router-view></router-view>
      </div>
    </main>
  </div>
</template>
