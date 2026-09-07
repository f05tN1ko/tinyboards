<script setup lang="ts">
import { ref } from 'vue'
import { useGraphQL, useGraphQLMutation } from '~/composables/useGraphQL'

const { t, locale } = useI18n()

definePageMeta({ layout: 'admin' })
useHead({ title: () => t('admin.invites.title') })

interface SiteInviteGql {
  id: string
  verificationCode: string
  createdAt: string
}

interface ListInvitesResponse {
  listInvites: SiteInviteGql[]
}

interface GenerateInviteResponse {
  createInvite: string
}

const { execute, data, loading, error } = useGraphQL<ListInvitesResponse>()
const { execute: executeGenerate, loading: generateLoading } = useGraphQLMutation<GenerateInviteResponse>()

const copiedId = ref<string | null>(null)

const LIST_INVITES_QUERY = `
  query ListInvites {
    listInvites {
      id
      verificationCode
      createdAt
    }
  }
`

async function fetchInvites () {
  await execute(LIST_INVITES_QUERY)
}

async function generateInvite () {
  await executeGenerate(`
    mutation CreateInvite {
      createInvite
    }
  `)

  await fetchInvites()
}

async function copyCode (invite: SiteInviteGql) {
  try {
    await navigator.clipboard.writeText(invite.verificationCode)
    copiedId.value = invite.id
    setTimeout(() => {
      copiedId.value = null
    }, 2000)
  } catch {
    // Fallback: select the text for manual copy
  }
}

fetchInvites()

function formatDate (dateStr: string): string {
  return new Date(dateStr).toLocaleDateString(locale.value === 'zh-CN' ? 'zh-CN' : 'en-US')
}
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h2 class="text-lg font-semibold text-gray-900">
        {{ $t('admin.invites.heading') }}
      </h2>
      <button
        class="button primary"
        :disabled="generateLoading"
        @click="generateInvite"
      >
        {{ generateLoading ? $t('admin.invites.generating') : $t('admin.invites.generate') }}
      </button>
    </div>

    <CommonLoadingSpinner v-if="loading" size="lg" />

    <CommonErrorDisplay
      v-else-if="error"
      :message="error.message"
      @retry="fetchInvites"
    />

    <div v-else-if="data?.listInvites?.length">
      <div class="space-y-3">
        <div
          v-for="invite in data.listInvites"
          :key="invite.id"
          class="flex items-center justify-between p-4 bg-white border rounded-lg"
        >
          <div>
            <code class="text-sm font-mono bg-gray-100 px-2 py-1 rounded select-all">
              {{ invite.verificationCode }}
            </code>
            <div class="text-xs text-gray-500 mt-1">
              {{ $t('admin.invites.created', { date: formatDate(invite.createdAt) }) }}
            </div>
          </div>

          <button
            class="button button-sm white"
            @click="copyCode(invite)"
          >
            {{ copiedId === invite.id ? $t('admin.invites.copied') : $t('admin.invites.copy') }}
          </button>
        </div>
      </div>
    </div>

    <div v-else class="py-12 text-center text-sm text-gray-500">
      {{ $t('admin.invites.none') }}
    </div>
  </div>
</template>
