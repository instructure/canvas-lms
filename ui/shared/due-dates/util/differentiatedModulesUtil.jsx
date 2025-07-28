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

import React from 'react'
import _ from 'underscore'
import {map} from 'lodash'
import {getOverriddenAssignees} from '@canvas/context-modules/differentiated-modules/utils/assignToHelper'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {View} from '@instructure/ui-view'
import {Link} from '@instructure/ui-link'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconEditLine} from '@instructure/ui-icons'

const I18n = createI18nScope('DueDateOverrideView')

export const cloneObject = object => JSON.parse(JSON.stringify(object))

export const combinedDates = override => {
  const overrideId = override.id == null ? '0' : override.id
  const dueAt = override.due_at == null ? '' : override.due_at
  const unlockAt = override.unlock_at == null ? '' : override.unlock_at
  const lockAt = override.lock_at == null ? '' : override.lock_at

  return `${dueAt}${unlockAt}${lockAt}${overrideId}`
}

export const sortedRowKeys = rows => {
  const {datedKeys, numberedKeys} = _.chain(rows)
    .keys()
    .groupBy(key => (key.length > 11 ? 'datedKeys' : 'numberedKeys'))
    .value()
  return _.chain([datedKeys, numberedKeys]).flatten().compact().value()
}

export const datesFromOverride = override => ({
  due_at: override ? override.due_at : null,
  lock_at: override ? override.lock_at : null,
  unlock_at: override ? override.unlock_at : null,
  reply_to_topic_due_at: override ? override.reply_to_topic_due_at : null,
  required_replies_due_at: override ? override.required_replies_due_at : null,
})

export const getAllOverridesFromCards = givenCards => {
  const cards = givenCards
  return _.chain(cards)
    .values()
    .map(card =>
      map(card.overrides, override => {
        override.persisted = card.persisted
        return override
      }),
    )
    .flatten()
    .compact()
    .value()
}

export const areCardsEqual = (preSavedCard, currentCard) => {
  if (preSavedCard === undefined) return false

  const {index, ...preSaved} = preSavedCard
  const {index: indexb, ...current} = currentCard
  preSaved.overrides = preSaved.overrides.map(override => {
    const {course_section_id, student_ids, group_id, due_at, lock_at, unlock_at, rowKey} = override
    const params = {due_at, lock_at, unlock_at, rowKey}
    if (course_section_id) {
      params.course_section_id = course_section_id
    }
    if (group_id) {
      params.group_id = group_id
    }
    if (student_ids) {
      return {...params, student_ids: student_ids.filter(s => s).sort()}
    }
    return params
  })

  current.overrides = current.overrides
    .filter(
      override =>
        override?.course_section_id ||
        override?.student_ids ||
        override?.course_id ||
        override?.noop_id === '1' ||
        override?.group_id,
    )
    .map(override => {
      const {course_section_id, group_id, student_ids, due_at, lock_at, unlock_at, rowKey} =
        override

      const params = {due_at, lock_at, unlock_at, rowKey}
      if (course_section_id) {
        params.course_section_id = course_section_id
      }
      if (group_id) {
        params.group_id = group_id
      }
      if (student_ids) {
        return {...params, student_ids: student_ids.filter(s => s).sort()}
      }
      return params
    })

  return JSON.stringify(preSaved) === JSON.stringify(current)
}

export const resetOverrides = (overrides, newState) => {
  newState.forEach(newOverride => {
    const override = overrides.find(
      override => override.stagedOverrideId === newOverride.stagedOverrideId,
    )
    if (override) {
      Object.entries(newOverride).forEach(([key, value]) => {
        override[key] = value
      })
    }
  })
  return overrides
}

export const resetStagedCards = (cards, newCardsState, defaultState) => {
  const newState = cloneObject(newCardsState)
  Object.keys(newState).forEach(rowKey => {
    const card = cards[rowKey] ?? defaultState[rowKey]
    if (!card) return undefined
    const newCard = newState[rowKey]
    const validOverrides = card.overrides.filter(o =>
      newCard?.overrides.find(override => o.stagedOverrideId === override.stagedOverrideId),
    )

    newCard.overrides = resetOverrides(validOverrides, newCard.overrides)
  })
  return newState
}

