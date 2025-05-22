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

import type {AssignmentOverridePayload, AssignmentOverridesPayload, ItemType} from '../react/types'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {
  DateDetailsPayload,
  ItemAssignToCardSpec,
  DateDetailsOverride,
  AssigneeOption,
} from '../react/Item/types'

const I18n = createI18nScope('differentiated_modules')

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

/********************* Generating Assignment Override Payload *********************/

const studentOverridePayload = (
  students: AssigneeOption[],
  overrideId: string | undefined,
): AssignmentOverridePayload => ({
  student_ids: students.map(student => student.id.split('-')[1]),
  id: overrideId,
})

const getStudentOverride = (studentAssignees: AssigneeOption[]): AssignmentOverridePayload => {
  const studentOverrideId = studentAssignees.find(assignee => assignee.overrideId)?.overrideId
  return studentOverridePayload(studentAssignees, studentOverrideId)
}

const sectionOverridePayload = (section: AssigneeOption): AssignmentOverridePayload => ({
  course_section_id: section.id.split('-')[1],
  id: section.overrideId,
})

const getSectionOverrides = (sectionAssignees: AssigneeOption[]) => {
  return sectionAssignees.map(section => sectionOverridePayload(section))
}

const differentiationTagOverridePayload = (tag: AssigneeOption): AssignmentOverridePayload => ({
  group_id: tag.id.split('-')[1],
  id: tag.overrideId,
})

const getDifferentiationTagOverrides = (differentiationTagAssignees: AssigneeOption[]) => {
  return differentiationTagAssignees.map(tag => differentiationTagOverridePayload(tag))
}

const separateAssigneesByType = (selectedAssignees: AssigneeOption[]) => {
  const studentAssignees = selectedAssignees.filter(assignee => assignee.id.includes('student'))
  const sectionAssignees = selectedAssignees.filter(assignee => assignee.id.includes('section'))
  const differentiationTagAssignees = selectedAssignees.filter(assignee =>
    assignee.id.includes('tag'),
  )
  return {studentAssignees, sectionAssignees, differentiationTagAssignees}
}

export const generateAssignmentOverridesPayload = (
  selectedAssignees: AssigneeOption[],
): AssignmentOverridesPayload => {
  const {studentAssignees, sectionAssignees, differentiationTagAssignees} =
    separateAssigneesByType(selectedAssignees)
  const sectionOverrides = getSectionOverrides(sectionAssignees)
  const differentiationTagOverrides = getDifferentiationTagOverrides(differentiationTagAssignees)

  const overrides: AssignmentOverridePayload[] = [
    ...sectionOverrides,
    ...differentiationTagOverrides,
  ]

  if (studentAssignees.length > 0) {
    overrides.push(getStudentOverride(studentAssignees))
  }

  return {overrides}
}

/********************* Generating Date Details Payload *********************/

export const generateDateDetailsPayload = (
  cards: ItemAssignToCardSpec[],
  hasModuleOverrides: boolean,
  deletedModuleAssignees: string[],
) => {
  const overrideCards = getOverrideCards(cards)
  const everyoneCard = getEveryoneCard(cards)
  const payload = defaultDateDetailsPayload(overrideCards, everyoneCard, hasModuleOverrides)
  payload.assignment_overrides = createAssignmentOverrides(
    overrideCards,
    everyoneCard,
    hasModuleOverrides,
    deletedModuleAssignees,
  )

  return payload
}

const defaultDateDetailsPayload = (
  overrideCards: ItemAssignToCardSpec[],
  everyoneCard: ItemAssignToCardSpec | undefined,
  hasModuleOverrides: boolean,
): DateDetailsPayload => {
  const payload: DateDetailsPayload = {} as DateDetailsPayload
  if (everyoneCard !== undefined && !hasModuleOverrides) {
    payload.due_at = everyoneCard.due_at || null
    payload.unlock_at = everyoneCard.unlock_at || null
    payload.lock_at = everyoneCard.lock_at || null
    payload.reply_to_topic_due_at = everyoneCard.reply_to_topic_due_at || null
    payload.required_replies_due_at = everyoneCard.required_replies_due_at || null
  }
  if (
    (everyoneCard !== undefined && !hasModuleOverrides) ||
    (hasModuleOverrides && overrideCards.length === 0)
  ) {
    payload.only_visible_to_overrides = false
  } else {
    payload.only_visible_to_overrides = true
  }
  return payload
}

