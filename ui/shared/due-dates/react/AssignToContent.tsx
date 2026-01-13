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

import React, {useState, useEffect, useCallback, useMemo} from 'react'
import {Checkbox} from '@instructure/ui-checkbox'
import {useScope as createI18nScope} from '@canvas/i18n'
import ItemAssignToManager from '@canvas/context-modules/differentiated-modules/react/Item/ItemAssignToManager'
import {View} from '@instructure/ui-view'
import {uid} from '@instructure/uid'
import {getParsedOverrides, removeOverriddenAssignees} from '../util/differentiatedModulesUtil'
import {generateDateDetailsPayload} from '../../context-modules/differentiated-modules/utils/assignToHelper'
import type {
  ItemAssignToCardSpec,
  DateDetailsOverride,
  DateDetailsPayload,
  AssigneeOption,
  exportedOverride,
  PeerReviewPayload,
} from '@canvas/context-modules/differentiated-modules/react/Item/types'
import type {ItemType} from '@canvas/context-modules/differentiated-modules/react/types'

const I18n = createI18nScope('DueDateOverrideView')

interface AssignToContentProps {
  onSync: (overrides?: DateDetailsOverride[], importantDates?: boolean) => void
  assignmentId?: string
  getGroupCategoryId?: () => string | null
  type: ItemType
  overrides: DateDetailsOverride[]
  setOverrides?: (overrides: exportedOverride[] | null) => void
  defaultSectionId?: number | string
  importantDates?: boolean
  supportDueDates?: boolean
  isCheckpointed?: boolean
  postToSIS?: boolean
  defaultGroupCategoryId?: string | null
  discussionId?: string | null
}

const convertCardsToOverrides = (
  cards: ItemAssignToCardSpec[],
  hasModuleOverrides: boolean = false,
  defaultSectionId: number | string | undefined,
  deletedModuleAssignees: string[],
  unassignedOverrides: DateDetailsOverride[],
): DateDetailsOverride[] => {
  const payload = generateDateDetailsPayload(
    cards,
    hasModuleOverrides,
    deletedModuleAssignees,
    unassignedOverrides,
  )
  const overrides = payload.assignment_overrides
  if (!payload.only_visible_to_overrides) {
    overrides.push({
      id: undefined,
      course_section_id: defaultSectionId?.toString() ?? undefined,
      due_at: payload.due_at,
      unlock_at: payload.unlock_at,
      lock_at: payload.lock_at,
      reply_to_topic_due_at: payload.reply_to_topic_due_at,
      required_replies_due_at: payload.required_replies_due_at,
      peer_review_available_from: payload.peer_review_available_from,
      peer_review_due_at: payload.peer_review_due_at,
      peer_review_available_to: payload.peer_review_available_to,
      peer_review_default_dates: true,
      unassign_item: false,
    })
  }

  return overrides
}
interface ConvertedData {
  cards: ItemAssignToCardSpec[]
  selectedOptionIds: string[]
  moduleAssignees: string[]
  hasModuleOverrides: boolean
  unassignedOverrides: DateDetailsOverride[]
}

