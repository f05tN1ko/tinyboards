<script setup lang="ts">
import { useGraphQL } from '~/composables/useGraphQL'
import { useAuth } from '~/composables/useAuth'
import { useUIStore, type ThemeMode } from '~/stores/ui'

definePageMeta({ layout: 'settings', middleware: 'guards' })
const { t } = useI18n()
useHead({ title: () => t('settings.account.title') })

const { logout } = useAuth()
const uiStore = useUIStore()

const GET_SETTINGS_QUERY = `
  query GetUserSettings {
    getUserSettings {
      id
      name
      email
      showNSFW
      showBots
      theme
      defaultSortType
      defaultListingType
      isEmailNotificationsEnabled
      isEmailVerified
      editorMode
    }
  }
`

const UPDATE_SETTINGS_MUTATION = `
  mutation UpdateSettings($input: UpdateSettingsInput!) {
    updateSettings(input: $input) {
      id
      name
      email
      showNSFW
      showBots
      theme
      isEmailNotificationsEnabled
    }
  }
`

const DELETE_ACCOUNT_MUTATION = `
  mutation DeleteAccount {
    deleteAccount
  }
`

interface SettingsData {
  showNSFW: boolean
  showBots: boolean
  theme: string
  isEmailNotificationsEnabled: boolean
  isEmailVerified: boolean
  email: string | null
}

interface GetSettingsResponse {
  getUserSettings: SettingsData
}

const { execute, loading, error } = useGraphQL<GetSettingsResponse>()

const settings = ref<SettingsData | null>(null)
const saving = ref(false)
const saveError = ref<string | null>(null)
const success = ref(false)
const showDeleteConfirm = ref(false)
const deleting = ref(false)
const verificationSending = ref(false)
const verificationSent = ref(false)
const verificationError = ref<string | null>(null)

async function requestVerification (): Promise<void> {
  if (!settings.value?.email) return
  verificationSending.value = true
  verificationError.value = null
  verificationSent.value = false

  try {
    await $fetch('/api/auth/email-request-verification', {
      method: 'POST',
      body: { email: settings.value.email },
    })
    verificationSent.value = true
  } catch (err: unknown) {
    const fetchError = err as { data?: { error?: string }; statusMessage?: string }
    verificationError.value = fetchError.data?.error ?? fetchError.statusMessage ?? t('settings.account.failedToSendVerification')
  } finally {
    verificationSending.value = false
  }
}

async function fetchSettings (): Promise<void> {
  const result = await execute(GET_SETTINGS_QUERY)
  if (result?.getUserSettings) {
    settings.value = { ...result.getUserSettings }
  }
}

onMounted(() => { fetchSettings() })

async function saveSettings (): Promise<void> {
  if (!settings.value) { return }
  saving.value = true
  success.value = false
  saveError.value = null

  const { execute: exec, error: mutError } = useGraphQL()
  await exec(UPDATE_SETTINGS_MUTATION, {
    variables: {
      input: {
        showNsfw: settings.value.showNSFW,
        showBots: settings.value.showBots,
        theme: settings.value.theme,
        isEmailNotificationsEnabled: settings.value.isEmailNotificationsEnabled,
      },
    },
  })

  if (mutError.value) {
    saveError.value = mutError.value.message
  } else {
    // Apply theme change to UI immediately
    if (settings.value) {
      const themeValue = settings.value.theme === 'default' ? 'light' : settings.value.theme
      uiStore.setTheme(themeValue as ThemeMode)
    }
    success.value = true
    setTimeout(() => { success.value = false }, 3000)
  }

  saving.value = false
}

async function deleteAccount (): Promise<void> {
  deleting.value = true
  const { execute: exec, error: delError } = useGraphQL()
  await exec(DELETE_ACCOUNT_MUTATION)

  if (delError.value) {
    saveError.value = delError.value.message
    deleting.value = false
    showDeleteConfirm.value = false
    return
  }

  await logout()
}

</script>