const createAssignmentOverrides = (
  overrideCards: ItemAssignToCardSpec[],
  everyoneCard: ItemAssignToCardSpec | undefined,
  hasModuleOverrides: boolean,
  deletedModuleAssignees: string[],
) => {
  let overrides: DateDetailsOverride[] = []
  overrideCards.forEach(card => {
    const isUpdatedModuleOverride = !!(card.contextModuleId !== undefined && card.isEdited)
    const sectionOverrides = generateSectionOverrides(card, everyoneCard, isUpdatedModuleOverride)
    const groupOverrides = generateGroupOverrides(card, isUpdatedModuleOverride)
    const differentiationTagOverrides = generateGroupOverrides(card, isUpdatedModuleOverride, true)
    overrides = overrides.concat([
      ...sectionOverrides,
      ...groupOverrides,
      ...differentiationTagOverrides,
    ])

    // the following overrides need to be individually added and are not always
    // included when generating the overrides depending on certain situations
    addStudentOverridesIfApplicable(overrides, card, isUpdatedModuleOverride)
    addCourseOverrideIfApplicable(overrides, card, hasModuleOverrides, isUpdatedModuleOverride)
    addMasteryPathsOverrideIfApplicable(overrides, card)
  })

  // add any unassign_item overrides if present
  if (deletedModuleAssignees.length > 0) {
    addUnassignStudentOverrides(overrides, deletedModuleAssignees)
    addUnassignSectionOverrides(overrides, deletedModuleAssignees)
  }

  return overrides.flat()
}

const generateSectionOverrides = (
  card: ItemAssignToCardSpec,
  everyoneCard: ItemAssignToCardSpec | undefined,
  isUpdatedModuleOverride: boolean,
) => {
  const overrides: DateDetailsOverride[] = []
  const sectionAssignees = getAssigneesByType(card.selectedAssigneeIds, 'section')
  sectionAssignees.map(section => {
    overrides.push(createSectionOverride(card, section, isUpdatedModuleOverride, everyoneCard))
  })
  return overrides
}

const createSectionOverride = (
  card: ItemAssignToCardSpec,
  section: string,
  isUpdatedModuleOverride: boolean,
  everyoneCard: ItemAssignToCardSpec | undefined,
): DateDetailsOverride => {
  const isDefaultSectionOverride =
    card?.defaultOptions?.[0]?.includes(section) && card.overrideId !== everyoneCard?.overrideId
  const shouldUpdate = isDefaultSectionOverride && !isUpdatedModuleOverride
  const overrideId = shouldUpdate ? card.overrideId : undefined
  return {
    course_section_id: section.split('-')[1],
    ...createOverride(overrideId, card),
  }
}

// This method determines whether an override should be created for a group
// If the group is not a default group override, then an override should be made
// If the group is a default group override, then an override should be made if the card now contains dates
//   - This means that the the context module override will be overridden by the assignment override
//   - Context module overrides cannot contain dates
const shouldCreateGroupOverride = (card: ItemAssignToCardSpec, group: string): boolean => {
  const isDefaultGroupOverride = card.defaultOptions?.[0]?.includes(group)
  const cardHasADate = Boolean(
    card.due_at ||
      card.unlock_at ||
      card.lock_at ||
      card.reply_to_topic_due_at ||
      card.required_replies_due_at,
  )

  return !isDefaultGroupOverride || cardHasADate
}

const generateGroupOverrides = (
  card: ItemAssignToCardSpec,
  isUpdatedModuleOverride: boolean,
  isDifferentiationTag = false,
) => {
  const overrides: DateDetailsOverride[] = []
  const groupType = isDifferentiationTag ? 'tag' : 'group'
  const groupAssignees = getAssigneesByType(card.selectedAssigneeIds, groupType)
  groupAssignees.map(group => {
    if (shouldCreateGroupOverride(card, group)) {
      overrides.push(createGroupOverride(card, group, isUpdatedModuleOverride))
    }
  })
  return overrides
}

const createGroupOverride = (
  card: ItemAssignToCardSpec,
  group: string,
  isUpdatedModuleOverride: boolean,
): DateDetailsOverride => {
  const isDefaultGroupOverride = card.defaultOptions?.[0]?.includes(group)
  const overrideId =
    isDefaultGroupOverride && !isUpdatedModuleOverride ? card.overrideId : undefined
  return {
    group_id: group.split('-')[1],
    ...createOverride(overrideId, card),
  }
}

const addStudentOverridesIfApplicable = (
  overrides: DateDetailsOverride[],
  card: ItemAssignToCardSpec,
  isUpdatedModuleOverride: boolean,
) => {
  const studentAssignees = getAssigneesByType(card.selectedAssigneeIds, 'student')
  // Add override if there are student assignees
  // All students are grouped into one override per card
  if (studentAssignees.length > 0) {
    const studentOverride = createStudentOverride(card, isUpdatedModuleOverride)
    overrides.push(studentOverride)
  }
}

const createStudentOverride = (
  card: ItemAssignToCardSpec,
  isUpdatedModuleOverride: boolean,
): DateDetailsOverride => {
  const studentAssignees = getAssigneesByType(card.selectedAssigneeIds, 'student')
  const {studentIds, isDefaultAdhocOverride} = parseStudentIds(card, studentAssignees)
  const overrideId =
    isDefaultAdhocOverride && !isUpdatedModuleOverride ? card.overrideId : undefined
  return {
    student_ids: studentIds,
    ...createOverride(overrideId, card),
  }
}

