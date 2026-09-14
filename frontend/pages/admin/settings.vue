<script setup lang="ts">
import { useGraphQL, useGraphQLMutation } from '~/composables/useGraphQL'
import { useSiteStore } from '~/stores/site'

const { t } = useI18n()

definePageMeta({ layout: 'admin' })
useHead({ title: () => t('admin.settings.title') })

const siteStore = useSiteStore()

interface SiteConfig {
  name: string
  description: string
  enableDownvotes: boolean
  enableNSFW: boolean
  registrationMode: string
  requireEmailVerification: boolean
  applicationQuestion: string
  isPrivate: boolean
  captchaEnabled: boolean
  captchaDifficulty: string
}

interface SiteResponse {
  site: SiteConfig
}

interface UpdateSiteResponse {
  updateSiteConfig: SiteConfig
}

const { execute: fetchSite, loading, error } = useGraphQL<SiteResponse>()
const { execute: executeMutation, loading: saving, error: saveError } = useGraphQLMutation<UpdateSiteResponse>()

const form = reactive({
  name: '',
  description: '',
  enableDownvotes: true,
  enableNSFW: false,
  registrationMode: 'open',
  requireEmailVerification: false,
  applicationQuestion: '',
  isPrivate: false,
  captchaEnabled: false,
  captchaDifficulty: 'medium',
})

const saveSuccess = ref(false)

const SITE_QUERY = `
  query {
    site {
      name
      description
      enableDownvotes
      enableNSFW
      registrationMode
      requireEmailVerification
      applicationQuestion
      isPrivate
      captchaEnabled
      captchaDifficulty
    }
  }
`

const UPDATE_SITE_MUTATION = `
  mutation UpdateSiteConfig($input: UpdateSiteConfigInput!) {
    updateSiteConfig(input: $input) {
      name
      description
      enableDownvotes
      enableNSFW
      registrationMode
      requireEmailVerification
      applicationQuestion
      isPrivate
      captchaEnabled
      captchaDifficulty
    }
  }
`

const registrationModes = computed(() => [
  { value: 'open', label: t('admin.settings.modeOpen') },
  { value: 'application_required', label: t('admin.settings.modeRequireApplication') },
  { value: 'invite_only', label: t('admin.settings.modeInviteOnly') },
  { value: 'closed', label: t('admin.settings.modeClosed') },
])

onMounted(async () => {
  const result = await fetchSite(SITE_QUERY)
  if (result?.site) {
    Object.assign(form, result.site)
  }
})

async function saveSettings () {
  saveSuccess.value = false
  const result = await executeMutation(UPDATE_SITE_MUTATION, {
    variables: {
      input: {
        name: form.name,
        description: form.description,
        enableDownvotes: form.enableDownvotes,
        enableNsfw: form.enableNSFW,
        registrationMode: form.registrationMode,
        requireEmailVerification: form.requireEmailVerification,
        applicationQuestion: form.applicationQuestion || undefined,
        isPrivate: form.isPrivate,
        captchaEnabled: form.captchaEnabled,
        captchaDifficulty: form.captchaDifficulty,
      },
    },
  })
  if (result?.updateSiteConfig) {
    Object.assign(form, result.updateSiteConfig)
    saveSuccess.value = true
    if (siteStore.site) {
      siteStore.setSite({
        ...siteStore.site,
        name: form.name,
        registrationMode: form.registrationMode,
        enableDownvotes: form.enableDownvotes,
        enableNSFW: form.enableNSFW,
        requireEmailVerification: form.requireEmailVerification,
        isPrivate: form.isPrivate,
      })
    }
    setTimeout(() => { saveSuccess.value = false }, 3000)
  }
}
</script>

