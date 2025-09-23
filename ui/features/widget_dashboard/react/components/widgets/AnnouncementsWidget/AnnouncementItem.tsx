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
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import type {Announcement} from '../../../types'
import {useToggleAnnouncementReadState} from '../../../hooks/useToggleAnnouncementReadState'
import {CourseCode} from '../../shared/CourseCode'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {FilterOption} from './utils'

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
  <span title={children.length > maxLength ? children : undefined}>
    {truncateText(children, maxLength)}
  </span>
)

interface AnnouncementItemProps {
  announcementItem: Announcement
  filter: FilterOption
}

const AnnouncementItem: React.FC<AnnouncementItemProps> = ({announcementItem, filter}) => {
  const toggleReadState = useToggleAnnouncementReadState()
  const [announcement, setAnnouncement] = useState(announcementItem)
  const [isLoading, setIsLoading] = useState(false)

  const handleToggleReadState = async () => {
    setIsLoading(true)
    try {
      await toggleReadState.mutateAsync({
        discussionTopicId: announcement.id,
        read: !announcement.isRead,
      })
      if (filter === 'all') {
        // No need to set isLoading to false on `finally` or `success` as the item will
        // be removed from the list, unless filtering by all
        setAnnouncement(prev => ({
          ...prev,
          isRead: !prev.isRead,
        }))
        setIsLoading(false)
      }
    } catch (error) {
      showFlashAlert({
        message: I18n.t("An error ocurred while changing the announcement's read state"),
        type: 'error',
      })
      setIsLoading(false)
      console.error('Failed to toggle read state:', error)
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

  const renderReadUnreadButton = () => {
    const isRead = announcement.isRead

    const label = isLoading
      ? I18n.t('Updating...')
      : isRead
        ? I18n.t('Mark as unread')
        : I18n.t('Mark as read')

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
        data-testid={testId}
      >
        {content}
      </IconButton>
    )
  }

  return (
    <View
      as="div"
      padding="x-small"
      borderWidth="0 0 small 0"
      borderColor="primary"
      width="100%"
      maxWidth="100%"
      data-testid={`announcement-item-${announcement.id}`}
    >
      <Flex direction="column" gap="xxx-small">
        <Flex.Item overflowY="visible">
          <Flex direction="row" gap="x-small">
            {/* Avatar */}
            <Flex.Item shouldShrink>
              <Avatar
                name={announcement.author?.name || I18n.t('Unknown Author')}
                src={announcement.author?.avatarUrl}
                size="x-small"
              />
            </Flex.Item>

            {/* Content Grid */}
            <Flex.Item shouldGrow shouldShrink>
              <Flex direction="column" gap="xxx-small">
                {/* Row 1: Title and read/unread indicator */}
                <Flex.Item shouldShrink overflowX="visible" overflowY="visible">
                  <Flex direction="row" justifyItems="space-between" alignItems="start" gap="small">
                    <Flex.Item shouldGrow shouldShrink>
                      <Link href={announcement.html_url} isWithinText={false}>
                        <Text weight="bold" size="small" wrap="normal" color="primary">
                          <TruncatedText maxLength={25}>{announcement.title}</TruncatedText>
                        </Text>
                      </Link>
                    </Flex.Item>
                    <Flex.Item shouldShrink={false}>{renderReadUnreadButton()}</Flex.Item>
                  </Flex>
                </Flex.Item>

                {/* Row 2: Course code */}
                {announcement.course?.courseCode && (
                  <Flex.Item>
                    <CourseCode
                      courseId={announcement.course.id}
                      overrideCode={announcement.course.courseCode}
                      size="x-small"
                    />
                  </Flex.Item>
                )}

                {/* Row 3: Posted date */}
                <Flex.Item>
                  <Text size="x-small" color="secondary">
                    <FriendlyDatetime
                      dateTime={announcement.posted_at}
                      format={I18n.t('#date.formats.medium')}
                      alwaysUseSpecifiedFormat={true}
                    />
                  </Text>
                </Flex.Item>
              </Flex>
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item overflowX="visible" overflowY="visible">
          {/* Announcement Content */}
          {announcement.message && (
            <View padding="0 0 0 xxx-small">
              <Text size="x-small">
                <TruncatedText maxLength={60}>{decodedMessage}</TruncatedText>{' '}
                <Link href={announcement.html_url} isWithinText={false}>
                  <Text size="x-small" color="brand">
                    {I18n.t('Read more')}
                  </Text>
                </Link>
              </Text>
            </View>
          )}
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default AnnouncementItem
