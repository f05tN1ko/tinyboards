<script setup lang="ts">
const { t } = useI18n()
</script>

<template>
  <div class="space-y-2">
    <h3 class="text-xs font-semibold text-gray-500 uppercase">
      {{ t('board.wiki.pagesHeading') }}
    </h3>
    <slot />
  </div>
</template>