<template>
  <div>
    <h2 class="text-lg font-semibold text-gray-900 mb-6">
      {{ $t('admin.settings.heading') }}
    </h2>

    <div v-if="loading" class="text-sm text-gray-500">
      {{ $t('admin.settings.loading') }}
    </div>

    <div v-else-if="error" class="rounded-md bg-red-50 p-4 text-sm text-red-700">
      {{ $t('admin.settings.loadFailed', { message: error.message }) }}
    </div>

    <form v-else class="space-y-8 max-w-2xl" @submit.prevent="saveSettings">
      <!-- General section -->
      <section>
        <h3 class="text-sm font-medium text-gray-500 uppercase tracking-wide mb-4">
          {{ $t('admin.settings.general') }}
        </h3>
        <div class="space-y-5">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('admin.settings.siteName') }}</label>
            <input v-model="form.name" type="text" class="form-input w-full" />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('admin.settings.description') }}</label>
            <textarea v-model="form.description" rows="3" class="form-input w-full" />
          </div>

          <div class="space-y-3">
            <label class="flex items-center gap-2">
              <input v-model="form.enableDownvotes" type="checkbox" class="form-checkbox" />
              <span class="text-sm text-gray-700">{{ $t('admin.settings.enableDownvotes') }}</span>
            </label>

            <label class="flex items-center gap-2">
              <input v-model="form.enableNSFW" type="checkbox" class="form-checkbox" />
              <span class="text-sm text-gray-700">{{ $t('admin.settings.enableNsfw') }}</span>
            </label>

            <label class="flex items-center gap-2">
              <input v-model="form.isPrivate" type="checkbox" class="form-checkbox" />
              <span class="text-sm text-gray-700">{{ $t('admin.settings.privateInstance') }}</span>
            </label>
          </div>
        </div>
      </section>

      <hr class="border-gray-200" />

      <!-- Registration & Security section -->
      <section>
        <h3 class="text-sm font-medium text-gray-500 uppercase tracking-wide mb-4">
          {{ $t('admin.settings.registrationSecurity') }}
        </h3>
        <div class="space-y-5">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              {{ $t('admin.settings.registrationMode') }}
            </label>
            <select v-model="form.registrationMode" class="form-input w-full">
              <option v-for="mode in registrationModes" :key="mode.value" :value="mode.value">
                {{ mode.label }}
              </option>
            </select>
            <p class="mt-1 text-xs text-gray-500">
              {{ $t('admin.settings.registrationModeHint') }}
            </p>
          </div>

          <div v-if="form.registrationMode === 'application_required'">
            <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('admin.settings.applicationQuestion') }}</label>
            <textarea v-model="form.applicationQuestion" rows="2" class="form-input w-full" />
          </div>

          <div class="space-y-3">
            <div>
              <label class="flex items-center gap-2">
                <input v-model="form.requireEmailVerification" type="checkbox" class="form-checkbox" />
                <span class="text-sm text-gray-700">{{ $t('admin.settings.requireEmailVerification') }}</span>
              </label>
              <p class="ml-6 text-xs text-gray-500">
                {{ $t('admin.settings.emailVerificationHint') }}
              </p>
            </div>

            <div>
              <label class="flex items-center gap-2">
                <input v-model="form.captchaEnabled" type="checkbox" class="form-checkbox" />
                <span class="text-sm text-gray-700">{{ $t('admin.settings.enableCaptcha') }}</span>
              </label>
              <p class="ml-6 text-xs text-gray-500">
                {{ $t('admin.settings.captchaHint') }}
              </p>
            </div>
          </div>

          <div v-if="form.captchaEnabled">
            <label class="block text-sm font-medium text-gray-700 mb-1">
              {{ $t('admin.settings.captchaDifficulty') }}
            </label>
            <select v-model="form.captchaDifficulty" class="form-input w-full">
              <option value="easy">{{ $t('admin.settings.difficultyEasy') }}</option>
              <option value="medium">{{ $t('admin.settings.difficultyMedium') }}</option>
              <option value="hard">{{ $t('admin.settings.difficultyHard') }}</option>
            </select>
          </div>
        </div>
      </section>

      <hr class="border-gray-200" />

      <div v-if="saveError" class="rounded-md bg-red-50 p-4 text-sm text-red-700">
        {{ $t('admin.settings.saveFailed', { message: saveError.message }) }}
      </div>

      <div v-if="saveSuccess" class="rounded-md bg-green-50 p-4 text-sm text-green-700">
        {{ $t('admin.settings.saveSuccess') }}
      </div>

      <div>
        <button type="submit" class="button button-sm primary" :disabled="saving">
          {{ saving ? $t('admin.settings.saving') : $t('admin.settings.saveSettings') }}
        </button>
      </div>
    </form>
  </div>
</template>
