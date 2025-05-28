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

import {
  IconDocumentLine,
  IconPaperclipLine,
  IconDiscussionLine,
  IconAssignmentLine,
  IconQuizLine,
  IconLinkLine,
} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ModuleItemContent} from './types'

const I18n = createI18nScope('context_modules_v2')
const pixelOffset = 20

export const INDENT_LOOKUP: Record<number, string> = {
  0: `${pixelOffset * 0}px`,
  1: `${pixelOffset * 1}px`,
  2: `${pixelOffset * 2}px`,
  3: `${pixelOffset * 3}px`,
  4: `${pixelOffset * 4}px`,
  5: `${pixelOffset * 5}px`,
}

export const getIconColor = (published: boolean | undefined, isStudentView = false) => {
  return published && !isStudentView ? 'success' : 'primary'
}

export const getItemIcon = (content: ModuleItemContent, isStudentView = false) => {
  if (!content?.type) return <IconDocumentLine />

  const type = content.type
  const color = getIconColor(content?.published, isStudentView)

  switch (type) {
    case 'Assignment':
      return content.isNewQuiz ? (
        <IconQuizLine color={color} data-testid="new-quiz-icon" />
      ) : (
        <IconAssignmentLine color={color} data-testid="assignment-icon" />
      )
    case 'Quiz':
      return <IconQuizLine color={color} data-testid="quiz-icon" />
    case 'Discussion':
      return <IconDiscussionLine color={color} data-testid="discussion-icon" />
    case 'File':
    case 'Attachment':
      return <IconPaperclipLine color={color} data-testid="attachment-icon" />
    case 'ExternalUrl':
      return <IconLinkLine color={color} data-testid="url-icon" />
    case 'Page':
      return <IconDocumentLine color={color} data-testid="page-icon" />
    default:
      return <IconDocumentLine color="primary" data-testid="document-icon" />
  }
}

export const getItemTypeText = (content: ModuleItemContent) => {
  if (!content?.type) return I18n.t('Unknown')

  switch (content.type) {
    case 'Assignment':
      return content.isNewQuiz ? I18n.t('New Quiz') : I18n.t('Assignment')
    case 'Quiz':
      return I18n.t('Quiz')
    case 'Discussion':
      return I18n.t('Discussion')
    case 'File':
    case 'Attachment':
      return I18n.t('File')
    case 'ExternalUrl':
      return I18n.t('External Url')
    case 'Page':
      return I18n.t('Page')
    default:
      return I18n.t('Unknown')
  }
}

export const mapContentSelection = (id: string, contentType: string) => {
  // Cast the string to our supported content types
  const type = contentType as
    | 'assignment'
    | 'quiz'
    | 'discussion'
    | 'attachment'
    | 'file'
    | 'external'
    | 'url'
    | 'page'
    | 'link'

  if (type === 'assignment') return {assignments: [id]}
  if (type === 'quiz') return {quizzes: [id]}
  if (type === 'discussion') return {discussions: [id]}
  if (type === 'attachment' || type === 'file') return {files: [id]}
  if (type === 'external' || type === 'url') return {urls: [id]}
  if (type === 'page') return {pages: [id]}
  if (type === 'link') return {links: [id]}

  return {modules: [id]}
}

export const validateModuleStudentRenderRequirements = (prevProps: any, nextProps: any) => {
  return (
    prevProps.id === nextProps.id &&
    prevProps.expanded === nextProps.expanded &&
    prevProps.name === nextProps.name &&
    prevProps.completionRequirements === nextProps.completionRequirements
  )
}

export const validateModuleItemStudentRenderRequirements = (prevProps: any, nextProps: any) => {
  return (
    prevProps.id === nextProps.id &&
    prevProps.url === nextProps.url &&
    prevProps.indent === nextProps.indent &&
    prevProps.index === nextProps.index &&
    prevProps.content === nextProps.content
  )
}
