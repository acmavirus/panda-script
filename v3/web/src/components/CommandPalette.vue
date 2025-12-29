<template>
  <Teleport to="body">
    <Transition name="fade">
      <div v-if="isOpen" class="command-palette-overlay" @click.self="close" @keydown="handleKeydown">
        <div class="command-palette" @click.stop>
          <!-- Search Input -->
          <div class="relative">
            <Search class="absolute left-4 top-1/2 -translate-y-1/2 text-[var(--text-muted)]" :size="18" />
            <input
              ref="inputRef"
              v-model="query"
              type="text"
              class="command-palette-input pl-12"
              placeholder="Search pages, actions, commands..."
              @keydown="handleInputKeydown"
            />
            <kbd class="absolute right-4 top-1/2 -translate-y-1/2">ESC</kbd>
          </div>
          
          <!-- Results -->
          <div class="command-palette-results">
            <!-- Pages -->
            <div v-if="filteredPages.length" class="mb-2">
              <div class="px-3 py-2 text-xs font-medium text-[var(--text-muted)] uppercase tracking-wider">
                Pages
              </div>
              <div
                v-for="(item, index) in filteredPages"
                :key="item.path"
                :class="['command-palette-item', { selected: selectedIndex === index }]"
                @click="navigate(item.path)"
                @mouseenter="selectedIndex = index"
              >
                <div class="command-palette-item-icon">
                  <component :is="item.icon" :size="16" />
                </div>
                <div class="flex-1">
                  <div class="text-sm font-medium">{{ item.label }}</div>
                  <div class="text-xs text-[var(--text-muted)]">{{ item.path }}</div>
                </div>
                <span v-if="item.badge" class="panda-badge panda-badge-new">{{ item.badge }}</span>
              </div>
            </div>
            
            <!-- Actions -->
            <div v-if="filteredActions.length" class="mb-2">
              <div class="px-3 py-2 text-xs font-medium text-[var(--text-muted)] uppercase tracking-wider">
                Actions
              </div>
              <div
                v-for="(item, index) in filteredActions"
                :key="item.id"
                :class="['command-palette-item', { selected: selectedIndex === filteredPages.length + index }]"
                @click="executeAction(item)"
                @mouseenter="selectedIndex = filteredPages.length + index"
              >
                <div class="command-palette-item-icon">
                  <component :is="item.icon" :size="16" />
                </div>
                <div class="flex-1">
                  <div class="text-sm font-medium">{{ item.label }}</div>
                </div>
                <kbd v-if="item.shortcut">{{ item.shortcut }}</kbd>
              </div>
            </div>
            
            <!-- No Results -->
            <div v-if="!filteredPages.length && !filteredActions.length" class="py-8 text-center text-[var(--text-muted)]">
              <Search :size="32" class="mx-auto mb-2 opacity-50" />
              <p>No results found for "{{ query }}"</p>
            </div>
          </div>
          
          <!-- Footer -->
          <div class="flex items-center justify-between px-4 py-3 border-t border-[var(--border-color)] text-xs text-[var(--text-muted)]">
            <div class="flex items-center gap-4">
              <span class="flex items-center gap-1">
                <kbd>↑</kbd><kbd>↓</kbd> Navigate
              </span>
              <span class="flex items-center gap-1">
                <kbd>↵</kbd> Select
              </span>
            </div>
            <span>Panda Panel v3</span>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script>
