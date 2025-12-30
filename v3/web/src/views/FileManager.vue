<script setup>
import { ref, onMounted, computed, watch } from 'vue'
import { useRoute } from 'vue-router'
import axios from 'axios'
import { 
  Folder, File, ArrowLeft, Trash2, Edit2, FilePlus, FolderPlus, 
  RefreshCw, Save, X, Upload, Download, Archive, Search, MoreVertical,
  ChevronRight, FileText, Info, ExternalLink, Copy, Scissors
} from 'lucide-vue-next'
import { VueMonacoEditor } from '@guolao/vue-monaco-editor'

const currentPath = ref('/')
const files = ref([])
const loading = ref(false)
const error = ref('')
const editingFile = ref(null)
const fileContent = ref('')
const searchQuery = ref('')

const showNewFolderModal = ref(false)
const newFolderName = ref('')
const showNewFileModal = ref(false)
const newFileName = ref('')
const showRemoteDownloadModal = ref(false)
const remoteUrl = ref('')
const remoteFilename = ref('')
const showCompressModal = ref(false)
const compressOutput = ref('')
const compressFormat = ref('zip')

const fileInput = ref(null)
const selectedFiles = ref([])
const contextMenu = ref({ show: false, x: 0, y: 0, file: null })
const showPermissionModal = ref(false)
const permFile = ref(null)
const permissions = ref({ 
  owner: { r: true, w: true, x: false }, 
  group: { r: true, w: false, x: false }, 
  other: { r: true, w: false, x: false } 
})
const clipboard = ref({ action: null, files: [] }) // action: 'copy' or 'move'
const showArchiveListModal = ref(false)
const archiveList = ref([])
const archivePath = ref('')

// Monaco Editor Config
const editorOptions = {
  theme: 'vs-dark',
  fontSize: 14,
  automaticLayout: true,
  minimap: { enabled: true },
  scrollBeyondLastLine: false,
  wordWrap: 'on'
}

// Formatting
const formatSize = (bytes) => {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleString()
}

// Computed
const filteredFiles = computed(() => {
  if (!searchQuery.value) return files.value
  const query = searchQuery.value.toLowerCase()
  return files.value.filter(f => f.name.toLowerCase().includes(query))
})

const breadcrumbs = computed(() => {
  const parts = currentPath.value.split('/').filter(p => p !== '')
  const result = [{ name: 'Root', path: '/' }]
  let current = ''
  parts.forEach(p => {
    current += '/' + p
    result.push({ name: p, path: current })
  })
  return result
})

// Actions
const loadFiles = async (path) => {
  loading.value = true
  error.value = ''
  try {
    const res = await axios.get('/api/files/list', { params: { path } })
    files.value = res.data.sort((a, b) => {
      if (a.is_dir && !b.is_dir) return -1
      if (!a.is_dir && b.is_dir) return 1
      return a.name.localeCompare(b.name)
    })
    currentPath.value = path
  } catch (err) {
    error.value = err.response?.data?.error || 'Failed to load files'
  } finally {
    loading.value = false
  }
}

const navigate = (path) => {
  loadFiles(path)
}

const goUp = () => {
  const parent = currentPath.value.split('/').slice(0, -1).join('/') || '/'
  navigate(parent)
}

const openItem = (file) => {
  if (file.is_dir) {
    navigate(file.path)
  } else {
    editFile(file)
  }
}

// File Operations
const editFile = async (file) => {
  try {
    loading.value = true
    const res = await axios.get('/api/files/read', { params: { path: file.path } })
    fileContent.value = res.data.content
    editingFile.value = file
  } catch (err) {
    alert('Failed to read file: ' + (err.response?.data?.error || err.message))
  } finally {
    loading.value = false
  }
}

const saveFile = async () => {
  if (!editingFile.value) return
  try {
    loading.value = true
    await axios.post('/api/files/write', {
      path: editingFile.value.path,
      content: fileContent.value
    })
    alert('File saved successfully')
    // We don't close the editor here to allow continued editing
  } catch (err) {
    alert('Failed to save file: ' + (err.response?.data?.error || err.message))
  } finally {
    loading.value = false
  }
}

const deleteItem = async (file) => {
  if (!confirm(`Are you sure you want to delete ${file.name}?`)) return
  try {
    await axios.post('/api/files/delete', null, { params: { path: file.path } })
    loadFiles(currentPath.value)
  } catch (err) {
    alert('Failed to delete: ' + (err.response?.data?.error || err.message))
  }
}

const deleteSelected = async () => {
  if (selectedFiles.value.length === 0) return
  if (!confirm(`Delete ${selectedFiles.value.length} selected items?`)) return
  try {
    loading.value = true
    for (const file of selectedFiles.value) {
      await axios.post('/api/files/delete', null, { params: { path: file.path } })
    }
    selectedFiles.value = []
    loadFiles(currentPath.value)
  } catch (err) {
    alert('Failed to delete some items')
  } finally {
    loading.value = false
  }
}

