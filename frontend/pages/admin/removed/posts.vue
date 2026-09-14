<script setup lang="ts">
import { useGraphQL, useGraphQLMutation } from '~/composables/useGraphQL'

const { t, locale } = useI18n()

definePageMeta({ layout: 'admin' })
useHead({ title: () => t('admin.removed.postsTitle') })

interface Post {
  id: string
  title: string
  creator: { name: string } | null
  createdAt: string
}

interface ListPostsResponse {
  listPosts: Post[]
}

interface RestorePostResponse {
  restorePost: { id: string }
}

const page = ref(1)
const limit = 20

const { execute, loading, error, data } = useGraphQL<ListPostsResponse>()
const { execute: executeRestore, loading: restoring } = useGraphQLMutation<RestorePostResponse>()

const LIST_REMOVED_POSTS = `
  query ListRemovedPosts($page: Int, $limit: Int) {
    listPosts(removedOnly: true, page: $page, limit: $limit) {
      id
      title
      creator { name }
      createdAt
    }
  }
`

const RESTORE_POST = `
  mutation RestorePost($postId: ID!) {
    restorePost(postId: $postId) { id }
  }
`

async function fetchPosts () {
  await execute(LIST_REMOVED_POSTS, {
    variables: { page: page.value, limit },
  })
}

async function restorePost (id: string) {
  await executeRestore(RESTORE_POST, { variables: { postId: id } })
  await fetchPosts()
}

onMounted(() => {
  fetchPosts()
})

const posts = computed(() => data.value?.listPosts ?? [])
</script>

<template>
  <div>
    <h2 class="text-lg font-semibold text-gray-900 mb-4">
      {{ $t('admin.removed.postsTitle') }}
    </h2>

    <CommonLoadingSpinner v-if="loading" />
    <CommonErrorDisplay v-else-if="error" :message="error.message" />

    <div v-else-if="posts.length === 0" class="text-sm text-gray-500">
      {{ $t('admin.removed.noRemovedPosts') }}
    </div>

    <div v-else class="space-y-3">
      <div v-for="post in posts" :key="post.id" class="bg-white rounded-lg border border-gray-200 p-4 flex items-start justify-between">
        <div class="flex-1 min-w-0">
          <h3 class="text-sm font-medium text-gray-900 truncate">{{ post.title }}</h3>
          <p class="text-xs text-gray-500 mt-1">{{ $t('common.by') }} {{ post.creator?.name ?? $t('common.unknown') }}</p>
        </div>
        <button class="button button-sm white ml-4 shrink-0" :disabled="restoring" @click="restorePost(post.id)">
          {{ $t('admin.removed.restore') }}
        </button>
      </div>

      <CommonPagination :page="page" :has-more="posts.length === limit" @prev="page > 1 && (page--, fetchPosts())" @next="page++; fetchPosts()" />
    </div>
  </div>
</template>
