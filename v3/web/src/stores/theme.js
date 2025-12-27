import { defineStore } from 'pinia'
import { ref, watch } from 'vue'
import axios from 'axios'

export const useThemeStore = defineStore('theme', () => {
    const theme = ref('dark')

    // Load initial theme
    const loadTheme = async () => {
        try {
            const res = await axios.get('/api/settings/theme')
            theme.value = res.data?.theme || 'dark'
            applyTheme()
        } catch (e) {
            theme.value = localStorage.getItem('theme') || 'dark'
            applyTheme()
        }
    }

    // Apply theme to document
    const applyTheme = () => {
        document.documentElement.classList.remove('light', 'dark')
        document.documentElement.classList.add(theme.value)
        localStorage.setItem('theme', theme.value)
    }

    // Toggle theme
    const toggleTheme = async () => {
        theme.value = theme.value === 'dark' ? 'light' : 'dark'
        applyTheme()
        try {
            await axios.post('/api/settings/theme', { theme: theme.value })
        } catch (e) {
            console.error('Failed to save theme')
        }
    }

    // Watch for changes
    watch(theme, applyTheme)

    return { theme, loadTheme, toggleTheme, applyTheme }
})
