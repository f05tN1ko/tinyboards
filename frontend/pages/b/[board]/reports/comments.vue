<script setup lang="ts">
import { useGraphQL, useGraphQLMutation } from '~/composables/useGraphQL'

definePageMeta({ middleware: 'guards' })

const route = useRoute()
const boardName = route.params.board as string
const { t } = useI18n()

useHead({ title: t('board.reports.commentsTitle', { board: boardName }) })

interface CommentReportView {
  id: string
  originalCommentText: string
  reason: string
  status: string
  createdAt: string
}

const { execute, loading, error, data } = useGraphQL<{ getCommentReports: CommentReportView[] }>()
const { execute: executeAction, loading: actioning } = useGraphQLMutation()

const statusFilter = ref('pending')
const boardId = ref<string | null>(null)

const BOARD_QUERY = `
  query GetBoard($name: String!) {
    board(name: $name) { id }
  }
`

const COMMENT_REPORTS_QUERY = `
  query GetCommentReports($boardId: ID, $statusFilter: String, $limit: Int, $offset: Int) {
    getCommentReports(boardId: $boardId, statusFilter: $statusFilter, limit: $limit, offset: $offset) {
      id originalCommentText reason status createdAt
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

async function loadReports () {
  if (!boardId.value) return
  await execute(COMMENT_REPORTS_QUERY, {
    variables: { boardId: boardId.value, statusFilter: statusFilter.value, limit: 20, offset: 0 },
  })
}

async function resolveReport (reportId: string) {
  await executeAction(RESOLVE_REPORT, { variables: { reportId, reportType: 'comment' } })
  await loadReports()
}

async function dismissReport (reportId: string) {
  await executeAction(DISMISS_REPORT, { variables: { reportId, reportType: 'comment' } })
  await loadReports()
}

function changeFilter (filter: string) {
  statusFilter.value = filter
  loadReports()
}

function formatDate (dateStr: string): string {
  return new Date(dateStr).toLocaleDateString('en-US', {
    year: 'numeric', month: 'short', day: 'numeric',
    hour: '2-digit', minute: '2-digit',
  })
}

function statusBadgeClass (status: string): string {
  switch (status) {
    case 'pending': return 'bg-yellow-100 text-yellow-800'
    case 'resolved': return 'bg-green-100 text-green-800'
    case 'dismissed': return 'bg-gray-100 text-gray-800'
    default: return 'bg-gray-100 text-gray-800'
  }
}

const filterOptions = computed(() => [
  { value: 'pending', label: t('board.mod.pending') },
  { value: 'resolved', label: t('board.mod.resolvedStatus') },
  { value: 'dismissed', label: t('board.mod.dismissedStatus') },
])

onMounted(async () => {
  const { execute: execBoard } = useGraphQL<{ board: { id: string } }>()
  const result = await execBoard(BOARD_QUERY, { variables: { name: boardName } })
  if (result?.board) {
    boardId.value = result.board.id
    await loadReports()
  }
})

const reports = computed(() => data.value?.getCommentReports ?? [])
</script>

<template>
  <div class="p-4">
    <h2 class="text-base font-semibold text-gray-900 mb-4">
      {{ $t('board.reports.commentsHeading') }}
    </h2>

    <div class="flex gap-2 mb-4">
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

    <CommonLoadingSpinner v-if="loading" />
    <CommonErrorDisplay v-else-if="error" :message="error.message" />

    <div v-else-if="reports.length === 0" class="text-sm text-gray-500">
      {{ $t('board.reports.noCommentReports') }}
    </div>

    <div v-else class="space-y-3">
      <div
        v-for="report in reports"
        :key="report.id"
        class="bg-white rounded-lg border border-gray-200 p-4"
      >
        <div class="flex items-start justify-between">
          <div class="flex-1 min-w-0">
            <p class="text-sm text-gray-900 line-clamp-2">
              {{ report.originalCommentText }}
            </p>
            <p class="mt-1 text-sm text-gray-600">
              {{ $t('board.reports.reason', { reason: report.reason }) }}
            </p>
            <p class="mt-1 text-xs text-gray-500">
              {{ formatDate(report.createdAt) }}
            </p>
          </div>
          <div class="ml-4 flex items-center gap-2 shrink-0">
            <template v-if="report.status === 'pending'">
              <button class="button button-sm primary" :disabled="actioning" @click="resolveReport(report.id)">
                {{ $t('board.reports.resolve') }}
              </button>
              <button class="button button-sm white" :disabled="actioning" @click="dismissReport(report.id)">
                {{ $t('board.reports.dismiss') }}
              </button>
            </template>
            <span
              v-else
              class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium"
              :class="statusBadgeClass(report.status)"
            >
              {{ report.status }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
