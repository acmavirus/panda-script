<script setup>
import { ref, onMounted, computed, shallowRef } from 'vue'
import { useRoute } from 'vue-router'
import axios from 'axios'
import { Folder, File, ArrowLeft, Trash2, Edit2, FilePlus, FolderPlus, RefreshCw, Save, X, Upload, Download, Archive } from 'lucide-vue-next'
import { VueMonacoEditor } from '@guolao/vue-monaco-editor'

const currentPath = ref('/')
const files = ref([])
const loading = ref(false)
const error = ref('')
const editingFile = ref(null)
const fileContent = ref('')
const showNewFolderModal = ref(false)
const newFolderName = ref('')
const showRemoteDownloadModal = ref(false)
const remoteUrl = ref('')
const remoteFilename = ref('')
const fileInput = ref(null)

// Monaco Editor Config
const editorOptions = {
  theme: 'vs-dark',
  fontSize: 14,
  automaticLayout: true,
  minimap: { enabled: true }
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
    const res = await axios.get('/api/files/read', { params: { path: file.path } })
    fileContent.value = res.data.content
    editingFile.value = file
  } catch (err) {
    alert('Failed to read file: ' + (err.response?.data?.error || err.message))
  }
}

const saveFile = async () => {
  if (!editingFile.value) return
  try {
    await axios.post('/api/files/write', {
      path: editingFile.value.path,
      content: fileContent.value
    })
    editingFile.value = null
    loadFiles(currentPath.value)
  } catch (err) {
    alert('Failed to save file: ' + (err.response?.data?.error || err.message))
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
    await axios.post('/api/files/upload', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })
    loadFiles(currentPath.value)
  } catch (err) {
    alert('Upload failed: ' + (err.response?.data?.error || err.message))
  } finally {
    event.target.value = '' // Reset input
  }
}

const getLanguage = (filename) => {
  const ext = filename.split('.').pop().toLowerCase()
  const map = {
    'js': 'javascript',
    'vue': 'html', // Monaco doesn't have vue out of box usually, treat as html
    'html': 'html',
    'css': 'css',
    'json': 'json',
    'go': 'go',
    'py': 'python',
    'php': 'php',
    'sh': 'shell',
    'md': 'markdown',
    'sql': 'sql',
    'conf': 'ini',
    'ini': 'ini'
  }
  return map[ext] || 'plaintext'
}

onMounted(() => {
  const route = useRoute()
  const initialPath = route.query.path || '/'
  loadFiles(initialPath)
})
</script>