<template>
  <div>
    <h2 class="text-lg font-semibold text-gray-900 mb-4">
      {{ $t('settings.account.title') }}
    </h2>

    <CommonErrorDisplay v-if="error" :message="error.message" @retry="fetchSettings" />
    <CommonLoadingSpinner v-else-if="loading && !settings" size="lg" />

    <template v-else-if="settings">
      <form @submit.prevent="saveSettings" class="space-y-4 max-w-md">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('settings.account.email') }}</label>
          <div class="flex items-center gap-2">
            <p class="text-sm text-gray-600">{{ settings.email ?? $t('settings.account.emailNotSet') }}</p>
            <span
              v-if="settings.email && settings.isEmailVerified"
              class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[11px] font-medium bg-green-100 text-green-700"
            >
              <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
              </svg>
              {{ $t('settings.account.verified') }}
            </span>
            <span
              v-else-if="settings.email"
              class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[11px] font-medium bg-yellow-100 text-yellow-700"
            >
              {{ $t('settings.account.notVerified') }}
            </span>
          </div>
          <div v-if="settings.email && !settings.isEmailVerified" class="mt-1.5">
            <button
              v-if="!verificationSent"
              class="text-sm text-primary hover:underline"
              :disabled="verificationSending"
              @click="requestVerification"
            >
              {{ verificationSending ? $t('settings.account.sendingVerification') : $t('settings.account.sendVerification') }}
            </button>
            <p v-else class="text-sm text-green-600">{{ $t('settings.account.verificationSent') }}</p>
            <p v-if="verificationError" class="text-sm text-red-600 mt-0.5">{{ verificationError }}</p>
          </div>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('settings.account.theme') }}</label>
          <select v-model="settings.theme" class="form-input">
            <option value="default">{{ $t('settings.account.themeDefault') }}</option>
            <option value="dark">{{ $t('settings.account.themeDark') }}</option>
            <option value="ocean">{{ $t('settings.account.themeOcean') }}</option>
            <option value="forest">{{ $t('settings.account.themeForest') }}</option>
            <option value="sunset">{{ $t('settings.account.themeSunset') }}</option>
            <option value="purple">{{ $t('settings.account.themePurple') }}</option>
          </select>
        </div>

        <div class="space-y-2">
          <label class="flex items-center gap-2">
            <input v-model="settings.showNSFW" type="checkbox" class="form-checkbox" />
            <span class="text-sm text-gray-700">{{ $t('settings.account.showNSFW') }}</span>
          </label>

          <label class="flex items-center gap-2">
            <input v-model="settings.showBots" type="checkbox" class="form-checkbox" />
            <span class="text-sm text-gray-700">{{ $t('settings.account.showBots') }}</span>
          </label>

          <label class="flex items-center gap-2">
            <input v-model="settings.isEmailNotificationsEnabled" type="checkbox" class="form-checkbox" />
            <span class="text-sm text-gray-700">{{ $t('settings.account.emailNotifications') }}</span>
          </label>
        </div>

        <div class="flex items-center gap-3">
          <button type="submit" class="button primary" :disabled="saving">
            {{ saving ? $t('settings.account.saving') : $t('settings.account.save') }}
          </button>
          <span v-if="success" class="text-sm text-green-600">{{ $t('settings.account.saveSuccess') }}</span>
          <span v-if="saveError" class="text-sm text-red-600">{{ saveError }}</span>
        </div>
      </form>

      <div class="mt-8 pt-6 border-t border-gray-200">
        <h3 class="text-sm font-semibold text-red-600 mb-2">{{ $t('settings.account.headingDangerZone') }}</h3>
        <button
          v-if="!showDeleteConfirm"
          class="button button-sm text-red-600 border-red-200 hover:bg-red-50"
          @click="showDeleteConfirm = true"
        >
          {{ $t('settings.account.deleteAccount') }}
        </button>
        <div v-else class="flex items-center gap-2">
          <p class="text-sm text-red-600">{{ $t('settings.account.deleteConfirmPrompt') }}</p>
          <button class="button button-sm text-red-600 border-red-300 hover:bg-red-50" :disabled="deleting" @click="deleteAccount">
            {{ deleting ? $t('settings.account.deleting') : $t('settings.account.deleteConfirm') }}
          </button>
          <button class="button button-sm white" @click="showDeleteConfirm = false">
            {{ $t('settings.account.cancel') }}
          </button>
        </div>
      </div>
    </template>
  </div>
</template>