const convertOverridesToCards = (
  overrides: DateDetailsOverride[],
  defaultSectionId: number | string | undefined,
  groupCategoryId: string | null | undefined,
): ConvertedData | undefined => {
  if (!overrides || overrides.length === 0) {
    return undefined
  }

  const unassignedOverrides = overrides.filter(override => override.unassign_item)

  const moduleAssignees = overrides
    .filter(override => override.context_module_id)
    ?.map((moduleOverride: DateDetailsOverride) => {
      if (moduleOverride.course_section_id) {
        return `section-${moduleOverride.course_section_id}`
      }
      if (moduleOverride.student_ids) {
        return moduleOverride.student_ids.map((id: string) => `student-${id}`)
      }
      if (moduleOverride.group_id && moduleOverride.non_collaborative === true) {
        return `tag-${moduleOverride.group_id}`
      }
      return []
    })
    .flat()
  const hasModuleOverrides = moduleAssignees.length > 0

  // Add stagedOverrideId to each override if missing
  const overridesWithIds = overrides.map((override: DateDetailsOverride) => ({
    ...override,
    stagedOverrideId: (override as any).stagedOverrideId || uid(),
  }))

  // Parse overrides into cards and remove overridden assignees (module overrides that have been overridden)
  const parsedOverrides = getParsedOverrides(
    overridesWithIds,
    {},
    groupCategoryId,
    defaultSectionId,
  )
  const cardsObj = removeOverriddenAssignees(overridesWithIds, parsedOverrides)

  const cards: ItemAssignToCardSpec[] = []
  const selectedOptionIds: string[] = []

  Object.values(cardsObj).forEach((cardData: any) => {
    const cardOverrides = cardData.overrides || []

    cardOverrides.forEach((override: any) => {
      const studentOverrides: AssigneeOption[] =
        override.students?.map((student: any) => ({
          id: `student-${student.id}`,
          value: student.name,
          group: 'Students',
        })) ?? []

      const initialAssigneeOptions: AssigneeOption[] = [...studentOverrides]
      const defaultOptions: string[] = studentOverrides.map((option: AssigneeOption) => option.id)

      if (override.noop_id === '1') {
        defaultOptions.push('mastery_paths')
      }

      if (override.course_section_id === defaultSectionId || override.course_id) {
        defaultOptions.push('everyone')
      } else if (override.course_section_id) {
        defaultOptions.push(`section-${override.course_section_id}`)
        initialAssigneeOptions.push({
          id: `section-${override.course_section_id}`,
          value: override.title,
          group: 'Sections',
        })
      }

      if (override.group_id && override.non_collaborative === false) {
        defaultOptions.push(`group-${override.group_id}`)
        initialAssigneeOptions.push({
          id: `group-${override.group_id}`,
          value: override.title,
          groupCategoryId: override.group_category_id,
          group: 'Groups',
        })
      }

      if (override.group_id && override.non_collaborative === true) {
        defaultOptions.push(`tag-${override.group_id}`)
        initialAssigneeOptions.push({
          id: `tag-${override.group_id}`,
          value: override.title,
          groupCategoryId: override.group_category_id,
          group: 'Tags',
        })
      }

      const cardId = uid('assign-to-card', 12)
      const card: ItemAssignToCardSpec = {
        key: cardId,
        isValid: true,
        hasAssignees: defaultOptions.length > 0,
        due_at: override.due_at,
        reply_to_topic_due_at: override.reply_to_topic_due_at,
        required_replies_due_at: override.required_replies_due_at,
        original_due_at: override.due_at,
        unlock_at: override.unlock_at,
        lock_at: override.lock_at,
        peer_review_available_from: override.peer_review_available_from,
        peer_review_due_at: override.peer_review_due_at,
        peer_review_available_to: override.peer_review_available_to,
        peer_review_override_id: override.peer_review_override_id,
        selectedAssigneeIds: defaultOptions,
        defaultOptions,
        initialAssigneeOptions,
        overrideId: override.id,
        contextModuleId: override.context_module_id,
        contextModuleName: override.context_module_name,
      }

      // Insert 'everyone' cards at the beginning
      if (defaultOptions.includes('everyone')) {
        cards.unshift(card)
      } else {
        cards.push(card)
      }

      selectedOptionIds.push(...defaultOptions)
    })
  })

  return {cards, selectedOptionIds, moduleAssignees, hasModuleOverrides, unassignedOverrides}
}

