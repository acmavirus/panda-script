<template>
  <!-- Skeleton Card -->
  <div v-if="loading && type === 'card'" class="panda-card skeleton-card"></div>
  
  <!-- Skeleton Table Row -->
  <tr v-else-if="loading && type === 'table-row'">
    <td v-for="n in columns" :key="n">
      <div class="skeleton skeleton-text" :class="n === 1 ? 'medium' : 'short'"></div>
    </td>
  </tr>
  
  <!-- Skeleton Stats Card -->
  <div v-else-if="loading && type === 'stats'" class="panda-card">
    <div class="flex justify-between items-start mb-4">
      <div class="skeleton skeleton-circle" style="width: 48px; height: 48px;"></div>
      <div class="skeleton skeleton-text short" style="width: 60px;"></div>
    </div>
    <div class="space-y-2">
      <div class="skeleton skeleton-text short"></div>
      <div class="skeleton skeleton-text medium" style="height: 28px;"></div>
    </div>
    <div class="skeleton mt-4" style="height: 6px; border-radius: 3px;"></div>
  </div>
  
  <!-- Skeleton List -->
  <div v-else-if="loading && type === 'list'" class="space-y-3">
    <div v-for="n in count" :key="n" class="flex items-center gap-3">
      <div class="skeleton skeleton-circle" style="width: 40px; height: 40px;"></div>
      <div class="flex-1 space-y-2">
        <div class="skeleton skeleton-text medium"></div>
        <div class="skeleton skeleton-text short"></div>
      </div>
    </div>
  </div>
  
  <!-- Skeleton Text Block -->
  <div v-else-if="loading && type === 'text'" class="space-y-2">
    <div class="skeleton skeleton-text long"></div>
    <div class="skeleton skeleton-text medium"></div>
    <div class="skeleton skeleton-text short"></div>
  </div>
  
  <!-- Default: Show content -->
  <slot v-else></slot>
</template>

<script>
export default {
  name: 'Skeleton',
  props: {
    loading: {
      type: Boolean,
      default: true
    },
    type: {
      type: String,
      default: 'text', // card, table-row, stats, list, text
      validator: (v) => ['card', 'table-row', 'stats', 'list', 'text'].includes(v)
    },
    columns: {
      type: Number,
      default: 4
    },
    count: {
      type: Number,
      default: 3
    }
  }
}
</script>
