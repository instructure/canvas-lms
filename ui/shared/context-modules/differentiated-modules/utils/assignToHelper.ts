/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import type {AssigneeOption} from '../react/AssigneeSelector'
import type {AssignmentOverridePayload, AssignmentOverridesPayload, ItemType} from '../react/types'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {
  DateDetailsPayload,
  ItemAssignToCardSpec,
  DateDetailsOverride,
} from '../react/Item/types'

const I18n = useI18nScope('differentiated_modules')

export const setContainScrollBehavior = (element: HTMLElement | null) => {
  if (element !== null) {
    let parent = element.parentElement
    while (parent) {
      const {overflowY} = window.getComputedStyle(parent)
      if (['scroll', 'auto'].includes(overflowY)) {
        parent.style.overscrollBehaviorY = 'contain'
        return
      }
      parent = parent.parentElement
    }
  }
}

export const generateAssignmentOverridesPayload = (
  selectedAssignees: AssigneeOption[]
): AssignmentOverridesPayload => {
  const studentsOverrideId = selectedAssignees.find(
    assignee => assignee.id.includes('student') && assignee.overrideId
  )?.overrideId
  const sectionOverrides = selectedAssignees
    .filter(assignee => assignee.id.includes('section'))
    ?.map(section => ({
      course_section_id: section.id.split('-')[1],
      id: section.overrideId,
    }))
  const studentIds = selectedAssignees
    .filter(assignee => assignee.id.includes('student'))
    ?.map(({id}) => id.split('-')[1])
  const overrides: AssignmentOverridePayload[] = [...sectionOverrides]
  if (studentIds.length > 0) {
    overrides.push({
      id: studentsOverrideId,
      student_ids: studentIds,
    })
  }

  return {overrides}
}

export const generateDateDetailsPayload = (
  cards: ItemAssignToCardSpec[],
  hasModuleOverrides: boolean
) => {
  const payload: DateDetailsPayload = {} as DateDetailsPayload
  const everyoneCard = cards.find(card => card.selectedAssigneeIds.includes('everyone'))
  const overrideCards = cards.filter(card => card.key !== 'everyone')
  if (everyoneCard !== undefined && !hasModuleOverrides) {
    payload.due_at = everyoneCard.due_at || null
    payload.unlock_at = everyoneCard.unlock_at || null
    payload.lock_at = everyoneCard.lock_at || null
    payload.only_visible_to_overrides = false
  } else if (!hasModuleOverrides) {
    payload.only_visible_to_overrides = true
  }
  payload.assignment_overrides = overrideCards
    .map(card => {
      const isUpdatedModuleOverride = card.contextModuleId !== undefined && card.isEdited
      const isDefaultSectionOverride =
        card.defaultOptions?.[0]?.includes('section') &&
        card.overrideId !== everyoneCard?.overrideId
      const shouldUpdate = isDefaultSectionOverride && !isUpdatedModuleOverride
      const overrides: DateDetailsOverride[] = card.selectedAssigneeIds
        .filter(assignee => assignee.includes('section'))
        ?.map((section, index) => ({
          id: index === 0 && shouldUpdate ? card.overrideId : undefined,
          course_section_id: section.split('-')[1],
          due_at: card.due_at,
          unlock_at: card.unlock_at,
          lock_at: card.lock_at,
        }))
      const isOverrideUsed = overrides.some(
        override => override.id === card.overrideId || everyoneCard?.overrideId === card.overrideId
      )

      const isDefaultAdhocOverride = card.defaultOptions?.[0]?.includes('student')
      const studentIds = card.selectedAssigneeIds
        .filter(assignee => assignee.includes('student'))
        ?.map(id => id.split('-')[1])
      if (studentIds.length > 0) {
        overrides.push({
          id:
            !isOverrideUsed && isDefaultAdhocOverride && !isUpdatedModuleOverride
              ? card.overrideId
              : undefined,
          student_ids: studentIds,
          due_at: card.due_at,
          unlock_at: card.unlock_at,
          lock_at: card.lock_at,
        })
      }

      const isDefaultCourseOverride = card.defaultOptions?.[0]?.includes('everyone')
      const courseOverrideCard = card.selectedAssigneeIds.includes('everyone')
      if (courseOverrideCard && hasModuleOverrides) {
        overrides.push({
          id:
            !isOverrideUsed && isDefaultCourseOverride && !isUpdatedModuleOverride
              ? card.overrideId
              : undefined,
          due_at: card.due_at || null,
          unlock_at: card.unlock_at || null,
          lock_at: card.lock_at || null,
          course_id: 'everyone',
        })
      }
      return overrides
    })
    .flat()

  const masteryPathsCard = cards.find(card => card.selectedAssigneeIds.includes('mastery_paths'))
  if (masteryPathsCard !== undefined) {
    payload.assignment_overrides.push({
      id: masteryPathsCard.overrideId,
      title: 'Mastery Paths',
      due_at: masteryPathsCard.due_at || null,
      unlock_at: masteryPathsCard.unlock_at || null,
      lock_at: masteryPathsCard.lock_at || null,
      noop_id: 1,
    })
  }

  return payload
}

