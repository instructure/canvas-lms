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
  IconAttachMediaLine,
  IconDiscussionLine,
  IconAssignmentLine,
  IconQuizLine,
  IconLinkLine,
} from '@instructure/ui-icons'
import {ModuleItemContent} from './types'

const pixelOffset = 20

export const INDENT_LOOKUP: Record<number, string> = {
  0: `${pixelOffset * 0}px`,
  1: `${pixelOffset * 1}px`,
  2: `${pixelOffset * 2}px`,
  3: `${pixelOffset * 3}px`,
  4: `${pixelOffset * 4}px`,
  5: `${pixelOffset * 5}px`,
}

export const getItemIcon = (content: ModuleItemContent) => {
  if (!content?.type) return <IconDocumentLine />

  const type = content.type.toLowerCase()

  if (type.includes('assignment'))
    return <IconAssignmentLine color={content.published ? 'success' : 'primary'} />
  if (type.includes('quiz'))
    return <IconQuizLine color={content.published ? 'success' : 'primary'} />
  if (type.includes('discussion'))
    return <IconDiscussionLine color={content.published ? 'success' : 'primary'} />
  if (type.includes('attachment') || type.includes('file'))
    return <IconAttachMediaLine color={content.published ? 'success' : 'primary'} />
  if (type.includes('external') || type.includes('url'))
    return <IconLinkLine color={content.published ? 'success' : 'primary'} />
  if (type.includes('wiki') || type.includes('page'))
    return <IconDocumentLine color={content.published ? 'success' : 'primary'} />
  if (type.includes('link'))
    return <IconLinkLine color={content.published ? 'success' : 'primary'} />

  return null
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
