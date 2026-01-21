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

import React, {useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {IconButton} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {Pill} from '@instructure/ui-pill'
import {Spinner} from '@instructure/ui-spinner'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconPublishSolid, IconUnpublishedLine, IconMoreLine} from '@instructure/ui-icons'

interface AIExperienceRowProps {
  canManage: boolean
  id: number
  title: string
  workflowState: 'published' | 'unpublished'
  canUnpublish: boolean
  createdAt: string
  submissionStatus?: 'not_started' | 'in_progress' | 'submitted'
  onEdit: (id: number) => void
  onTestConversation: (id: number) => void
  onPublishToggle: (id: number, newState: 'published' | 'unpublished') => void
  onDelete: (id: number) => void
}

const AIExperienceRow: React.FC<AIExperienceRowProps> = ({
  canManage,
  id,
  title,
  workflowState,
  canUnpublish,
  createdAt,
  submissionStatus,
  onEdit,
  onTestConversation,
  onPublishToggle,
  onDelete,
}) => {
  const I18n = useI18nScope('ai_experiences')
  const isPublished = workflowState === 'published'
  const formattedDate = new Date(createdAt).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })

  const [loadingProgress, setLoadingProgress] = useState(false)
  const [fetchedProgressPercentage, setFetchedProgressPercentage] = useState<number | null>(null)

  // Fetch progress data when status is in_progress
  useEffect(() => {
    const fetchProgress = async () => {
      if (submissionStatus !== 'in_progress' || canManage) {
        return
      }

      setLoadingProgress(true)
      try {
        const courseId = ENV.COURSE_ID
        const response = await fetch(
          `/api/v1/courses/${courseId}/ai_experiences/${id}/conversations`,
          {
            headers: {
              Accept: 'application/json',
            },
          },
        )

        if (!response.ok) {
          throw new Error('Failed to fetch progress')
        }

        const data = await response.json()
        console.log('Progress data for experience', id, ':', data.progress)
        const percentage = data.progress?.percentage ?? 0
        setFetchedProgressPercentage(percentage)
      } catch (err) {
        // On error, default to 0%
        setFetchedProgressPercentage(0)
      } finally {
        setLoadingProgress(false)
      }
    }

    fetchProgress()
  }, [submissionStatus, id, canManage])

  const handlePublishToggle = () => {
    // Only allow toggle if published and can unpublish, or if unpublished
    if (isPublished && !canUnpublish) return

    const newState = isPublished ? 'unpublished' : 'published'
    onPublishToggle(id, newState)
  }

  return (
    <View as="div" background="primary" padding="x-small small">
      <Flex justifyItems="space-between" alignItems="center">
        <Flex.Item shouldGrow shouldShrink>
          <View as="div" margin="0 0 0 small">
            <Link
              data-testid="ai-experiences-index-show-link"
              href={`/courses/${ENV.COURSE_ID}/ai_experiences/${id}`}
              isWithinText={false}
              themeOverride={{
                color: 'inherit',
                hoverColor: 'inherit',
                fontWeight: 700,
              }}
              style={{
                fontSize: '1.125rem',
                textDecoration: 'none',
              }}
            >
              {title}
            </Link>
            <View as="div">
              <Text size="small" color="secondary">
                {I18n.t('Created on %{date}', {date: formattedDate})}
              </Text>
            </View>
          </View>
        </Flex.Item>

        {!canManage && submissionStatus && (
          <Flex.Item>
            <View as="div" margin="0 small 0 0">
              {loadingProgress ? (
                <Spinner renderTitle={I18n.t('Loading progress')} size="x-small" />
              ) : (
                <Pill color={submissionStatus === 'in_progress' ? 'success' : undefined}>
                  {submissionStatus === 'not_started' && I18n.t('Not Started')}
                  {submissionStatus === 'in_progress' &&
                    I18n.t('In Progress (%{percentage}%)', {
                      percentage: fetchedProgressPercentage ?? 0,
                    })}
                  {submissionStatus === 'submitted' && I18n.t('Submitted')}
                </Pill>
              )}
            </View>
          </Flex.Item>
        )}

        {canManage && (
          <Flex.Item>
            <Flex alignItems="center" gap="small">
              <Flex.Item>
                <Text size="small" color="secondary">
                  {isPublished ? I18n.t('Published') : I18n.t('Not published')}
                </Text>
              </Flex.Item>
              <Flex.Item>
                {isPublished && !canUnpublish ? (
                  <Tooltip
                    renderTip={I18n.t("Can't unpublish: students have started conversations")}
                    on={['hover', 'focus']}
                  >
                    <IconButton
                      size="small"
                      withBackground={false}
                      withBorder={false}
                      onClick={handlePublishToggle}
                      interaction="disabled"
                      screenReaderLabel={I18n.t('Cannot unpublish - students have conversations')}
                      data-testid="ai-experience-publish-toggle"
                    >
                      <IconPublishSolid color="success" size="x-small" />
                    </IconButton>
                  </Tooltip>
                ) : (
                  <IconButton
                    size="small"
                    withBackground={false}
                    withBorder={false}
                    onClick={handlePublishToggle}
                    screenReaderLabel={
                      isPublished
                        ? I18n.t('Unpublish AI Experience')
                        : I18n.t('Publish AI Experience')
                    }
                    data-testid="ai-experience-publish-toggle"
                  >
                    {isPublished ? (
                      <IconPublishSolid color="success" size="x-small" />
                    ) : (
                      <IconUnpublishedLine color="secondary" size="x-small" />
                    )}
                  </IconButton>
                )}
              </Flex.Item>
              <Flex.Item>
                <Menu
                  trigger={
                    <IconButton
                      size="small"
                      withBackground={false}
                      withBorder={false}
                      screenReaderLabel={I18n.t('AI Experience Options')}
                      data-testid="ai-experience-menu"
                    >
                      <IconMoreLine />
                    </IconButton>
                  }
                >
                  <Menu.Item
                    data-testid="ai-experiences-index-edit-menu-item"
                    onSelect={() => onEdit(id)}
                  >
                    {I18n.t('Edit')}
                  </Menu.Item>
                  <Menu.Item
                    data-testid="ai-experiences-index-test-conversation-menu-item"
                    onSelect={() => onTestConversation(id)}
                  >
                    {I18n.t('Test Conversation')}
                  </Menu.Item>
                  <Menu.Item
                    data-testid="ai-experiences-index-delete-menu-item"
                    onSelect={() => onDelete(id)}
                  >
                    {I18n.t('Delete')}
                  </Menu.Item>
                </Menu>
              </Flex.Item>
            </Flex>
          </Flex.Item>
        )}
      </Flex>
    </View>
  )
}

export default AIExperienceRow
