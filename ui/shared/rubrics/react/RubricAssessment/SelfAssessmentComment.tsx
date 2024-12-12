/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React from 'react'
import type {Spacing} from '@instructure/emotion'
import {Avatar} from '@instructure/ui-avatar'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {RubricAssessmentData, RubricSubmissionUser} from '@canvas/rubrics/react/types/rubric'

const I18n = createI18nScope('rubrics-assessment-tray')

export const formatTime = (dateString: string): string => {
  const date = new Date(dateString)

  const options: Intl.DateTimeFormatOptions = {
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
  }

  const formatter = new Intl.DateTimeFormat(ENV.LOCALE || 'en', options)

  return formatter.format(date)
}

export const formatDate = (dateString: string): string => {
  const date = new Date(dateString)
  const today = new Date()

  const includeYear = date.getFullYear() !== today.getFullYear()

  const options: Intl.DateTimeFormatOptions = {
    month: 'short',
    day: 'numeric',
  }

  if (includeYear) {
    options.year = 'numeric'
  }

  const formatter = new Intl.DateTimeFormat(ENV.LOCALE || 'en', options)

  return formatter.format(date)
}

export type SelfAssessmentCommentProps = {
  margin?: Spacing
  selfAssessment?: RubricAssessmentData
  submittedAtAlignment?: 'start' | 'end'
  user?: RubricSubmissionUser
}
export const SelfAssessmentComment = ({
  margin = 'small 0 0 0',
  selfAssessment,
  submittedAtAlignment = 'end',
  user,
}: SelfAssessmentCommentProps) => {
  const hasSelfAssessmentComments = (selfAssessment?.comments?.length || 0) > 0

  if (!selfAssessment || !hasSelfAssessmentComments || !user) {
    return null
  }

  const {name: userName = '', avatarUrl} = user

  const getCommentedAtText = () => {
    if (!selfAssessment.updatedAt) {
      return ''
    }

    return I18n.t(', %{dueDate} at %{time}', {
      dueDate: formatDate(selfAssessment.updatedAt),
      time: formatTime(selfAssessment.updatedAt),
    })
  }

  return (
    <Flex margin={margin}>
      <Flex.Item>
        <Avatar size="x-small" src={avatarUrl || ''} name={userName} />
      </Flex.Item>
      <Flex.Item margin="0 0 0 small" shouldGrow={true}>
        <View as="div">
          <Text size="small">{selfAssessment.comments}</Text>
        </View>
        <View as="div" textAlign={submittedAtAlignment} width="100%">
          <Text size="small" data-testid={`self-assessment-comment-${selfAssessment.id}`}>
            {userName}
            {getCommentedAtText()}
          </Text>
        </View>
      </Flex.Item>
    </Flex>
  )
}
