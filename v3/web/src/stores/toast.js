import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useToastStore = defineStore('toast', () => {
    const toasts = ref([])

    const add = (message, type = 'info', duration = 3000) => {
        const id = Date.now()
        toasts.value.push({ id, message, type })

        setTimeout(() => {
            remove(id)
        }, duration)
    }

    const remove = (id) => {
        const index = toasts.value.findIndex(t => t.id === id)
        if (index !== -1) {
            toasts.value.splice(index, 1)
        }
    }

    const success = (msg, duration) => add(msg, 'success', duration)
    const error = (msg, duration) => add(msg, 'error', duration)
    const warning = (msg, duration) => add(msg, 'warning', duration)
    const info = (msg, duration) => add(msg, 'info', duration)

    return { toasts, success, error, warning, info, remove }
})
