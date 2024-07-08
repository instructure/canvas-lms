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
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'
import {Checkbox} from '@instructure/ui-checkbox'
import {useScope as useI18nScope} from '@canvas/i18n'
import ItemAssignToTray, {
  getEveryoneOption,
} from '@canvas/context-modules/differentiated-modules/react/Item/ItemAssignToTray'
import {IconEditLine} from '@instructure/ui-icons'
import _ from 'underscore'
import {forEach, map} from 'lodash'
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
  resetStagedCards,
  removeOverriddenAssignees,
  processModuleOverrides,
} from '../util/differentiatedModulesUtil'
import {uid} from '@instructure/uid'
import {Pill} from '@instructure/ui-pill'
import DateValidator from '@canvas/grading/DateValidator'
import GradingPeriodsAPI from '@canvas/grading/jquery/gradingPeriodsApi'

const I18n = useI18nScope('DueDateOverrideView')

const DifferentiatedModulesSection = ({
  onSync,
  getAssignmentName,
  assignmentId,
  getGroupCategoryId,
  type,
  getPointsPossible,
  overrides,
  defaultSectionId,
  importantDates,
  onTrayOpen,
  onTrayClose,
  supportDueDates = true,
  isCheckpointed,
  postToSIS = false,
}) => {
  const [open, setOpen] = useState(false)
  // stagedCards are the itemAssignToCards that will be saved when the assignment is saved
  const [stagedCards, setStagedCards] = useState([])
  // stagedOverrides represent individual overrides to a student/section/group/etc that will be submitted.
  const [stagedOverrides, setStagedOverrides] = useState(null)
  // preSavedOverrides are the state of the overrides as they are displayed and edited in the tray. Canceling the tray
  // Will causes these to reset to the last stagedOverrides
  const [preSavedOverrides, setPreSavedOverrides] = useState(null)
  // The initial state of the overrides, used to determine if there are pending changes
  const [initialState, setInitialState] = useState(null)
  // set every time the user clicks apply to the overrides
  const [checkPoint, setCheckPoint] = useState(null)
  const [showPendingChangesPill, setShowPendingChangesPill] = useState(false)
  const [disabledOptionIds, setDisabledOptionIds] = useState([])
  const [stagedImportantDates, setStagedImportantDates] = useState(importantDates)
  const [hasModuleOverrides, setHasModuleOverrides] = useState(false)
  const [moduleAssignees, setModuleAssignees] = useState([])
  const linkRef = useRef()
  const dateValidator = useMemo(
    () =>
      new DateValidator({
        date_range: {...ENV.VALID_DATE_RANGE},
        hasGradingPeriods: ENV.HAS_GRADING_PERIODS,
        gradingPeriods: GradingPeriodsAPI.deserializePeriods(ENV.active_grading_periods),
        userIsAdmin: ENV.current_user_is_admin,
        postToSIS,
      }),
    [postToSIS]
  )

  const shouldRenderImportantDates = useMemo(
    () => type === 'assignment' || type === 'discussion' || type === 'quiz',
    [type]
  )

  const formData = useMemo(
    () => ({
      assignmentName: getAssignmentName(),
      pointsPossible: getPointsPossible(),
      groupCategoryId: getGroupCategoryId?.(),
    }),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [open]
  )

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
    setStagedOverrides(updatedOverrides)
  }, [overrides])

  useEffect(() => {
    if (stagedOverrides === null) return
    const parsedOverrides = getParsedOverrides(
      stagedOverrides,
      stagedCards,
      formData.groupCategoryId
    )
    const uniqueOverrides = removeOverriddenAssignees(overrides, parsedOverrides)
    setStagedCards(uniqueOverrides)
    if (initialState === null) {
      const state = cloneObject(uniqueOverrides)
      // initialState is set only 1 time to check if the overrides have pending changes
      setInitialState(state)
      // hasModuleOverrides and module assignees are only set once since they don't change
      setHasModuleOverrides(overrides.some(card => card.context_module_id))
      const allModuleAssignees = overrides
        .filter(override => override.context_module_id)
        ?.map(moduleOverride => {
          if (moduleOverride.course_section_id) {
            return `section-${moduleOverride.course_section_id}`
          }
          if (moduleOverride.student_ids) {
            return moduleOverride.student_ids.map(id => `student-${id}`)
          }
        })
        .flat()
      setModuleAssignees(allModuleAssignees)
      // checkPoint is set every time the user applies changes to the overrides
      setCheckPoint(state)
    }
    if (preSavedOverrides === null) {
      setPreSavedOverrides(cloneObject(stagedOverrides))
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [stagedOverrides, formData.groupCategoryId])

  const cards = useMemo(() => {
    const selectedOptionIds = []
    const everyoneOptionKey = getEveryoneOption(stagedCards?.length > 1).id
    const mappedCards = map(sortedRowKeys(stagedCards), cardId => {
      const defaultOptions = []
      const card = stagedCards[cardId]
      const cardOverrides = card.overrides || []
      const dates = card.dates || {}
      cardOverrides.forEach(override => {
        if (override?.noop_id === '1') {
          defaultOptions.push('mastery_paths')
          selectedOptionIds.push(...defaultOptions)
        } else if (override?.course_section_id === defaultSectionId) {
          card.index = 0
          defaultOptions.push(everyoneOptionKey)
          selectedOptionIds.push(...defaultOptions)
        } else if (override?.course_id) {
          defaultOptions.push(everyoneOptionKey)
          selectedOptionIds.push(...defaultOptions)
        } else {
          const studentOverrides =
            override?.student_ids?.map(studentId => `student-${studentId}`) ?? []
          defaultOptions.push(...studentOverrides)
          if (override?.course_section_id) {
            defaultOptions.push(`section-${override?.course_section_id}`)
          }
          if (override?.group_id) {
            defaultOptions.push(`group-${override?.group_id}`)
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
        lock_at: dates.lock_at,
        selectedAssigneeIds: uniqueIds,
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

  const handleOpen = useCallback(() => {
    if (onTrayOpen !== undefined) {
      if (!onTrayOpen()) return
    }
    setOpen(true)
  }, [onTrayOpen])

  useEffect(() => {
    if (!open && ![undefined, null].includes(initialState)) {
      const hasChanges =
        cards.some(({highlightCard}) => highlightCard) ||
        cards.length < Object.entries(initialState).length
      setShowPendingChangesPill(hasChanges)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [cards, open])

  const handleClose = useCallback(() => {
    setOpen(false)
    onTrayClose?.()
  }, [onTrayClose])

  const handleDismiss = () => {
    handleClose()
    // revert changes in the overrides of the page
    resetOverrides(overrides, preSavedOverrides)
    // revert changes in the tray cards
    const preSaved = stagedOverrides.filter(o =>
      preSavedOverrides.find(override => o.stagedOverrideId === override.stagedOverrideId)
    )
    const defaultState = getParsedOverrides(preSaved, checkPoint)
    const checkPointOverrides = getAllOverridesFromCards(defaultState).filter(
      card =>
        card.course_section_id ||
        card.student_ids ||
        card.noop_id ||
        card.course_id ||
        card.group_id
    )
    setStagedOverrides(checkPointOverrides)
    const newStagedCards = resetStagedCards(stagedCards, checkPoint, defaultState)
    setStagedCards(newStagedCards)
    linkRef.current.focus()
  }

  const generateCard = cardId => {
    const newCard = CardActions.handleAssigneeAdd({}, [], cardId, {})[0]
    delete newCard.student_ids
    newCard.draft = true
    newCard.index = stagedOverrides.length + 1
    const oldOverrides = getAllOverridesFromCards(stagedCards).filter(
      card =>
        card.course_section_id ||
        card.student_ids ||
        card.noop_id ||
        card.course_id ||
        card.group_id
    )
    const newStageOverrides = [...oldOverrides, newCard]
    setStagedOverrides(newStageOverrides)
  }

  const handleCardRemove = cardId => {
    const newStagedCards = {...stagedCards}
    delete newStagedCards[cardId]
    setStagedCards(newStagedCards)

    const newStagedOverrides = stagedOverrides.filter(override => override.rowKey !== cardId)
    setStagedOverrides(newStagedOverrides)
  }

  const updateCard = (cardId, newOverrides, cardDates) => {
    const tmp = {}
    const dates = cardDates || datesFromOverride(newOverrides[0])
    const currentIndex = stagedCards[cardId]?.index
    tmp[cardId] = {overrides: newOverrides, dates, index: currentIndex}

    const newCards = _.extend({...stagedCards}, tmp)
    setStagedCards(newCards)
  }

  const addOverride = () => {
    const cardsCount = stagedOverrides.length + 1
    generateCard(cardsCount)
  }

  const handleChange = (cardId, newAssignee, deletedAssignees) => {
    // Cards without assignees are emty objects
    // ui/shared/context-modules/differentiated-modules/react/Item/ItemAssignToTray.tsx
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
    const card = {...stagedCards[cardId]}
    const oldOverrides = card.overrides || []
    const oldDates = card.dates
    const date = newDate === '' ? null : newDate

    const newOverrides = oldOverrides.map(override => {
      return {
        ...override,
        [dateType]: date,
        [`${dateType}_overridden`]: !!date,
      }
    })

    const tmp = {}
    tmp[dateType] = date
    const newDates = _.extend(oldDates, tmp)

    updateCard(cardId, newOverrides, newDates)

    const updatedOverrides = [...stagedOverrides]
    updatedOverrides.forEach(override => {
      if (String(override.rowKey) === String(cardId)) {
        override[dateType] = newDate
      }
    })
    setStagedOverrides(updatedOverrides)
  }

  const handleAssigneeAddition = (cardId, newAssignee) => {
    const targetedItemCard = stagedCards[cardId]
    // returns all new overrides
    const newOverridesForCard = CardActions.handleAssigneeAdd(
      newAssignee,
      targetedItemCard?.overrides ?? {},
      cardId,
      targetedItemCard.dates
    )
    // The last override is the new one
    let newOverride = {...newOverridesForCard[newOverridesForCard.length - 1]}
    // handleTokenAdd can either return an object or a backbone model. We convert it here

    newOverride = cloneObject(newOverride.attributes || newOverride || {})
    newOverride.stagedOverrideId = newOverride.stagedOverrideId
      ? newOverride.stagedOverrideId
      : uid()

    // Create a copy of the stagedOverrides array
    const updatedOverrides = [...stagedOverrides]

    // Check if stagedOverrides contains an object with the same stagedOverrideId
    const existingOverrideIndex = updatedOverrides.findIndex(
      override => override.stagedOverrideId === newOverride.stagedOverrideId
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
    const targetedItemCard = stagedCards[cardId]
    // These are unique overrides that are not associated with the card currently being edited
    const nonTargetedOverrides = getAllOverridesFromCards(stagedCards).filter(
      override => override.rowKey !== cardId
    )

    const targetedItemCardOverrides = targetedItemCard?.overrides ?? {}
    // Remote the override
    let remainingCardOverrides = CardActions.handleAssigneeRemove(
      tokenToRemove,
      targetedItemCardOverrides
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
      remainingCardOverrides = [existingOverrideData]
    }

    // add the newOverride to the statedOverrides. then remove duplicates
    const uniqueOverrides = Object.values(
      [...remainingCardOverrides, ...nonTargetedOverrides].reduce((uniqueMap, override) => {
        uniqueMap[override.stagedOverrideId] = override
        return uniqueMap
      }, {})
    )

    setStagedOverrides(uniqueOverrides)
  }

  const handleSave = () => {
    const newOverrides = getAllOverridesFromCards(stagedCards).filter(
      card =>
        card.course_section_id ||
        card.student_ids ||
        card.noop_id ||
        card.course_id ||
        card.group_id
    )

    const deletedModuleAssignees = moduleAssignees.filter(
      assignee => !disabledOptionIds.includes(assignee)
    )

    if (deletedModuleAssignees.length > 0) {
      const studentIds = deletedModuleAssignees
        .filter(assignee => assignee.includes('student'))
        ?.map(id => id.split('-')[1])
      if (studentIds.length > 0) {
        newOverrides.push({
          id: undefined,
          student_ids: studentIds,
          unassign_item: true,
        })
      }
      const sectionIds = deletedModuleAssignees
        .filter(assignee => assignee.includes('section'))
        ?.map(id => id.split('-')[1])
      sectionIds.forEach(section => {
        newOverrides.push({
          id: undefined,
          course_section_id: section,
          unassign_item: true,
        })
      })
    }

    const withoutModuleOverrides = processModuleOverrides(newOverrides, checkPoint)
    resetOverrides(newOverrides, withoutModuleOverrides)

    setStagedOverrides(newOverrides)
    setPreSavedOverrides(cloneObject(newOverrides))
    setCheckPoint(cloneObject(stagedCards))
    onSync(newOverrides, stagedImportantDates)
    handleClose(false)
  }

  const handleImportantDatesChange = useCallback(
    event => {
      const newImportantDatesValue = event.target.checked
      onSync(undefined, newImportantDatesValue)
      setStagedImportantDates(newImportantDatesValue)
    },
    [onSync]
  )

  const importantDatesCheckbox = useCallback(() => {
    if (supportDueDates && (ENV.K5_SUBJECT_COURSE || ENV.K5_HOMEROOM_COURSE)) {
      const disabled = !preSavedOverrides?.some(override => override.due_at)
      const checked = !disabled && stagedImportantDates
      return (
        <div id="important-dates">
          <Checkbox
            label={I18n.t('Mark as important date and show on homeroom sidebar')}
            name="important_dates"
            data-testid="important_dates"
            size="small"
            value={checked ? 1 : 0}
            checked={checked}
            onChange={handleImportantDatesChange}
            disabled={disabled}
            inline={true}
          />
        </div>
      )
    }
  }, [handleImportantDatesChange, preSavedOverrides, supportDueDates, stagedImportantDates])

  return (
    <>
      <View display="flex">
        <View as="div" margin="medium none" width="25px">
          <IconEditLine size="x-small" color="primary" />
        </View>
        <Link
          id="manage-assign-to"
          margin="medium none"
          data-testid="manage-assign-to"
          isWithinText={false}
          ref={ref => (linkRef.current = ref)}
          onClick={() => (open ? handleClose() : handleOpen())}
        >
          <View as="div">
            {I18n.t('Manage Assign To')}
            {showPendingChangesPill && (
              <Pill data-testid="pending_changes_pill" color="info" margin="auto small">
                {I18n.t('Pending Changes')}
              </Pill>
            )}
          </View>
        </Link>
      </View>
      {shouldRenderImportantDates && importantDatesCheckbox()}
      <ItemAssignToTray
        open={open}
        onClose={handleClose}
        onDismiss={handleDismiss}
        courseId={ENV.COURSE_ID}
        itemName={formData.assignmentName}
        itemType={type}
        iconType={type}
        itemContentId={assignmentId}
        initHasModuleOverrides={hasModuleOverrides}
        pointsPossible={formData.pointsPossible}
        defaultGroupCategoryId={formData.groupCategoryId}
        useApplyButton={true}
        locale={ENV.LOCALE || 'en'}
        timezone={ENV.TIMEZONE || 'UTC'}
        defaultCards={cards}
        defaultSectionId={defaultSectionId}
        defaultDisabledOptionIds={disabledOptionIds}
        onSave={handleSave}
        onAddCard={addOverride}
        onAssigneesChange={handleChange}
        onDatesChange={handleDatesUpdate}
        onCardRemove={handleCardRemove}
        removeDueDateInput={!supportDueDates}
        isCheckpointed={isCheckpointed}
        postToSIS={postToSIS}
      />
    </>
  )
}

DifferentiatedModulesSection.propTypes = {
  onSync: func.isRequired,
  getAssignmentName: func.isRequired,
  assignmentId: string,
  type: string.isRequired,
  getPointsPossible: func.isRequired,
  overrides: array.isRequired,
  defaultSectionId: oneOfType([number, string]),
  importantDates: bool,
  getGroupCategoryId: func,
  onTrayOpen: func,
  onTrayClose: func,
  supportDueDates: bool,
  isCheckpointed: bool,
  postToSIS: bool,
}

export default DifferentiatedModulesSection
