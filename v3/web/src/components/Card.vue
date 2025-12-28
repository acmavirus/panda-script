<template>
  <div :class="['panda-card', { 'panda-card-interactive': interactive }]">
    <!-- Header -->
    <div v-if="$slots.header || title" class="flex items-center justify-between mb-4">
      <div>
        <h3 v-if="title" class="text-base font-semibold text-[var(--text-primary)]">{{ title }}</h3>
        <p v-if="subtitle" class="text-sm text-[var(--text-muted)] mt-0.5">{{ subtitle }}</p>
      </div>
      <slot name="header-action"></slot>
    </div>
    
    <!-- Content -->
    <slot></slot>
    
    <!-- Footer -->
    <div v-if="$slots.footer" class="mt-4 pt-4 border-t border-[var(--border-color)]">
      <slot name="footer"></slot>
    </div>
  </div>
</template>

<script>
export default {
  name: 'Card',
  props: {
    title: String,
    subtitle: String,
    interactive: {
      type: Boolean,
      default: false
    }
  }
}
</script>