import { ref, computed, watch, nextTick, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { 
  Search, LayoutDashboard, Globe, Database, HardDrive, Terminal, 
  Settings, Server, Code, Lock, Shield, Archive, Cpu, Users, 
  Store, Stethoscope, Wrench, Package, Rocket, RefreshCw, 
  Moon, Sun, LogOut 
} from 'lucide-vue-next'

export default {
  name: 'CommandPalette',
  components: { 
    Search, LayoutDashboard, Globe, Database, HardDrive, Terminal,
    Settings, Server, Code, Lock, Shield, Archive, Cpu, Users,
    Store, Stethoscope, Wrench, Package, Rocket, RefreshCw,
    Moon, Sun, LogOut
  },
  setup() {
    const router = useRouter()
    const isOpen = ref(false)
    const query = ref('')
    const selectedIndex = ref(0)
    const inputRef = ref(null)
    
    const pages = [
      { label: 'Dashboard', path: '/', icon: LayoutDashboard },
      { label: 'Websites', path: '/websites', icon: Globe },
      { label: 'Databases', path: '/databases', icon: Database },
      { label: 'Files', path: '/files', icon: HardDrive },
      { label: 'Terminal', path: '/terminal', icon: Terminal },
      { label: 'Services', path: '/services', icon: Server },
      { label: 'PHP', path: '/php', icon: Code },
      { label: 'PM2 Manager', path: '/pm2', icon: Terminal },
      { label: 'Security', path: '/security', icon: Shield },
      { label: 'Backup', path: '/backup', icon: Archive },
      { label: 'Processes', path: '/processes', icon: Cpu },
      { label: 'App Store', path: '/apps', icon: Store },
      { label: 'Dev Tools', path: '/tools', icon: Wrench },
      { label: 'Projects', path: '/projects', icon: Package, badge: 'NEW' },
      { label: 'CMS Installer', path: '/cms', icon: Rocket, badge: 'NEW' },
      { label: 'Health Check', path: '/health', icon: Stethoscope },
      { label: 'Users', path: '/users', icon: Users },
      { label: 'Settings', path: '/settings', icon: Settings },
    ]
    
    const actions = [
      { id: 'refresh', label: 'Refresh Page', icon: RefreshCw, action: () => window.location.reload() },
      { id: 'theme', label: 'Toggle Theme', icon: Moon, shortcut: '⌘T', action: () => document.body.classList.toggle('light') },
    ]
    
    const filteredPages = computed(() => {
      if (!query.value) return pages.slice(0, 6)
      const q = query.value.toLowerCase()
      return pages.filter(p => 
        p.label.toLowerCase().includes(q) || 
        p.path.toLowerCase().includes(q)
      )
    })
    
    const filteredActions = computed(() => {
      if (!query.value) return actions
      const q = query.value.toLowerCase()
      return actions.filter(a => a.label.toLowerCase().includes(q))
    })
    
    const totalResults = computed(() => filteredPages.value.length + filteredActions.value.length)
    
    const open = () => {
      isOpen.value = true
      query.value = ''
      selectedIndex.value = 0
      nextTick(() => inputRef.value?.focus())
    }
    
    const close = () => {
      isOpen.value = false
    }
    
    const navigate = (path) => {
      router.push(path)
      close()
    }
    
    const executeAction = (action) => {
      action.action()
      close()
    }
    
    const handleInputKeydown = (e) => {
      if (e.key === 'ArrowDown') {
        e.preventDefault()
        selectedIndex.value = Math.min(selectedIndex.value + 1, totalResults.value - 1)
      } else if (e.key === 'ArrowUp') {
        e.preventDefault()
        selectedIndex.value = Math.max(selectedIndex.value - 1, 0)
      } else if (e.key === 'Enter') {
        e.preventDefault()
        if (selectedIndex.value < filteredPages.value.length) {
          navigate(filteredPages.value[selectedIndex.value].path)
        } else {
          const actionIndex = selectedIndex.value - filteredPages.value.length
          if (filteredActions.value[actionIndex]) {
            executeAction(filteredActions.value[actionIndex])
          }
        }
      }
    }
    
    const handleKeydown = (e) => {
      if (e.key === 'Escape') close()
    }
    
    const handleGlobalKeydown = (e) => {
      // Ctrl+K or Cmd+K
      if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault()
        isOpen.value ? close() : open()
      }
    }
    
    watch(query, () => {
      selectedIndex.value = 0
    })
    
    onMounted(() => {
      window.addEventListener('keydown', handleGlobalKeydown)
    })
    
    onUnmounted(() => {
      window.removeEventListener('keydown', handleGlobalKeydown)
    })
    
    return {
      isOpen,
      query,
      selectedIndex,
      inputRef,
      filteredPages,
      filteredActions,
      open,
      close,
      navigate,
      executeAction,
      handleInputKeydown,
      handleKeydown
    }
  }
}
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.15s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