const parseStudentIds = (card: ItemAssignToCardSpec, studentAssignees: string[]) => {
  let isDefaultAdhocOverride = false
  const studentIds = studentAssignees.map(id => {
    if (!isDefaultAdhocOverride) {
      // this checks if the card assignees changed to not include any of it's original student assignees
      // which would make this a new override
      isDefaultAdhocOverride = card.defaultOptions?.includes(id) || false
    }
    return id.split('-')[1]
  })
  return {studentIds, isDefaultAdhocOverride}
}

const addCourseOverrideIfApplicable = (
  overrides: DateDetailsOverride[],
  card: ItemAssignToCardSpec,
  hasModuleOverrides: boolean,
  isUpdatedModuleOverride: boolean,
) => {
  const courseOverrideCard = card.selectedAssigneeIds.includes('everyone')
  if (courseOverrideCard && hasModuleOverrides) {
    const isDefaultCourseOverride = card.defaultOptions?.[0]?.includes('everyone')
    const overrideId =
      isDefaultCourseOverride && !isUpdatedModuleOverride ? card.overrideId : undefined
    const courseOverride = {
      course_id: 'everyone',
      ...createOverride(overrideId, card),
    }
    overrides.push(courseOverride)
  }
}

const addMasteryPathsOverrideIfApplicable = (
  overrides: DateDetailsOverride[],
  card: ItemAssignToCardSpec,
) => {
  if (card.selectedAssigneeIds.includes('mastery_paths')) {
    const isAlreadyMasteryPath = card.defaultOptions?.[0]?.includes('Mastery Paths')
    const overrideId = isAlreadyMasteryPath ? card.overrideId : undefined
    const masteryPathsOverride = {
      title: 'Mastery Paths',
      noop_id: 1,
      ...createOverride(overrideId, card),
    }
    overrides.push(masteryPathsOverride)
  }
}

const addUnassignStudentOverrides = (
  overrides: DateDetailsOverride[],
  deletedModuleAssignees: string[],
) => {
  const studentIds = getAssigneesByType(deletedModuleAssignees, 'student').map(
    id => id.split('-')[1],
  )
  if (studentIds.length > 0) {
    const studentOverride = {
      id: undefined,
      due_at: null,
      reply_to_topic_due_at: null,
      required_replies_due_at: null,
      unlock_at: null,
      lock_at: null,
      student_ids: studentIds,
      unassign_item: true,
    }
    overrides.push(studentOverride)
  }
}

const addUnassignSectionOverrides = (
  overrides: DateDetailsOverride[],
  deletedModuleAssignees: string[],
) => {
  const sectionIds = getAssigneesByType(deletedModuleAssignees, 'section').map(
    id => id.split('-')[1],
  )
  sectionIds.forEach(section => {
    const sectionOverride = {
      id: undefined,
      due_at: null,
      reply_to_topic_due_at: null,
      required_replies_due_at: null,
      unlock_at: null,
      lock_at: null,
      course_section_id: section,
      unassign_item: true,
    }
    overrides.push(sectionOverride)
  })
}

const createOverride = (
  overrideId: string | undefined,
  card: ItemAssignToCardSpec,
  unassignItem = false,
): DateDetailsOverride => {
  return {
    id: overrideId,
    due_at: card.due_at,
    reply_to_topic_due_at: card.reply_to_topic_due_at,
    required_replies_due_at: card.required_replies_due_at,
    unlock_at: card.unlock_at,
    lock_at: card.lock_at,
    unassign_item: unassignItem,
  }
}

const getEveryoneCard = (cards: ItemAssignToCardSpec[]) => {
  return cards.find(card => card.selectedAssigneeIds.includes('everyone'))
}

const getOverrideCards = (cards: ItemAssignToCardSpec[]) => {
  return cards.filter(card => card.key !== 'everyone') || []
}

const getAssigneesByType = (assignees: string[], type: string) => {
  return assignees.filter(assignee => assignee.includes(type))
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
    (acc: {sections: string[]; differentiationTags: string[]; students: string[]}, current) => {
      const sectionOverride = overrides?.find(
        tmp =>
          tmp.course_section_id !== undefined &&
          tmp.course_section_id === current.course_section_id &&
          !tmp.context_module_id,
      )
      if (sectionOverride && current.course_section_id) {
        acc.sections.push(current.course_section_id)
        return acc
      }
      const differentiationTagOverride = overrides?.find(
        tmp =>
          tmp.group_id !== undefined && tmp.group_id === current.group_id && !tmp.context_module_id,
      )
      if (differentiationTagOverride && current.group_id) {
        acc.differentiationTags.push(current.group_id)
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
    {sections: [], differentiationTags: [], students: []},
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
