<script setup lang="ts">
import { useGraphQL, useGraphQLMutation } from '~/composables/useGraphQL'

const { t, locale } = useI18n()

definePageMeta({ layout: 'admin' })
useHead({ title: () => t('admin.removed.commentsTitle') })

interface Comment {
  id: string
  body: string
  creator: { name: string } | null
  post: { title: string }
  createdAt: string
}

interface ListCommentsResponse {
  listComments: Comment[]
}

interface RestoreCommentResponse {
  restoreComment: { id: string }
}

const page = ref(1)
const limit = 20

const { execute, loading, error, data } = useGraphQL<ListCommentsResponse>()
const { execute: executeRestore, loading: restoring } = useGraphQLMutation<RestoreCommentResponse>()

const LIST_REMOVED_COMMENTS = `
  query ListRemovedComments($page: Int, $limit: Int) {
    listComments(removedOnly: true, page: $page, limit: $limit) {
      id
      body
      creator { name }
      post { title }
      createdAt
    }
  }
`

const RESTORE_COMMENT = `
  mutation RestoreComment($commentId: ID!) {
    restoreComment(commentId: $commentId) { id }
  }
`

async function fetchComments () {
  await execute(LIST_REMOVED_COMMENTS, {
    variables: { page: page.value, limit },
  })
}

async function restoreComment (id: string) {
  await executeRestore(RESTORE_COMMENT, { variables: { commentId: id } })
  await fetchComments()
}

onMounted(() => {
  fetchComments()
})

const comments = computed(() => data.value?.listComments ?? [])
</script>

<template>
  <div>
    <h2 class="text-lg font-semibold text-gray-900 mb-4">
      {{ $t('admin.removed.commentsTitle') }}
    </h2>

    <CommonLoadingSpinner v-if="loading" />
    <CommonErrorDisplay v-else-if="error" :message="error.message" />

    <div v-else-if="comments.length === 0" class="text-sm text-gray-500">
      {{ $t('admin.removed.noRemovedComments') }}
    </div>

    <div v-else class="space-y-3">
      <div v-for="comment in comments" :key="comment.id" class="bg-white rounded-lg border border-gray-200 p-4 flex items-start justify-between">
        <div class="flex-1 min-w-0">
          <p class="text-sm text-gray-900 line-clamp-2">{{ comment.body }}</p>
          <p class="text-xs text-gray-500 mt-1">
            {{ $t('admin.removed.byOn', { author: comment.creator?.name ?? $t('common.unknown'), title: comment.post.title }) }}
          </p>
        </div>
        <button class="button button-sm white ml-4 shrink-0" :disabled="restoring" @click="restoreComment(comment.id)">
          {{ $t('admin.removed.restore') }}
        </button>
      </div>

      <CommonPagination :page="page" :has-more="comments.length === limit" @prev="page > 1 && (page--, fetchComments())" @next="page++; fetchComments()" />
    </div>
  </div>
</template>
