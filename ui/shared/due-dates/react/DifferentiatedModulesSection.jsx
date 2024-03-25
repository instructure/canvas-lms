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
import TokenActions from './TokenActions'
import { string, func, array, number, oneOfType, bool } from 'prop-types'
import {uid} from '@instructure/uid'
import {Pill} from '@instructure/ui-pill'
import {
  sortedRowKeys,
  getAllOverrides,
  datesFromOverride,
  areCardsEqual,
  resetOverrides,
  cloneObject,
  getParsedOverrides,
  resetStagedCards,
  removeOverriddenAssignees,
  processModuleOverrides,
} from "../util/overridesUtils";

const I18n = useI18nScope('DueDateOverrideView')


const DifferentiatedModulesSection = ({
  onSync,
  assignmentName,
  assignmentId,
  type,
  pointsPossible,
  overrides,
  defaultSectionId,
  importantDates,
  onTrayOpen,
  onTrayClose,
}) => {
  const [open, setOpen] = useState(false)
  const [stagedCards, setStagedCards] = useState([])
  const [stagedOverrides, setStagedOverrides] = useState(null)
  const [preSavedOverrides, setPreSavedOverrides] = useState(null)
  const [initialState, setInitialState] = useState(null);
  const [checkPoint, setCheckPoint] = useState(null)
  const [showPendingChangesPill, setShowPendingChangesPill] = useState(false);
  const [disabledOptionIds, setDisabledOptionIds] = useState([])
  const [stagedImportantDates, setStagedImportantDates] = useState(importantDates)
  const linkRef = useRef()

  useEffect(()=>{
    overrides.forEach(override => override.set('stagedOverrideId', uid()))
    setStagedOverrides(overrides);
  },[overrides])

  useEffect(() => {
    if(stagedOverrides === null) return

    const parsedOverrides = getParsedOverrides(stagedOverrides, stagedCards)
    const uniqueOverrides = removeOverriddenAssignees(overrides, parsedOverrides)
    setStagedCards(uniqueOverrides)
    if(initialState === null){
      const state = cloneObject(uniqueOverrides);
      // initialState is set only 1 time to check if the overrides have pending changes 
      setInitialState(state)
      // checkPoint is set every time the user applies changes to the overrides
      setCheckPoint(state)
    }
    if(preSavedOverrides === null){
      setPreSavedOverrides(cloneObject(overrides))
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [stagedOverrides])

  const cards = useMemo(() => {
    let selectedOptionIds = []
    const everyoneOptionKey = getEveryoneOption(stagedCards?.length > 1).id
    const cards = map(sortedRowKeys(stagedCards), cardId => {
      let defaultOptions = []
      const row = stagedCards[cardId]
      const rowOverrides = row.overrides || []
      const dates = row.dates || {}
      rowOverrides.forEach(override => {
        if (override?.attributes?.noop_id === "1") {
          defaultOptions.push('mastery_paths')
          selectedOptionIds.push(...defaultOptions)
        } else if (override?.attributes?.course_section_id === defaultSectionId) {
          row.index = 0
          defaultOptions.push(everyoneOptionKey)
          selectedOptionIds.push(...defaultOptions)
        } else {
          const studentOverrides =
            override?.attributes?.student_ids?.map(studentId => `student-${studentId}`) ?? []
          defaultOptions.push(...studentOverrides)
          if (override?.attributes?.course_section_id) {
            defaultOptions.push(`section-${override.attributes.course_section_id}`)
          }
          selectedOptionIds.push(...defaultOptions)
        }
      })
      const uniqueIds = [...new Set(defaultOptions)]
      const preSavedCard = initialState[cardId]
      const isPersisted = areCardsEqual(preSavedCard, row)
      return {
        key: cardId,
        isValid: uniqueIds.length > 0,
        highlightCard: !isPersisted,
        hasAssignees: uniqueIds.length > 0,
        due_at: dates.due_at,
        unlock_at: dates.unlock_at,
        lock_at: dates.lock_at,
        selectedAssigneeIds: uniqueIds,
        defaultOptions: uniqueIds,
        overrideId: row.id,
        index: row.index,
        contextModuleId: rowOverrides[0]?.attributes?.context_module_id,
        contextModuleName: rowOverrides[0]?.attributes?.context_module_name
      }
    })
    setDisabledOptionIds(selectedOptionIds)
    const sortedCards = cards.sort((cardA, cardB) => cardA.index - cardB.index)

    return sortedCards
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [stagedCards])

  const handleOpen = useCallback(() => {
    setOpen(true)
    onTrayOpen?.()
  }, [onTrayOpen])

  useEffect(()=>{
    if(!open && ![undefined, null].includes(initialState)){
      const hasChanges = cards.some(({highlightCard}) => highlightCard) || cards.length < Object.entries(initialState).length
      setShowPendingChangesPill(hasChanges)
    }
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
    const preSaved = stagedOverrides.filter(o => preSavedOverrides.find(({assignment_override}) => o.attributes.stagedOverrideId === assignment_override.stagedOverrideId))
    const defaultState = getParsedOverrides(preSaved, checkPoint)
    const checkPointOverrides = getAllOverrides(defaultState).filter(
      row => row.attributes.course_section_id || row.attributes.student_ids || row.attributes.noop_id
    )
    setStagedOverrides(checkPointOverrides);
    const newStagedCards = resetStagedCards(stagedCards, checkPoint, defaultState)
    setStagedCards(newStagedCards)
    linkRef.current.focus()
  }

  const generateCard = (cardId, newOverrides, rowDates) => {
    const newRow = TokenActions.handleTokenAdd({}, newOverrides, cardId, rowDates)[0]
    delete newRow.attributes.student_ids
    newRow.draft = true
    newRow.index = stagedOverrides.length + 1
    const oldOverrides = getAllOverrides(stagedCards).filter(
      row => row.attributes.course_section_id || row.attributes.student_ids || row.attributes.noop_id
    )
    const newStageOverrides = [...oldOverrides, newRow]
    setStagedOverrides(newStageOverrides)
  }

  const handleCardRemove = cardId => {
    const newStagedCards = {...stagedCards}
    delete newStagedCards[cardId]
    setStagedCards(newStagedCards)
  }

  const updateRow = (cardId, newOverrides, rowDates) => {
    const tmp = {}
    const dates = rowDates || datesFromOverride(newOverrides[0])
    const currentIndex = stagedCards[cardId]?.index
    tmp[cardId] = {overrides: newOverrides, dates, index: currentIndex}

    const newRows = _.extend({...stagedCards}, tmp)
    setStagedCards(newRows)
  }

  const addOverride = () => {
    const cardsCount = stagedOverrides.length + 1
    generateCard(cardsCount, [], {})
  }

  const handleChange = (cardId, newAssignee, deletedAssignees) => {
    if (newAssignee) {
      handleAssigneeAddition(cardId, newAssignee)
    }
    if (deletedAssignees.length > 0) {
      forEach(deletedAssignees, deleted => {
        handleAssigneeDeletion(cardId, deleted)
      })
    }
  }

  const handleDatesUpdate = (cardId, dateType, newDate) => {
    const row = {...stagedCards[cardId]}
    const oldOverrides = row.overrides
    const oldDates = row.dates
    const date = newDate === "" ? null : newDate

    const newOverrides = map(oldOverrides, override => {
      override.set(dateType, date)
      return override
    })

    const tmp = {}
    tmp[dateType] = date
    const newDates = _.extend(oldDates, tmp)

    updateRow(cardId, newOverrides, newDates)
  }

  const handleAssigneeAddition = (cardId, newToken) => {
    const row = stagedCards[cardId]
    const newOverridesForRow = TokenActions.handleTokenAdd(
      newToken,
      row?.overrides ?? {},
      cardId,
      row.dates
    )
    const newOverride = newOverridesForRow[newOverridesForRow.length - 1]
    newOverride.set('stagedOverrideId', uid())
    const uniqueOverrides = [...new Set([...stagedOverrides, newOverride])]

    setStagedOverrides(uniqueOverrides)
  }

  const handleAssigneeDeletion = (cardId, tokenToRemove) => {
    const row = stagedCards[cardId]
    const tmpOverrides = getAllOverrides(stagedCards).filter(({attributes}) => attributes.rowKey !== cardId)
    let newCardOverrides = TokenActions.handleTokenRemove(tokenToRemove, row?.overrides ?? {})
    if (newCardOverrides.length === 0) {
      const emptyRow = TokenActions.handleTokenAdd({}, newCardOverrides, cardId, row.dates)[0]
      delete emptyRow.attributes.student_ids
      emptyRow.index = row.index
      newCardOverrides = [emptyRow]
    }

    setStagedOverrides([...tmpOverrides, ...newCardOverrides])
  }

  const handleSave = () => {
    const newOverrides = getAllOverrides(stagedCards).filter(
      row => row.attributes.course_section_id || row.attributes.student_ids || row.attributes.noop_id
    )
    const withoutModuleOverrides = processModuleOverrides(newOverrides, checkPoint)
    resetOverrides(newOverrides, withoutModuleOverrides)

    setStagedOverrides(newOverrides)
    setPreSavedOverrides(cloneObject(newOverrides))
    setCheckPoint(cloneObject(stagedCards))
    onSync(newOverrides, stagedImportantDates)
    handleClose(false)
  }

  const handleImportantDatesChange = event => {
    const newImportantDatesValue = event.target.checked
    onSync(undefined, newImportantDatesValue)
    setStagedImportantDates(newImportantDatesValue)
  }

  const imporantDatesCheckbox = () => {
    if (ENV.K5_SUBJECT_COURSE || ENV.K5_HOMEROOM_COURSE) {
      const disabled = !preSavedOverrides?.some(
        ({assignment_override}) => assignment_override.due_at
      )
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
  }

  return (
    <>
      <View display="flex">
        <View as="div" margin="medium none" width="25px">
          <IconEditLine size="x-small" color="primary" />
        </View>
        <Link
          margin="medium none"
          data-testid="manage-assign-to"
          isWithinText={false}
          ref={ref => (linkRef.current = ref)}
          onClick={() => (open ? handleClose() : handleOpen())}
        >
          <View as="div">
            {I18n.t('Manage Assign To')}
            {showPendingChangesPill && <Pill data-testid="pending_changes_pill" color="info" margin="auto small">
                    {I18n.t('Pending Changes')}
                </Pill>}
          </View>
        </Link>
      </View>
      {type === 'assignment' && imporantDatesCheckbox()}
      <ItemAssignToTray
        open={open}
        onClose={handleClose}
        onDismiss={handleDismiss}
        courseId={ENV.COURSE_ID}
        itemName={assignmentName}
        itemType={type}
        iconType={type}
        itemContentId={assignmentId}
        pointsPossible={pointsPossible}
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
      />
    </>
  )
}

DifferentiatedModulesSection.propTypes = {
  onSync: func.isRequired,
  assignmentName: string.isRequired,
  assignmentId: string.isRequired,
  type: string.isRequired,
  pointsPossible: oneOfType([number, string]),
  overrides: array.isRequired,
  defaultSectionId: oneOfType([number, string]),
  importantDates: bool,
  onTrayOpen: func,
  onTrayClose: func,
}
export default DifferentiatedModulesSection
