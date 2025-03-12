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
    IconExternalLinkLine
  } from '@instructure/ui-icons'
import { ModuleContent } from './types'


export const INDENT_LOOKUP: Record<number, 'x-small' | 'small' | 'medium' | 'large' | 'x-large' | 'xx-large'> = {
    0: 'x-small',
    1: 'small',
    2: 'medium',
    3: 'large',
    4: 'x-large',
    5: 'xx-large',
}

export const getItemIcon = (content: ModuleContent) => {
    if (!content?.type) return <IconDocumentLine />

    const type = content.type.toLowerCase()

    if (type.includes('assignment')) return <IconAssignmentLine />
    if (type.includes('quiz')) return <IconQuizLine />
    if (type.includes('discussion')) return <IconDiscussionLine />
    if (type.includes('attachment') || type.includes('file')) return <IconAttachMediaLine />
    if (type.includes('external') || type.includes('url')) return <IconExternalLinkLine />
    if (type.includes('wiki') || type.includes('page')) return <IconDocumentLine />
    if (type.includes('link')) return <IconLinkLine />

    return <IconDocumentLine />
  }

export const mapContentSelection = (id: string, contentType: string) => {
    // Cast the string to our supported content types
    const type = contentType as 'assignment' | 'quiz' | 'discussion' | 'attachment' | 'file' | 'external' | 'url' | 'page' | 'link'

    if (type === 'assignment') return {assignments: [id]}
    if (type === 'quiz') return {quizzes: [id]}
    if (type === 'discussion') return {discussions: [id]}
    if (type === 'attachment' || type === 'file') return {files: [id]}
    if (type === 'external' || type === 'url') return {urls: [id]}
    if (type === 'page') return {pages: [id]}
    if (type === 'link') return {links: [id]}

    return {modules: [id]}
}
