<script setup lang="ts">
import { useNotifications } from '~/composables/useNotifications'

definePageMeta({ middleware: 'guards' })
const { t } = useI18n()
useHead({ title: () => t('inbox.title') })

const {
  notifications,
  loading,
  error,
  page,
  hasMore,
  fetchNotifications,
  markRead,
  markAllRead,
  deleteNotification,
} = useNotifications()

const unreadOnly = ref(false)
const kindFilter = ref<string | null>(null)

const filters = computed(() => [
  { value: null, label: t('inbox.filter.all') },
  { value: 'replies', label: t('inbox.filter.replies') },
  { value: 'mention', label: t('inbox.filter.mentions') },
  { value: 'private_message', label: t('inbox.filter.privateMessage') },
  { value: 'activity', label: t('inbox.filter.activity') },
])

async function refresh (): Promise<void> {
  await fetchNotifications({
    unreadOnly: unreadOnly.value,
    kindFilter: kindFilter.value ?? undefined,
  })
}

async function handleMarkAllRead (): Promise<void> {
  await markAllRead()
}

async function handleMarkRead (id: string): Promise<void> {
  await markRead([id])
}

async function handleDelete (id: string): Promise<void> {
  await deleteNotification(id)
}

async function setFilter (filter: string | null): Promise<void> {
  kindFilter.value = filter
  page.value = 1
  await refresh()
}

async function toggleUnread (): Promise<void> {
  unreadOnly.value = !unreadOnly.value
  page.value = 1
  await refresh()
}

async function nextPage (): Promise<void> {
  if (hasMore.value) {
    page.value++
    await refresh()
  }
}

async function prevPage (): Promise<void> {
  if (page.value > 1) {
    page.value--
    await refresh()
  }
}

await refresh()
</script>

<template>
  <div class="max-w-5xl mx-auto px-4 py-4">
    <!-- Header card -->
    <div class="bg-white rounded-lg border border-gray-200 px-4 py-3 mb-4">
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
        <h1 class="text-lg font-semibold text-gray-900">
          {{ $t('inbox.notifications') }}
        </h1>
        <div class="flex items-center gap-2 flex-wrap">
          <NuxtLink to="/inbox/messages" class="button button-sm white no-underline inline-flex items-center gap-1">
            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
            </svg>
            {{ $t('inbox.messages') }}
          </NuxtLink>
          <button
            class="button button-sm"
            :class="unreadOnly ? 'primary' : 'white'"
            @click="toggleUnread"
          >
            {{ unreadOnly ? $t('inbox.showingUnread') : $t('inbox.unreadOnly') }}
          </button>
          <button class="button button-sm white" @click="handleMarkAllRead">
            {{ $t('inbox.markAllRead') }}
          </button>
        </div>
      </div>
    </div>

    <!-- Filter tabs in a card -->
    <div class="bg-white rounded-lg border border-gray-200 px-3 py-1 mb-4">
      <div class="flex gap-0.5 overflow-x-auto scrollbar-hidden">
        <button
          v-for="filter in filters"
          :key="filter.value ?? 'all'"
          class="px-3 py-2 text-sm font-medium border-b-2 -mb-px transition-colors whitespace-nowrap"
          :class="kindFilter === filter.value
            ? 'border-primary text-primary'
            : 'border-transparent text-gray-500 hover:text-gray-700'"
          @click="setFilter(filter.value)"
        >
          {{ filter.label }}
        </button>
      </div>
    </div>

    <CommonErrorDisplay v-if="error" :message="error.message" @retry="refresh" />
    <CommonLoadingSpinner v-else-if="loading && notifications.length === 0" size="lg" />

    <div v-else-if="notifications.length > 0" class="bg-white border border-gray-200 rounded-lg divide-y divide-gray-100 overflow-hidden">
      <NotificationsNotificationItem
        v-for="notification in notifications"
        :key="notification.id"
        :id="notification.id"
        :type="notification.type"
        :created-at="notification.createdAt"
        :read="notification.isRead"
        :post-id="notification.postId"
        :comment-id="notification.commentId"
        :message-id="notification.messageId"
        :actor="notification.actor"
        :post="notification.post"
        :comment="notification.comment"
        :message="notification.message"
        @mark-read="handleMarkRead"
        @delete="handleDelete"
      />
    </div>
    <div v-else class="bg-white border border-gray-200 rounded-lg py-12 text-center">
      <svg class="w-12 h-12 text-gray-300 mx-auto mb-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
        <path stroke-linecap="round" stroke-linejoin="round" d="M14.857 17.082a23.848 23.848 0 005.454-1.31A8.967 8.967 0 0118 9.75v-.7V9A6 6 0 006 9v.75a8.967 8.967 0 01-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 01-5.714 0m5.714 0a3 3 0 11-5.714 0" />
      </svg>
      <p class="text-sm text-gray-500">
        {{ unreadOnly ? $t('inbox.noNotificationsUnread') : $t('inbox.noNotifications') }}
      </p>
    </div>

    <CommonPagination
      v-if="notifications.length > 0"
      :page="page"
      :has-more="hasMore"
      @prev="prevPage"
      @next="nextPage"
    />
  </div>
</template>