const toggleSelect = (file) => {
  const index = selectedFiles.value.findIndex(f => f.path === file.path)
  if (index > -1) {
    selectedFiles.value.splice(index, 1)
  } else {
    selectedFiles.value.push(file)
  }
}

const selectAll = () => {
  if (selectedFiles.value.length === files.value.length) {
    selectedFiles.value = []
  } else {
    selectedFiles.value = [...files.value]
  }
}

const isSelected = (file) => {
  return selectedFiles.value.some(f => f.path === file.path)
}

// Context Menu
const showContextMenu = (e, file) => {
  e.preventDefault()
  contextMenu.value = {
    show: true,
    x: e.clientX,
    y: e.clientY,
    file
  }
  // If clicking on a file not selected, select only that one
  if (!selectedFiles.value.some(f => f.path === file.path)) {
    selectedFiles.value = [file]
  }
}

const closeContextMenu = () => {
  contextMenu.value.show = false
}

// Clipboard
const copyToClipboard = () => {
  clipboard.value = { action: 'copy', files: [...selectedFiles.value] }
  closeContextMenu()
}

const cutToClipboard = () => {
  clipboard.value = { action: 'move', files: [...selectedFiles.value] }
  closeContextMenu()
}

const pasteFromClipboard = async () => {
  if (!clipboard.value.files.length) return
  try {
    loading.value = true
    for (const file of clipboard.value.files) {
      const dest = currentPath.value === '/' ? `/${file.name}` : `${currentPath.value}/${file.name}`
      const api = clipboard.value.action === 'copy' ? '/api/files/copy' : '/api/files/move'
      await axios.post(api, { src: file.path, dst: dest })
    }
    loadFiles(currentPath.value)
    if (clipboard.value.action === 'move') clipboard.value = { action: null, files: [] }
    alert('Paste successful')
  } catch (err) {
    alert('Paste failed')
  } finally {
    loading.value = false
    closeContextMenu()
  }
}

// Permissions
const openPermissionModal = (file) => {
  permFile.value = file
  // Default 644 or 755
  if (file.is_dir) {
    permissions.value = { 
      owner: { r: true, w: true, x: true }, 
      group: { r: true, w: false, x: true }, 
      other: { r: true, w: false, x: true } 
    }
  } else {
    permissions.value = { 
      owner: { r: true, w: true, x: false }, 
      group: { r: true, w: false, x: false }, 
      other: { r: true, w: false, x: false } 
    }
  }
  showPermissionModal.value = true
  closeContextMenu()
}

const savePermissions = async () => {
  try {
    loading.value = true
    const octal = (p) => (p.r ? 4 : 0) + (p.w ? 2 : 0) + (p.x ? 1 : 0)
    // Construct mode as integer (e.g. 0644)
    // In Go os.Chmod(path, 0644) expects the int value
    // Octal 644 is 6*64 + 4*8 + 4 = 384 + 32 + 4 = 420
    const mode = (octal(permissions.value.owner) * 64) + (octal(permissions.value.group) * 8) + octal(permissions.value.other)
    await axios.post('/api/files/chmod', { path: permFile.value.path, mode })
    showPermissionModal.value = false
    loadFiles(currentPath.value)
    alert('Permissions updated')
  } catch (err) {
    alert('Failed to update permissions')
  } finally {
    loading.value = false
  }
}

const viewArchiveContents = async (file) => {
  try {
    loading.value = true
    const res = await axios.get('/api/files/archive/list', { params: { path: file.path } })
    archiveList.value = res.data.files
    archivePath.value = file.name
    showArchiveListModal.value = true
    closeContextMenu()
  } catch (err) {
    alert('Failed to read archive')
  } finally {
    loading.value = false
  }
}

const downloadRemoteFile = async () => {
  if (!remoteUrl.value) return
  const path = currentPath.value === '/' ? `/${remoteFilename.value}` : `${currentPath.value}/${remoteFilename.value}`
  try {
    loading.value = true
    await axios.post('/api/files/download', { url: remoteUrl.value, path })
    showRemoteDownloadModal.value = false
    remoteUrl.value = ''
    remoteFilename.value = ''
    loadFiles(currentPath.value)
    alert('Download successful')
  } catch (err) {
    alert('Download failed')
  } finally {
    loading.value = false
  }
}

const isArchive = (filename) => {
  const ext = filename.toLowerCase()
  return ext.endsWith('.zip') || ext.endsWith('.tar.gz') || ext.endsWith('.tgz') || ext.endsWith('.tar.bz2')
}

