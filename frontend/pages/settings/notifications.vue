<script setup lang="ts">
import { useGraphQL } from '~/composables/useGraphQL'

definePageMeta({ layout: 'settings', middleware: 'guards' })
const { t } = useI18n()
useHead({ title: () => t('settings.notifications.title') })

const GET_SETTINGS_QUERY = `
  query GetNotificationSettings {
    getNotificationSettings {
      emailEnabled
      commentRepliesEnabled
      postRepliesEnabled
      mentionsEnabled
      privateMessagesEnabled
      boardInvitesEnabled
      moderatorActionsEnabled
      systemNotificationsEnabled
    }
  }
`

const UPDATE_SETTINGS_MUTATION = `
  mutation UpdateNotificationSettings($input: UpdateNotificationSettingsInput!) {
    updateNotificationSettings(input: $input) {
      success
    }
  }
`

interface NotificationSettings {
  emailEnabled: boolean
  commentRepliesEnabled: boolean
  postRepliesEnabled: boolean
  mentionsEnabled: boolean
  privateMessagesEnabled: boolean
  boardInvitesEnabled: boolean
  moderatorActionsEnabled: boolean
  systemNotificationsEnabled: boolean
}

interface NotifSettingsResponse {
  getNotificationSettings: NotificationSettings
}

const { execute, loading, error } = useGraphQL<NotifSettingsResponse>()

const settings = ref<NotificationSettings | null>(null)
const saving = ref(false)
const success = ref(false)

const toggles = [
  { key: 'emailEnabled', labelKey: 'settings.notifications.emailEnabled' },
  { key: 'commentRepliesEnabled', labelKey: 'settings.notifications.commentReplies' },
  { key: 'postRepliesEnabled', labelKey: 'settings.notifications.postReplies' },
  { key: 'mentionsEnabled', labelKey: 'settings.notifications.mentions' },
  { key: 'privateMessagesEnabled', labelKey: 'settings.notifications.privateMessages' },
  { key: 'boardInvitesEnabled', labelKey: 'settings.notifications.boardInvites' },
  { key: 'moderatorActionsEnabled', labelKey: 'settings.notifications.moderatorActions' },
  { key: 'systemNotificationsEnabled', labelKey: 'settings.notifications.systemNotifications' },
] as const

async function fetchSettings (): Promise<void> {
  const result = await execute(GET_SETTINGS_QUERY)
  if (result?.getNotificationSettings) {
    settings.value = { ...result.getNotificationSettings }
  }
}

async function saveSettings (): Promise<void> {
  if (!settings.value) { return }
  saving.value = true
  success.value = false

  const { execute: exec, error: saveError } = useGraphQL()
  await exec(UPDATE_SETTINGS_MUTATION, {
    variables: { input: settings.value },
  })

  if (!saveError.value) {
    success.value = true
    setTimeout(() => { success.value = false }, 3000)
  }

  saving.value = false
}

await fetchSettings()
</script>

<template>
  <div>
    <h2 class="text-lg font-semibold text-gray-900 mb-4">
      {{ $t('settings.notifications.heading') }}
    </h2>

    <CommonErrorDisplay v-if="error" :message="error.message" @retry="fetchSettings" />
    <CommonLoadingSpinner v-else-if="loading && !settings" size="lg" />

    <form v-else-if="settings" @submit.prevent="saveSettings" class="space-y-3 max-w-md">
      <label
        v-for="toggle in toggles"
        :key="toggle.key"
        class="flex items-center gap-2"
      >
        <input v-model="(settings as any)[toggle.key]" type="checkbox" class="form-checkbox" />
        <span class="text-sm text-gray-700">{{ $t(toggle.labelKey) }}</span>
      </label>

      <div class="flex items-center gap-3 pt-2">
        <button type="submit" class="button primary" :disabled="saving">
          {{ saving ? $t('settings.notifications.saving') : $t('settings.notifications.save') }}
        </button>
        <span v-if="success" class="text-sm text-green-600">{{ $t('settings.notifications.saveSuccess') }}</span>
      </div>
    </form>
  </div>
</template>
