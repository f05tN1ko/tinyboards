<script setup lang="ts">
import { useGraphQL } from '~/composables/useGraphQL'

const { t, locale } = useI18n()

definePageMeta({ layout: 'admin' })
useHead({ title: () => t('admin.dashboard.title') })

interface SiteStats {
  users: number
  posts: number
  comments: number
  boards: number
  usersActiveDay: number
  usersActiveWeek: number
  usersActiveMonth: number
  usersActiveHalfYear: number
}

interface SiteStatsResponse {
  siteStats: SiteStats
}

const { execute, loading, error, data } = useGraphQL<SiteStatsResponse>()

const STATS_QUERY = `
  query {
    siteStats {
      users
      posts
      comments
      boards
      usersActiveDay
      usersActiveWeek
      usersActiveMonth
      usersActiveHalfYear
    }
  }
`

onMounted(async () => {
  await execute(STATS_QUERY)
})

const stats = computed(() => data.value?.siteStats ?? null)

const overviewCards = computed(() => {
  if (!stats.value) return []
  return [
    { label: t('admin.dashboard.totalUsers'), value: stats.value.users, icon: 'users' },
    { label: t('admin.dashboard.totalPosts'), value: stats.value.posts, icon: 'posts' },
    { label: t('admin.dashboard.totalComments'), value: stats.value.comments, icon: 'comments' },
    { label: t('admin.dashboard.totalBoards'), value: stats.value.boards, icon: 'boards' },
  ]
})

const activityCards = computed(() => {
  if (!stats.value) return []
  return [
    { label: t('admin.dashboard.activeToday'), value: stats.value.usersActiveDay },
    { label: t('admin.dashboard.activeThisWeek'), value: stats.value.usersActiveWeek },
    { label: t('admin.dashboard.activeThisMonth'), value: stats.value.usersActiveMonth },
    { label: t('admin.dashboard.activeHalfYear'), value: stats.value.usersActiveHalfYear },
  ]
})

function formatNumber (n: number): string {
  return n.toLocaleString(locale.value === 'zh-CN' ? 'zh-CN' : 'en-US')
}
</script>

<template>
  <div>
    <h2 class="text-lg font-semibold text-gray-900 mb-6">
      {{ $t('admin.dashboard.heading') }}
    </h2>

    <div v-if="loading" class="text-sm text-gray-500">
      {{ $t('admin.dashboard.loadingStats') }}
    </div>

    <div v-else-if="error" class="rounded-md bg-red-50 p-4 text-sm text-red-700">
      {{ $t('admin.dashboard.loadFailed', { message: error.message }) }}
    </div>

    <template v-else-if="stats">
      <h3 class="text-sm font-medium text-gray-500 uppercase tracking-wide mb-3">
        {{ $t('admin.dashboard.overview') }}
      </h3>
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <div
          v-for="card in overviewCards"
          :key="card.label"
          class="bg-white rounded-lg border border-gray-200 p-5"
        >
          <p class="text-sm font-medium text-gray-500">{{ card.label }}</p>
          <p class="mt-1 text-2xl font-semibold text-gray-900">
            {{ formatNumber(card.value) }}
          </p>
        </div>
      </div>

      <h3 class="text-sm font-medium text-gray-500 uppercase tracking-wide mb-3">
        {{ $t('admin.dashboard.userActivity') }}
      </h3>
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div
          v-for="card in activityCards"
          :key="card.label"
          class="bg-white rounded-lg border border-gray-200 p-5"
        >
          <p class="text-sm font-medium text-gray-500">{{ card.label }}</p>
          <p class="mt-1 text-2xl font-semibold text-gray-900">
            {{ formatNumber(card.value) }}
          </p>
        </div>
      </div>
    </template>
  </div>
</template>