const AssignToContent = ({
  onSync,
  assignmentId,
  getGroupCategoryId,
  type,
  overrides,
  setOverrides,
  defaultSectionId,
  importantDates,
  supportDueDates = true,
  isCheckpointed,
  postToSIS = false,
  defaultGroupCategoryId = null,
  discussionId = null,
}: AssignToContentProps) => {
  const [stagedImportantDates, setStagedImportantDates] = useState(importantDates)
  const [groupCategoryId, setGroupCategoryId] = useState(getGroupCategoryId?.())
  const [assignToCards, setAssignToCards] = useState<ItemAssignToCardSpec[]>([])
  const [moduleAssignees, setModuleAssignees] = useState<string[]>([])
  const [unassignedOverrides, setUnassignedOverrides] = useState<DateDetailsOverride[]>([])

  // Convert initial overrides to cards only on initial render
  const convertedData = useMemo(
    () =>
      convertOverridesToCards(overrides, defaultSectionId, groupCategoryId) || {
        cards: [],
        selectedOptionIds: [],
        moduleAssignees: [],
        hasModuleOverrides: false,
        unassignedOverrides: [],
      },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [],
  )

  const {cards: defaultCards, selectedOptionIds, hasModuleOverrides} = convertedData

  // Initialize module assignees and unassigned overrides once from initial overrides
  useEffect(() => {
    if (moduleAssignees.length === 0 && convertedData.moduleAssignees) {
      setModuleAssignees(convertedData.moduleAssignees)
    }
    if (unassignedOverrides.length === 0 && convertedData.unassignedOverrides) {
      setUnassignedOverrides(convertedData.unassignedOverrides)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // Listen for group category changes from the DOM
  useEffect(() => {
    if (getGroupCategoryId === undefined) return
    const handleGroupChange = () => setGroupCategoryId(getGroupCategoryId?.())
    document.addEventListener('group_category_changed', handleGroupChange)
    return () => {
      document.removeEventListener('group_category_changed', handleGroupChange)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useEffect(() => {
    const newGroupCategoryId = getGroupCategoryId?.()
    if (newGroupCategoryId !== undefined && newGroupCategoryId !== groupCategoryId) {
      setGroupCategoryId(newGroupCategoryId)
    }
  }, [getGroupCategoryId, groupCategoryId])

  useEffect(() => {
    if (getGroupCategoryId !== undefined) return
    setGroupCategoryId(defaultGroupCategoryId)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [defaultGroupCategoryId])

  const handleChange = useCallback(
    (
      cards: ItemAssignToCardSpec[],
      hasModuleOverridesParam: boolean,
      _deletedModuleAssignees: string[],
      newDisabledOptionIds?: string[],
      moduleOverrides?: ItemAssignToCardSpec[],
    ) => {
      const filteredCards = cards.filter(
        card =>
          [null, undefined, ''].includes(card.contextModuleId) ||
          (card.contextModuleId !== null && card.isEdited),
      )

      // Update module context if dates are added/removed
      if (hasModuleOverridesParam) {
        cards.forEach((card: ItemAssignToCardSpec) => {
          const hasDates = card.unlock_at != null || card.lock_at != null || card.due_at != null

          if (card.contextModuleId && card.isEdited && (hasDates || !card.hasInitialOverride)) {
            card.contextModuleId = null
            card.contextModuleName = null
            card.overrideId = undefined
            return
          } else if (hasDates) {
            return
          }

          const moduleCard = moduleOverrides?.find(
            (moduleOverride: ItemAssignToCardSpec) => moduleOverride.key === card.key,
          )
          if (
            moduleCard &&
            !hasDates &&
            (card.hasInitialOverride === undefined || card.hasInitialOverride)
          ) {
            card.contextModuleId = moduleCard.contextModuleId
            card.contextModuleName = moduleCard.contextModuleName
            card.overrideId = moduleCard.overrideId
          }
        })
      }

      const deletedModuleAssignees = moduleAssignees.filter(
        assignee => !newDisabledOptionIds?.includes(assignee),
      )

      const overrides = convertCardsToOverrides(
        filteredCards,
        hasModuleOverridesParam,
        defaultSectionId,
        deletedModuleAssignees,
        unassignedOverrides,
      )
      const noModuleOverrides = overrides.filter(o => !o.context_module_id)

      onSync(noModuleOverrides, stagedImportantDates)
      setAssignToCards(cards)
      return cards
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [stagedImportantDates, defaultSectionId, moduleAssignees, unassignedOverrides],
  )

  const handleImportantDatesChange = useCallback(
    (event: React.ChangeEvent<HTMLInputElement>) => {
      const newImportantDatesValue = event.target.checked
      onSync(undefined, newImportantDatesValue)
      setStagedImportantDates(newImportantDatesValue)
    },
    [onSync],
  )

  const shouldRenderImportantDates =
    type === 'assignment' || type === 'discussion' || type === 'quiz'

  const renderImportantDatesCheckbox = () => {
    if (!supportDueDates || (!ENV.K5_SUBJECT_COURSE && !ENV.K5_HOMEROOM_COURSE)) {
      return null
    }

    const disabled = !assignToCards.some(card => card.due_at)
    const checked = !disabled && stagedImportantDates

    return (
      <div id="important-dates">
        <Checkbox
          label={I18n.t('Mark as important date and show on homeroom sidebar')}
          name="important_dates"
          data-testid="important_dates"
          size="small"
          value={checked && !disabled ? 1 : 0}
          checked={checked && !disabled}
          onChange={handleImportantDatesChange}
          disabled={disabled}
          inline={true}
        />
      </div>
    )
  }

  return (
    <View as="div" padding="x-small 0 0 0">
      {shouldRenderImportantDates && renderImportantDatesCheckbox()}
      <ItemAssignToManager
        open={true}
        onClose={() => {}}
        onDismiss={() => {}}
        itemName=""
        iconType="assignment"
        courseId={ENV.COURSE_ID?.toString() ?? ''}
        itemType={type}
        itemContentId={type === 'discussion' ? (discussionId ?? undefined) : assignmentId}
        defaultCards={defaultCards}
        defaultDisabledOptionIds={selectedOptionIds}
        initHasModuleOverrides={hasModuleOverrides}
        defaultGroupCategoryId={groupCategoryId ?? undefined}
        useApplyButton={true}
        locale={ENV.LOCALE || 'en'}
        timezone={ENV.TIMEZONE || 'UTC'}
        defaultSectionId={defaultSectionId?.toString()}
        removeDueDateInput={!supportDueDates}
        isCheckpointed={isCheckpointed}
        postToSIS={postToSIS}
        isTray={false}
        onChange={handleChange}
        setOverrides={setOverrides}
      />
    </View>
  )
}

export default AssignToContent
