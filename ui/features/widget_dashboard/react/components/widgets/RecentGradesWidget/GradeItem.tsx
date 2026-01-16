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

import React, {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Pill} from '@instructure/ui-pill'
import {IconButton} from '@instructure/ui-buttons'
import {IconCompleteSolid, IconArrowOpenDownLine, IconArrowOpenUpLine} from '@instructure/ui-icons'
import {Expandable} from '@instructure/ui-expandable'
import CourseCode from '../../shared/CourseCode'
import type {GradeItemProps} from '../../../types'
import {determineItemType, getTypeIcon} from '../../../utils/assignmentUtils'
import {useResponsiveContext} from '../../../hooks/useResponsiveContext'
import {ExpandedGradeView} from './ExpandedGradeView'

const I18n = createI18nScope('widget_dashboard')

const formatTimeAgo = (dateString: string | null): string => {
  if (!dateString) return I18n.t('Not yet graded')

  const date = new Date(dateString)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24))
  const diffHours = Math.floor(diffMs / (1000 * 60 * 60))
  const diffMinutes = Math.floor(diffMs / (1000 * 60))

  if (diffDays > 0) {
    return I18n.t({one: 'Graded 1 day ago', other: 'Graded %{count} days ago'}, {count: diffDays})
  } else if (diffHours > 0) {
    return I18n.t(
      {one: 'Graded 1 hour ago', other: 'Graded %{count} hours ago'},
      {count: diffHours},
    )
  } else if (diffMinutes > 0) {
    return I18n.t(
      {one: 'Graded 1 minute ago', other: 'Graded %{count} minutes ago'},
      {count: diffMinutes},
    )
  } else {
    return I18n.t('Graded just now')
  }
}

export const GradeItem: React.FC<GradeItemProps> = ({submission}) => {
  const {isMobile} = useResponsiveContext()
  const [isExpanded, setIsExpanded] = useState(false)
  const isGraded = submission.gradedAt !== null
  const timeAgoText = formatTimeAgo(submission.gradedAt)
  const itemType = determineItemType(submission.assignment)

  const handleToggleExpand = () => {
    setIsExpanded(!isExpanded)
  }

  const assignmentTitle = (
    <Text size="medium" weight="bold" data-testid={`assignment-title-${submission._id}`}>
      {submission.assignment.name}
    </Text>
  )

  const courseCode = (
    <CourseCode
      courseId={submission.assignment.course._id}
      overrideCode={submission.assignment.course.courseCode}
      size="x-small"
    />
  )

  const timestamp = (
    <Text size="small" color="secondary" data-testid={`grade-timestamp-${submission._id}`}>
      {timeAgoText}
    </Text>
  )

  const statusPill = (
    <Pill
      color={isGraded ? 'success' : 'primary'}
      data-testid={`grade-status-badge-${submission._id}`}
      renderIcon={isGraded ? <IconCompleteSolid /> : undefined}
    >
      {isGraded ? I18n.t('Graded') : I18n.t('Not graded')}
    </Pill>
  )

  const expandButton = isGraded ? (
    <IconButton
      screenReaderLabel={
        isExpanded ? I18n.t('Collapse grade details') : I18n.t('Expand grade details')
      }
      size="small"
      withBackground={false}
      withBorder={false}
      onClick={handleToggleExpand}
      data-testid={`expand-grade-${submission._id}`}
    >
      {isExpanded ? <IconArrowOpenUpLine /> : <IconArrowOpenDownLine />}
    </IconButton>
  ) : null

  if (isMobile) {
    return (
      <View as="div" padding="small 0" data-testid={`grade-item-${submission._id}`}>
        <Flex direction="column" gap="x-small">
          <Flex.Item>{assignmentTitle}</Flex.Item>
          <Flex.Item>{courseCode}</Flex.Item>
          <Flex.Item>{timestamp}</Flex.Item>
          <Flex.Item>
            <Flex direction="row" gap="x-small" alignItems="center">
              <Flex.Item>{statusPill}</Flex.Item>
              {expandButton && <Flex.Item>{expandButton}</Flex.Item>}
            </Flex>
          </Flex.Item>
          {isExpanded && (
            <Flex.Item>
              <Expandable expanded={isExpanded} onToggle={handleToggleExpand}>
                {({expanded}) => (
                  <div>{expanded && <ExpandedGradeView submission={submission} />}</div>
                )}
              </Expandable>
            </Flex.Item>
          )}
        </Flex>
      </View>
    )
  }

  return (
    <View as="div" data-testid={`grade-item-${submission._id}`}>
      <Flex direction="column" gap="x-small">
        <Flex.Item padding="small">
          <Flex gap="small" alignItems="center">
            <Flex.Item>
              <View as="div" background="secondary" borderRadius="medium" padding="small">
                {getTypeIcon(itemType, isMobile)}
              </View>
            </Flex.Item>

            <Flex.Item shouldGrow shouldShrink>
              <Flex direction="column">
                <Flex.Item>{assignmentTitle}</Flex.Item>
                <Flex.Item>
                  <Flex direction="row" gap="x-small" alignItems="center" wrap="wrap">
                    <Flex.Item>{courseCode}</Flex.Item>
                    <Flex.Item>{timestamp}</Flex.Item>
                  </Flex>
                </Flex.Item>
              </Flex>
            </Flex.Item>

            <Flex.Item align="center">
              <Flex direction="row" gap="x-small" alignItems="center">
                <Flex.Item>{statusPill}</Flex.Item>
                {expandButton && <Flex.Item>{expandButton}</Flex.Item>}
              </Flex>
            </Flex.Item>
          </Flex>
        </Flex.Item>

        {isExpanded && (
          <Flex.Item>
            <Expandable expanded={isExpanded} onToggle={handleToggleExpand}>
              {({expanded}) => (
                <div>{expanded && <ExpandedGradeView submission={submission} />}</div>
              )}
            </Expandable>
          </Flex.Item>
        )}
      </Flex>
    </View>
  )
}