<template>
  <div class="p-4 lg:p-6 h-full flex flex-col">
    <!-- Header -->
    <div class="flex flex-col gap-4 mb-6">
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div class="flex items-center space-x-3 overflow-hidden">
          <button @click="goUp" :disabled="currentPath === '/'" 
                  class="shrink-0 p-2 bg-white/5 rounded-lg hover:bg-white/10 disabled:opacity-50 disabled:cursor-not-allowed transition-colors">
            <ArrowLeft :size="18" />
          </button>
          <div class="text-[13px] font-mono bg-black/20 px-3 py-2 rounded-lg border border-white/5 truncate flex-1 md:w-96">
            {{ currentPath }}
          </div>
        </div>
        
        <div class="flex items-center space-x-2 shrink-0 overflow-x-auto pb-2 sm:pb-0">
          <input type="file" ref="fileInput" multiple class="hidden" @change="handleFileUpload">
          <button @click="triggerUpload" class="flex items-center space-x-2 px-3 py-2 bg-green-500/10 text-green-400 hover:bg-green-500/20 rounded-lg transition-colors whitespace-nowrap text-xs sm:text-sm">
            <Upload :size="16" />
            <span class="hidden sm:inline">Upload</span>
          </button>
          <button @click="showRemoteDownloadModal = true" class="flex items-center space-x-2 px-3 py-2 bg-purple-500/10 text-purple-400 hover:bg-purple-500/20 rounded-lg transition-colors whitespace-nowrap text-xs sm:text-sm">
            <Download :size="16" />
            <span class="hidden lg:inline">Remote URL</span>
            <span class="hidden sm:inline lg:hidden">Remote</span>
          </button>
          <button @click="showNewFolderModal = true" class="flex items-center space-x-2 px-3 py-2 bg-blue-500/10 text-blue-400 hover:bg-blue-500/20 rounded-lg transition-colors whitespace-nowrap text-xs sm:text-sm">
            <FolderPlus :size="16" />
            <span class="hidden sm:inline">New Folder</span>
          </button>
          <button @click="loadFiles(currentPath)" class="p-2 bg-white/5 rounded-lg hover:bg-white/10 transition-colors shrink-0">
            <RefreshCw :size="16" :class="{'animate-spin': loading}" />
          </button>
        </div>
      </div>
    </div>

    <!-- Error Message -->
    <div v-if="error" class="bg-red-500/10 border border-red-500/20 text-red-400 p-4 rounded-xl mb-6">
      {{ error }}
    </div>

    <!-- File List -->
    <!-- File List -->
    <div class="flex-1 bg-black/20 border border-white/5 rounded-xl overflow-hidden flex flex-col"
         @dragover.prevent
         @drop.prevent="handleDrop">
      
      <!-- Horizontal Scroll Wrapper -->
      <div class="overflow-x-auto flex-1 flex flex-col">
        <div class="min-w-[750px] flex-1 flex flex-col">
          <!-- Header -->
          <div class="grid grid-cols-12 gap-4 p-4 border-b border-white/5 text-xs font-medium text-gray-500 uppercase tracking-wider bg-white/2">
            <div class="col-span-6">Name</div>
            <div class="col-span-2">Size</div>
            <div class="col-span-2">Permissions</div>
            <div class="col-span-2 text-right">Actions</div>
          </div>

          <!-- List Body -->
          <div class="overflow-y-auto flex-1">
            <div v-if="loading" class="p-8 text-center text-gray-500 italic">
              <div class="animate-spin inline-block w-5 h-5 border-2 border-panda-primary border-t-transparent rounded-full mr-2"></div>
              Loading files...
            </div>
            <div v-else-if="files.length === 0" class="p-8 text-center text-gray-500">Folder is empty</div>
            
            <div v-for="file in files" :key="file.path" 
                 class="grid grid-cols-12 gap-4 p-3 items-center hover:bg-white/5 transition-colors border-b border-white/5 last:border-0 group cursor-pointer"
                 @dblclick="openItem(file)">
              <div class="col-span-6 flex items-center space-x-3 overflow-hidden">
                <Folder v-if="file.is_dir" class="text-yellow-500 shrink-0" :size="18" />
                <File v-else class="text-blue-400 shrink-0" :size="18" />
                <span class="truncate text-sm text-gray-200">{{ file.name }}</span>
              </div>
              <div class="col-span-2 text-[13px] text-gray-500 font-mono">{{ file.is_dir ? '-' : formatSize(file.size) }}</div>
              <div class="col-span-2 text-[13px] text-gray-500 font-mono">{{ file.mode }}</div>
              <div class="col-span-2 flex items-center justify-end space-x-2 md:opacity-0 group-hover:opacity-100 transition-opacity pr-2">
                <button 
                  v-if="!file.is_dir && isArchive(file.name)"
                  @click.stop="extractFile(file)" 
                  class="p-1.5 hover:bg-orange-500/10 rounded-lg text-gray-400 hover:text-orange-500" 
                  title="Extract Here"
                >
                  <Archive :size="16" />
                </button>
                <button @click.stop="openItem(file)" class="p-1.5 hover:bg-white/10 rounded-lg text-gray-400 hover:text-white" title="Edit/Open">
                  <Edit2 :size="16" />
                </button>
                <button @click.stop="deleteItem(file)" class="p-1.5 hover:bg-red-500/10 rounded-lg text-gray-400 hover:text-red-500" title="Delete">
                  <Trash2 :size="16" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Editor Modal -->
    <div v-if="editingFile" class="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-8">
      <div class="bg-panda-dark border border-white/10 rounded-2xl w-full max-w-6xl h-[90vh] flex flex-col shadow-2xl">
        <div class="flex items-center justify-between p-4 border-b border-white/5">
          <h3 class="font-medium flex items-center space-x-2">
            <File :size="18" class="text-blue-400" />
            <span>{{ editingFile.name }}</span>
          </h3>
          <div class="flex items-center space-x-2">
            <button @click="saveFile" class="flex items-center space-x-2 px-4 py-2 bg-panda-primary hover:bg-panda-primary/90 rounded-lg text-sm font-bold transition-colors">
              <Save :size="16" />
              <span>Save</span>
            </button>
            <button @click="editingFile = null" class="p-2 hover:bg-white/10 rounded-lg transition-colors">
              <X :size="20" />
            </button>
          </div>
        </div>
        <div class="flex-1 overflow-hidden">
          <VueMonacoEditor
            v-model:value="fileContent"
            :language="getLanguage(editingFile.name)"
            theme="vs-dark"
            :options="editorOptions"
            class="h-full w-full"
          />
        </div>
      </div>
    </div>

    <!-- New Folder Modal -->
    <div v-if="showNewFolderModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm">
      <div class="bg-panda-dark border border-white/10 rounded-2xl w-96 p-6 shadow-2xl">
        <h3 class="text-lg font-bold mb-4">Create New Folder</h3>
        <input v-model="newFolderName" type="text" placeholder="Folder Name" 
               class="w-full bg-black/20 border border-white/10 rounded-xl px-4 py-2 mb-4 focus:border-panda-primary outline-none text-white"
               @keyup.enter="createFolder">
        <div class="flex justify-end space-x-2">
          <button @click="showNewFolderModal = false" class="px-4 py-2 text-gray-400 hover:text-white transition-colors">Cancel</button>
          <button @click="createFolder" class="px-4 py-2 bg-blue-500 hover:bg-blue-600 rounded-lg font-medium transition-colors">Create</button>
        </div>
      </div>
    </div>
  </div>
</template>