const extractFile = async (file) => {
  if (!confirm(`Extract ${file.name} to the current folder?`)) return
  try {
    loading.value = true
    await axios.post('/api/files/extract', {
      archive: file.path,
      output: currentPath.value
    })
    loadFiles(currentPath.value)
    alert('Extracted successfully')
  } catch (err) {
    alert('Extraction failed: ' + (err.response?.data?.error || err.message))
  } finally {
    loading.value = false
  }
}

const createFolder = async () => {
  if (!newFolderName.value) return
  const newPath = currentPath.value === '/' 
    ? `/${newFolderName.value}` 
    : `${currentPath.value}/${newFolderName.value}`
  
  try {
    await axios.post('/api/files/mkdir', { path: newPath })
    showNewFolderModal.value = false
    newFolderName.value = ''
    loadFiles(currentPath.value)
  } catch (err) {
    alert('Failed to create folder: ' + (err.response?.data?.error || err.message))
  }
}

const createFile = async () => {
  if (!newFileName.value) return
  const newPath = currentPath.value === '/' 
    ? `/${newFileName.value}` 
    : `${currentPath.value}/${newFileName.value}`
  
  try {
    await axios.post('/api/files/write', { path: newPath, content: '' })
    showNewFileModal.value = false
    newFileName.value = ''
    loadFiles(currentPath.value)
  } catch (err) {
    alert('Failed to create file: ' + (err.response?.data?.error || err.message))
  }
}

const compressFiles = async () => {
  if (!compressOutput.value) return
  try {
    loading.value = true
    await axios.post('/api/files/compress', {
      path: currentPath.value,
      output: currentPath.value + '/' + compressOutput.value,
      format: compressFormat.value
    })
    showCompressModal.value = false
    compressOutput.value = ''
    loadFiles(currentPath.value)
    alert('Compressed successfully')
  } catch (err) {
    alert('Compression failed: ' + (err.response?.data?.error || err.message))
  } finally {
    loading.value = false
  }
}

// Upload
const triggerUpload = () => {
  fileInput.value.click()
}

const handleFileUpload = async (event) => {
  const files = event.target.files
  if (!files.length) return

  const formData = new FormData()
  formData.append('path', currentPath.value)
  for (let i = 0; i < files.length; i++) {
    formData.append('files', files[i])
  }

  try {
    loading.value = true
    await axios.post('/api/files/upload', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })
    loadFiles(currentPath.value)
    alert('Upload successful')
  } catch (err) {
    alert('Upload failed: ' + (err.response?.data?.error || err.message))
  } finally {
    event.target.value = '' // Reset input
    loading.value = false
  }
}

const getLanguage = (filename) => {
  const ext = filename.split('.').pop().toLowerCase()
  const map = {
    'js': 'javascript',
    'ts': 'typescript',
    'vue': 'html', 
    'html': 'html',
    'css': 'css',
    'json': 'json',
    'go': 'go',
    'py': 'python',
    'php': 'php',
    'sh': 'shell',
    'md': 'markdown',
    'sql': 'sql',
    'yaml': 'yaml',
    'yml': 'yaml',
    'conf': 'ini',
    'ini': 'ini'
  }
  return map[ext] || 'plaintext'
}

onMounted(() => {
  const route = useRoute()
  const initialPath = route.query.path || '/'
  loadFiles(initialPath)

  // Global Shortcuts
  window.addEventListener('keydown', (e) => {
    if (editingFile.value && (e.ctrlKey || e.metaKey) && e.key === 's') {
      e.preventDefault()
      saveFile()
    }
  })
})
</script>

