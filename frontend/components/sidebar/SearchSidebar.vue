<script setup lang="ts">
const { t } = useI18n()
</script>

<template>
  <div class="space-y-5">
    <!-- Search tips card -->
    <div class="bg-white rounded-lg border border-gray-200 p-4">
      <h4 class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-3">
        {{ $t('search.tipsTitle') }}
      </h4>
      <ul class="space-y-2.5 text-xs text-gray-600">
        <li class="flex items-start gap-2">
          <span class="inline-block w-1 h-1 rounded-full bg-gray-300 mt-1.5 shrink-0" />
          {{ $t('search.tip1') }}
        </li>
        <li class="flex items-start gap-2">
          <span class="inline-block w-1 h-1 rounded-full bg-gray-300 mt-1.5 shrink-0" />
          {{ $t('search.tip2') }}
        </li>
        <li class="flex items-start gap-2">
          <span class="inline-block w-1 h-1 rounded-full bg-gray-300 mt-1.5 shrink-0" />
          {{ $t('search.tip3') }}
        </li>
      </ul>
    </div>
  </div>
</template>
