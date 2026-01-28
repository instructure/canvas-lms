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

import React, {useState, useRef, useEffect, useMemo, useCallback} from 'react'
import {Checkbox} from '@instructure/ui-checkbox'
import {useScope as createI18nScope} from '@canvas/i18n'
import ItemAssignToManager from '@canvas/context-modules/differentiated-modules/react/Item/ItemAssignToManager'
import {getEveryoneOption} from '@canvas/context-modules/differentiated-modules/react/Item/ItemAssignToTray'
import {forEach, map} from 'es-toolkit/compat'
import CardActions from '../util/differentiatedModulesCardActions'
import {string, func, array, number, oneOfType, bool} from 'prop-types'
import {
  sortedRowKeys,
  getAllOverridesFromCards,
  datesFromOverride,
  areCardsEqual,
  resetOverrides,
  cloneObject,
  getParsedOverrides,
  removeOverriddenAssignees,
  processModuleOverrides,
} from '../util/differentiatedModulesUtil'
import {markPeerReviewDefaultDates} from '@canvas/context-modules/differentiated-modules/utils/assignToHelper'
import {uid} from '@instructure/uid'
import DateValidator from '@canvas/grading/DateValidator'
import GradingPeriodsAPI from '@canvas/grading/jquery/gradingPeriodsApi'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('DueDateOverrideView')

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
}) => {
  // stagedCards are the itemAssignToCards that will be saved when the assignment is saved
  const [stagedCards, setStagedCardsInner] = useState([])
  // stagedOverrides represent individual overrides to a student/section/group/etc that will be submitted.
  const [stagedOverrides, setStagedOverridesInner] = useState(null)
  // The initial state of the overrides, used to determine if there are pending changes
  const [initialState, setInitialState] = useState(null)
  const [disabledOptionIds, setDisabledOptionIds] = useState([])
  const [stagedImportantDates, setStagedImportantDates] = useState(importantDates)
  const [hasModuleOverrides, setHasModuleOverrides] = useState(false)
  const [moduleAssignees, setModuleAssignees] = useState([])
  const [initialModuleOverrides, setInitialModuleOverrides] = useState([])
  const [unassignedOverrides, setUnassignedOverrides] = useState([])
  const [groupCategoryId, setGroupCategoryId] = useState(getGroupCategoryId?.())
  const dateValidator = useMemo(
    () =>
      new DateValidator({
        date_range: {...ENV.VALID_DATE_RANGE},
        hasGradingPeriods: ENV.HAS_GRADING_PERIODS,
        gradingPeriods: GradingPeriodsAPI.deserializePeriods(ENV.active_grading_periods),
        userIsAdmin: ENV.current_user_is_admin,
        postToSIS,
      }),
    [postToSIS],
  )

  const stagedCardsRef = useRef(stagedCards)

  const setStagedCards = cards => {
    stagedCardsRef.current = cards
    setStagedCardsInner(cards)
  }

  const stagedOverridesRef = useRef(stagedOverrides)

  const setStagedOverrides = newOverrides => {
    stagedOverridesRef.current = newOverrides
    setStagedOverridesInner(newOverrides)
  }

  const shouldRenderImportantDates = useMemo(
    () => type === 'assignment' || type === 'discussion' || type === 'quiz',
    [type],
  )

  // Helper function to detect if card structure has changed (not just dates)
  const hasStructuralChanges = useCallback((currentCards, newCards) => {
    if (!currentCards || !newCards) return true

    const currentKeys = Object.keys(currentCards)
    const newKeys = Object.keys(newCards)

    // Different number of cards
    if (currentKeys.length !== newKeys.length) return true

    // Different card IDs
    if (!currentKeys.every(key => newKeys.includes(key))) return true

    // Check if assignees have changed for any card
    for (const cardId of currentKeys) {
      const currentOverrides = currentCards[cardId]?.overrides || []
      const newOverrides = newCards[cardId]?.overrides || []

      // Different number of overrides
      if (currentOverrides.length !== newOverrides.length) return true

      // Check if assignee structure has changed (ignoring dates)
      const currentAssignees = currentOverrides.map(o => ({
        student_ids: o.student_ids?.sort(),
        course_section_id: o.course_section_id,
        group_id: o.group_id,
        course_id: o.course_id,
        noop_id: o.noop_id,
      }))

      const newAssignees = newOverrides.map(o => ({
        student_ids: o.student_ids?.sort(),
        course_section_id: o.course_section_id,
        group_id: o.group_id,
        course_id: o.course_id,
        noop_id: o.noop_id,
      }))

      if (JSON.stringify(currentAssignees) !== JSON.stringify(newAssignees)) {
        return true
      }
    }

    return false
  }, [])

  useEffect(() => {
    const newGroupCategoryId = getGroupCategoryId?.()
    if (newGroupCategoryId !== undefined && newGroupCategoryId !== groupCategoryId) {
      setGroupCategoryId(newGroupCategoryId)
    }
  }, [getGroupCategoryId, groupCategoryId])

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
    if (getGroupCategoryId !== undefined) return
    setGroupCategoryId(defaultGroupCategoryId)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [defaultGroupCategoryId])

  useEffect(() => {
    const updatedOverrides = overrides.map(override => {
      if (!override.stagedOverrideId) {
        return {
          ...override,
          stagedOverrideId: uid(),
        }
      }
      return override
    })
    if (stagedOverridesRef.current === null) {
      setStagedOverrides(updatedOverrides)
    }
  }, [overrides])

  useEffect(() => {
    if (stagedOverridesRef.current === null) return

    const parsedOverrides = getParsedOverrides(
      stagedOverridesRef.current,
      stagedCards,
      groupCategoryId,
      defaultSectionId,
    )
    const uniqueOverrides = removeOverriddenAssignees(overrides, parsedOverrides)

    // Only update stagedCards if the structure has actually changed
    // This prevents unnecessary rebuilds that lose dates during date-only updates
    if (initialState === null || hasStructuralChanges(stagedCards, uniqueOverrides)) {
      setStagedCards(uniqueOverrides)
    }
    if (initialState === null) {
      const state = cloneObject(uniqueOverrides)
      // initialState is set only 1 time to check if the overrides have pending changes
      setInitialState(state)
      // hasModuleOverrides, module assignees, and existing unassigned overrides are only set once since they don't change
      const unassigned = overrides.filter(override => override.unassign_item)
      setUnassignedOverrides(unassigned)
      let moduleOverrides = []
      for (const card in state) {
        moduleOverrides = moduleOverrides.concat(
          state[card].overrides.filter(o => o.context_module_id),
        )
      }
      setInitialModuleOverrides(moduleOverrides)

      setHasModuleOverrides(moduleOverrides.length > 0)
      const allModuleAssignees = overrides
        .filter(override => override.context_module_id)
        ?.map(moduleOverride => {
          if (moduleOverride.course_section_id) {
            return `section-${moduleOverride.course_section_id}`
          }
          if (moduleOverride.student_ids) {
            return moduleOverride.student_ids.map(id => `student-${id}`)
          }
          if (moduleOverride.group_id && moduleOverride.non_collaborative === true) {
            return `tag-${moduleOverride.group_id}`
          }
          return []
        })
        .flat()
      setModuleAssignees(allModuleAssignees)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [stagedOverrides, groupCategoryId])

  useEffect(() => {
    const newOverrides = getAllOverridesFromCards(stagedCardsRef.current).filter(
      card =>
        card.course_section_id ||
        card.student_ids ||
        card.noop_id ||
        card.course_id ||
        card.group_id,
    )

    const deletedModuleAssignees = moduleAssignees.filter(
      assignee => !disabledOptionIds.includes(assignee),
    )

    if (deletedModuleAssignees.length > 0) {
      const studentIds = deletedModuleAssignees
        .filter(assignee => assignee.includes('student'))
        ?.map(id => id.split('-')[1])
      if (studentIds.length > 0) {
        // Find existing unassigned override with matching student_ids
        const existingOverride = unassignedOverrides.find(override => {
          if (!override.student_ids) {
            return false
          }
          const existingIds = [...override.student_ids].sort()
          const newIds = [...studentIds].sort()
          return (
            existingIds.length === newIds.length &&
            existingIds.every((id, index) => id === newIds[index])
          )
        })
        newOverrides.push({
          id: existingOverride?.id,
          student_ids: studentIds,
          unassign_item: true,
          stagedOverrideId: uid(),
        })
      }
      const sectionIds = deletedModuleAssignees
        .filter(assignee => assignee.includes('section'))
        ?.map(id => id.split('-')[1])
      sectionIds.forEach(section => {
        // Find existing unassigned override for this section
        const existingOverride = unassignedOverrides.find(
          override => override.unassign_item && override.course_section_id === section,
        )
        newOverrides.push({
          id: existingOverride?.id,
          course_section_id: section,
          unassign_item: true,
          stagedOverrideId: uid(),
        })
      })
    }

    const withoutModuleOverrides = processModuleOverrides(newOverrides, initialModuleOverrides)
    resetOverrides(newOverrides, withoutModuleOverrides)

    const noModuleOverrides = newOverrides.filter(o => !o.context_module_id)
    const overridesWithDefaultDates = markPeerReviewDefaultDates(
      noModuleOverrides,
      defaultSectionId,
    )

    onSync(overridesWithDefaultDates, stagedImportantDates)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [stagedCards, stagedOverrides])

  const cards = useMemo(() => {
    const selectedOptionIds = []
    const everyoneOptionKey = getEveryoneOption(stagedCards?.length > 1).id
    const mappedCards = map(sortedRowKeys(stagedCards), cardId => {
      const defaultOptions = []
      const initialAssigneeOptions = []
      const card = stagedCards[cardId]
      const cardOverrides = card.overrides || []
      const dates = card.dates || {}
      cardOverrides.forEach(override => {
        if (override?.noop_id === '1') {
          defaultOptions.push('mastery_paths')
          selectedOptionIds.push(...defaultOptions)
        } else if (override?.course_section_id === defaultSectionId) {
          defaultOptions.push(everyoneOptionKey)
          selectedOptionIds.push(...defaultOptions)
        } else if (override?.course_id) {
          defaultOptions.push(everyoneOptionKey)
          selectedOptionIds.push(...defaultOptions)
        } else {
          const studentOverrides =
            override?.students?.map(student => ({
              id: `student-${student.id}`,
              value: student.name,
              group: 'Students',
            })) ?? []
          defaultOptions.push(...studentOverrides.map(student => student.id))
          initialAssigneeOptions.push(...studentOverrides)
          if (override?.course_section_id) {
            defaultOptions.push(`section-${override?.course_section_id}`)
            initialAssigneeOptions.push({
              id: `section-${override?.course_section_id}`,
              value: override?.title,
            })
          }
          if (override?.group_id && override?.non_collaborative === false) {
            defaultOptions.push(`group-${override?.group_id}`)
            initialAssigneeOptions.push({id: `group-${override?.group_id}`, value: override?.title})
          }
          if (override?.group_id && override?.non_collaborative === true) {
            defaultOptions.push(`tag-${override?.group_id}`)
            initialAssigneeOptions.push({id: `tag-${override?.group_id}`, value: override?.title})
          }
          selectedOptionIds.push(...defaultOptions)
        }
      })
      const uniqueIds = [...new Set(defaultOptions)]
      const preSavedCard = initialState[cardId]
      const isPersisted = areCardsEqual(preSavedCard, card)

      const data = {
        ...card,
        due_at: dates.due_at,
        unlock_at: dates.unlock_at,
        lock_at: dates.lock_at,
      }
      const dateErrors = dateValidator.validateDatetimes(data)
      return {
        key: cardId,
        isValid: uniqueIds.length > 0 && Object.keys(dateErrors).length === 0,
        highlightCard: !isPersisted,
        hasAssignees: uniqueIds.length > 0,
        due_at: dates.due_at,
        unlock_at: dates.unlock_at,
        reply_to_topic_due_at: dates.reply_to_topic_due_at,
        required_replies_due_at: dates.required_replies_due_at,
        peer_review_available_from: dates.peer_review_available_from,
        peer_review_available_to: dates.peer_review_available_to,
        peer_review_due_at: dates.peer_review_due_at,
        peer_review_override_id: dates.peer_review_override_id,
        lock_at: dates.lock_at,
        selectedAssigneeIds: uniqueIds,
        initialAssigneeOptions,
        defaultOptions: uniqueIds,
        overrideId: card.id,
        index: card.index,
        contextModuleId: cardOverrides[0]?.context_module_id,
        contextModuleName: cardOverrides[0]?.context_module_name,
      }
    })
    setDisabledOptionIds(selectedOptionIds)
    const sortedCards = mappedCards.sort((cardA, cardB) => cardA.index - cardB.index)

    return sortedCards
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [stagedCards])

  const generateCard = cardId => {
    const newCard = CardActions.handleAssigneeAdd({}, [], cardId, {})[0]
    delete newCard.student_ids
    delete newCard.students
    newCard.draft = true
    newCard.index = cardId
    const oldOverrides = getAllOverridesFromCards(stagedCardsRef.current).filter(
      card =>
        card.course_section_id ||
        card.student_ids ||
        card.noop_id ||
        card.course_id ||
        card.group_id,
    )
    const newStageOverrides = [...oldOverrides, newCard]
    setStagedOverrides(newStageOverrides)
  }

  const handleCardRemove = cardId => {
    const newStagedCards = {...stagedCardsRef.current}
    delete newStagedCards[cardId]
    setStagedCards(newStagedCards)

    const newStagedOverrides = stagedOverridesRef.current.filter(
      override => override.rowKey.toString() !== cardId,
    )
    setStagedOverrides(newStagedOverrides)
  }

  const updateCard = (cardId, newOverrides, cardDates) => {
    const tmp = {}
    const dates = cardDates || datesFromOverride(newOverrides[0])
    const currentIndex = stagedCardsRef.current[cardId]?.index
    tmp[cardId] = {overrides: newOverrides, dates, index: currentIndex}

    const newCards = {...stagedCardsRef.current, ...tmp}
    setStagedCards(newCards)
  }

  const addOverride = () => {
    const lastCard = cards.at(-1)
    generateCard(lastCard ? lastCard.index + 1 : 1)
  }

  const handleChange = (cardId, newAssignee, deletedAssignees) => {
    // Cards without assignees are empty objects
    // ui/shared/context-modules/differentiated-modules/react/Item/ItemAssignToManager.tsx
    if (Object.keys(newAssignee).length > 0) {
      handleAssigneeAddition(cardId, newAssignee)
    }
    if (deletedAssignees.length > 0) {
      forEach(deletedAssignees, deleted => {
        handleAssigneeDeletion(cardId, deleted)
      })
    }
  }

  const handleDatesUpdate = (cardId, dateType, newDate) => {
    const card = {...stagedCardsRef.current[cardId]}
    const oldOverrides = card.overrides || []
    const oldDates = card.dates || {} // Ensure oldDates is never undefined
    const date = newDate === '' ? null : newDate

    const initialModuleOverrideState = initialModuleOverrides.find(obj => obj.rowKey === cardId)

    const newDates = {...oldDates, [dateType]: date}
    const hasDates = !Object.values(newDates).every(
      value => value === null || value === undefined || value === '',
    )

    const newOverrides = oldOverrides.map(override => {
      return {
        ...override,
        [dateType]: date,
        [`${dateType}_overridden`]: !!date,
        context_module_id: hasDates ? null : initialModuleOverrideState?.context_module_id,
        context_module_name: hasDates ? null : initialModuleOverrideState?.context_module_name,
      }
    })

    updateCard(cardId, newOverrides, newDates)

    // Ensure stagedOverridesRef stays in sync with stagedCards
    const updatedStagedOverrides = stagedOverridesRef.current.map(override => {
      if (override.rowKey === cardId || override.rowKey === cardId.toString()) {
        return {
          ...override,
          [dateType]: date,
          [`${dateType}_overridden`]: !!date,
          context_module_id: hasDates ? null : initialModuleOverrideState?.context_module_id,
          context_module_name: hasDates ? null : initialModuleOverrideState?.context_module_name,
        }
      }
      return override
    })

    setStagedOverrides(updatedStagedOverrides)
  }

  const handleAssigneeAddition = (cardId, newAssignee) => {
    const targetedItemCard = stagedCardsRef.current[cardId]
    // returns all new overrides
    const newOverridesForCard = CardActions.handleAssigneeAdd(
      newAssignee,
      targetedItemCard?.overrides ?? {},
      cardId,
      targetedItemCard.dates,
    )
    // The last override is the new one
    let newOverride = {...newOverridesForCard[newOverridesForCard.length - 1]}
    // handleTokenAdd can either return an object or a backbone model. We convert it here

    newOverride = cloneObject(newOverride.attributes || newOverride || {})
    newOverride.stagedOverrideId = newOverride.stagedOverrideId
      ? newOverride.stagedOverrideId
      : uid()

    // Create a copy of the stagedOverrides array
    const updatedOverrides = [...stagedOverridesRef.current]

    // Check if stagedOverrides contains an object with the same stagedOverrideId
    const existingOverrideIndex = updatedOverrides.findIndex(
      override => override.stagedOverrideId === newOverride.stagedOverrideId,
    )

    if (existingOverrideIndex !== -1) {
      // If it contains an object with the same stagedOverrideId, replace it with the new override
      updatedOverrides[existingOverrideIndex] = newOverride
    } else {
      // If it does not contain an object with the same stagedOverrideId, add the new override to the stagedOverrides
      updatedOverrides.push(newOverride)
    }

    setStagedOverrides(updatedOverrides)
  }

  const handleAssigneeDeletion = (cardId, tokenToRemove) => {
    const targetedItemCard = stagedCardsRef.current[cardId]
    // These are unique overrides that are not associated with the card currently being edited
    const nonTargetedOverrides = getAllOverridesFromCards(stagedCardsRef.current).filter(
      override => override.rowKey !== cardId,
    )

    const targetedItemCardOverrides = targetedItemCard?.overrides ?? {}
    // Remote the override
    let remainingCardOverrides = CardActions.handleAssigneeRemove(
      tokenToRemove,
      targetedItemCardOverrides,
    )

    if (remainingCardOverrides.length === 0) {
      const existingOverrideData = targetedItemCardOverrides[0]

      // Delete all properties that are related to assignees
      delete existingOverrideData.student_ids
      delete existingOverrideData.students
      delete existingOverrideData.course_section_id
      delete existingOverrideData.group_id
      delete existingOverrideData.noop_id
      delete existingOverrideData.course_id
      delete existingOverrideData.context_module_id
      delete existingOverrideData.context_module_name
      remainingCardOverrides = [existingOverrideData]
    }

    // add the newOverride to the statedOverrides. then remove duplicates
    const uniqueOverrides = Object.values(
      [...remainingCardOverrides, ...nonTargetedOverrides].reduce((uniqueMap, override) => {
        uniqueMap[override.stagedOverrideId] = override
        return uniqueMap
      }, {}),
    )

    setStagedOverrides(uniqueOverrides)
  }

  const handleImportantDatesChange = useCallback(
    event => {
      const newImportantDatesValue = event.target.checked
      onSync(undefined, newImportantDatesValue)
      setStagedImportantDates(newImportantDatesValue)
    },
    [onSync],
  )

  const importantDatesCheckbox = useCallback(() => {
    if (supportDueDates && (ENV.K5_SUBJECT_COURSE || ENV.K5_HOMEROOM_COURSE)) {
      const disabled = !Object.values(stagedCardsRef?.current)?.some(
        override => override?.dates?.due_at,
      )
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
    return null
  }, [handleImportantDatesChange, supportDueDates, stagedImportantDates])

  return (
    <View as="div" padding="x-small 0 0 0">
      {shouldRenderImportantDates && importantDatesCheckbox()}
      <ItemAssignToManager
        courseId={ENV.COURSE_ID}
        itemType={type}
        itemContentId={type === 'discussion' ? discussionId : assignmentId}
        initHasModuleOverrides={hasModuleOverrides}
        defaultGroupCategoryId={groupCategoryId}
        useApplyButton={true}
        locale={ENV.LOCALE || 'en'}
        timezone={ENV.TIMEZONE || 'UTC'}
        defaultCards={cards}
        defaultSectionId={defaultSectionId}
        defaultDisabledOptionIds={disabledOptionIds}
        onAddCard={addOverride}
        onAssigneesChange={handleChange}
        onDatesChange={handleDatesUpdate}
        onCardRemove={handleCardRemove}
        removeDueDateInput={!supportDueDates}
        isCheckpointed={isCheckpointed}
        postToSIS={postToSIS}
        isTray={false}
        setOverrides={setOverrides}
      />
    </View>
  )
}

AssignToContent.propTypes = {
  onSync: func.isRequired,
  assignmentId: string,
  type: string.isRequired,
  overrides: array.isRequired,
  defaultSectionId: oneOfType([number, string]),
  importantDates: bool,
  getGroupCategoryId: func,
  defaultGroupCategoryId: string,
  supportDueDates: bool,
  isCheckpointed: bool,
  postToSIS: bool,
}

export default AssignToContent
