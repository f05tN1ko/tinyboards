<script setup lang="ts">
import { useGraphQL, useGraphQLMutation } from '~/composables/useGraphQL'

const { t } = useI18n()

definePageMeta({ layout: 'admin' })
useHead({ title: () => t('admin.boardSettings.title') })

interface BoardSettingsConfig {
  boardsEnabled: boolean
  boardCreationMode: string
  trustedUserMinReputation: number
  trustedUserMinAccountAgeDays: number
  trustedUserMinPosts: number
  trustedUserManualApproval: boolean
  defaultBoardMode: string
}

interface SiteResponse {
  site: BoardSettingsConfig
}

interface UpdateSiteResponse {
  updateSiteConfig: BoardSettingsConfig
}

const { execute, loading, error } = useGraphQL<SiteResponse>()
const { execute: executeMutation, loading: saving, error: saveError } = useGraphQLMutation<UpdateSiteResponse>()

const boardsEnabled = ref(false)
const boardCreationMode = ref('Open')
const trustedUserMinReputation = ref(0)
const trustedUserMinAccountAgeDays = ref(0)
const trustedUserMinPosts = ref(0)
const trustedUserManualApproval = ref(false)
const defaultBoardMode = ref('feed')

const saved = ref(false)

const SITE_QUERY = `
  query {
    site {
      boardsEnabled
      boardCreationMode
      trustedUserMinReputation
      trustedUserMinAccountAgeDays
      trustedUserMinPosts
      trustedUserManualApproval
      defaultBoardMode
    }
  }
`

const UPDATE_MUTATION = `
  mutation UpdateSiteConfig($input: UpdateSiteConfigInput!) {
    updateSiteConfig(input: $input) {
      boardsEnabled
      boardCreationMode
      trustedUserMinReputation
      trustedUserMinAccountAgeDays
      trustedUserMinPosts
      trustedUserManualApproval
      defaultBoardMode
    }
  }
`

const creationModeOptions = computed(() => [
  { value: 'Open', label: t('admin.boardSettings.modeOpen') },
  { value: 'TrustedUsers', label: t('admin.boardSettings.modeTrustedUsers') },
  { value: 'AdminOnly', label: t('admin.boardSettings.modeAdminOnly') },
  { value: 'Disabled', label: t('admin.boardSettings.modeDisabled') },
])

onMounted(async () => {
  const result = await execute(SITE_QUERY)
  if (result?.site) {
    boardsEnabled.value = result.site.boardsEnabled
    boardCreationMode.value = result.site.boardCreationMode
    trustedUserMinReputation.value = result.site.trustedUserMinReputation
    trustedUserMinAccountAgeDays.value = result.site.trustedUserMinAccountAgeDays
    trustedUserMinPosts.value = result.site.trustedUserMinPosts
    trustedUserManualApproval.value = result.site.trustedUserManualApproval
    defaultBoardMode.value = result.site.defaultBoardMode
  }
})

async function saveSettings () {
  const result = await executeMutation(UPDATE_MUTATION, {
    variables: {
      input: {
        boardsEnabled: boardsEnabled.value,
        boardCreationMode: boardCreationMode.value,
        trustedUserMinReputation: trustedUserMinReputation.value,
        trustedUserMinAccountAgeDays: trustedUserMinAccountAgeDays.value,
        trustedUserMinPosts: trustedUserMinPosts.value,
        trustedUserManualApproval: trustedUserManualApproval.value,
        defaultBoardMode: defaultBoardMode.value,
      },
    },
  })
  if (result?.updateSiteConfig) {
    saved.value = true
    setTimeout(() => { saved.value = false }, 3000)
  }
}
</script>

