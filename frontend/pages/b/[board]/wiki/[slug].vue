<script setup lang="ts">
import { useWiki } from '~/composables/useWiki'
import { useContentConverter } from '~/composables/useContentConverter'
import { useGraphQL } from '~/composables/useGraphQL'
import { formatDate as fmtDate } from '~/utils/date'

const route = useRoute()
const boardName = route.params.board as string
const slug = route.params.slug as string
const { t } = useI18n()

const { page, loading, error, fetchPage } = useWiki()
const { toSafeHTML } = useContentConverter()
const boardId = ref<string | null>(null)
const isMod = ref(false)
const notFound = ref(false)

const BOARD_QUERY = `
  query GetBoard($name: String!) {
    board(name: $name) { id }
  }
`

const BOARD_SETTINGS_QUERY = `
  query GetBoardSettings($boardId: ID!) {
    getBoardSettings(boardId: $boardId) {
      moderatorPermissions
    }
  }
`

onMounted(async () => {
  const { execute: execBoard } = useGraphQL<{ board: { id: string } }>()
  const boardResult = await execBoard(BOARD_QUERY, { variables: { name: boardName } })
  if (!boardResult?.board) return

  boardId.value = boardResult.board.id

  const { execute: execSettings } = useGraphQL<{ getBoardSettings: { moderatorPermissions: number | null } }>()
  const settingsResult = await execSettings(BOARD_SETTINGS_QUERY, { variables: { boardId: boardId.value } })
  if (settingsResult?.getBoardSettings?.moderatorPermissions != null) {
    isMod.value = true
  }

  await fetchPage(boardName, slug)
  if (!page.value) {
    notFound.value = true
  }
})

const sanitizedContent = computed(() => {
  if (!page.value) return ''
  const html = page.value.bodyHTML || page.value.body
  return toSafeHTML(html)
})

useHead({ title: computed(() => page.value?.title ?? slug) })
useSeoMeta({
  title: computed(() => `${page.value?.title ?? slug} - ${t('board.wiki.breadcrumbWiki')} | b/${boardName}`),
  ogTitle: computed(() => `${page.value?.title ?? slug} - ${t('board.wiki.breadcrumbWiki')} | b/${boardName}`),
  description: computed(() => t('board.wiki.seoDescription', { board: boardName })),
  ogType: 'article',
})
</script>

<template>
  <div class="max-w-4xl mx-auto px-4 py-4">
    <CommonLoadingSpinner v-if="loading" />

    <div v-else-if="notFound" class="text-center py-12">
      <p class="text-sm text-gray-500 mb-4">{{ $t('board.wiki.pageNotFound') }}</p>
      <NuxtLink :to="`/b/${boardName}/wiki`" class="text-sm text-primary hover:underline">
        {{ $t('board.wiki.backToIndex') }}
      </NuxtLink>
    </div>

    <template v-else-if="page">
      <nav class="text-sm text-gray-500 mb-4">
        <NuxtLink :to="`/b/${boardName}`" class="hover:text-gray-700">b/{{ boardName }}</NuxtLink>
        <span class="mx-1">/</span>
        <NuxtLink :to="`/b/${boardName}/wiki`" class="hover:text-gray-700">{{ $t('board.wiki.breadcrumbWiki') }}</NuxtLink>
        <span class="mx-1">/</span>
        <span>{{ page.title }}</span>
      </nav>

      <div class="flex items-start justify-between mb-6">
        <div>
          <h1 class="text-lg font-semibold text-gray-900">{{ page.title }}</h1>
          <p class="text-xs text-gray-500 mt-1">
            {{ $t('board.wiki.lastEdited', { date: fmtDate(page.updatedAt) }) }}
          </p>
        </div>
        <NuxtLink
          v-if="isMod"
          :to="`/b/${boardName}/wiki/${slug}/edit`"
          class="button white button-sm"
        >
          {{ $t('board.wiki.edit') }}
        </NuxtLink>
      </div>

      <div class="prose prose-sm max-w-none" v-html="sanitizedContent" />
    </template>
  </div>
</template>