<template>
  <div class="p-0 h-full flex flex-col bg-[#f8f9fa] dark:bg-[#0c0c0e]">
    <!-- Top Action Bar -->
    <div class="flex items-center justify-between px-6 py-4 bg-white dark:bg-[#121214] border-b border-gray-200 dark:border-white/5 sticky top-0 z-30 shadow-sm">
      <div class="flex items-center space-x-4">
        <h2 class="text-lg font-semibold text-gray-800 dark:text-white flex items-center gap-2">
          <Folder class="text-blue-500" :size="20" />
          FileManager
        </h2>
        
        <div class="h-6 w-px bg-gray-200 dark:bg-white/10 hidden sm:block"></div>
        
        <div class="hidden lg:flex items-center bg-gray-100 dark:bg-white/5 rounded-lg px-3 py-1.5 w-80 group focus-within:ring-2 focus-within:ring-blue-500/50 transition-all">
          <Search :size="16" class="text-gray-400 mr-2" />
          <input 
            v-model="searchQuery"
            type="text" 
            placeholder="Search files in this folder..." 
            class="bg-transparent border-none outline-none text-sm w-full dark:text-white"
          />
        </div>
      </div>

      <div class="flex items-center gap-2">
        <button @click="loadFiles(currentPath)" 
                class="p-2 hover:bg-gray-100 dark:hover:bg-white/5 rounded-lg transition-colors text-gray-500 dark:text-gray-400"
                :class="{'animate-spin text-blue-500': loading}">
          <RefreshCw :size="18" />
        </button>
        
        <div class="flex items-center gap-1">
          <input type="file" ref="fileInput" multiple class="hidden" @change="handleFileUpload">
          <button @click="triggerUpload" class="flex items-center gap-2 px-3 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-medium transition-all shadow-sm">
            <Upload :size="16" />
            <span class="hidden md:inline">Upload</span>
          </button>
          
          <div class="relative group">
            <button class="flex items-center gap-2 px-3 py-2 border border-gray-200 dark:border-white/10 hover:bg-gray-50 dark:hover:bg-white/5 rounded-lg text-sm font-medium transition-all dark:text-white">
              <FilePlus :size="16" />
              <span class="hidden md:inline">New</span>
            </button>
            
            <div class="absolute right-0 mt-2 w-48 bg-white dark:bg-[#1a1a1c] border border-gray-200 dark:border-white/10 rounded-xl shadow-xl opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all z-50 p-1">
              <button @click="showNewFileModal = true" class="flex items-center w-full px-3 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-blue-50 dark:hover:bg-blue-500/10 hover:text-blue-600 rounded-lg transition-colors gap-2">
                <FileText :size="16" /> Create File
              </button>
              <button @click="showNewFolderModal = true" class="flex items-center w-full px-3 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-blue-50 dark:hover:bg-blue-500/10 hover:text-blue-600 rounded-lg transition-colors gap-2">
                <FolderPlus :size="16" /> Create Folder
              </button>
              <button @click="showCompressModal = true" class="flex items-center w-full px-3 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-blue-50 dark:hover:bg-blue-500/10 hover:text-blue-600 rounded-lg transition-colors gap-2">
                <Archive :size="16" /> Compress Folder
              </button>
              <button @click="showRemoteDownloadModal = true" class="flex items-center w-full px-3 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-blue-50 dark:hover:bg-blue-500/10 hover:text-blue-600 rounded-lg transition-colors gap-2 border-t border-gray-100 dark:border-white/5 mt-1 pt-2">
                <Download :size="16" /> Remote Download
              </button>
            </div>
          </div>

          <button v-if="clipboard.files.length > 0" @click="pasteFromClipboard" class="flex items-center gap-2 px-3 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg text-sm font-medium transition-all shadow-sm animate-bounce-subtle">
            <Save :size="16" />
            <span>Paste ({{ clipboard.files.length }})</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Path & Breadcrumbs -->
    <div class="px-6 py-3 bg-white/50 dark:bg-white/2 border-b border-gray-100 dark:border-white/5 flex items-center justify-between min-h-[50px]">
      <div v-if="selectedFiles.length === 0" class="flex items-center text-sm overflow-hidden">
        <button @click="goUp" :disabled="currentPath === '/'" 
                class="p-1.5 hover:bg-gray-200 dark:hover:bg-white/10 rounded-md disabled:opacity-30 transition-colors mr-2">
          <ArrowLeft :size="14" />
        </button>
        <div class="flex items-center overflow-x-auto whitespace-nowrap hide-scrollbar">
          <template v-for="(bc, index) in breadcrumbs" :key="index">
            <span v-if="index > 0" class="mx-2 text-gray-300 dark:text-white/20">/</span>
            <button @click="navigate(bc.path)" 
                    class="hover:text-blue-600 dark:hover:text-blue-400 transition-colors"
                    :class="index === breadcrumbs.length - 1 ? 'font-semibold text-gray-900 dark:text-white' : 'text-gray-500 dark:text-gray-400'">
              {{ bc.name }}
            </button>
          </template>
        </div>
      </div>

      <!-- Bulk Actions Bar -->
      <div v-else class="flex items-center justify-between w-full bg-blue-600 -mx-6 -my-3 px-6 py-3 text-white transition-all animate-fade-in">
        <div class="flex items-center gap-4">
          <button @click="selectedFiles = []" class="p-1 hover:bg-white/20 rounded-md">
            <X :size="18" />
          </button>
          <span class="font-bold">{{ selectedFiles.length }} items selected</span>
        </div>
        <div class="flex items-center gap-2">
          <button @click="copyToClipboard" class="flex items-center gap-2 px-3 py-1.5 hover:bg-white/20 rounded-lg text-sm font-medium transition-colors">
            <Copy :size="16" /> Copy
          </button>
          <button @click="cutToClipboard" class="flex items-center gap-2 px-3 py-1.5 hover:bg-white/20 rounded-lg text-sm font-medium transition-colors">
            <Scissors :size="16" /> Cut
          </button>
          <button @click="deleteSelected" class="flex items-center gap-2 px-3 py-1.5 bg-red-500 hover:bg-red-600 rounded-lg text-sm font-medium transition-colors">
            <Trash2 :size="16" /> Delete
          </button>
        </div>
      </div>
      
      <div v-if="selectedFiles.length === 0" class="text-[11px] font-mono text-gray-400 hidden sm:block">
        {{ filteredFiles.length }} items
      </div>
    </div>

    <!-- Main Content -->
    <div class="flex-1 overflow-auto px-6 py-4">
      <div v-if="error" class="mb-6 p-4 bg-red-50 dark:bg-red-500/10 border border-red-100 dark:border-red-500/20 rounded-xl text-red-600 dark:text-red-400 flex items-center gap-3 animate-shake">
        <Info :size="20" />
        {{ error }}
      </div>

      <div class="bg-white dark:bg-[#121214] border border-gray-200 dark:border-white/10 rounded-xl shadow-sm overflow-hidden">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="text-[12px] font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider bg-gray-50/50 dark:bg-white/2">
              <th class="px-6 py-3 w-4">
                <input type="checkbox" :checked="selectedFiles.length === files.length && files.length > 0" @change="selectAll" class="rounded border-gray-300 text-blue-600 focus:ring-blue-500">
              </th>
              <th class="px-2 py-3 font-medium w-8">Type</th>
              <th class="px-2 py-3 font-medium">Name</th>
              <th class="px-6 py-3 font-medium hidden md:table-cell">Size</th>
              <th class="px-6 py-3 font-medium hidden lg:table-cell">Perms</th>
              <th class="px-6 py-3 font-medium text-right">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100 dark:divide-white/5">
            <tr v-if="loading && files.length === 0">
              <td colspan="6" class="px-6 py-12 text-center">
                <div class="inline-block animate-spin h-8 w-8 border-4 border-blue-500 border-t-transparent rounded-full mb-4"></div>
                <p class="text-gray-500 dark:text-gray-400 text-sm">Fetching files...</p>
              </td>
            </tr>
            <tr v-else-if="filteredFiles.length === 0" class="hover:bg-transparent">
              <td colspan="6" class="px-6 py-16 text-center">
                <div class="bg-gray-50 dark:bg-white/5 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Search :size="24" class="text-gray-300 dark:text-gray-600" />
                </div>
                <p class="text-gray-500 dark:text-gray-400 text-sm">No files found matching your search</p>
                <button @click="searchQuery = ''" v-if="searchQuery" class="mt-4 text-blue-500 hover:underline text-sm font-medium">Clear search</button>
              </td>
            </tr>
            
            <tr v-for="file in filteredFiles" :key="file.path" 
                @dblclick="openItem(file)"
                @contextmenu.prevent="showContextMenu($event, file)"
                class="group hover:bg-blue-50/30 dark:hover:bg-blue-500/5 transition-all cursor-pointer"
                :class="{'bg-blue-50/50 dark:bg-blue-500/10': isSelected(file)}">
              <td class="px-6 py-4">
                <input type="checkbox" :checked="isSelected(file)" @change.stop="toggleSelect(file)" class="rounded border-gray-300 text-blue-600 focus:ring-blue-500">
              </td>
              <td class="px-2 py-4">
                <Folder v-if="file.is_dir" class="text-amber-400 fill-amber-400/20" :size="20" />
                <File v-else class="text-blue-500 fill-blue-500/10" :size="20" />
              </td>
              <td class="px-2 py-4">
                <div class="flex flex-col">
                  <span class="text-sm font-medium text-gray-700 dark:text-gray-200 truncate max-w-md group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors">
                    {{ file.name }}
                  </span>
                  <span class="text-[11px] text-gray-400 lg:hidden">
                    {{ file.is_dir ? 'Directory' : formatSize(file.size) }}
                  </span>
                </div>
              </td>
              <td class="px-6 py-4 hidden md:table-cell">
                <span class="text-xs font-mono text-gray-500 dark:text-gray-400">
                  {{ file.is_dir ? '-' : formatSize(file.size) }}
                </span>
              </td>
              <td class="px-6 py-4 hidden lg:table-cell">
                <span @click.stop="openPermissionModal(file)" class="px-2 py-0.5 bg-gray-100 dark:bg-white/5 hover:bg-gray-200 dark:hover:bg-white/10 cursor-pointer rounded font-mono text-[11px] text-gray-500 dark:text-gray-400 transition-colors">
                  {{ file.mode }}
                </span>
              </td>
              <td class="px-6 py-4 text-right">
                <div class="flex items-center justify-end gap-1 opacity-10 sm:opacity-0 group-hover:opacity-100 transition-all">
                  <button 
                    @click.stop="showContextMenu($event, file)" 
                    class="p-1.5 hover:bg-gray-200 dark:hover:bg-white/10 rounded-lg text-gray-400 transition-colors"
                  >
                    <MoreVertical :size="16" />
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Monaco Editor Modal (Full Screen) -->
    <Transition name="fade">
      <div v-if="editingFile" class="fixed inset-0 z-[100] flex flex-col bg-white dark:bg-[#0c0c0e]">
        <div class="h-14 flex items-center justify-between px-6 bg-white dark:bg-[#121214] border-b border-gray-200 dark:border-white/5 shadow-sm">
          <div class="flex items-center gap-3 overflow-hidden">
            <div class="bg-blue-500/10 p-1.5 rounded-lg">
              <FileText :size="18" class="text-blue-500" />
            </div>
            <div class="flex flex-col">
              <span class="text-sm font-semibold truncate dark:text-white">{{ editingFile.name }}</span>
              <span class="text-[10px] text-gray-400 font-mono truncate">{{ editingFile.path }}</span>
            </div>
          </div>
          
          <div class="flex items-center gap-2">
            <span class="text-[11px] text-gray-400 hidden sm:block mr-2 bg-gray-100 dark:bg-white/5 px-2 py-1 rounded">
              Ctrl+S to save
            </span>
            <button @click="saveFile" 
                    class="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-bold transition-all shadow-md shadow-blue-500/20"
                    :disabled="loading">
              <Save :size="16" />
              <span>Save</span>
            </button>
            <button @click="editingFile = null" class="p-2 hover:bg-gray-100 dark:hover:bg-white/10 rounded-lg transition-colors text-gray-500">
              <X :size="20" />
            </button>
          </div>
        </div>
        
        <div class="flex-1 relative overflow-hidden bg-[#1e1e1e]">
          <VueMonacoEditor
            v-model:value="fileContent"
            :language="getLanguage(editingFile.name)"
            theme="vs-dark"
            :options="editorOptions"
            class="h-full w-full"
          />
          <div v-if="loading" class="absolute inset-0 bg-black/20 backdrop-blur-[1px] flex items-center justify-center z-10">
            <div class="animate-spin h-8 w-8 border-3 border-blue-500 border-t-transparent rounded-full"></div>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Context Menu -->
    <Teleport to="body">
      <div v-if="contextMenu.show" 
           :style="{ top: contextMenu.y + 'px', left: contextMenu.x + 'px' }"
           class="fixed z-[200] w-56 bg-white dark:bg-[#1a1a1c] border border-gray-200 dark:border-white/10 rounded-xl shadow-2xl py-1 animate-scale-in"
           @click.stop>
        <div class="px-4 py-2 text-[10px] font-bold text-gray-400 uppercase tracking-wider border-b border-gray-100 dark:border-white/5 mb-1">
          {{ contextMenu.file?.name }}
        </div>
        <button @click="openItem(contextMenu.file)" class="flex items-center w-full px-4 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-blue-50 dark:hover:bg-blue-500/10 hover:text-blue-600 transition-colors gap-3">
          <Edit2 :size="16" /> Edit / Open
        </button>
        <button @click="copyToClipboard" class="flex items-center w-full px-4 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-blue-50 dark:hover:bg-blue-500/10 hover:text-blue-600 transition-colors gap-3">
          <Copy :size="16" /> Copy
        </button>
        <button @click="cutToClipboard" class="flex items-center w-full px-4 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-blue-50 dark:hover:bg-blue-500/10 hover:text-blue-600 transition-colors gap-3">
          <Scissors :size="16" /> Cut
        </button>
        <button @click="openPermissionModal(contextMenu.file)" class="flex items-center w-full px-4 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-blue-50 dark:hover:bg-blue-500/10 hover:text-blue-600 transition-colors gap-3">
          <Info :size="16" /> Permissions
        </button>
        <div v-if="isArchive(contextMenu.file?.name)" class="border-t border-gray-100 dark:border-white/5 my-1"></div>
        <button v-if="isArchive(contextMenu.file?.name)" @click="extractFile(contextMenu.file)" class="flex items-center w-full px-4 py-2 text-sm text-orange-600 hover:bg-orange-50 dark:hover:bg-orange-500/10 transition-colors gap-3">
          <Archive :size="16" /> Extract
        </button>
        <button v-if="isArchive(contextMenu.file?.name)" @click="viewArchiveContents(contextMenu.file)" class="flex items-center w-full px-4 py-2 text-sm text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-500/10 transition-colors gap-3">
          <Search :size="16" /> View Contents
        </button>
        <div class="border-t border-gray-100 dark:border-white/5 my-1"></div>
        <button @click="deleteItem(contextMenu.file)" class="flex items-center w-full px-4 py-2 text-sm text-red-600 hover:bg-red-50 dark:hover:bg-red-500/10 transition-colors gap-3">
          <Trash2 :size="16" /> Delete
        </button>
      </div>
      <div v-if="contextMenu.show" class="fixed inset-0 z-[190]" @click="closeContextMenu"></div>
    </Teleport>

    <!-- Modals -->
    <Transition name="modal">
      <div v-if="showNewFolderModal || showNewFileModal || showCompressModal || showPermissionModal || showArchiveListModal || showRemoteDownloadModal" 
           class="fixed inset-0 z-[110] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
        <div class="bg-white dark:bg-[#121214] border border-gray-200 dark:border-white/10 rounded-2xl w-full max-w-md shadow-2xl p-6 transform transition-all animate-scale-in max-h-[90vh] overflow-y-auto">
          
          <div v-if="showPermissionModal">
            <h3 class="text-xl font-bold mb-1 dark:text-white">Permission UI</h3>
            <p class="text-sm text-gray-500 mb-6">Set CHMOD for {{ permFile?.name }}</p>
            
            <div class="space-y-6">
              <div v-for="role in ['owner', 'group', 'other']" :key="role" class="space-y-2">
                <label class="block text-xs font-bold text-gray-400 uppercase">{{ role }}</label>
                <div class="flex gap-4">
                  <label v-for="p in ['r', 'w', 'x']" :key="p" class="flex items-center gap-2 cursor-pointer group">
                    <input type="checkbox" v-model="permissions[role][p]" class="rounded border-gray-300 text-blue-600 focus:ring-blue-500">
                    <span class="text-sm text-gray-600 dark:text-gray-400 group-hover:text-blue-500 transition-colors uppercase">{{ p }}</span>
                  </label>
                </div>
              </div>
              
              <div class="bg-gray-50 dark:bg-white/5 p-4 rounded-xl border border-gray-200 dark:border-white/10 text-center">
                <span class="text-xs text-gray-400 uppercase font-bold block mb-1">Numeric Value</span>
                <span class="text-2xl font-mono font-bold text-blue-600 dark:text-blue-400">
                  {{ (permissions.owner.r?4:0)+(permissions.owner.w?2:0)+(permissions.owner.x?1:0) }}{{ (permissions.group.r?4:0)+(permissions.group.w?2:0)+(permissions.group.x?1:0) }}{{ (permissions.other.r?4:0)+(permissions.other.w?2:0)+(permissions.other.x?1:0) }}
                </span>
              </div>

              <div class="flex gap-2 pt-2">
                <button @click="showPermissionModal = false" class="flex-1 px-4 py-3 text-gray-500 hover:bg-gray-50 dark:hover:bg-white/5 rounded-xl font-medium transition-colors">Cancel</button>
                <button @click="savePermissions" class="flex-1 px-4 py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-bold transition-all shadow-md">Apply</button>
              </div>
            </div>
          </div>

          <div v-if="showArchiveListModal">
            <h3 class="text-xl font-bold mb-1 dark:text-white">Archive Contents</h3>
            <p class="text-sm text-gray-500 mb-6">{{ archivePath }}</p>
            <div class="bg-gray-50 dark:bg-white/5 rounded-xl border border-gray-200 dark:border-white/10 max-h-64 overflow-y-auto font-mono text-xs p-2">
              <div v-for="f in archiveList" :key="f" class="py-1 px-2 hover:bg-blue-500/10 dark:text-gray-300">
                {{ f }}
              </div>
            </div>
            <button @click="showArchiveListModal = false" class="w-full mt-6 px-4 py-3 bg-gray-100 dark:bg-white/10 text-gray-700 dark:text-white rounded-xl font-bold transition-all">Close</button>
          </div>

          <!-- Existing Folder/File Modals -->
          <div v-if="showNewFolderModal">
            <h3 class="text-xl font-bold mb-1 dark:text-white">New Folder</h3>
            <p class="text-sm text-gray-500 mb-6">Create a new sub-directory in current path.</p>
            <div class="space-y-4">
              <input v-model="newFolderName" type="text" placeholder="Folder Name" class="w-full bg-gray-50 dark:bg-white/5 border border-gray-200 dark:border-white/10 rounded-xl px-4 py-3 outline-none dark:text-white shadow-inner" @keyup.enter="createFolder">
              <div class="flex gap-2 pt-2">
                <button @click="showNewFolderModal = false" class="flex-1 px-4 py-3 text-gray-500 rounded-xl font-medium">Cancel</button>
                <button @click="createFolder" class="flex-1 px-4 py-3 bg-blue-600 text-white rounded-xl font-bold">Create</button>
              </div>
            </div>
          </div>

          <div v-if="showNewFileModal">
            <h3 class="text-xl font-bold mb-1 dark:text-white">New File</h3>
            <p class="text-sm text-gray-500 mb-6">Create an empty file.</p>
            <div class="space-y-4">
              <input v-model="newFileName" type="text" placeholder="Filename" class="w-full bg-gray-50 dark:bg-white/5 border border-gray-200 dark:border-white/10 rounded-xl px-4 py-3 outline-none dark:text-white shadow-inner" @keyup.enter="createFile">
              <div class="flex gap-2 pt-2">
                <button @click="showNewFileModal = false" class="flex-1 px-4 py-3 text-gray-500 rounded-xl font-medium">Cancel</button>
                <button @click="createFile" class="flex-1 px-4 py-3 bg-blue-600 text-white rounded-xl font-bold">Create</button>
              </div>
            </div>
          </div>

          <div v-if="showCompressModal">
            <h3 class="text-xl font-bold mb-1 dark:text-white">Compress Folder</h3>
            <p class="text-sm text-gray-500 mb-6">Archive current directory.</p>
            <div class="space-y-4">
              <input v-model="compressOutput" type="text" placeholder="Output filename" class="w-full bg-gray-50 dark:bg-white/5 border border-gray-200 dark:border-white/10 rounded-xl px-4 py-3 dark:text-white shadow-inner" @keyup.enter="compressFiles">
              <div class="flex gap-2 p-1 bg-gray-50 dark:bg-white/5 rounded-xl border border-gray-200 dark:border-white/10">
                <button v-for="f in ['zip', 'tar.gz']" :key="f" @click="compressFormat = f" 
                        class="flex-1 py-2 text-sm font-bold rounded-lg transition-all uppercase"
                        :class="compressFormat === f ? 'bg-white dark:bg-white/10 shadow-sm text-blue-600' : 'text-gray-400'">
                  {{ f }}
                </button>
              </div>
              <div class="flex gap-2 pt-2">
                <button @click="showCompressModal = false" class="flex-1 px-4 py-3 text-gray-500 rounded-xl font-medium">Cancel</button>
                <button @click="compressFiles" class="flex-1 px-4 py-3 bg-blue-600 text-white rounded-xl font-bold">Compress</button>
              </div>
            </div>
          </div>

          <div v-if="showRemoteDownloadModal">
            <h3 class="text-xl font-bold mb-1 dark:text-white">Remote Download (Wget)</h3>
            <p class="text-sm text-gray-500 mb-6">Download file directly to server.</p>
            <div class="space-y-4">
              <div>
                <label class="block text-xs font-bold text-gray-400 uppercase mb-2">URL</label>
                <input v-model="remoteUrl" type="text" placeholder="https://example.com/file.zip" class="w-full bg-gray-50 dark:bg-white/5 border border-gray-200 dark:border-white/10 rounded-xl px-4 py-3 outline-none dark:text-white">
              </div>
              <div>
                <label class="block text-xs font-bold text-gray-400 uppercase mb-2">Save as (Filename)</label>
                <input v-model="remoteFilename" type="text" placeholder="filename.zip" class="w-full bg-gray-50 dark:bg-white/5 border border-gray-200 dark:border-white/10 rounded-xl px-4 py-3 outline-none dark:text-white">
              </div>
              <div class="flex gap-2 pt-2">
                <button @click="showRemoteDownloadModal = false" class="flex-1 px-4 py-3 text-gray-500 rounded-xl font-medium">Cancel</button>
                <button @click="downloadRemoteFile" class="flex-1 px-4 py-3 bg-blue-600 text-white rounded-xl font-bold">Download</button>
              </div>
            </div>
          </div>

        </div>
      </div>
    </Transition>

  </div>
