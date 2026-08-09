<script setup lang="ts">
const { t } = useI18n()

definePageMeta({ layout: 'admin' })
useHead({ title: () => t('admin.security.redirecting') })

// Redirect to settings page
onMounted(() => {
  navigateTo('/admin/settings')
})
</script>

<template>
  <div class="text-sm text-gray-500">
    {{ $t('admin.security.redirecting') }}
  </div>
</template>
