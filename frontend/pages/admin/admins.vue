<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useGraphQL } from '~/composables/useGraphQL'
import { useToast } from '~/composables/useToast'

const { t, locale } = useI18n()

definePageMeta({ layout: 'admin' })
const toast = useToast()
useHead({ title: () => t('admin.admins.title') })

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

const page = ref(1)
const limit = 50
const searchTerm = ref('')

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

const SET_ADMIN_LEVEL_MUTATION = `
  mutation SetUserAdminLevel($userId: ID!, $adminLevel: Int!) {
    setUserAdminLevel(userId: $userId, adminLevel: $adminLevel) {
      id
      name
      isAdmin
      adminLevel
    }
  }
`

const REMOVE_ADMIN_MUTATION = `
  mutation SetUserAdminLevel($userId: ID!, $adminLevel: Int!) {
    setUserAdminLevel(userId: $userId, adminLevel: $adminLevel) {
      id
      name
      isAdmin
      adminLevel
    }
  }
`

const adminUsers = computed(() => {
  if (!data.value?.listUsers) return []
  return data.value.listUsers.filter(u => u.isAdmin)
})

const showAddAdmin = ref(false)
const newAdminSearch = ref('')
const selectedUser = ref<User | null>(null)
const selectedLevel = ref(1)
const { execute: executeSearch, data: searchData } = useGraphQL<ListUsersResponse>()

async function searchUsers () {
  if (!newAdminSearch.value.trim()) return
  await executeSearch(LIST_USERS_QUERY, {
    variables: {
      searchTerm: newAdminSearch.value,
      page: 1,
      limit: 10,
    },
  })
}

let searchTimeout: ReturnType<typeof setTimeout> | null = null
function onSearchInput () {
  if (searchTimeout) clearTimeout(searchTimeout)
  searchTimeout = setTimeout(searchUsers, 300)
}

const searchResults = computed(() => {
  if (!searchData.value?.listUsers) return []
  return searchData.value.listUsers.filter(u => !u.isAdmin)
})

async function addAdmin () {
  if (!selectedUser.value) return
  const result = await executeMutation(SET_ADMIN_LEVEL_MUTATION, {
    variables: { userId: selectedUser.value.id, adminLevel: selectedLevel.value },
  })
  if (result) {
    toast.success(t('admin.admins.addedToast', { name: selectedUser.value.displayName || selectedUser.value.name }))
    showAddAdmin.value = false
    selectedUser.value = null
    newAdminSearch.value = ''
    selectedLevel.value = 1
    await fetchUsers()
  }
}

async function removeAdmin (user: User) {
  if (!confirm(t('admin.admins.confirmRemove', { name: user.displayName || user.name }))) return
  const result = await executeMutation(REMOVE_ADMIN_MUTATION, {
    variables: { userId: user.id, adminLevel: 0 },
  })
  if (result) {
    toast.success(t('admin.admins.removedToast', { name: user.displayName || user.name }))
    await fetchUsers()
  }
}

async function changeLevel (user: User, newLevel: number) {
  const result = await executeMutation(SET_ADMIN_LEVEL_MUTATION, {
    variables: { userId: user.id, adminLevel: newLevel },
  })
  if (result) {
    toast.success(t('admin.admins.levelUpdatedToast', { level: newLevel }))
    await fetchUsers()
  }
}

async function fetchUsers () {
  await execute(LIST_USERS_QUERY, {
    variables: {
      page: page.value,
      limit,
    },
  })
}

watch(page, fetchUsers)

fetchUsers()

function formatDate (dateStr: string): string {
  return new Date(dateStr).toLocaleDateString(locale.value === 'zh-CN' ? 'zh-CN' : 'en-US')
}

