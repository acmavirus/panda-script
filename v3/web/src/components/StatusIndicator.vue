<template>
  <span 
    :class="['status-indicator', status]"
    :data-tooltip="tooltipText"
  ></span>
</template>

<script>
export default {
  name: 'StatusIndicator',
  props: {
    status: {
      type: String,
      required: true,
      validator: (v) => ['online', 'offline', 'active', 'inactive', 'running', 'stopped', 'warning', 'pending'].includes(v)
    },
    tooltip: String
  },
  computed: {
    tooltipText() {
      if (this.tooltip) return this.tooltip
      const statusMap = {
        online: 'Online',
        offline: 'Offline',
        active: 'Active',
        inactive: 'Inactive',
        running: 'Running',
        stopped: 'Stopped',
        warning: 'Warning',
        pending: 'Pending'
      }
      return statusMap[this.status] || this.status
    }
  }
}
</script>
