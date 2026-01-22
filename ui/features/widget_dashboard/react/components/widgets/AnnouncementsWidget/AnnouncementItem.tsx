/*
 * Copyright (C) 2025 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React, {useMemo, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Avatar} from '@instructure/ui-avatar'
import {IconButton} from '@instructure/ui-buttons'
import {IconCheckMarkSolid, IconEmptyLine} from '@instructure/ui-icons'
import {Spinner} from '@instructure/ui-spinner'
import {useQueryClient} from '@tanstack/react-query'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import type {Announcement} from '../../../types'
import {useToggleAnnouncementReadState} from '../../../hooks/useToggleAnnouncementReadState'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {FilterOption} from './utils'
import {ANNOUNCEMENTS_PAGINATED_KEY} from '../../../constants'

const I18n = createI18nScope('widget_dashboard')

const truncateText = (text: string, maxLength: number = 80): string => {
  if (!text || text.length <= maxLength) return text
  return text.slice(0, maxLength).trim() + '...'
}

interface TruncatedTextProps {
  children: string
  maxLength?: number
}

const TruncatedText: React.FC<TruncatedTextProps> = ({children, maxLength = 80}) => (
  <Text title={children.length > maxLength ? children : undefined} wrap="break-word" size="x-small">
    {truncateText(children, maxLength)}
  </Text>
)

interface AnnouncementItemProps {
  announcementItem: Announcement
  filter: FilterOption
}

const AnnouncementItem: React.FC<AnnouncementItemProps> = ({announcementItem, filter}) => {
  const toggleReadState = useToggleAnnouncementReadState()
  const [announcement, setAnnouncement] = useState(announcementItem)
  const [isLoading, setIsLoading] = useState(false)
  const queryClient = useQueryClient()

  const handleToggleReadState = async () => {
    setIsLoading(true)
    try {
      const newReadState = !announcement.isRead
      await toggleReadState.mutateAsync({
        discussionTopicId: announcement.id,
        read: newReadState,
      })
      if (filter === 'all') {
        setAnnouncement(prev => ({
          ...prev,
          isRead: !prev.isRead,
        }))
      }
      showFlashAlert({
        message: newReadState
          ? I18n.t('"%{title}" marked as read', {title: announcement.title})
          : I18n.t('"%{title}" marked as unread', {title: announcement.title}),
        type: 'success',
      })
    } catch {
      showFlashAlert({
        message: I18n.t("An error ocurred while changing the announcement's read state"),
        type: 'error',
      })
    } finally {
      setIsLoading(false)
    }
  }

  const decodeHtmlMessage = (html: string): string => {
    const textarea = document.createElement('textarea')
    textarea.innerHTML = html
    return textarea.value
  }

  const decodedMessage = useMemo(
    () => decodeHtmlMessage(announcement.message.replace(/<[^>]*>/g, '')),
    [announcement.message],
  )

  const handleReadMoreClick = (event: any) => {
    event.preventDefault()
    if (!announcement.isRead) {
      queryClient.removeQueries({
        predicate: query => {
          const queryKey = query.queryKey as unknown[]
          return queryKey[0] === ANNOUNCEMENTS_PAGINATED_KEY
        },
      })

      // Also clear persisted cache from sessionStorage
      const keysToRemove: string[] = []
      for (let i = 0; i < sessionStorage.length; i++) {
        const key = sessionStorage.key(i)
        if (key?.includes('announcementsPaginated')) {
          keysToRemove.push(key)
        }
      }
      keysToRemove.forEach(key => sessionStorage.removeItem(key))
    }
    window.location.href = announcement.html_url
  }

  const renderReadUnreadButton = () => {
    const isRead = announcement.isRead

    const label = isLoading
      ? I18n.t('Updating...')
      : isRead
        ? I18n.t('Mark %{title} as unread', {title: announcement.title})
        : I18n.t('Mark %{title} as read', {title: announcement.title})

    const testId = isLoading
      ? `updating-${announcement.id}`
      : `${isRead ? 'mark-unread' : 'mark-read'}-${announcement.id}`

    const content = isLoading ? (
      <Spinner size="x-small" renderTitle={I18n.t('Updating read status')} />
    ) : isRead ? (
      <IconCheckMarkSolid color="success" size="x-small" />
    ) : (
      <IconEmptyLine color="secondary" size="x-small" />
    )

    return (
      <IconButton
        size="small"
        withBackground={false}
        withBorder={false}
        onClick={isLoading ? undefined : handleToggleReadState}
        disabled={isLoading}
        screenReaderLabel={label}
        aria-pressed={isLoading ? undefined : isRead}
        data-testid={testId}
      >
        {content}
      </IconButton>
    )
  }

  return (
    <View
      as="div"
      padding="x-small 0"
      borderWidth="0 0 small 0"
      borderColor="primary"
      width="100%"
      maxWidth="100%"
      data-testid={`announcement-item-${announcement.id}`}
      role="group"
      aria-label={announcement.title}
    >
      <Flex direction="column" gap="xxx-small">
        <Flex.Item overflowY="visible">
          <Flex direction="row" gap="x-small">
            {/* Avatar */}
            <Flex.Item shouldShrink={false}>
              <Avatar
                name={announcement.author?.name || I18n.t('Unknown Author')}
                src={announcement.author?.avatarUrl}
                size="medium"
              />
            </Flex.Item>

            {/* Content Grid */}
            <Flex.Item shouldGrow shouldShrink>
              <Flex direction="column" gap="xxx-small">
                {/* Row 1: Title and read/unread indicator */}
                <Flex.Item shouldShrink overflowX="visible" overflowY="visible">
                  <Flex direction="row" justifyItems="space-between" alignItems="start" gap="small">
                    <Flex.Item shouldGrow shouldShrink>
                      <Text weight="bold" size="small" wrap="normal" color="primary">
                        <TruncatedText maxLength={75}>{announcement.title}</TruncatedText>
                      </Text>
                    </Flex.Item>
                    <Flex.Item shouldShrink={false}>{renderReadUnreadButton()}</Flex.Item>
                  </Flex>
                </Flex.Item>

                {/* Row 2: Author name and posted date */}
                <Flex.Item>
                  <Text
                    size="x-small"
                    color="secondary"
                    wrap="break-word"
                    style={{wordBreak: 'break-all'}}
                  >
                    {announcement.author?.name && (
                      <>
                        {I18n.t('Sent by %{authorName}', {authorName: announcement.author.name})}
                        {' | '}
                      </>
                    )}
                    <FriendlyDatetime
                      dateTime={announcement.posted_at}
                      format={I18n.t('#date.formats.medium')}
                      alwaysUseSpecifiedFormat={true}
                    />
                  </Text>
                </Flex.Item>

                {/* Row 3: Course name */}
                {announcement.course?.name && (
                  <Flex.Item>
                    <Text
                      size="x-small"
                      color="secondary"
                      data-testid={`course-name-${announcement.id}`}
                    >
                      {announcement.course.name}
                    </Text>
                  </Flex.Item>
                )}
              </Flex>
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item overflowX="visible" overflowY="visible">
          {/* Announcement Content */}
          {announcement.message && (
            <View>
              <Text size="x-small">
                <TruncatedText maxLength={120}>{decodedMessage}</TruncatedText>{' '}
              </Text>
            </View>
          )}
        </Flex.Item>
        <Flex.Item overflowX="visible" overflowY="visible">
          <Link href={announcement.html_url} isWithinText={false} onClick={handleReadMoreClick}>
            <Text size="small">{I18n.t('Read more')}</Text>
          </Link>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default AnnouncementItem
