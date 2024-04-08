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

import _ from 'underscore'
import {map} from 'lodash'
import {getOverriddenAssignees} from '@canvas/context-modules/differentiated-modules/utils/assignToHelper'

export const cloneObject = object => JSON.parse(JSON.stringify(object))

const combinedDates = override => {
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
})

export const getAllOverridesFromCards = givenCards => {
  const cards = givenCards
  return _.chain(cards)
    .values()
    .map(card =>
      map(card.overrides, override => {
        override.persisted = card.persisted
        return override
      })
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
    const {course_section_id, student_ids, due_at, lock_at, unlock_at, rowKey} = override
    const params = {due_at, lock_at, unlock_at, rowKey}
    if (course_section_id) {
      params.course_section_id = course_section_id
    }
    if (student_ids) {
      return {...params, student_ids: student_ids.filter(s => s).sort()}
    }
    return params
  })

  current.overrides = current.overrides
    .filter(
      override => override?.course_section_id || override?.student_ids || override?.noop_id === '1'
    )
    .map(override => {
      const {course_section_id, student_ids, due_at, lock_at, unlock_at, rowKey} = override

      const params = {due_at, lock_at, unlock_at, rowKey}
      if (course_section_id) {
        params.course_section_id = course_section_id
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
      override => override.stagedOverrideId === newOverride.stagedOverrideId
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
    const newCard = newState[rowKey]
    const validOverrides = card.overrides.filter(o =>
      newCard.overrides.find(override => o.stagedOverrideId === override.stagedOverrideId)
    )

    newCard.overrides = resetOverrides(validOverrides, newCard.overrides)
  })
  return newState
}

export const getParsedOverrides = (stagedOverrides, cards) => {
  let index = 0
  const overridesByKey = stagedOverrides.reduce((acc, override) => {
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
    index = cards?.[key]?.index ?? overrides[0].index ?? index
    acc[key] = {overrides, dates: datesForGroup, index}
    return acc
  }, {})

  return parsedOverrides
}

export const removeOverriddenAssignees = (overrides, parsedOverrides) => {
  const parsed = overrides.map(o => o)
  const overriddenTargets = getOverriddenAssignees(parsed)

  for (const [key, value] of Object.entries(parsedOverrides)) {
    value.overrides.forEach(override => {
      const {context_module_id, student_ids, course_section_id} = override

      if (context_module_id && student_ids) {
        let filteredStudents = student_ids
        filteredStudents = filteredStudents?.filter(
          id => !overriddenTargets?.students?.includes(id)
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
    })
  }

  return parsedOverrides
}

export const processModuleOverrides = (overrides, lastCheckpoint) => {
  const withoutModuleOverrides = overrides.map(o => {
    if (o.context_module_id) {
      const checkpointOverrides = lastCheckpoint[o.rowKey]?.overrides

      const lastOverrideState = checkpointOverrides?.find(
        override => override.stagedOverrideId === o.stagedOverrideId
      )

      const {persisted, id, context_module_id, context_module_name, ...previousAttributes} =
        lastOverrideState || {}

      const {
        persisted: _p,
        id: id_,
        context_module_id: cId,
        context_module_name: cName,
        ...currentAttributes
      } = o

      const hasChanges = JSON.stringify(previousAttributes) !== JSON.stringify(currentAttributes)

      //   If there are changes, remove the context_module override information
      return hasChanges
        ? {
            ...o,
            context_module_id: undefined,
            context_module_name: undefined,
            id: undefined,
          }
        : o // If there are no changes, use the current override as is
    }

    return o
  })

  return withoutModuleOverrides
}