<template>
  <div>
    <h2 class="text-lg font-semibold text-gray-900 mb-6">
      {{ $t('admin.boardSettings.heading') }}
    </h2>

    <CommonLoadingSpinner v-if="loading" />
    <CommonErrorDisplay v-else-if="error" :message="error.message" />

    <form v-else class="space-y-6 max-w-lg" @submit.prevent="saveSettings">
      <!-- Boards enabled -->
      <div>
        <label class="flex items-center gap-2">
          <input v-model="boardsEnabled" type="checkbox" class="form-checkbox" />
          <span class="text-sm font-medium text-gray-700">{{ $t('admin.boardSettings.boardsEnabled') }}</span>
        </label>
        <p class="mt-1 text-xs text-gray-500">
          {{ $t('admin.boardSettings.boardsEnabledHint') }}
        </p>
      </div>

      <!-- Board creation mode -->
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">
          {{ $t('admin.boardSettings.creationMode') }}
        </label>
        <select v-model="boardCreationMode" class="form-input w-full">
          <option v-for="opt in creationModeOptions" :key="opt.value" :value="opt.value">
            {{ opt.label }}
          </option>
        </select>
        <p class="mt-1 text-xs text-gray-500">
          {{ $t('admin.boardSettings.creationModeHint') }}
        </p>
      </div>

      <!-- Trusted Users settings (shown only when TrustedUsers mode is selected) -->
      <template v-if="boardCreationMode === 'TrustedUsers'">
        <div class="rounded-lg border border-gray-200 bg-gray-50 p-4 space-y-4">
          <h3 class="text-sm font-semibold text-gray-800">
            {{ $t('admin.boardSettings.trustedRequirements') }}
          </h3>
          <p class="text-xs text-gray-500">
            {{ $t('admin.boardSettings.trustedRequirementsHint') }}
          </p>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              {{ $t('admin.boardSettings.minReputation') }}
            </label>
            <input
              v-model.number="trustedUserMinReputation"
              type="number"
              min="0"
              class="form-input w-full"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              {{ $t('admin.boardSettings.minAccountAge') }}
            </label>
            <input
              v-model.number="trustedUserMinAccountAgeDays"
              type="number"
              min="0"
              class="form-input w-full"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              {{ $t('admin.boardSettings.minPosts') }}
            </label>
            <input
              v-model.number="trustedUserMinPosts"
              type="number"
              min="0"
              class="form-input w-full"
            />
          </div>

          <div>
            <label class="flex items-center gap-2">
              <input v-model="trustedUserManualApproval" type="checkbox" class="form-checkbox" />
              <span class="text-sm font-medium text-gray-700">{{ $t('admin.boardSettings.requireManualApproval') }}</span>
            </label>
            <p class="mt-1 text-xs text-gray-500">
              {{ $t('admin.boardSettings.manualApprovalHint') }}
            </p>
          </div>
        </div>
      </template>

      <!-- Default board mode -->
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-2">{{ $t('admin.boardSettings.defaultBoardMode') }}</label>
        <p class="text-xs text-gray-500 mb-3">
          {{ $t('admin.boardSettings.defaultBoardModeHint') }}
        </p>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <button
            type="button"
            class="text-left rounded-lg border-2 p-4 transition-all"
            :class="defaultBoardMode === 'feed'
              ? 'border-blue-600 bg-blue-50 ring-1 ring-blue-600'
              : 'border-gray-200 bg-white hover:border-gray-300'"
            @click="defaultBoardMode = 'feed'"
          >
            <div class="flex items-center gap-2 mb-1.5">
              <span class="text-lg">📰</span>
              <span class="font-semibold text-sm text-gray-900">{{ $t('admin.boardSettings.feedBoard') }}</span>
            </div>
            <p class="text-xs text-gray-500 leading-relaxed">
              {{ $t('admin.boardSettings.feedBoardDesc') }}
            </p>
          </button>
          <button
            type="button"
            class="text-left rounded-lg border-2 p-4 transition-all"
            :class="defaultBoardMode === 'forum'
              ? 'border-blue-600 bg-blue-50 ring-1 ring-blue-600'
              : 'border-gray-200 bg-white hover:border-gray-300'"
            @click="defaultBoardMode = 'forum'"
          >
            <div class="flex items-center gap-2 mb-1.5">
              <span class="text-lg">💬</span>
              <span class="font-semibold text-sm text-gray-900">{{ $t('admin.boardSettings.forumBoard') }}</span>
            </div>
            <p class="text-xs text-gray-500 leading-relaxed">
              {{ $t('admin.boardSettings.forumBoardDesc') }}
            </p>
          </button>
        </div>
      </div>

      <CommonErrorDisplay v-if="saveError" :message="saveError.message" />

      <div class="flex items-center gap-3">
        <button type="submit" class="button primary" :disabled="saving">
          {{ saving ? $t('admin.boardSettings.saving') : $t('admin.boardSettings.saveSettings') }}
        </button>
        <span v-if="saved" class="text-sm text-green-600">
          {{ $t('admin.boardSettings.saveSuccess') }}
        </span>
      </div>
    </form>
  </div>
</template>
