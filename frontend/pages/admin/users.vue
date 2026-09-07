<script setup lang="ts">
import { ref, watch } from 'vue'
import { useGraphQL } from '~/composables/useGraphQL'
import { useToast } from '~/composables/useToast'
import { useAuthStore } from '~/stores/auth'

const { t, locale } = useI18n()

definePageMeta({ layout: 'admin' })
useHead({ title: () => t('admin.users.title') })

interface User {
  id: string
  name: string
  displayName: string
  avatar: string | null
  isBanned: boolean
  isAdmin: boolean
  adminLevel: number
  createdAt: string
  postCount: number
  commentCount: number
}

interface ListUsersResponse {
  listUsers: User[]
}

const toast = useToast()
const authStore = useAuthStore()
const myAdminLevel = authStore.user?.adminLevel ?? 0

const searchTerm = ref('')
const page = ref(1)
const limit = 20

const { execute, data, loading, error } = useGraphQL<ListUsersResponse>()
const { execute: executeMutation, loading: mutationLoading } = useGraphQL()

const LIST_USERS_QUERY = `
  query ListUsers($searchTerm: String, $page: Int, $limit: Int) {
    listUsers(searchTerm: $searchTerm, page: $page, limit: $limit) {
      id
      name
      displayName
      avatar
      isBanned
      isAdmin
      adminLevel
      createdAt
      postCount
      commentCount
    }
  }
`

async function fetchUsers () {
  await execute(LIST_USERS_QUERY, {
    variables: {
      searchTerm: searchTerm.value || null,
      page: page.value,
      limit,
    },
  })
}

async function banUser (user: User) {
  if (!confirm(t('admin.users.confirmBan', { name: user.displayName || user.name }))) return

  const result = await executeMutation(`
    mutation BanUserFromSite($input: BanUserInput!) {
      banUserFromSite(input: $input) { success message }
    }
  `, { variables: { input: { userId: user.id } } })

  if (result) {
    toast.success(t('admin.users.bannedToast', { name: user.name }))
    await fetchUsers()
  }
}

async function unbanUser (user: User) {
  if (!confirm(t('admin.users.confirmUnban', { name: user.displayName || user.name }))) return

  const result = await executeMutation(`
    mutation UnbanUserFromSite($userId: ID!, $reason: String) {
      unbanUserFromSite(userId: $userId, reason: $reason) { success message }
    }
  `, { variables: { userId: user.id } })

  if (result) {
    toast.success(t('admin.users.unbannedToast', { name: user.name }))
    await fetchUsers()
  }
}

function canManage (user: User): boolean {
  if (user.isAdmin && user.adminLevel >= myAdminLevel) return false
  return true
}

async function onSearch () {
  page.value = 1
  await fetchUsers()
}

let searchTimeout: ReturnType<typeof setTimeout> | null = null
function onSearchInput () {
  if (searchTimeout) clearTimeout(searchTimeout)
  searchTimeout = setTimeout(onSearch, 300)
}

watch(page, fetchUsers)

fetchUsers()

function formatDate (dateStr: string): string {
  return new Date(dateStr).toLocaleDateString(locale.value === 'zh-CN' ? 'zh-CN' : 'en-US')
}
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h2 class="text-lg font-semibold text-gray-900">
        {{ $t('admin.users.heading') }}
      </h2>
    </div>

    <div class="mb-4">
      <input
        v-model="searchTerm"
        type="text"
        class="form-input w-full max-w-sm"
        :placeholder="$t('admin.users.searchPlaceholder')"
        @input="onSearchInput"
        @keydown.enter="onSearch"
      >
    </div>

    <CommonLoadingSpinner v-if="loading" size="lg" />

    <CommonErrorDisplay
      v-else-if="error"
      :message="error.message"
      @retry="fetchUsers"
    />

    <div v-else-if="data?.listUsers?.length">
      <div class="overflow-x-auto">
        <table class="w-full text-sm text-left">
          <thead class="text-xs text-gray-500 uppercase border-b">
            <tr>
              <th class="py-3 px-4">{{ $t('admin.users.colUser') }}</th>
              <th class="py-3 px-4">{{ $t('admin.users.colPosts') }}</th>
              <th class="py-3 px-4">{{ $t('admin.users.colComments') }}</th>
              <th class="py-3 px-4">{{ $t('admin.users.colStatus') }}</th>
              <th class="py-3 px-4">{{ $t('admin.users.colJoined') }}</th>
              <th class="py-3 px-4">{{ $t('admin.users.colActions') }}</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="user in data.listUsers"
              :key="user.id"
              class="border-b last:border-0 hover:bg-gray-50"
            >
              <td class="py-3 px-4">
                <div class="flex items-center gap-3">
                  <CommonAvatar
                    :src="user.avatar ?? undefined"
                    :name="user.displayName || user.name"
                    size="sm"
                  />
                  <div>
                    <NuxtLink :to="`/@${user.name}`" class="font-medium text-gray-900 hover:underline">
                      {{ user.displayName || user.name }}
                    </NuxtLink>
                    <div class="text-xs text-gray-500">
                      @{{ user.name }}
                    </div>
                  </div>
                </div>
              </td>
              <td class="py-3 px-4 text-gray-600">
                {{ user.postCount }}
              </td>
              <td class="py-3 px-4 text-gray-600">
                {{ user.commentCount }}
              </td>
              <td class="py-3 px-4">
                <span
                  v-if="user.isBanned"
                  class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-red-100 text-red-800"
                >
                  {{ $t('admin.users.banned') }}
                </span>
                <span
                  v-else-if="user.isAdmin"
                  class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800"
                >
                  {{ $t('admin.users.adminLevel', { level: user.adminLevel }) }}
                </span>
                <span
                  v-else
                  class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800"
                >
                  {{ $t('admin.users.active') }}
                </span>
              </td>
              <td class="py-3 px-4 text-gray-600">
                {{ formatDate(user.createdAt) }}
              </td>
              <td class="py-3 px-4">
                <div v-if="canManage(user)" class="flex items-center gap-2">
                  <button
                    v-if="user.isBanned"
                    class="button button-sm text-green-600 hover:text-green-800 hover:bg-green-50"
                    :disabled="mutationLoading"
                    @click="unbanUser(user)"
                  >
                    {{ $t('admin.users.unban') }}
                  </button>
                  <button
                    v-else
                    class="button button-sm text-red-600 hover:text-red-800 hover:bg-red-50"
                    :disabled="mutationLoading"
                    @click="banUser(user)"
                  >
                    {{ $t('admin.users.ban') }}
                  </button>
                  <NuxtLink
                    :to="`/@${user.name}`"
                    class="button button-sm text-gray-600 hover:text-gray-800 hover:bg-gray-100 no-underline"
                  >
                    {{ $t('admin.users.profile') }}
                  </NuxtLink>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <CommonPagination
        :page="page"
        :has-more="data.listUsers.length >= limit"
        @prev="page--"
        @next="page++"
      />
    </div>

    <div v-else class="py-12 text-center text-sm text-gray-500">
      {{ $t('admin.users.noUsers') }}
    </div>
  </div>
</template>
