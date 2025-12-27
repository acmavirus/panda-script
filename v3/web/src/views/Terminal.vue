<script setup>
import { onMounted, onUnmounted, ref } from 'vue'
import { Terminal } from '@xterm/xterm'
import { FitAddon } from '@xterm/addon-fit'
import '@xterm/xterm/css/xterm.css'
import { useAuthStore } from '../stores/auth'

const terminalContainer = ref(null)
const status = ref('disconnected')
let term = null
let socket = null
let fitAddon = null
const authStore = useAuthStore()

const initTerminal = () => {
  term = new Terminal({
    cursorBlink: true,
    fontSize: 14,
    fontFamily: 'Menlo, Monaco, "Courier New", monospace',
    theme: {
      background: '#1e1e1e',
      foreground: '#ffffff',
    }
  })

  fitAddon = new FitAddon()
  term.loadAddon(fitAddon)
  term.open(terminalContainer.value)
  fitAddon.fit()

  connect()
}

const connect = () => {
  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
  const host = window.location.host // Use current host (vite proxy will handle it if configured, else backend host)
  // Since we are using vite proxy, we might need to adjust. 
  // If vite runs on 5173 and backend on 8080.
  // We can try to connect to backend directly or via proxy upgrade.
  // Assuming proxy handles WS upgrade.
  
  // Actually, for WS in dev mode with proxy, we usually connect to location.host and vite proxies it.
  const wsUrl = `${protocol}//${host}/api/terminal/ws?token=${authStore.token}`
  
  socket = new WebSocket(wsUrl)

  socket.onopen = () => {
    status.value = 'connected'
    term.write('\r\n\x1b[32mConnected to server shell\x1b[0m\r\n')
  }

  socket.onmessage = (event) => {
    term.write(event.data)
    term.write('\r\n') // Add newline for readability since our backend scanner strips them or sends lines
  }

  socket.onclose = () => {
    status.value = 'disconnected'
    term.write('\r\n\x1b[31mConnection closed\x1b[0m\r\n')
  }

  socket.onerror = (error) => {
    console.error('WebSocket error:', error)
    status.value = 'error'
  }

  term.onData(data => {
    if (socket && socket.readyState === WebSocket.OPEN) {
      // In a real PTY, we send every keystroke.
      // Since we are using a simple pipe scanner on backend that expects lines:
      // We might need to buffer line locally? 
      // Or just send data and let backend handle it?
      // Our backend reads "msg" and writes to stdin with appended newline.
      // This implies we should send WHOLE COMMANDS.
      // BUT xterm.js sends characters.
      
      // Let's implement a simple local echo and line buffering for this "fake" terminal.
      
      // Check for Enter key
      if (data === '\r') {
        term.write('\r\n')
        socket.send(currentLine)
        currentLine = ''
      } else if (data === '\u007F') { // Backspace
        if (currentLine.length > 0) {
          term.write('\b \b')
          currentLine = currentLine.slice(0, -1)
        }
      } else {
        term.write(data)
        currentLine += data
      }
    }
  })
}

let currentLine = ''

onMounted(() => {
  initTerminal()
  window.addEventListener('resize', () => fitAddon?.fit())
})

onUnmounted(() => {
  if (socket) socket.close()
  if (term) term.dispose()
  window.removeEventListener('resize', () => fitAddon?.fit())
})
</script>

<template>
  <div class="h-full flex flex-col p-6">
    <div class="flex items-center justify-between mb-4">
      <h2 class="text-xl font-bold text-white flex items-center gap-2">
        <span class="text-green-400">$</span> Web Terminal
      </h2>
      <div class="flex items-center space-x-2 text-xs">
        <span :class="{
          'text-green-400': status === 'connected',
          'text-red-400': status === 'disconnected' || status === 'error'
        }">● {{ status }}</span>
      </div>
    </div>
    
    <div class="flex-1 bg-[#1e1e1e] rounded-xl overflow-hidden border border-white/10 p-2 relative">
      <div ref="terminalContainer" class="h-full w-full"></div>
    </div>
  </div>
</template>

<style>
.xterm-viewport {
  overflow-y: auto !important;
}
</style>
