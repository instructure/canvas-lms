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

import React from 'react'
import {
  IconAssignmentLine,
  IconQuizLine,
  IconDiscussionLine,
  IconDocumentLine,
} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('widget_dashboard')

export type AssignmentType = 'assignment' | 'quiz' | 'discussion'

export interface AssignmentData {
  submissionTypes?: string[]
  quiz?: {_id: string; title: string} | null
  discussion?: {_id: string; title: string} | null
}

export function determineItemType(assignment: AssignmentData): AssignmentType {
  if (assignment.quiz) return 'quiz'
  if (assignment.discussion) return 'discussion'
  if (assignment.submissionTypes?.includes('online_quiz')) return 'quiz'
  if (assignment.submissionTypes?.includes('discussion_topic')) return 'discussion'
  return 'assignment'
}

export function getTypeIcon(type: AssignmentType, isMobile: boolean = false) {
  const iconSize = isMobile ? 'x-small' : 'small'
  switch (type) {
    case 'assignment':
      return (
        <IconAssignmentLine
          title={I18n.t('Assignment')}
          size={iconSize}
          data-testid="assignment-icon"
        />
      )
    case 'quiz':
      return <IconQuizLine title={I18n.t('Quiz')} size={iconSize} data-testid="quiz-icon" />
    case 'discussion':
      return (
        <IconDiscussionLine
          title={I18n.t('Discussion')}
          size={iconSize}
          data-testid="discussion-icon"
        />
      )
    default:
      return (
        <IconDocumentLine
          title={I18n.t('Course Work Item')}
          size={iconSize}
          data-testid="document-icon"
        />
      )
  }
}
