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
  IconQuizSolid,
  IconLinkLine,
} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {CompletionRequirement, ModuleItemContent, ModuleRequirement} from './types'
import {DateTime} from '@instructure/ui-i18n'
import moment from 'moment'
import {ModuleItemContentType} from '../hooks/queries/useModuleItemContent'
import {
  EXTERNAL_NEW_ITEM_FIELDS,
  EXTERNAL_TOOL_NEW_ITEM_FIELDS,
  ITEM_TYPE,
  ItemType,
  TYPES_WITH_CREATE_NAME,
  TYPES_WITH_URL,
} from './constants'
import {captureMessage} from '@sentry/react'

const I18n = createI18nScope('context_modules_v2')
const pixelOffset = 20
export const ALL_MODULES = '0'

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

export const getItemIcon = (
  content: ModuleItemContent,
  published: boolean,
  isStudentView = false,
) => {
  if (!content?.type) return <IconDocumentLine />

  const type = content.type
  const color = getIconColor(published, isStudentView)

  switch (type) {
    case 'Assignment':
      return content.isNewQuiz ? (
        <IconQuizSolid color={color} data-testid="new-quiz-icon" />
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
    case 'ModuleExternalTool':
    case 'ExternalTool':
      return <IconLinkLine color={color} data-testid="url-icon" />
    case 'Page':
      return <IconDocumentLine color={color} data-testid="page-icon" />
    case 'SubHeader':
      return null
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
    case 'ModuleExternalTool':
    case 'ExternalTool':
      return I18n.t('External Tool')
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
  if (type === 'discussion') return {discussion_topics: [id]}
  if (type === 'attachment' || type === 'file') return {files: [id]}
  if (type === 'external' || type === 'url') return {urls: [id]}
  if (type === 'page') return {pages: [id]}
  if (type === 'link') return {links: [id]}

  return {modules: [id]}
}

export const mapContentTypeForSharing = (contentType: string): string => {
  const lowerType = contentType.toLowerCase()

  const typeMap: Record<string, string> = {
    discussion: 'discussion_topic',
    file: 'attachment',
    page: 'wiki_page',
  }

  return typeMap[lowerType] || lowerType
}

export const validateModuleStudentRenderRequirements = (prevProps: any, nextProps: any) => {
  return (
    prevProps.id === nextProps.id &&
    prevProps.expanded === nextProps.expanded &&
    prevProps.name === nextProps.name &&
    prevProps.completionRequirements === nextProps.completionRequirements &&
    prevProps.position === nextProps.position
  )
}

export const validateModuleItemStudentRenderRequirements = (prevProps: any, nextProps: any) => {
  const basicPropsEqual =
    prevProps.id === nextProps.id &&
    prevProps.url === nextProps.url &&
    prevProps.title === nextProps.title &&
    prevProps.indent === nextProps.indent &&
    prevProps.index === nextProps.index &&
    prevProps.smallScreen === nextProps.smallScreen

  if (!basicPropsEqual) return false

  // If content objects are the same reference, they're equal
  if (prevProps.content === nextProps.content) return true

  // If one is null/undefined and the other isn't, they're different
  if (!prevProps.content !== !nextProps.content) return false

  // If both are null/undefined, they're equal
  if (!prevProps.content && !nextProps.content) return true

  // Compare checkpoint data explicitly (deep comparison needed for nested arrays)
  const prevCheckpoints = prevProps.content?.checkpoints
  const nextCheckpoints = nextProps.content?.checkpoints

  // Handle exact null/undefined differences
  if (prevCheckpoints !== nextCheckpoints && (!prevCheckpoints || !nextCheckpoints)) return false

  if (prevCheckpoints && nextCheckpoints) {
    if (prevCheckpoints.length !== nextCheckpoints.length) return false

    // Use JSON.stringify for deep comparison of checkpoint arrays
    if (JSON.stringify(prevCheckpoints) !== JSON.stringify(nextCheckpoints)) return false
  }

  // If we reach here, checkpoint data is identical (or both are null/undefined)
  // But since content objects are different references, we need to check if
  // any other content properties that matter have changed
  const contentPropsEqual =
    prevProps.content?.id === nextProps.content?.id &&
    prevProps.content?.title === nextProps.content?.title &&
    prevProps.content?.type === nextProps.content?.type &&
    prevProps.content?.published === nextProps.content?.published &&
    prevProps.content?.pointsPossible === nextProps.content?.pointsPossible &&
    prevProps.content?.dueAt === nextProps.content?.dueAt &&
    prevProps.content?.lockAt === nextProps.content?.lockAt &&
    prevProps.content?.unlockAt === nextProps.content?.unlockAt

  return contentPropsEqual
}

// Optimized shallow comparison for completion requirements
const compareCompletionRequirements = (prev: any[], next: any[]): boolean => {
  if (!prev && !next) return true
  if (!prev || !next) return false
  if (prev.length !== next.length) return false

  for (let i = 0; i < prev.length; i++) {
    const prevReq = prev[i]
    const nextReq = next[i]
    if (
      prevReq?.type !== nextReq?.type ||
      prevReq?.min_score !== nextReq?.min_score ||
      prevReq?.minScore !== nextReq?.minScore ||
      prevReq?.completed !== nextReq?.completed
    ) {
      return false
    }
  }
  return true
}

// Optimized checkpoint comparison
const compareCheckpoints = (prev: any[], next: any[]): boolean => {
  if (!prev && !next) return true
  if (!prev || !next) return false
  if (prev.length !== next.length) return false

  for (let i = 0; i < prev.length; i++) {
    const prevCP = prev[i]
    const nextCP = next[i]
    if (
      prevCP?.dueAt !== nextCP?.dueAt ||
      prevCP?.name !== nextCP?.name ||
      prevCP?.tag !== nextCP?.tag
    ) {
      return false
    }
  }
  return true
}

// Optimized assignment overrides comparison
const compareAssignmentOverrides = (prev: any, next: any): boolean => {
  if (!prev && !next) return true
  if (!prev || !next) return false

  const prevEdges = prev.edges || []
  const nextEdges = next.edges || []

  if (prevEdges.length !== nextEdges.length) return false
  if (prevEdges.length === 0) return true

  // For performance, only do deep comparison if edges count is reasonable
  if (prevEdges.length > 20) {
    // For very large override lists, fall back to JSON comparison but cache it
    return JSON.stringify(prev) === JSON.stringify(next)
  }

  for (let i = 0; i < prevEdges.length; i++) {
    const prevEdge = prevEdges[i]
    const nextEdge = nextEdges[i]
    const prevNode = prevEdge?.node
    const nextNode = nextEdge?.node

    if (
      prevNode?._id !== nextNode?._id ||
      prevNode?.dueAt !== nextNode?.dueAt ||
      prevNode?.lockAt !== nextNode?.lockAt ||
      prevNode?.unlockAt !== nextNode?.unlockAt
    ) {
      return false
    }
  }
  return true
}

function extractDueAts(props: {content: {assignedToDates: any}}) {
  const dates = props?.content?.assignedToDates
  if (!Array.isArray(dates)) return []

  return dates
    .map(date => date?.dueAt)
    .filter(dueAt => typeof dueAt !== 'undefined' && dueAt !== null)
}

export const validateModuleItemTeacherRenderRequirements = (prevProps: any, nextProps: any) => {
  // Basic props comparison (most likely to differ)
  const basicPropsEqual =
    prevProps.id === nextProps.id &&
    prevProps.moduleId === nextProps.moduleId &&
    prevProps.published === nextProps.published &&
    prevProps.index === nextProps.index &&
    prevProps.indent === nextProps.indent &&
    prevProps.title === nextProps.title &&
    prevProps.focusTargetItemId === nextProps.focusTargetItemId &&
    prevProps?.content?.dueAt === nextProps?.content?.dueAt &&
    prevProps?.content?.lockAt === nextProps?.content?.lockAt &&
    prevProps?.content?.unlockAt === nextProps?.content?.unlockAt &&
    prevProps.position === nextProps.position

  if (!basicPropsEqual) return false

  const prevDueAts = extractDueAts(prevProps)
  const nextDueAts = extractDueAts(nextProps)
  if (
    prevDueAts.length !== nextDueAts.length ||
    !prevDueAts.every((val, idx) => val === nextDueAts[idx])
  ) {
    return false
  }

  // Optimized completion requirements comparison
  if (
    !compareCompletionRequirements(
      prevProps.completionRequirements,
      nextProps.completionRequirements,
    )
  ) {
    return false
  }

  // Optimized checkpoint comparison
  const prevCheckpoints = prevProps.content?.checkpoints
  const nextCheckpoints = nextProps.content?.checkpoints
  if (!compareCheckpoints(prevCheckpoints, nextCheckpoints)) {
    return false
  }

  // Optimized assignment overrides comparison
  const prevOverrides = prevProps.content?.assignmentOverrides
  const nextOverrides = nextProps.content?.assignmentOverrides
  if (!compareAssignmentOverrides(prevOverrides, nextOverrides)) {
    return false
  }

  return true
}

export const validateModuleTeacherRenderRequirements = (prevProps: any, nextProps: any) => {
  return (
    prevProps.id === nextProps.id &&
    prevProps.expanded === nextProps.expanded &&
    prevProps.published === nextProps.published &&
    prevProps.name === nextProps.name &&
    prevProps.hasActiveOverrides === nextProps.hasActiveOverrides &&
    prevProps.prerequisites === nextProps.prerequisites &&
    prevProps.completionRequirements === nextProps.completionRequirements &&
    prevProps.unlockAt === nextProps.unlockAt &&
    prevProps.requirementCount === nextProps.requirementCount &&
    prevProps.lockAt === nextProps.lockAt &&
    prevProps.position === nextProps.position
  )
}

export const filterRequirementsMet = (
  requirementsMet: ModuleRequirement[],
  completionRequirements: CompletionRequirement[],
) => {
  return requirementsMet.filter(req =>
    completionRequirements.some(cr => {
      const idMatch = String(req.id) === String(cr.id)

      const typeMatch = req?.type === cr?.type

      const scoreMatch = req?.minScore === cr?.minScore

      const percentageMatch = req?.minPercentage === cr?.minPercentage

      return idMatch && typeMatch && scoreMatch && percentageMatch
    }),
  )
}

export const isModuleUnlockAtDateInTheFuture = (unlockAtDate: string) => {
  const TIMEZONE = ENV?.TIMEZONE || DateTime.browserTimeZone()
  const unlockMoment = moment.tz(unlockAtDate, TIMEZONE)
  const now = moment.tz(TIMEZONE)

  return unlockMoment.isAfter(now)
}

export function focusModuleItemTitleLinkById(id?: string, preventScroll = false) {
  if (!id) return

  const selector = `[data-testid="module-item-title-link"][data-module-item-id="${id}"]`
  const el = document.querySelector<HTMLElement>(selector)

  if (el && typeof el.focus === 'function') {
    el.focus({preventScroll})
  }
}

export function getItemTypeLabel(type: ModuleItemContentType): string {
  switch (type) {
    case ITEM_TYPE.ASSIGNMENT:
      return I18n.t('Assignment')
    case ITEM_TYPE.QUIZ:
      return I18n.t('Quiz')
    case ITEM_TYPE.DISCUSSION:
      return I18n.t('Discussion')
    case ITEM_TYPE.FILE:
      return I18n.t('File')
    case ITEM_TYPE.PAGE:
      return I18n.t('Page')
    case ITEM_TYPE.EXTERNAL_URL:
      return I18n.t('External URL')
    case ITEM_TYPE.EXTERNAL_TOOL:
      return I18n.t('External Tool')
    case ITEM_TYPE.CONTEXT_MODULE_SUB_HEADER:
      return I18n.t('Header')
    default: {
      captureMessage(`Unhandled ModuleItemContentType: ${String(type)}`, 'error')
      return I18n.t('Unknown')
    }
  }
}

export const getWarningLabel = (itemType: ItemType, state: {tabIndex: number}, type: string) => {
  const itemLabel = getItemTypeLabel(itemType)

  if (TYPES_WITH_CREATE_NAME.includes(itemType) && state.tabIndex == 1) {
    return I18n.t('%{itemLabel} name is required', {itemLabel})
  }

  if (itemType === ITEM_TYPE.CONTEXT_MODULE_SUB_HEADER) {
    return I18n.t('Header text is required')
  }

  if (TYPES_WITH_URL.includes(itemType) && type === 'name') {
    return I18n.t('Page name is required')
  }

  if (TYPES_WITH_URL.includes(itemType) && type === 'url') {
    return I18n.t('Url is required')
  }

  return I18n.t('%{itemLabel} is required', {itemLabel})
}

export const isExternalNewItemField = (
  field: string,
): field is (typeof EXTERNAL_NEW_ITEM_FIELDS)[number] => {
  return (EXTERNAL_NEW_ITEM_FIELDS as readonly string[]).includes(field)
}

export const isExternalToolNewItemField = (
  field: string,
): field is (typeof EXTERNAL_TOOL_NEW_ITEM_FIELDS)[number] => {
  return (EXTERNAL_TOOL_NEW_ITEM_FIELDS as readonly string[]).includes(field)
}
