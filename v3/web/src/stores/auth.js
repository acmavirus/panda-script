import { defineStore } from 'pinia'
import { ref } from 'vue'
import axios from 'axios'
import { useRouter } from 'vue-router'

export const useAuthStore = defineStore('auth', () => {
  const token = ref(localStorage.getItem('panda_token') || null)
  const isAuthenticated = ref(!!token.value)
  const router = useRouter()

  function setToken(newToken) {
    token.value = newToken
    isAuthenticated.value = true
    localStorage.setItem('panda_token', newToken)
    axios.defaults.headers.common['Authorization'] = `Bearer ${newToken}`
  }

  function logout() {
    token.value = null
    isAuthenticated.value = false
    localStorage.removeItem('panda_token')
    delete axios.defaults.headers.common['Authorization']
    router.push('/login')
  }

  async function login(username, password) {
    try {
      const res = await axios.post('/api/auth/login', { username, password })
      setToken(res.data.token)
      return true
    } catch (error) {
      console.error('Login failed:', error)
      return false
    }
  }

  // Initialize axios header if token exists
  if (token.value) {
    axios.defaults.headers.common['Authorization'] = `Bearer ${token.value}`
  }

  return { token, isAuthenticated, login, logout }
})
