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

const router = createRouter({
  history: createWebHistory(),
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
        }
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
