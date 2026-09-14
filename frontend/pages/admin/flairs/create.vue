<script setup lang="ts">
import { useGraphQL, useGraphQLMutation } from '~/composables/useGraphQL'

const { t } = useI18n()

definePageMeta({ layout: 'admin' })
useHead({ title: () => t('admin.flairs.createTitle') })

interface Board {
  id: string
  name: string
  title: string
}

interface ListBoardsResponse {
  listBoards: Board[]
}

const { execute: executeBoards, data: boardsData } = useGraphQL<ListBoardsResponse>()
const { execute: executeCreate, loading: creating, error: createError } = useGraphQL()

const route = useRoute()

const selectedBoardId = ref((route.query.boardId as string) || '')
const flairType = ref('Post')
const templateName = ref('')
const textDisplay = ref('')
const textColor = ref('#1f2937')
const backgroundColor = ref('#e5e7eb')

const BOARDS_QUERY = `query { listBoards { id name title } }`

const CREATE_FLAIR = `
  mutation CreateFlair($input: CreateFlairInput!) {
    createFlair(input: $input) { id }
  }
`

const boards = computed(() => boardsData.value?.listBoards ?? [])

onMounted(async () => {
  await executeBoards(BOARDS_QUERY)
})

async function createFlair () {
  await executeCreate(CREATE_FLAIR, {
    variables: {
      input: {
        boardId: selectedBoardId.value,
        flairType: flairType.value,
        templateName: templateName.value,
        textDisplay: textDisplay.value || null,
        textColor: textColor.value,
        backgroundColor: backgroundColor.value,
      },
    },
  })
  await navigateTo('/admin/flairs')
}
</script>

<template>
  <div>
    <h2 class="text-lg font-semibold text-gray-900 mb-6">
      {{ $t('admin.flairs.createTitle') }}
    </h2>

    <form class="space-y-4 max-w-lg" @submit.prevent="createFlair">
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('admin.flairs.board') }}</label>
        <select v-model="selectedBoardId" class="form-input w-full" required>
          <option value="" disabled>
            {{ $t('admin.flairs.selectBoard') }}
          </option>
          <option v-for="board in boards" :key="board.id" :value="board.id">
            +{{ board.name }} ({{ board.title }})
          </option>
        </select>
      </div>

      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('admin.flairs.flairType') }}</label>
        <select v-model="flairType" class="form-input w-full">
          <option value="Post">{{ $t('admin.flairs.postFlair') }}</option>
          <option value="User">{{ $t('admin.flairs.userFlair') }}</option>
        </select>
      </div>

      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('admin.flairs.name') }}</label>
        <input v-model="templateName" type="text" class="form-input w-full" :placeholder="$t('admin.flairs.namePlaceholder')" required />
      </div>

      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('admin.flairs.displayText') }}</label>
        <input v-model="textDisplay" type="text" class="form-input w-full" :placeholder="$t('admin.flairs.displayTextPlaceholder')" />
      </div>

      <div class="flex gap-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('admin.flairs.textColor') }}</label>
          <input v-model="textColor" type="color" class="h-10 w-16 p-1 border border-gray-300 rounded" />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">{{ $t('admin.flairs.backgroundColor') }}</label>
          <input v-model="backgroundColor" type="color" class="h-10 w-16 p-1 border border-gray-300 rounded" />
        </div>
        <div class="flex items-end">
          <span
            class="inline-flex items-center px-2.5 py-1 rounded text-xs font-medium"
            :style="{ color: textColor, backgroundColor }"
          >
            {{ textDisplay || templateName || $t('admin.flairs.preview') }}
          </span>
        </div>
      </div>

      <CommonErrorDisplay v-if="createError" :message="createError.message" />

      <div class="flex gap-3">
        <button
          type="submit"
          class="button primary"
          :disabled="creating || !selectedBoardId || !templateName.trim()"
        >
          {{ creating ? $t('admin.flairs.creating') : $t('admin.flairs.create') }}
        </button>
        <NuxtLink to="/admin/flairs" class="button white">
          {{ $t('admin.flairs.cancel') }}
        </NuxtLink>
      </div>
    </form>
  </div>
</template>
