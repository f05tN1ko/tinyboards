<script setup lang="ts">
const { t, locale, locales, setLocale } = useI18n()

const open = ref(false)

function toggle () {
  open.value = !open.value
}

function close () {
  open.value = false
}

async function switchLocale (code: string) {
  close()
  if (code !== locale.value) {
    await setLocale(code)
  }
}

// Close on outside click (simple backdrop like the user menu)
</script>

<template>
  <div class="relative">
    <button
      class="flex items-center gap-1.5 px-2.5 py-1.5 text-sm text-white/80 hover:text-white hover:bg-white/10 rounded-lg transition-colors cursor-pointer"
      :aria-label="t('common.language')"
      @click="toggle"
      @keydown.escape="close"
    >
      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      <span class="hidden sm:inline text-xs font-semibold uppercase tracking-wide">{{ locale }}</span>
    </button>

    <div v-if="open" class="fixed inset-0 z-[60]" @click="close" />

    <Transition
      enter-active-class="transition ease-out duration-100"
      enter-from-class="transform opacity-0 scale-95"
      enter-to-class="transform opacity-100 scale-100"
      leave-active-class="transition ease-in duration-75"
      leave-from-class="transform opacity-100 scale-100"
      leave-to-class="transform opacity-0 scale-95"
    >
      <div
        v-if="open"
        class="absolute right-0 mt-1 w-36 bg-white rounded-lg shadow-lg ring-1 ring-black/5 z-[70] py-1"
      >
        <button
          v-for="l in locales"
          :key="l.code"
          class="flex items-center justify-between w-full px-3 py-2 text-sm cursor-pointer transition-colors"
          :class="l.code === locale ? 'text-primary font-semibold bg-primary/5' : 'text-gray-700 hover:bg-gray-100'"
          @click="switchLocale(l.code)"
        >
          <span>{{ l.name }}</span>
          <svg
            v-if="l.code === locale"
            class="w-4 h-4"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
        </button>
      </div>
    </Transition>
  </div>
</template>
