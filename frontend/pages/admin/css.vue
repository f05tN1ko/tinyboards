<script setup lang="ts">
import { useGraphQL, useGraphQLMutation } from '~/composables/useGraphQL'
import { useToast } from '~/composables/useToast'
import { validateCss, CSS_SNIPPET_CATEGORIES } from '~/utils/css-validator'
import type { CssSnippet } from '~/utils/css-validator'

const { t } = useI18n()

definePageMeta({ layout: 'admin' })
useHead({ title: () => t('admin.css.title') })

const toast = useToast()

const SITE_CSS_QUERY = `
  query GetSiteCss {
    site {
      customCss
      customCssEnabled
    }
  }
`

const UPDATE_CSS_MUTATION = `
  mutation UpdateSiteCSS($input: UpdateSiteConfigInput!) {
    updateSiteConfig(input: $input) {
      customCss
      customCssEnabled
    }
  }
`

const { execute, loading } = useGraphQL<{ site: { customCss: string | null; customCssEnabled: boolean } }>()
const { execute: executeMutation, loading: saving } = useGraphQLMutation()

const cssCode = ref('')
const cssEnabled = ref(false)
const activeTab = ref<'editor' | 'wizard' | 'preview'>('wizard')
const expandedCategory = ref<string | null>(null)
const previewCss = ref('')
const showPreview = ref(false)

const validation = computed(() => validateCss(cssCode.value))
const charCount = computed(() => new Blob([cssCode.value]).size)
const maxBytes = 50 * 1024

onMounted(async () => {
  const result = await execute(SITE_CSS_QUERY)
  if (result?.site) {
    cssCode.value = result.site.customCss ?? ''
    cssEnabled.value = result.site.customCssEnabled
  }
})

function insertSnippet (snippet: CssSnippet) {
  if (cssCode.value && !cssCode.value.endsWith('\n')) {
    cssCode.value += '\n'
  }
  cssCode.value += `\n/* ${snippet.name} */\n${snippet.css}\n`
  activeTab.value = 'editor'
  toast.success(t('admin.css.insertedToast', { name: snippet.name }))
}

function toggleCategory (name: string) {
  expandedCategory.value = expandedCategory.value === name ? null : name
}

function updatePreview () {
  previewCss.value = cssCode.value
  showPreview.value = true
  activeTab.value = 'preview'
}

function clearCss () {
  cssCode.value = ''
  toast.info(t('admin.css.clearedToast'))
}

async function saveCss () {
  if (!validation.value.valid) {
    toast.error(t('admin.css.saveError'))
    return
  }

  const result = await executeMutation(UPDATE_CSS_MUTATION, {
    variables: {
      input: {
        customCss: cssCode.value || '',
        customCssEnabled: cssEnabled.value,
      },
    },
  })

  if (result) {
    toast.success(t('admin.css.saveSuccess'))
    const siteStore = useSiteStore()
    if (siteStore.site) {
      siteStore.site.customCss = cssCode.value || null
      siteStore.site.customCssEnabled = cssEnabled.value
    }
  }
}

const tabs = computed(() => [
  { id: 'wizard', label: t('admin.css.tabWizard') },
  { id: 'editor', label: t('admin.css.tabEditor') },
  { id: 'preview', label: t('admin.css.tabPreview') },
] as const)

function getCategoryIcon (icon: string): string {
  const icons: Record<string, string> = {
    'rectangle-stack': '\u25A1',
    'font': 'Aa',
    'palette': '\u25CE',
    'layout': '\u2B1C',
    'cursor-click': '\u25B6',
    'chat-bubble': '\u25AC',
    'sparkles': '\u2728',
    'moon': '\u25D0',
  }
  return icons[icon] || '\u2022'
}
</script>

