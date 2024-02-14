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

export const sortedRowKeys = rows => {
  const {datedKeys, numberedKeys} = _.chain(rows)
    .keys()
    .groupBy(key => (key.length > 11 ? 'datedKeys' : 'numberedKeys'))
    .value()
  return _.chain([datedKeys, numberedKeys]).flatten().compact().value()
}

export const datesFromOverride = override => ({
  due_at: override ? override.get('due_at') : null,
  lock_at: override ? override.get('lock_at') : null,
  unlock_at: override ? override.get('unlock_at') : null,
})

export const rowsFromOverrides = assignmentOverrides => {
  const overridesByKey = _.groupBy(assignmentOverrides, override => {
    override.set('rowKey', override.combinedDates())
    return override.get('rowKey')
  })

  return _.chain(overridesByKey)
    .map((overrides, key) => {
      const datesForGroup = datesFromOverride(overrides[0])
      return [key, {overrides, dates: datesForGroup, persisted: true}]
    })
    .object()
    .value()
}

export const getAllOverrides = givenRows => {
  const rows = givenRows
  return _.chain(rows)
    .values()
    .map(row =>
      map(row.overrides, override => {
        override.attributes.persisted = row.persisted
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
  preSaved.overrides = preSaved.overrides.map(({assignment_override}) => {
    const {course_section_id, student_ids, due_at, lock_at, unlock_at, rowKey} = assignment_override
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
    .filter(override => override.attributes.course_section_id || override.attributes.student_ids)
    .map(({attributes}) => {
      const {course_section_id, student_ids, due_at, lock_at, unlock_at, rowKey} = attributes
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