export function updateModuleUI(moduleElement: HTMLDivElement, payload: AssignmentOverridesPayload) {
  const assignToButtonContainer = moduleElement.querySelector('.view_assign')
  if (assignToButtonContainer) {
    if (payload.overrides.length > 0) {
      const moduleId = moduleElement.getAttribute('data-module-id') ?? ''
      assignToButtonContainer.innerHTML = `
        <i aria-hidden="true" class="icon-group"></i>
        <a
          href="#${moduleId}"
          class="view_assign_link"
          title="${I18n.t('View Assign To')}"
        >
          ${I18n.t('View Assign To')}
        </a>
        `
    } else {
      assignToButtonContainer.innerHTML = ''
    }
  }
}

export function getOverriddenAssignees(overrides?: DateDetailsOverride[]) {
  const moduleOverrides = overrides?.filter(override => override.context_module_id !== undefined)
  const overriddenTargets = moduleOverrides?.reduce(
    (acc: {sections: string[]; students: string[]}, current) => {
      const sectionOverride = overrides?.find(
        tmp =>
          tmp.course_section_id !== undefined &&
          tmp.course_section_id === current.course_section_id &&
          !tmp.context_module_id
      )
      if (sectionOverride && current.course_section_id) {
        acc.sections.push(current.course_section_id)
        return acc
      }
      const students = current.student_ids
      const studentsOverride =
        overrides?.reduce((studentIds: string[], current) => {
          if (current.context_module_id !== undefined) return studentIds
          const overriddenIds = current.student_ids?.filter(id => students?.includes(id)) ?? []
          studentIds.push(...overriddenIds)
          return studentIds
        }, []) ?? []
      acc.students.push(...studentsOverride)
      return acc
    },
    {sections: [], students: []}
  )
  return overriddenTargets
}

export const itemTypeToApiURL = (courseId: string, itemType: ItemType, itemId: string) => {
  switch (itemType) {
    case 'assignment':
    case 'lti-quiz':
      return `/api/v1/courses/${courseId}/assignments/${itemId}/date_details`
    case 'quiz':
      return `/api/v1/courses/${courseId}/quizzes/${itemId}/date_details`
    case 'discussion':
    case 'discussion_topic':
      return `/api/v1/courses/${courseId}/discussion_topics/${itemId}/date_details`
    case 'page':
    case 'wiki_page':
      return `/api/v1/courses/${courseId}/pages/${itemId}/date_details`
    default:
      return ''
  }
}

export const generateDefaultCard = () => ({
  key: 'assign-to-card__everyone',
  isValid: true,
  hasAssignees: true,
  due_at: null,
  unlock_at: null,
  lock_at: null,
  selectedAssigneeIds: ['everyone'],
})
