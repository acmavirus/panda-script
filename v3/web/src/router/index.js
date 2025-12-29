import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import MainLayout from '../layouts/MainLayout.vue'
import Dashboard from '../views/Dashboard.vue'
import Login from '../views/Login.vue'
import FileManager from '../views/FileManager.vue'
import Docker from '../views/Docker.vue'
import Terminal from '../views/Terminal.vue'
import Websites from '../views/Websites.vue'
import Databases from '../views/Databases.vue'
import Settings from '../views/Settings.vue'
import Services from '../views/Services.vue'
import PHP from '../views/PHP.vue'
import Security from '../views/Security.vue'
import Backup from '../views/Backup.vue'
import Processes from '../views/Processes.vue'
import Users from '../views/Users.vue'
import AppStore from '../views/AppStore.vue'
import HealthCheck from '../views/HealthCheck.vue'
import Tools from '../views/Tools.vue'

const router = createRouter({
  history: createWebHistory('/panda/'),
  routes: [
    {
      path: '/',
      component: MainLayout,
      meta: { requiresAuth: true },
      children: [
        {
          path: '',
          name: 'dashboard',
          component: Dashboard
        },
        {
          path: 'settings',
          name: 'settings',
          component: Settings
        },
        {
          path: 'websites',
          name: 'websites',
          component: Websites
        },
        {
          path: 'databases',
          name: 'databases',
          component: Databases
        },
        {
          path: 'files',
          name: 'files',
          component: FileManager
        },
        {
          path: 'docker',
          name: 'docker',
          component: Docker
        },
        {
          path: 'terminal',
          name: 'terminal',
          component: Terminal
        },
        {
          path: 'services',
          name: 'services',
          component: Services
        },
        {
          path: 'php',
          name: 'php',
          component: PHP
        },
        {
          path: 'nginx',
          name: 'nginx',
          component: () => import('../views/Nginx.vue')
        },
        {
          path: 'security',
          name: 'security',
          component: Security
        },
        {
          path: 'backup',
          name: 'backup',
          component: Backup
        },
        {
          path: 'processes',
          name: 'processes',
          component: Processes
        },
        {
          path: 'users',
          name: 'users',
          component: Users
        },
        {
          path: 'apps',
          name: 'apps',
          component: AppStore
        },
        {
          path: 'health',
          name: 'health',
          component: HealthCheck
        },
        {
          path: 'tools',
          name: 'tools',
          component: Tools
        },
      ]
    },
    {
      path: '/login',
      name: 'login',
      component: Login
    }
  ]
})

router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()

  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    next('/login')
  } else if (to.path === '/login' && authStore.isAuthenticated) {
    next('/')
  } else {
    next()
  }
})

export default router

