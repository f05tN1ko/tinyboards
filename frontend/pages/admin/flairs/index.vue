<script setup lang="ts">
import { useGraphQL, useGraphQLMutation } from '~/composables/useGraphQL'
import { useToast } from '~/composables/useToast'

const { t } = useI18n()

definePageMeta({ layout: 'admin' })
useHead({ title: () => t('admin.flairs.indexTitle') })

const toast = useToast()

interface Board {
  id: string
  name: string
  title: string
}

interface Flair {
  id: string
  templateName: string
  textDisplay: string | null
  textColor: string
  backgroundColor: string
  flairType: string
  usageCount: number
  isModOnly: boolean
  isActive: boolean
}

interface ListBoardsResponse {
  listBoards: Board[]
}

interface ListFlairsResponse {
  listFlairs: Flair[]
}

const { execute: executeBoards, data: boardsData } = useGraphQL<ListBoardsResponse>()
const { execute: executeFlairs, loading, error, data: flairsData } = useGraphQL<ListFlairsResponse>()
const { execute: executeDelete, loading: deleting } = useGraphQLMutation()

const selectedBoardId = ref<string | null>(null)

const BOARDS_QUERY = `
  query { listBoards { id name title } }
`

const FLAIRS_QUERY = `
  query ListFlairs($boardId: ID!) {
    listFlairs(boardId: $boardId) {
      id templateName textDisplay textColor backgroundColor flairType usageCount isModOnly isActive
    }
  }
`

const DELETE_FLAIR = `
  mutation DeleteFlair($flairId: ID!) {
    deleteFlair(flairId: $flairId)
  }
`

const boards = computed(() => boardsData.value?.listBoards ?? [])
const flairs = computed(() => flairsData.value?.listFlairs ?? [])

onMounted(async () => {
  await executeBoards(BOARDS_QUERY)
})

watch(selectedBoardId, async (newId) => {
  if (newId) {
    await executeFlairs(FLAIRS_QUERY, { variables: { boardId: newId } })
  }
})

function selectBoard (id: string) {
  selectedBoardId.value = id
}

async function deleteFlair (id: string) {
  await executeDelete(DELETE_FLAIR, { variables: { flairId: id } })
  if (selectedBoardId.value) {
    await executeFlairs(FLAIRS_QUERY, { variables: { boardId: selectedBoardId.value } })
  }
}
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h2 class="text-lg font-semibold text-gray-900">
        {{ $t('admin.flairs.indexTitle') }}
      </h2>
      <NuxtLink
        v-if="selectedBoardId"
        :to="`/admin/flairs/create?boardId=${selectedBoardId}`"
        class="button primary button-sm"
      >
        {{ $t('admin.flairs.create') }}
      </NuxtLink>
    </div>

    <p class="text-sm text-gray-500 mb-4">
      {{ $t('admin.flairs.description') }}
    </p>

    <div class="mb-6">
      <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('admin.flairs.board') }}</label>
      <select
        class="form-input w-full max-w-sm"
        :value="selectedBoardId ?? ''"
        @change="selectBoard(($event.target as HTMLSelectElement).value)"
      >
        <option value="" disabled>
          {{ $t('admin.flairs.selectBoard') }}
        </option>
        <option v-for="board in boards" :key="board.id" :value="board.id">
          +{{ board.name }} ({{ board.title }})
        </option>
      </select>
    </div>

    <template v-if="selectedBoardId">
      <CommonLoadingSpinner v-if="loading" />
      <CommonErrorDisplay v-else-if="error" :message="error.message" />

      <div v-else-if="flairs.length === 0" class="text-sm text-gray-500">
        {{ $t('admin.flairs.noFlairs') }}
      </div>

      <div v-else class="space-y-3">
        <div
          v-for="flair in flairs"
          :key="flair.id"
          class="bg-white rounded-lg border border-gray-200 p-4 flex items-center justify-between"
        >
          <div class="flex items-center gap-3">
            <span
              class="inline-flex items-center px-2.5 py-0.5 rounded text-xs font-medium"
              :style="{ color: flair.textColor, backgroundColor: flair.backgroundColor }"
            >
              {{ flair.textDisplay || flair.templateName }}
            </span>
            <div>
              <span class="text-sm text-gray-900">{{ flair.templateName }}</span>
              <span class="ml-2 text-xs text-gray-500">
                {{ flair.flairType }} &middot; {{ $t('admin.flairs.uses', { count: flair.usageCount }) }}
              </span>
              <span v-if="flair.isModOnly" class="ml-2 text-xs text-orange-600">
                {{ $t('admin.flairs.modOnly') }}
              </span>
              <span v-if="!flair.isActive" class="ml-2 text-xs text-red-600">
                {{ $t('admin.flairs.inactive') }}
              </span>
            </div>
          </div>
          <div class="flex items-center gap-2 shrink-0">
            <NuxtLink :to="`/admin/flairs/${flair.id}/edit`" class="button button-sm white">
              {{ $t('admin.flairs.edit') }}
            </NuxtLink>
            <button
              class="button button-sm red"
              :disabled="deleting"
              @click="deleteFlair(flair.id)"
            >
              {{ $t('admin.flairs.delete') }}
            </button>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>
