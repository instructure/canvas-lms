/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {SVGIcon} from '@instructure/ui-svg-images'
import {
  IconAssignmentLine,
  IconDiscussionLine,
  IconModuleLine,
  IconQuizLine,
  IconQuizSolid as IconNewQuiz,
  IconAnnouncementLine,
  IconDocumentLine,
} from '@instructure/ui-icons'
import formatMessage from 'format-message'

export const IconBlank = props => {
  return (
    <SVGIcon name="IconBlank" viewBox="0 0 1920 1920" {...props}>
      <g role="presentation" />
    </SVGIcon>
  )
}

export const getIcon = type => {
  switch (type) {
    case 'assignments':
      return IconAssignmentLine
    case 'discussions':
      return IconDiscussionLine
    case 'modules':
      return IconModuleLine
    case 'quizzes':
      return IconQuizLine
    case 'quizzes.next':
      return IconNewQuiz
    case 'announcements':
      return IconAnnouncementLine
    case 'wikiPages':
      return IconDocumentLine
    case 'navigation':
      return IconBlank
    default:
      return IconDocumentLine
  }
}

export const getFriendlyLinkType = type => {
  switch (type) {
    case 'assignments':
      return formatMessage('Assignment')
    case 'discussions':
      return formatMessage('Discussion')
    case 'modules':
      return formatMessage('Module')
    case 'quizzes':
      return formatMessage('Quiz')
    case 'quizzes.next':
      return formatMessage('New Quiz')
    case 'announcements':
      return formatMessage('Announcement')
    case 'wikiPages':
      return formatMessage('Page')
    case 'navigation':
      return formatMessage('Navigation')
    default:
      return ''
  }
}