const levelOptions = computed(() => [
  { value: 1, label: t('admin.admins.level1') },
  { value: 2, label: t('admin.admins.level2') },
  { value: 3, label: t('admin.admins.level3') },
  { value: 4, label: t('admin.admins.level4') },
  { value: 5, label: t('admin.admins.level5') },
  { value: 6, label: t('admin.admins.level6') },
  { value: 7, label: t('admin.admins.level7') },
])
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h2 class="text-lg font-semibold text-gray-900">
        {{ $t('admin.admins.heading') }}
      </h2>
      <button class="button primary button-sm" @click="showAddAdmin = true">
        {{ $t('admin.admins.addAdmin') }}
      </button>
    </div>

    <CommonLoadingSpinner v-if="loading" size="lg" />

    <CommonErrorDisplay
      v-else-if="error"
      :message="error.message"
      @retry="fetchUsers"
    />

    <div v-else-if="adminUsers.length">
      <div class="space-y-3">
        <div
          v-for="user in adminUsers"
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
              <NuxtLink :to="`/@${user.name}`" class="font-medium text-gray-900 hover:underline">
                {{ user.displayName || user.name }}
              </NuxtLink>
              <div class="text-xs text-gray-500">
                @{{ user.name }} &middot; {{ $t('admin.admins.joined') }} {{ formatDate(user.createdAt) }}
              </div>
            </div>
          </div>

          <div class="flex items-center gap-3">
            <span class="text-xs text-gray-500">
              {{ $t('admin.admins.postsAndComments', { posts: user.postCount, comments: user.commentCount }) }}
            </span>

            <select
              :value="user.adminLevel"
              class="form-select text-xs py-1 px-2 rounded border-gray-300"
              :disabled="mutationLoading"
              @change="changeLevel(user, parseInt(($event.target as HTMLSelectElement).value))"
            >
              <option v-for="opt in levelOptions" :key="opt.value" :value="opt.value">
                {{ opt.label }}
              </option>
            </select>

            <button
              class="button button-sm text-red-600 hover:text-red-800 hover:bg-red-50"
              :disabled="mutationLoading"
              @click="removeAdmin(user)"
            >
              {{ $t('admin.admins.remove') }}
            </button>
          </div>
        </div>
      </div>

      <CommonPagination
        :page="page"
        :has-more="(data?.listUsers?.length ?? 0) >= limit"
        @prev="page--"
        @next="page++"
      />
    </div>

    <div v-else class="py-12 text-center text-sm text-gray-500">
      {{ $t('admin.admins.noAdmins') }}
    </div>

    <!-- Add Admin Modal -->
    <div v-if="showAddAdmin" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50" @click.self="showAddAdmin = false">
      <div class="bg-white rounded-lg shadow-xl w-full max-w-md p-6">
        <h3 class="text-lg font-semibold mb-4">{{ $t('admin.admins.addTitle') }}</h3>

        <div class="mb-4">
          <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('admin.admins.searchUser') }}</label>
          <input
            v-model="newAdminSearch"
            type="text"
            class="form-input w-full"
            :placeholder="$t('admin.admins.searchPlaceholder')"
            @input="onSearchInput"
          >
        </div>

        <div v-if="searchResults.length" class="mb-4 max-h-40 overflow-y-auto border rounded">
          <button
            v-for="u in searchResults"
            :key="u.id"
            class="flex items-center gap-2 w-full px-3 py-2 text-left hover:bg-gray-50 text-sm"
            :class="selectedUser?.id === u.id ? 'bg-primary/10' : ''"
            @click="selectedUser = u"
          >
            <CommonAvatar :src="u.avatar ?? undefined" :name="u.name" size="xs" />
            <span>{{ u.displayName || u.name }}</span>
            <span class="text-gray-400">@{{ u.name }}</span>
          </button>
        </div>

        <div v-if="selectedUser" class="mb-4 p-3 bg-gray-50 rounded text-sm">
          {{ $t('admin.admins.selected') }} <strong>{{ selectedUser.displayName || selectedUser.name }}</strong> (@{{ selectedUser.name }})
        </div>

        <div class="mb-4">
          <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('admin.admins.adminLevel') }}</label>
          <select v-model="selectedLevel" class="form-select w-full">
            <option v-for="opt in levelOptions" :key="opt.value" :value="opt.value">
              {{ opt.label }}
            </option>
          </select>
        </div>

        <div class="flex justify-end gap-2">
          <button class="button gray button-sm" @click="showAddAdmin = false">{{ $t('admin.admins.cancel') }}</button>
          <button
            class="button primary button-sm"
            :disabled="!selectedUser || mutationLoading"
            @click="addAdmin"
          >
            {{ $t('admin.admins.grantAdmin') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
