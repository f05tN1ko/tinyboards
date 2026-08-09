<script setup lang="ts">
import { useGraphQL, useGraphQLMutation } from '~/composables/useGraphQL'

const { t } = useI18n()

definePageMeta({ layout: 'admin' })
useHead({ title: () => t('admin.flairs.editTitle') })

interface Flair {
  id: string
  templateName: string
  textDisplay: string | null
  textColor: string
  backgroundColor: string
  isModOnly: boolean
  isActive: boolean
}

interface FlairResponse {
  getFlair: Flair
}

const route = useRoute()
const flairId = route.params.id as string

const { execute, loading, error, data } = useGraphQL<FlairResponse>()
const { execute: executeSave, loading: saving, error: saveError } = useGraphQL()

const form = reactive({
  templateName: '',
  textDisplay: '',
  textColor: '#1f2937',
  backgroundColor: '#e5e7eb',
  isModOnly: false,
  isActive: true,
})

const FLAIR_QUERY = `
  query GetFlair($id: ID!) {
    getFlair(id: $id) {
      id templateName textDisplay textColor backgroundColor isModOnly isActive
    }
  }
`

const UPDATE_FLAIR = `
  mutation UpdateFlair($input: UpdateFlairInput!) {
    updateFlair(input: $input) { id }
  }
`

onMounted(async () => {
  const result = await execute(FLAIR_QUERY, { variables: { id: flairId } })
  if (result?.getFlair) {
    Object.assign(form, result.getFlair)
  }
})

async function saveFlair () {
  await executeSave(UPDATE_FLAIR, {
    variables: {
      input: {
        id: flairId,
        templateName: form.templateName,
        textDisplay: form.textDisplay || null,
        textColor: form.textColor,
        backgroundColor: form.backgroundColor,
        isModOnly: form.isModOnly,
        isActive: form.isActive,
      },
    },
  })
  await navigateTo('/admin/flairs')
}
</script>

<template>
  <div>
    <h2 class="text-lg font-semibold text-gray-900 mb-6">
      {{ $t('admin.flairs.editTitle') }}
    </h2>

    <CommonLoadingSpinner v-if="loading" />
    <CommonErrorDisplay v-else-if="error" :message="error.message" />

    <form v-else class="space-y-4 max-w-lg" @submit.prevent="saveFlair">
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('admin.flairs.name') }}</label>
        <input v-model="form.templateName" type="text" class="form-input w-full" required />
      </div>

      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('admin.flairs.displayText') }}</label>
        <input v-model="form.textDisplay" type="text" class="form-input w-full" />
      </div>

      <div class="flex gap-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('admin.flairs.textColor') }}</label>
          <input v-model="form.textColor" type="color" class="h-10 w-16 p-1 border border-gray-300 rounded" />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('admin.flairs.backgroundColor') }}</label>
          <input v-model="form.backgroundColor" type="color" class="h-10 w-16 p-1 border border-gray-300 rounded" />
        </div>
        <div class="flex items-end">
          <span
            class="inline-flex items-center px-2.5 py-1 rounded text-xs font-medium"
            :style="{ color: form.textColor, backgroundColor: form.backgroundColor }"
          >
            {{ form.textDisplay || form.templateName || $t('admin.flairs.preview') }}
          </span>
        </div>
      </div>

      <div class="space-y-2">
        <label class="flex items-center gap-2">
          <input v-model="form.isModOnly" type="checkbox" class="form-checkbox" />
          <span class="text-sm text-gray-700">{{ $t('admin.flairs.modOnlyFlair') }}</span>
        </label>
        <label class="flex items-center gap-2">
          <input v-model="form.isActive" type="checkbox" class="form-checkbox" />
          <span class="text-sm text-gray-700">{{ $t('admin.flairs.active') }}</span>
        </label>
      </div>

      <CommonErrorDisplay v-if="saveError" :message="saveError.message" />

      <div class="flex gap-3">
        <button type="submit" class="button primary" :disabled="saving">
          {{ saving ? $t('admin.flairs.saving') : $t('admin.flairs.saveChanges') }}
        </button>
        <NuxtLink to="/admin/flairs" class="button white">
          {{ $t('admin.flairs.cancel') }}
        </NuxtLink>
      </div>
    </form>
  </div>
</template>