<template>
  <div class="max-w-5xl">
    <!-- Header -->
    <div class="flex items-center justify-between mb-6">
      <div>
        <h2 class="text-lg font-semibold text-gray-900">
          {{ $t('admin.css.heading') }}
        </h2>
        <p class="text-sm text-gray-500 mt-1">
          {{ $t('admin.css.description') }}
        </p>
      </div>

      <!-- Enable toggle -->
      <label class="flex items-center gap-3 cursor-pointer select-none">
        <span class="text-sm font-medium" :class="cssEnabled ? 'text-green-700' : 'text-gray-500'">
          {{ cssEnabled ? $t('admin.css.enabled') : $t('admin.css.disabled') }}
        </span>
        <button
          type="button"
          role="switch"
          :aria-checked="cssEnabled"
          :class="cssEnabled ? 'bg-green-500' : 'bg-gray-300'"
          class="relative inline-flex h-6 w-11 shrink-0 rounded-full transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2"
          @click="cssEnabled = !cssEnabled"
        >
          <span
            :class="cssEnabled ? 'translate-x-5' : 'translate-x-0'"
            class="pointer-events-none inline-block h-5 w-5 translate-y-0.5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ml-0.5"
          />
        </button>
      </label>
    </div>

    <CommonLoadingSpinner v-if="loading" size="lg" />

    <template v-else>
      <!-- Safety notice -->
      <div class="rounded-lg bg-blue-50 border border-blue-200 p-4 mb-6">
        <div class="flex gap-3">
          <div class="text-blue-500 text-lg shrink-0">&#9432;</div>
          <div class="text-sm text-blue-800">
            <p class="font-medium mb-1">{{ $t('admin.css.safetyInfo') }}</p>
            <ul class="list-disc ml-4 space-y-0.5 text-blue-700">
              <li>{{ $t('admin.css.safety1') }}</li>
              <li>
                <code class="text-xs bg-blue-100 rounded px-1">@import</code>,
                <code class="text-xs bg-blue-100 rounded px-1">url()</code>,
                <code class="text-xs bg-blue-100 rounded px-1">expression()</code>,
                <code class="text-xs bg-blue-100 rounded px-1">position: fixed</code>
                — {{ $t('admin.css.safety2') }}
              </li>
              <li>{{ $t('admin.css.safety3') }}</li>
              <li>{{ $t('admin.css.safety4') }}</li>
            </ul>
          </div>
        </div>
      </div>

      <!-- Tabs -->
      <div class="flex gap-1 border-b border-gray-200 mb-4">
        <button
          v-for="tab in tabs"
          :key="tab.id"
          :class="activeTab === tab.id
            ? 'border-primary text-primary'
            : 'border-transparent text-gray-500 hover:text-gray-700'"
          class="px-4 py-2 text-sm font-medium border-b-2 transition-colors"
          @click="activeTab = tab.id"
        >
          {{ tab.label }}
        </button>
      </div>

      <!-- WIZARD TAB -->
      <div v-if="activeTab === 'wizard'" class="space-y-3">
        <p class="text-sm text-gray-600 mb-4">
          {{ $t('admin.css.wizardHint') }}
        </p>

        <div
          v-for="category in CSS_SNIPPET_CATEGORIES"
          :key="category.name"
          class="border border-gray-200 rounded-lg overflow-hidden"
        >
          <button
            class="w-full flex items-center gap-3 px-4 py-3 text-left hover:bg-gray-50 transition-colors"
            @click="toggleCategory(category.name)"
          >
            <span class="text-lg w-6 text-center opacity-70">{{ getCategoryIcon(category.icon) }}</span>
            <span class="font-medium text-sm text-gray-900 flex-1">{{ category.name }}</span>
            <span class="text-xs text-gray-400">{{ $t('admin.css.snippets', { count: category.snippets.length }) }}</span>
            <span
              class="text-gray-400 transition-transform duration-200"
              :class="expandedCategory === category.name ? 'rotate-90' : ''"
            >&#9656;</span>
          </button>

          <div v-if="expandedCategory === category.name" class="border-t border-gray-100 divide-y divide-gray-100">
            <div
              v-for="snippet in category.snippets"
              :key="snippet.name"
              class="p-4 hover:bg-gray-50 transition-colors"
            >
              <div class="flex items-start justify-between gap-4">
                <div class="flex-1 min-w-0">
                  <div class="font-medium text-sm text-gray-900">{{ snippet.name }}</div>
                  <div class="text-xs text-gray-500 mt-0.5">{{ snippet.description }}</div>
                  <pre class="mt-2 text-xs bg-gray-900 text-green-400 rounded-md p-3 overflow-x-auto font-mono leading-relaxed"><code>{{ snippet.css }}</code></pre>
                </div>
                <button
                  class="shrink-0 button primary button-sm"
                  @click="insertSnippet(snippet)"
                >
                  {{ $t('admin.css.insert') }}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- EDITOR TAB -->
      <div v-if="activeTab === 'editor'" class="space-y-4">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2">
            <button class="button white button-sm" @click="updatePreview">
              {{ $t('admin.css.previewBtn') }}
            </button>
            <button class="button white button-sm text-red-600" :disabled="!cssCode" @click="clearCss">
              {{ $t('admin.css.clearAll') }}
            </button>
          </div>
          <div class="text-xs text-gray-400">
            {{ (charCount / 1024).toFixed(1) }} KB / {{ maxBytes / 1024 }} KB
          </div>
        </div>

        <div class="relative">
          <textarea
            v-model="cssCode"
            class="w-full h-96 font-mono text-sm bg-gray-900 text-green-400 rounded-lg p-4 border border-gray-700 focus:border-primary focus:ring-1 focus:ring-primary resize-y leading-relaxed"
            spellcheck="false"
            autocomplete="off"
            autocorrect="off"
            autocapitalize="off"
          />
          <div class="absolute bottom-3 right-3 text-xs text-gray-500 bg-gray-800 rounded px-2 py-1">
            {{ $t('admin.css.lines', { count: cssCode.split('\n').length }) }}
          </div>
        </div>

        <div v-if="cssCode && !validation.valid" class="rounded-lg bg-red-50 border border-red-200 p-3">
          <div class="text-sm font-medium text-red-800 mb-1">{{ $t('admin.css.validationErrors') }}</div>
          <ul class="list-disc ml-4 text-sm text-red-700 space-y-0.5">
            <li v-for="(err, i) in validation.errors" :key="i">{{ err }}</li>
          </ul>
        </div>

        <div v-if="cssCode && validation.warnings.length > 0" class="rounded-lg bg-yellow-50 border border-yellow-200 p-3">
          <div class="text-sm font-medium text-yellow-800 mb-1">{{ $t('admin.css.warnings') }}</div>
          <ul class="list-disc ml-4 text-sm text-yellow-700 space-y-0.5">
            <li v-for="(warn, i) in validation.warnings" :key="i">{{ warn }}</li>
          </ul>
        </div>

        <div v-if="cssCode && validation.valid && validation.warnings.length === 0" class="flex items-center gap-2 text-sm text-green-700">
          <span>&#10003;</span> {{ $t('admin.css.valid') }}
        </div>
      </div>

      <!-- PREVIEW TAB -->
      <div v-if="activeTab === 'preview'" class="space-y-4">
        <div class="flex items-center justify-between">
          <p class="text-sm text-gray-500">
            {{ $t('admin.css.previewHint') }}
          </p>
          <button class="button white button-sm" @click="updatePreview">
            {{ $t('admin.css.refreshPreview') }}
          </button>
        </div>

        <div class="border border-gray-200 rounded-lg overflow-hidden">
          <div class="px-4 py-3 bg-primary text-white text-sm font-medium flex items-center gap-2 preview-header">
            <span class="w-6 h-6 rounded bg-white/20" />
            <span>{{ $t('admin.css.headerPreview') }}</span>
            <span class="ml-auto flex gap-2">
              <span class="text-xs opacity-70">{{ $t('nav.home') }}</span>
              <span class="text-xs opacity-70">{{ $t('nav.boards') }}</span>
              <span class="text-xs opacity-70">{{ $t('nav.search') }}</span>
            </span>
          </div>

          <div class="p-4 bg-gray-100 preview-body" style="min-height: 300px">
            <div class="max-w-2xl mx-auto space-y-3">
              <div class="post-card bg-white rounded-lg border border-gray-200 p-4">
                <div class="flex gap-3">
                  <div class="flex flex-col items-center gap-1">
                    <button class="vote-button text-gray-400 hover:text-primary text-lg">&#9650;</button>
                    <span class="text-sm font-medium text-gray-700">42</span>
                    <button class="vote-button text-gray-400 hover:text-red-500 text-lg">&#9660;</button>
                  </div>
                  <div class="flex-1">
                    <div class="post-title text-base font-semibold text-gray-900">{{ $t('admin.css.mockPostTitle') }}</div>
                    <div class="text-xs text-gray-500 mt-1">{{ $t('common.by') }} <span class="text-primary">{{ $t('admin.css.mockAuthor') }}</span> {{ $t('nav.boards') }} <span class="font-medium">b/general</span> &middot; 2h</div>
                    <div class="post-body text-sm text-gray-700 mt-2">{{ $t('admin.css.description') }}</div>
                  </div>
                </div>
              </div>

              <div class="bg-white rounded-lg border border-gray-200 p-4">
                <div class="text-xs text-gray-500 mb-2">{{ $t('common.comments') }}</div>
                <div class="comment-body text-sm text-gray-700 pl-3 border-l-2 border-primary/30 comment-thread-line">
                  <div class="text-xs text-gray-500 mb-1"><span class="text-primary font-medium">{{ $t('admin.css.mockCommenter') }}</span> &middot; 1h</div>
                  {{ $t('admin.css.description') }}
                </div>
              </div>
            </div>
          </div>
        </div>

        <Teleport to="head">
          <component :is="'style'" v-if="showPreview" id="tb-css-preview">
            {{ previewCss }}
          </component>
        </Teleport>
      </div>

      <!-- SAVE BAR -->
      <div class="flex items-center justify-between pt-6 mt-6 border-t border-gray-200">
        <div class="text-sm text-gray-500">
          <template v-if="cssEnabled && cssCode">
            {{ $t('admin.css.saveBarActive') }}
          </template>
          <template v-else-if="!cssEnabled && cssCode">
            {{ $t('admin.css.saveBarDisabled') }}
          </template>
          <template v-else>
            {{ $t('admin.css.saveBarEmpty') }}
          </template>
        </div>
        <button
          class="button primary"
          :disabled="saving || (!validation.valid && !!cssCode)"
          @click="saveCss"
        >
          {{ saving ? $t('common.saving') : $t('admin.css.save') }}
        </button>
      </div>

      <!-- HELP / CASCADE EXPLANATION -->
      <div class="mt-8 rounded-lg bg-gray-50 border border-gray-200 p-5">
        <h3 class="text-sm font-semibold text-gray-900 mb-3">{{ $t('admin.css.cascadeTitle') }}</h3>
        <div class="text-sm text-gray-600 space-y-2">
          <p>{{ $t('admin.css.cascadeIntro') }}</p>
          <ol class="list-decimal ml-5 space-y-1">
            <li><strong>{{ $t('admin.css.cascade1') }}</strong></li>
            <li><strong>{{ $t('admin.css.cascade2') }}</strong></li>
            <li><strong>{{ $t('admin.css.cascade3') }}</strong></li>
          </ol>
          <p class="text-gray-500 mt-3">
            {{ $t('admin.css.cascadeNote') }}
          </p>
        </div>
      </div>
    </template>
  </div>
</template>
