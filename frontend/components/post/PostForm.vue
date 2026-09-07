<script setup lang="ts">
import { ref } from 'vue'

const props = defineProps<{
  boardName?: string
  boardId?: string
  initialTitle?: string
  initialBody?: string
  initialUrl?: string
  submitLabel?: string
}>()

const emit = defineEmits<{
  submit: [data: { title: string; body: string; url: string; file: File | null; altText: string }]
}>()

const { t } = useI18n()

const title = ref(props.initialTitle ?? '')
const body = ref(props.initialBody ?? '')
const url = ref(props.initialUrl ?? '')
const activeTab = ref<'text' | 'link' | 'media'>(props.initialUrl ? 'link' : 'text')
const selectedFile = ref<File | null>(null)
const filePreview = ref<string | null>(null)
const altText = ref('')

function handleFileSelect (event: Event): void {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) return

  selectedFile.value = file

  // Generate preview for images and videos
  if (file.type.startsWith('image/')) {
    const reader = new FileReader()
    reader.onload = () => {
      filePreview.value = reader.result as string
    }
    reader.readAsDataURL(file)
  } else if (file.type.startsWith('video/')) {
    filePreview.value = null // No inline preview for video, just show filename
  } else {
    filePreview.value = null
  }
}

function removeFile (): void {
  selectedFile.value = null
  filePreview.value = null
  altText.value = ''
}

function formatFileSize (bytes: number): string {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

function handleSubmit (): void {
  emit('submit', {
    title: title.value,
    body: body.value,
    url: url.value,
    file: activeTab.value === 'media' ? selectedFile.value : null,
    altText: activeTab.value === 'media' ? altText.value : '',
  })
}

const bodyLabel = computed(() =>
  activeTab.value === 'link' ? t('postForm.descriptionOptional')
    : activeTab.value === 'media' ? t('postForm.captionOptional')
    : t('postForm.body'),
)

const bodyPlaceholder = computed(() =>
  activeTab.value === 'link' ? t('postForm.addDescription')
    : activeTab.value === 'media' ? t('postForm.addCaption')
    : t('postForm.writeYourPost'),
)
</script>

<template>
  <form class="space-y-4" @submit.prevent="handleSubmit">
    <div>
      <label for="post-title" class="block text-sm font-medium text-gray-700 mb-1">{{ $t('postForm.title') }}</label>
      <input
        id="post-title"
        v-model="title"
        type="text"
        class="form-input"
        required
        :placeholder="$t('postForm.titlePlaceholder')"
      >
    </div>

    <!-- Tab selector for post content type -->
    <div class="flex gap-1 border-b border-gray-200">
      <button
        type="button"
        class="px-3 py-1.5 text-sm font-medium border-b-2 transition-colors"
        :class="activeTab === 'text' ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700'"
        @click="activeTab = 'text'"
      >
        {{ $t('postForm.text') }}
      </button>
      <button
        type="button"
        class="px-3 py-1.5 text-sm font-medium border-b-2 transition-colors"
        :class="activeTab === 'media' ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700'"
        @click="activeTab = 'media'"
      >
        {{ $t('postForm.imageVideo') }}
      </button>
      <button
        type="button"
        class="px-3 py-1.5 text-sm font-medium border-b-2 transition-colors"
        :class="activeTab === 'link' ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700'"
        @click="activeTab = 'link'"
      >
        {{ $t('postForm.link') }}
      </button>
    </div>

    <!-- Link URL input -->
    <div v-if="activeTab === 'link'">
      <label for="post-url" class="block text-sm font-medium text-gray-700 mb-1">{{ $t('postForm.url') }}</label>
      <input
        id="post-url"
        v-model="url"
        type="url"
        class="form-input"
        :placeholder="$t('postForm.urlPlaceholder')"
      >
    </div>

    <!-- Media upload -->
    <div v-if="activeTab === 'media'" class="space-y-3">
      <div v-if="!selectedFile" class="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center hover:border-gray-400 transition-colors">
        <div class="text-gray-400 mb-2">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10 mx-auto" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
          </svg>
        </div>
        <label class="button white cursor-pointer">
          {{ $t('postForm.chooseFile') }}
          <input
            type="file"
            class="hidden"
            accept="image/*,video/*"
            @change="handleFileSelect"
          >
        </label>
        <p class="text-xs text-gray-500 mt-2">{{ $t('postForm.mediaHint') }}</p>
      </div>

      <!-- File preview -->
      <div v-else class="border border-gray-200 rounded-lg p-4">
        <div class="flex items-start gap-4">
          <!-- Image preview -->
          <div v-if="filePreview" class="flex-shrink-0">
            <img :src="filePreview" :alt="$t('postForm.preview')" class="h-24 w-24 object-cover rounded-lg border" />
          </div>
          <!-- Video indicator -->
          <div v-else-if="selectedFile.type.startsWith('video/')" class="flex-shrink-0 h-24 w-24 bg-gray-100 rounded-lg border flex items-center justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>

          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-gray-900 truncate">{{ selectedFile.name }}</p>
            <p class="text-xs text-gray-500">{{ formatFileSize(selectedFile.size) }}</p>
            <button type="button" class="text-xs text-red-600 hover:text-red-700 mt-1" @click="removeFile">
              {{ $t('postForm.remove') }}
            </button>
          </div>
        </div>

        <!-- Alt text -->
        <div class="mt-3">
          <label for="alt-text" class="block text-xs font-medium text-gray-600 mb-1">
            {{ $t('postForm.altText') }}
          </label>
          <input
            id="alt-text"
            v-model="altText"
            type="text"
            class="form-input text-sm"
            :placeholder="$t('postForm.altTextPlaceholder')"
          >
        </div>
      </div>
    </div>

    <!-- Body / description -->
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-1">
        {{ bodyLabel }}
      </label>
      <EditorRichTextEditor
        v-model="body"
        :board-id="boardId"
        :placeholder="bodyPlaceholder"
        min-height="150px"
      />
    </div>

    <button type="submit" class="button primary">
      {{ submitLabel ?? $t('postForm.submitFallback') }}
    </button>
  </form>
</template>
