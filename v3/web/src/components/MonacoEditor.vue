<script setup>
import { ref, onMounted, watch, defineProps, defineEmits } from 'vue'
import loader from '@monaco-editor/loader'

const props = defineProps({
  modelValue: { type: String, default: '' },
  language: { type: String, default: 'javascript' },
  theme: { type: String, default: 'vs-dark' },
  readOnly: { type: Boolean, default: false }
})

const emit = defineEmits(['update:modelValue'])

const editorContainer = ref(null)
let editor = null
let monaco = null

const getLanguage = (filename) => {
  const ext = filename?.split('.').pop()?.toLowerCase()
  const langMap = {
    'js': 'javascript',
    'ts': 'typescript',
    'py': 'python',
    'php': 'php',
    'html': 'html',
    'css': 'css',
    'json': 'json',
    'md': 'markdown',
    'sh': 'shell',
    'bash': 'shell',
    'yml': 'yaml',
    'yaml': 'yaml',
    'xml': 'xml',
    'sql': 'sql',
    'go': 'go',
    'conf': 'ini',
    'nginx': 'nginx',
    'env': 'ini'
  }
  return langMap[ext] || 'plaintext'
}

onMounted(async () => {
  monaco = await loader.init()
  
  editor = monaco.editor.create(editorContainer.value, {
    value: props.modelValue,
    language: props.language,
    theme: props.theme,
    readOnly: props.readOnly,
    minimap: { enabled: false },
    fontSize: 14,
    lineNumbers: 'on',
    scrollBeyondLastLine: false,
    automaticLayout: true,
    wordWrap: 'on',
    tabSize: 2,
    padding: { top: 10 }
  })

  editor.onDidChangeModelContent(() => {
    emit('update:modelValue', editor.getValue())
  })
})

watch(() => props.modelValue, (newVal) => {
  if (editor && newVal !== editor.getValue()) {
    editor.setValue(newVal)
  }
})

watch(() => props.language, (newLang) => {
  if (editor && monaco) {
    monaco.editor.setModelLanguage(editor.getModel(), newLang)
  }
})

defineExpose({ getLanguage })
</script>

<template>
  <div ref="editorContainer" class="monaco-editor-container w-full h-full min-h-[400px] rounded-lg overflow-hidden border border-white/10"></div>
</template>

<style>
.monaco-editor-container {
  background: #1e1e1e;
}
</style>
