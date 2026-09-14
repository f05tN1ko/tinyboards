<script setup lang="ts">
import { ref, watch } from 'vue'
import { useGraphQL, useGraphQLMutation } from '~/composables/useGraphQL'

const { t, locale } = useI18n()

definePageMeta({ layout: 'admin' })
useHead({ title: () => t('admin.bans.title') })

interface BannedUser {
  id: string
  name: string
  displayName: string
  avatar: string | null
  createdAt: string
  postCount: number
  commentCount: number
}

interface ListBannedResponse {
  listBannedUsers: {
    totalCount: number
    users: BannedUser[]
  }
}

const page = ref(1)
const limit = 20

const { execute, data, loading, error } = useGraphQL<ListBannedResponse>()
const { execute: executeMutation, loading: unbanLoading } = useGraphQLMutation()

const LIST_BANNED_QUERY = `
  query ListBannedUsers($page: Int, $limit: Int) {
    listBannedUsers(page: $page, limit: $limit) {
      totalCount
      users {
        id
        name
        displayName
        avatar
        createdAt
        postCount
        commentCount
      }
    }
  }
`

async function fetchBannedUsers () {
  await execute(LIST_BANNED_QUERY, {
    variables: { page: page.value, limit },
  })
}

async function unbanUser (id: string) {
  await executeMutation(`
    mutation UnbanUserFromSite($userId: ID!, $reason: String) {
      unbanUserFromSite(userId: $userId, reason: $reason) {
        success
        message
      }
    }
  `, { variables: { userId: id } })
  await fetchBannedUsers()
}

watch(page, fetchBannedUsers)

onMounted(() => {
  fetchBannedUsers()
})

function formatDate (dateStr: string): string {
  return new Date(dateStr).toLocaleDateString(locale.value === 'zh-CN' ? 'zh-CN' : 'en-US')
}
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h2 class="text-lg font-semibold text-gray-900">
        {{ $t('admin.bans.heading') }}
      </h2>
      <span
        v-if="data?.listBannedUsers"
        class="text-sm text-gray-500"
      >
        {{ $t('admin.bans.bannedCount', { count: data.listBannedUsers.totalCount }) }}
      </span>
    </div>

    <CommonLoadingSpinner v-if="loading" size="lg" />

    <CommonErrorDisplay
      v-else-if="error"
      :message="error.message"
      @retry="fetchBannedUsers"
    />

    <div v-else-if="data?.listBannedUsers?.users?.length">
      <div class="space-y-3">
        <div
          v-for="user in data.listBannedUsers.users"
          :key="user.id"
          class="flex items-center justify-between p-4 bg-white border rounded-lg"
        >
          <div class="flex items-center gap-3">
            <CommonAvatar
              :src="user.avatar ?? undefined"
              :name="user.displayName || user.name"
              size="sm"
            />
            <div>
              <div class="font-medium text-gray-900">
                {{ user.displayName || user.name }}
              </div>
              <div class="text-xs text-gray-500">
                @{{ user.name }} &middot; {{ $t('common.joined') }} {{ formatDate(user.createdAt) }}
              </div>
            </div>
          </div>

          <div class="flex items-center gap-3">
            <span class="text-xs text-gray-500">
              {{ $t('admin.bans.postsAndComments', { posts: user.postCount, comments: user.commentCount }) }}
            </span>
            <button
              class="button button-sm primary"
              :disabled="unbanLoading"
              @click="unbanUser(user.id)"
            >
              {{ $t('admin.bans.unban') }}
            </button>
          </div>
        </div>
      </div>

      <CommonPagination
        :page="page"
        :has-more="data.listBannedUsers.users.length >= limit"
        @prev="page--"
        @next="page++"
      />
    </div>

    <div v-else class="py-12 text-center text-sm text-gray-500">
      {{ $t('admin.bans.noBannedUsers') }}
    </div>
  </div>
</template>
