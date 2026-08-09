<script setup lang="ts">
import { useGraphQL, useGraphQLMutation } from '~/composables/useGraphQL'

const { t } = useI18n()

definePageMeta({ layout: 'admin' })
useHead({ title: () => t('admin.appearance.title') })

interface AppearanceConfig {
  primaryColor: string
  secondaryColor: string
  hoverColor: string
  defaultTheme: string
}

interface SiteAppearanceResponse {
  site: AppearanceConfig
}

interface UpdateAppearanceResponse {
  updateSiteConfig: AppearanceConfig
}

const { execute: fetchAppearance, loading, error, data } = useGraphQL<SiteAppearanceResponse>()
const { execute: executeMutation, loading: saving, error: saveError } = useGraphQLMutation<UpdateAppearanceResponse>()

const form = reactive({
  primaryColor: '#3b82f6',
  secondaryColor: '#6366f1',
  hoverColor: '#2563eb',
  defaultTheme: 'light',
})

const saveSuccess = ref(false)

const APPEARANCE_QUERY = `
  query {
    site {
      primaryColor
      secondaryColor
      hoverColor
      defaultTheme
    }
  }
`

const UPDATE_APPEARANCE_MUTATION = `
  mutation UpdateSiteConfig($input: UpdateSiteConfigInput!) {
    updateSiteConfig(input: $input) {
      primaryColor
      secondaryColor
      hoverColor
      defaultTheme
    }
  }
`

const themeOptions = computed(() => [
  { value: 'light', label: t('admin.appearance.themeLight') },
  { value: 'dark', label: t('admin.appearance.themeDark') },
  { value: 'system', label: t('admin.appearance.themeSystem') },
])

onMounted(async () => {
  const result = await fetchAppearance(APPEARANCE_QUERY)
  if (result?.site) {
    Object.assign(form, result.site)
  }
})

async function saveAppearance () {
  saveSuccess.value = false
  const result = await executeMutation(UPDATE_APPEARANCE_MUTATION, {
    variables: {
      input: {
        primaryColor: form.primaryColor,
        secondaryColor: form.secondaryColor,
        hoverColor: form.hoverColor,
        defaultTheme: form.defaultTheme,
      },
    },
  })
  if (result?.updateSiteConfig) {
    Object.assign(form, result.updateSiteConfig)
    saveSuccess.value = true
    setTimeout(() => { saveSuccess.value = false }, 3000)
  }
}
</script>

<template>
  <div>
    <h2 class="text-lg font-semibold text-gray-900 mb-6">
      {{ $t('admin.appearance.heading') }}
    </h2>

    <div v-if="loading" class="text-sm text-gray-500">
      {{ $t('admin.appearance.loading') }}
    </div>

    <div v-else-if="error" class="rounded-md bg-red-50 p-4 text-sm text-red-700">
      {{ $t('admin.appearance.loadFailed', { message: error.message }) }}
    </div>

    <form v-else class="space-y-6 max-w-2xl" @submit.prevent="saveAppearance">
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('admin.appearance.primaryColor') }}</label>
        <div class="flex items-center gap-3">
          <input v-model="form.primaryColor" type="color" class="h-10 w-10 rounded border border-gray-300 cursor-pointer" />
          <input v-model="form.primaryColor" type="text" class="form-input w-40" placeholder="#3b82f6" />
        </div>
      </div>

      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('admin.appearance.secondaryColor') }}</label>
        <div class="flex items-center gap-3">
          <input v-model="form.secondaryColor" type="color" class="h-10 w-10 rounded border border-gray-300 cursor-pointer" />
          <input v-model="form.secondaryColor" type="text" class="form-input w-40" placeholder="#6366f1" />
        </div>
      </div>

      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('admin.appearance.hoverColor') }}</label>
        <div class="flex items-center gap-3">
          <input v-model="form.hoverColor" type="color" class="h-10 w-10 rounded border border-gray-300 cursor-pointer" />
          <input v-model="form.hoverColor" type="text" class="form-input w-40" placeholder="#2563eb" />
        </div>
      </div>

      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('admin.appearance.defaultTheme') }}</label>
        <select v-model="form.defaultTheme" class="form-input w-full">
          <option v-for="theme in themeOptions" :key="theme.value" :value="theme.value">
            {{ theme.label }}
          </option>
        </select>
      </div>

      <div class="rounded-md border border-gray-200 p-4">
        <p class="text-sm font-medium text-gray-700 mb-3">{{ $t('admin.appearance.preview') }}</p>
        <div class="flex items-center gap-3">
          <div
            class="h-10 w-10 rounded-md border border-gray-300"
            :style="{ backgroundColor: form.primaryColor }"
            :title="$t('admin.appearance.previewPrimary')"
          />
          <div
            class="h-10 w-10 rounded-md border border-gray-300"
            :style="{ backgroundColor: form.secondaryColor }"
            :title="$t('admin.appearance.previewSecondary')"
          />
          <div
            class="h-10 w-10 rounded-md border border-gray-300"
            :style="{ backgroundColor: form.hoverColor }"
            :title="$t('admin.appearance.previewHover')"
          />
        </div>
      </div>

      <div v-if="saveError" class="rounded-md bg-red-50 p-4 text-sm text-red-700">
        {{ $t('admin.appearance.saveFailed', { message: saveError.message }) }}
      </div>

      <div v-if="saveSuccess" class="rounded-md bg-green-50 p-4 text-sm text-green-700">
        {{ $t('admin.appearance.saveSuccess') }}
      </div>

      <div>
        <button type="submit" class="button button-sm primary" :disabled="saving">
          {{ saving ? $t('common.saving') : $t('admin.appearance.saveAppearance') }}
        </button>
      </div>
    </form>
  </div>
</template>