export const getParsedOverrides = (stagedOverrides, cards, groupCategoryId, defaultSectionId) => {
  let index = 0
  const validOverrides = getValidOverrides(stagedOverrides, groupCategoryId)
  const overridesByKey = validOverrides.reduce((acc, override) => {
    const rowKey = override?.rowKey ?? combinedDates(override)
    override.rowKey = rowKey

    if (!acc[rowKey]) {
      acc[rowKey] = []
    }
    acc[rowKey].push(override)
    return acc
  }, {})

  const parsedOverrides = Object.entries(overridesByKey).reduce((acc, [key, overrides]) => {
    const datesForGroup = datesFromOverride(overrides[0])
    index++
    // ensure on initial load of the cards, the everyone option is first
    const everyoneOption = overrides[0].course_section_id === defaultSectionId ? 0 : undefined
    index = cards?.[key]?.index ?? overrides[0].index ?? everyoneOption ?? index
    acc[key] = {overrides, dates: datesForGroup, index}
    return acc
  }, {})

  return parsedOverrides
}

// This function filters out any Group overrides
// Differentiation tag overrides are valid but they use 'group_category_id'
// Differentiation tag overrides will pass the filter because of the non_collaborative check
const getValidOverrides = (stagedOverrides, groupCategoryId) => {
  return stagedOverrides.filter(override =>
    [undefined, groupCategoryId].includes(override.group_category_id) || override.non_collaborative === true,
  )
}

export const removeOverriddenAssignees = (overrides, parsedOverrides) => {
  const parsed = overrides.map(o => o)
  const overriddenTargets = getOverriddenAssignees(parsed)

  for (const [key, value] of Object.entries(parsedOverrides)) {
    value.overrides.forEach(override => {
      if (override.unassign_item) {
        delete parsedOverrides[key]
      }
      const {context_module_id, student_ids, course_section_id, group_id} = override
      if (context_module_id && student_ids) {
        let filteredStudents = student_ids
        filteredStudents = filteredStudents?.filter(
          id => !overriddenTargets?.students?.includes(id),
        )

        if (student_ids?.length > 0 && filteredStudents?.length === 0) {
          delete parsedOverrides[key]
        }
      }

      if (
        context_module_id &&
        course_section_id &&
        overriddenTargets?.sections?.includes(course_section_id)
      ) {
        delete parsedOverrides[key]
      }

      if (
        context_module_id &&
        group_id &&
        overriddenTargets?.differentiationTags?.includes(group_id)
      ) {
        delete parsedOverrides[key]
      }
    })
  }

  return parsedOverrides
}

// This is a slightly modified version of the processModuleOverrides function for AssignToContent
// The original function can be removed once we remove DifferentiatedModulesSection
export const processModuleOverrides = (overrides, initialModuleOverrides) => {
  const rowKeyModuleOverrides = initialModuleOverrides.map(obj => obj.rowKey)
  const withoutModuleOverrides = overrides.map(o => {
    if (rowKeyModuleOverrides.includes(o.rowKey)) {
      const initialModuleOverrideState = initialModuleOverrides.find(obj => obj.rowKey === o.rowKey)

      const {persisted, id, context_module_id, context_module_name, ...previousAttributes} =
        initialModuleOverrideState || {}

      const {
        persisted: _p,
        id: id_,
        context_module_id: cId,
        context_module_name: cName,
        ...currentAttributes
      } = o

      const hasDates =
        currentAttributes.due_at || currentAttributes.lock_at || currentAttributes.unlock_at
      const hasChanges = !(
        !hasDates &&
        currentAttributes.course_section_id == previousAttributes.course_section_id &&
        currentAttributes.group_id == previousAttributes.group_id &&
        JSON.stringify(currentAttributes.student_ids) ==
          JSON.stringify(previousAttributes.student_ids)
      )

      //   If there are changes, remove the context_module override information
      return hasChanges
        ? {
            ...o,
            context_module_id: undefined,
            context_module_name: undefined,
            id: undefined,
          }
        : {
            ...o,
            context_module_id: initialModuleOverrideState.context_module_id,
            context_module_name: initialModuleOverrideState.context_module_name,
            id: initialModuleOverrideState.id,
          } // If there are no changes, use the current override as is
    }

    return o
  })

  return withoutModuleOverrides
}

export const showPostToSisFlashAlert =
  (assignToButtonId, isTray = false) =>
  () =>
    showFlashAlert({
      message: (
        <>
          {I18n.t('Please set a due date or change your selection for the “Sync to SIS” option.')}
          {isTray && (
            <>
              <br />
              <View display="flex">
                <View as="div" margin="xx-small none none none" width="25px">
                  <IconEditLine size="x-small" color="primary" />
                </View>
                <Link
                  margin="xx-small none none none"
                  isWithinText={false}
                  onClick={() => document.getElementById(assignToButtonId)?.click()}
                >
                  {I18n.t('Manage Due Dates and Assign To')}
                </Link>
              </View>
            </>
          )}
        </>
      ),
      type: 'error',
    })
