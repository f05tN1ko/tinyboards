<script setup lang="ts">
import { useWiki } from '~/composables/useWiki'
import { useGraphQL } from '~/composables/useGraphQL'
import { formatDate as fmtDate } from '~/utils/date'

const route = useRoute()
const boardName = route.params.board as string
const slug = route.params.slug as string
const { t } = useI18n()

useHead({ title: () => t('board.wiki.revisionsTitle', { slug }) })

const { page, fetchPage, fetchRevisions } = useWiki()
const loading = ref(true)

interface WikiRevision {
  id: string
  body: string
  editSummary: string | null
  revisionNumber: number
  createdAt: string
  creator: { id: string; name: string } | null
}

const revisions = ref<WikiRevision[]>([])

onMounted(async () => {
  await fetchPage(boardName, slug)
  if (!page.value) {
    loading.value = false
    return
  }

  revisions.value = await fetchRevisions(page.value.id)
  loading.value = false
})
</script>

<template>
  <div class="max-w-4xl mx-auto px-4 py-4">
    <nav class="text-sm text-gray-500 mb-4">
      <NuxtLink :to="`/b/${boardName}`" class="hover:text-gray-700">b/{{ boardName }}</NuxtLink>
      <span class="mx-1">/</span>
      <NuxtLink :to="`/b/${boardName}/wiki`" class="hover:text-gray-700">{{ $t('board.wiki.breadcrumbWiki') }}</NuxtLink>
      <span class="mx-1">/</span>
      <NuxtLink :to="`/b/${boardName}/wiki/${slug}`" class="hover:text-gray-700">{{ slug }}</NuxtLink>
      <span class="mx-1">/</span>
      <span>{{ $t('board.wiki.revisions') }}</span>
    </nav>

    <h1 class="text-lg font-semibold text-gray-900 mb-6">{{ $t('board.wiki.revisionHistory') }}</h1>

    <CommonLoadingSpinner v-if="loading" />

    <div v-else-if="revisions.length === 0" class="text-center py-12">
      <p class="text-sm text-gray-500">{{ $t('board.wiki.noRevisions') }}</p>
    </div>

    <div v-else class="space-y-3">
      <div
        v-for="revision in revisions"
        :key="revision.id"
        class="bg-white rounded-lg border border-gray-200 p-4"
      >
        <div class="flex items-start justify-between">
          <div>
            <p class="text-sm font-medium text-gray-900">
              {{ $t('board.wiki.revisionNumber', { n: revision.revisionNumber }) }}
            </p>
            <p v-if="revision.editSummary" class="text-sm text-gray-600 mt-0.5">
              {{ revision.editSummary }}
            </p>
            <p class="text-xs text-gray-500 mt-1">
              <template v-if="revision.creator">
                {{ $t('board.wiki.by') }} {{ revision.creator.name }}
              </template>
              &middot; {{ fmtDate(revision.createdAt) }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
