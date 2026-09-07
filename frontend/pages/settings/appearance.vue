<script setup lang="ts">
import { useUIStore, type ThemeMode } from '~/stores/ui'

definePageMeta({ layout: 'settings', middleware: 'guards' })
const { t } = useI18n()
useHead({ title: () => t('settings.appearance.page.title') })

const uiStore = useUIStore()

const themes = computed(() => [
  { value: 'light', label: t('settings.appearance.page.themes.light'), description: t('settings.appearance.page.themes.lightDesc') },
  { value: 'dark', label: t('settings.appearance.page.themes.dark'), description: t('settings.appearance.page.themes.darkDesc') },
  { value: 'ocean', label: t('settings.appearance.page.themes.ocean'), description: t('settings.appearance.page.themes.oceanDesc') },
  { value: 'forest', label: t('settings.appearance.page.themes.forest'), description: t('settings.appearance.page.themes.forestDesc') },
  { value: 'sunset', label: t('settings.appearance.page.themes.sunset'), description: t('settings.appearance.page.themes.sunsetDesc') },
  { value: 'purple', label: t('settings.appearance.page.themes.purple'), description: t('settings.appearance.page.themes.purpleDesc') },
])

function selectTheme (theme: string): void {
  uiStore.setTheme(theme as ThemeMode)
}
</script>

<template>
  <div>
    <h2 class="text-lg font-semibold text-gray-900 mb-4">
      {{ $t('settings.appearance.page.heading') }}
    </h2>

    <div class="max-w-md">
      <p class="text-sm text-gray-600 mb-4">{{ $t('settings.appearance.page.chooseTheme') }}</p>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <button
          v-for="theme in themes"
          :key="theme.value"
          class="p-4 rounded-lg border-2 text-left transition-colors"
          :class="uiStore.theme === theme.value
            ? 'border-primary bg-primary/5'
            : 'border-gray-200 hover:border-gray-300'"
          @click="selectTheme(theme.value)"
        >
          <p class="font-medium text-sm text-gray-900">{{ theme.label }}</p>
          <p class="text-xs text-gray-500 mt-0.5">{{ theme.description }}</p>
        </button>
      </div>
    </div>
  </div>
</template>