</template>

<style scoped>
.hide-scrollbar::-webkit-scrollbar {
  display: none;
}
.hide-scrollbar {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

.animate-shake {
  animation: shake 0.5s cubic-bezier(.36,.07,.19,.97) both;
}

@keyframes shake {
  10%, 90% { transform: translate3d(-1px, 0, 0); }
  20%, 80% { transform: translate3d(2px, 0, 0); }
  30%, 50%, 70% { transform: translate3d(-4px, 0, 0); }
  40%, 60% { transform: translate3d(4px, 0, 0); }
}

.animate-scale-in {
  animation: scale-in 0.2s ease-out;
}

@keyframes scale-in {
  from { transform: scale(0.95); opacity: 0; }
  to { transform: scale(1); opacity: 1; }
}

/* Transitions */
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}
.fade-enter-from, .fade-leave-to {
  opacity: 0;
  transform: translateY(10px);
}

.modal-enter-active, .modal-leave-active {
  transition: opacity 0.3s ease;
}
.modal-enter-from, .modal-leave-to {
  opacity: 0;
}
@keyframes fade-in {
  from { opacity: 0; transform: translateY(-10px); }
  to { opacity: 1; transform: translateY(0); }
}
.animate-fade-in {
  animation: fade-in 0.2s ease-out;
}

@keyframes bounce-subtle {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-3px); }
}
.animate-bounce-subtle {
  animation: bounce-subtle 2s infinite ease-in-out;
}
</style>
