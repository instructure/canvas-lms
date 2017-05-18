#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'react'
  'underscore'
  'jsx/due_dates/TokenActions'
  'compiled/models/AssignmentOverride'
], (React, _, TokenActions, AssignmentOverride) ->

  QUnit.module 'TokenActions is a thing',
    setup: ->
      @assertValuesEqual = (override, keysAndVals) ->
        _.map(keysAndVals, (val, key) ->
          deepEqual override.get(key), val
        )

      @assertTimesEqual = (override, keysAndVals) ->
        _.map(keysAndVals, (val, key) ->
          deepEqual override.get(key).getTime(), val.getTime()
        )

    teardown: ->

  test 'new token with course section id is handled properly', ->
    initialOverrides = []
    tokenToAdd = {type: "section", course_section_id: 1}

    newOverrides = TokenActions.handleTokenAdd(
      tokenToAdd,
      initialOverrides,
      1, #rowKey
      {due_at: new Date(2012, 1, 1)} #dates
    )

    @assertTimesEqual(newOverrides[0], due_at: new Date(2012, 1, 1) )
    @assertValuesEqual(newOverrides[0],
      course_section_id: 1
      rowKey: 1
    )

  test 'new token with group id is handled properly', ->
    initialOverrides = []
    tokenToAdd = {type: "group", group_id: 1}

    newOverrides = TokenActions.handleTokenAdd(
      tokenToAdd,
      initialOverrides,
      1, #rowKey
      {due_at: new Date(2012, 1, 1)} #dates
    )

    @assertTimesEqual(newOverrides[0], due_at: new Date(2012, 1, 1) )
    @assertValuesEqual(newOverrides[0],
      group_id: 1
      rowKey: 1
    )

  test 'new token with student id is handled properly with no adhoc', ->
    initialOverrides = []
    tokenToAdd = {type: "student", id: 1}

    newOverrides = TokenActions.handleTokenAdd(
      tokenToAdd,
      initialOverrides,
      1, #rowKey
      {due_at: new Date(2012, 1, 1)} #dates
    )

    @assertTimesEqual(newOverrides[0], due_at: new Date(2012, 1, 1))
    @assertValuesEqual(newOverrides[0],
      student_ids: [1],
      rowKey: 1
    )

  test 'new token with student id is handled properly with an adhoc', ->
    attrs = {student_ids: [2], due_at: new Date(2012, 1, 1), rowKey: 1}
    initialOverrides = [new AssignmentOverride(attrs)]
    tokenToAdd = {type: "student", id: 1}

    newOverrides = TokenActions.handleTokenAdd(
      tokenToAdd,
      initialOverrides,
      1, #rowKey
      {due_at: new Date(2012, 1, 1)} #dates
    )

    @assertTimesEqual(newOverrides[0], due_at: new Date(2012, 1, 1))
    @assertValuesEqual(newOverrides[0],
      student_ids: [2, 1]
      rowKey: 1
    )

  test 'override properties are properly copied', ->
    attrs = {student_ids: [1,2], due_at: new Date(2012, 1, 1), lock_at: new Date(2012, 1, 5), rowKey: 1}
    initialOverrides = [new AssignmentOverride(attrs)]
    tokenToAdd = {type: "section", course_section_id: 1}

    newOverrides = TokenActions.handleTokenAdd(
      tokenToAdd,
      initialOverrides,
      1, #rowKey
      {due_at: new Date(2012, 1, 1), lock_at: new Date(2012, 1, 5)} #dates
    )

    sectionOverride = _.find(newOverrides, (o)-> o.get("course_section_id"))

    @assertTimesEqual(newOverrides[0],
      due_at: new Date(2012, 1, 1)
      lock_at: new Date(2012, 1, 5)
    )

    @assertValuesEqual(sectionOverride, {
      course_section_id: 1
      rowKey: 1
      due_at_overridden: true
      lock_at_overridden: true
      unlock_at_overridden: false
    })

# ----------------------REMOVES------------------------------

  test 'removing token with course section id is handled properly', ->
    initialOverrideAttrs = {course_section_id: 2, due_at: new Date(2012, 1, 1), rowKey: 1}
    initialOverrides = [new AssignmentOverride(initialOverrideAttrs)]
    tokenToRemove = {type: "section", course_section_id: 2}

    newOverrides = TokenActions.handleTokenRemove(
      tokenToRemove,
      initialOverrides
    )

    deepEqual newOverrides, []

  test 'removing token with group id is handled properly', ->
    initialOverrideAttrs = {group_id: 2, due_at: new Date(2012, 1, 1), rowKey: 1}
    initialOverrides = [new AssignmentOverride(initialOverrideAttrs)]
    tokenToRemove = {type: "section", group_id: 2}

    newOverrides = TokenActions.handleTokenRemove(
      tokenToRemove,
      initialOverrides
    )

    deepEqual newOverrides, []

  test 'removing token with student id is handled properly when only student in adhoc', ->
    initialOverrideAttrs = {student_ids: [1], due_at: new Date(2012, 1, 1), rowKey: 1}
    initialOverrides = [new AssignmentOverride(initialOverrideAttrs)]
    tokenToRemove = {type: "student", student_id: 1}

    newOverrides = TokenActions.handleTokenRemove(
      tokenToRemove,
      initialOverrides
    )
    deepEqual newOverrides, []

  test 'removing token with student id is handled properly with other students in adhoc', ->
    initialOverrideAttrs = {student_ids: [1,2], due_at: new Date(2012, 1, 1), rowKey: 1}
    initialOverrides = [new AssignmentOverride(initialOverrideAttrs)]
    tokenToRemove = {type: "student", student_id: 1}

    newOverrides = TokenActions.handleTokenRemove(
      tokenToRemove,
      initialOverrides
    )

    @assertTimesEqual(newOverrides[0],
      due_at: new Date(2012, 1, 1)
    )

    @assertValuesEqual(newOverrides[0],
      student_ids: [2]
      rowKey: 1
    )
