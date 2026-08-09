<script setup lang="ts">
import { useGraphQL, useGraphQLMutation } from '~/composables/useGraphQL'

const { t, locale } = useI18n()

definePageMeta({ layout: 'admin' })
useHead({ title: () => t('admin.reports.postsTitle') })

interface PostReportView {
  id: string
  postId: string
  originalPostTitle: string
  originalPostBody: string
  reason: string
  status: string
  createdAt: string
}

interface PostReportsResponse {
  getPostReports: PostReportView[]
}

const statusFilter = ref('pending')
const limit = 20
const offset = ref(0)

const { execute, loading, error, data } = useGraphQL<PostReportsResponse>()
const { execute: executeResolve } = useGraphQLMutation()
const { execute: executeDismiss } = useGraphQLMutation()
const { execute: executeRemovePost } = useGraphQLMutation()

const POST_REPORTS_QUERY = `
  query GetPostReports($statusFilter: String, $limit: Int, $offset: Int) {
    getPostReports(statusFilter: $statusFilter, limit: $limit, offset: $offset) {
      id
      postId
      originalPostTitle
      originalPostBody
      reason
      status
      createdAt
    }
  }
`

const RESOLVE_REPORT = `
  mutation ResolveReport($reportId: ID!, $reportType: String!) {
    resolveReport(reportId: $reportId, reportType: $reportType) { success }
  }
`

const DISMISS_REPORT = `
  mutation DismissReport($reportId: ID!, $reportType: String!) {
    dismissReport(reportId: $reportId, reportType: $reportType) { success }
  }
`

const REMOVE_POST = `
  mutation RemovePost($postId: ID!) {
    removePost(postId: $postId) { id }
  }
`

const filterOptions = computed(() => [
  { value: 'pending', label: t('admin.reports.filterOpen') },
  { value: 'resolved', label: t('admin.reports.filterResolved') },
  { value: '', label: t('admin.reports.filterAll') },
])

async function loadReports () {
  await execute(POST_REPORTS_QUERY, {
    variables: { statusFilter: statusFilter.value, limit, offset: offset.value },
  })
}

async function changeFilter (val: string) {
  statusFilter.value = val
  offset.value = 0
  await loadReports()
}

async function handleResolve (reportId: string) {
  await executeResolve(RESOLVE_REPORT, { variables: { reportId, reportType: 'post' } })
  await loadReports()
}

async function handleDismiss (reportId: string) {
  await executeDismiss(DISMISS_REPORT, { variables: { reportId, reportType: 'post' } })
  await loadReports()
}

async function handleRemovePost (postId: string, reportId: string) {
  await executeRemovePost(REMOVE_POST, { variables: { postId } })
  await handleResolve(reportId)
}

async function loadMore () {
  offset.value += limit
  await loadReports()
}

onMounted(() => {
  loadReports()
})

const postReports = computed(() => data.value?.getPostReports ?? [])

function formatDate (dateStr: string): string {
  return new Date(dateStr).toLocaleDateString(locale.value === 'zh-CN' ? 'zh-CN' : 'en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

function statusBadgeClass (status: string): string {
  switch (status) {
    case 'pending': return 'bg-yellow-100 text-yellow-800'
    case 'resolved': return 'bg-green-100 text-green-800'
    default: return 'bg-gray-100 text-gray-800'
  }
}
</script>

<template>
  <div>
    <h2 class="text-lg font-semibold text-gray-900 mb-6">
      {{ $t('admin.reports.postsTitle') }}
    </h2>

    <div class="flex gap-2 mb-6">
      <button
        v-for="filter in filterOptions"
        :key="filter.value"
        class="button button-sm"
        :class="statusFilter === filter.value ? 'primary' : 'white'"
        @click="changeFilter(filter.value)"
      >
        {{ filter.label }}
      </button>
    </div>

    <CommonLoadingSpinner v-if="loading" size="lg" />
    <CommonErrorDisplay v-else-if="error" :message="error.message" @retry="loadReports" />

    <div v-else-if="postReports.length === 0" class="py-12 text-center text-sm text-gray-500">
      {{ $t('admin.reports.noPostReports') }}
    </div>

    <div v-else class="space-y-4">
      <div
        v-for="report in postReports"
        :key="report.id"
        class="bg-white rounded-lg border border-gray-200 p-4"
      >
        <div class="flex items-start justify-between gap-4">
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 mb-1">
              <h3 class="text-sm font-medium text-gray-900 truncate">
                {{ report.originalPostTitle }}
              </h3>
              <span
                class="shrink-0 inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium"
                :class="statusBadgeClass(report.status)"
              >
                {{ report.status }}
              </span>
            </div>
            <p class="text-sm text-gray-600 mb-1">
              <span class="font-medium">{{ $t('admin.reports.reasonLabel') }}:</span> {{ report.reason }}
            </p>
            <p v-if="report.originalPostBody" class="text-xs text-gray-500 line-clamp-2 mb-1">
              {{ report.originalPostBody }}
            </p>
            <p class="text-xs text-gray-400">
              {{ $t('admin.reports.reported', { date: formatDate(report.createdAt) }) }}
            </p>
          </div>

          <div v-if="report.status === 'pending'" class="flex items-center gap-2 shrink-0">
            <button
              class="button button-sm primary"
              @click="handleResolve(report.id)"
            >
              {{ $t('admin.reports.resolve') }}
            </button>
            <button
              class="button button-sm text-red-600 border-red-200 hover:bg-red-50"
              @click="handleRemovePost(report.postId, report.id)"
            >
              {{ $t('admin.reports.removePost') }}
            </button>
            <button
              class="button button-sm white"
              @click="handleDismiss(report.id)"
            >
              {{ $t('admin.reports.dismiss') }}
            </button>
          </div>
        </div>
      </div>

      <div v-if="postReports.length >= limit" class="flex justify-center pt-2">
        <button class="button button-sm white" @click="loadMore">
          {{ $t('admin.reports.loadMore') }}
        </button>
      </div>
    </div>
  </div>
</template>
