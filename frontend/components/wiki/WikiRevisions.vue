<script setup lang="ts">
const { t } = useI18n()
</script>

<template>
  <div class="space-y-2">
    <slot />
    <div v-if="!$slots.default" class="text-sm text-gray-500">
      {{ t('board.wiki.noRevisionsShort') }}
    </div>
  </div>
</template>
