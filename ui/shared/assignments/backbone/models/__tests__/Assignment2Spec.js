/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import 'jquery-migrate'
import '@canvas/jquery/jquery.ajaxJSON'
import Assignment from '../Assignment'
import Submission from '../Submission'
import fakeENV from '@canvas/test-utils/fakeENV'

QUnit.module('Assignment#unlockAt as a setter')

test("sets the record's unlock_at", () => {
  const date = Date.now()
  const assignment = new Assignment({name: 'foo'})
  assignment.set('unlock_at', null)
  assignment.unlockAt(date)
  equal(assignment.unlockAt(), date)
})

QUnit.module('Assignment#lockAt as a getter')

test('gets the records lock_at', () => {
  const date = Date.now()
  const assignment = new Assignment({name: 'foo'})
  assignment.set('lock_at', date)
  equal(assignment.lockAt(), date)
})

QUnit.module('Assignment#lockAt as a setter')

test("sets the record's lock_at", () => {
  const date = Date.now()
  const assignment = new Assignment({name: 'foo'})
  assignment.set('unlock_at', null)
  assignment.lockAt(date)
  equal(assignment.lockAt(), date)
})

QUnit.module('Assignment#description as a getter')

test("returns the record's description", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('description', 'desc')
  equal(assignment.description(), 'desc')
})

QUnit.module('Assignment#description as a setter')

test("sets the record's description", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('description', null)
  assignment.description('desc')
  equal(assignment.description(), 'desc')
  equal(assignment.get('description'), 'desc')
})

QUnit.module('Assignment#dueDateRequired as a getter')

test("returns the record's dueDateRequired", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('dueDateRequired', true)
  equal(assignment.dueDateRequired(), true)
})

QUnit.module('Assignment#dueDateRequired as a setter')

test("sets the record's dueDateRequired", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('dueDateRequired', null)
  assignment.dueDateRequired(true)
  equal(assignment.dueDateRequired(), true)
  equal(assignment.get('dueDateRequired'), true)
})

QUnit.module('Assignment#name as a getter')

test("returns the record's name", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('name', 'Todd')
  equal(assignment.name(), 'Todd')
})

QUnit.module('Assignment#name as a setter')

test("sets the record's name", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('name', 'NotTodd')
  assignment.name('Todd')
  equal(assignment.get('name'), 'Todd')
})

QUnit.module('Assignment#pointsPossible as a setter')

test("sets the record's points_possible", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('points_possible', 0)
  assignment.pointsPossible(12)
  equal(assignment.pointsPossible(), 12)
  equal(assignment.get('points_possible'), 12)
})

QUnit.module('Assignment#secureParams as a getter')

test('returns secure params if set', () => {
  const secure_params = 'eyJ0eXAiOiJKV1QiLCJhb.asdf232.asdf2334'
  const assignment = new Assignment({name: 'foo'})
  assignment.set('secure_params', secure_params)
  equal(assignment.secureParams(), secure_params)
})

QUnit.module('Assignment#assignmentGroupId as a setter')

test("sets the record's assignment group id", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('assignment_group_id', 0)
  assignment.assignmentGroupId(12)
  equal(assignment.assignmentGroupId(), 12)
  equal(assignment.get('assignment_group_id'), 12)
})

QUnit.module('Assignment#canDelete', {
  setup() {
    fakeENV.setup({current_user_roles: ['teacher'], current_user_is_admin: false})
  },
  teardown() {
    fakeENV.teardown()
  },
})

test("returns false if 'frozen' is true", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('frozen', true)
  equal(assignment.canDelete(), false)
})

test("returns false if 'in_closed_grading_period' is true", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('in_closed_grading_period', true)
  equal(assignment.canDelete(), false)
})

test("returns true if 'frozen' and 'in_closed_grading_period' are false", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('frozen', false)
  assignment.set('in_closed_grading_period', false)
  equal(assignment.canDelete(), true)
})

QUnit.module('Assignment#canMove as teacher', {
  setup() {
    fakeENV.setup({current_user_roles: ['teacher'], current_user_is_admin: false})
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('returns false if grading period is closed', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('in_closed_grading_period', true)
  equal(assignment.canMove(), false)
})

test('returns false if grading period not closed but group id is locked', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('in_closed_grading_period', false)
  assignment.set('in_closed_grading_period', ['assignment_group_id'])
  equal(assignment.canMove(), false)
})

test('returns true if grading period not closed and and group id is not locked', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('in_closed_grading_period', false)
  equal(assignment.canMove(), true)
})

QUnit.module('Assignment#canMove as admin', {
  setup() {
    fakeENV.setup({current_user_is_admin: true})
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('returns true if grading period is closed', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('in_closed_grading_period', true)
  equal(assignment.canMove(), true)
})

test('returns true if grading period not closed but group id is locked', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('in_closed_grading_period', false)
  assignment.set('in_closed_grading_period', ['assignment_group_id'])
  equal(assignment.canMove(), true)
})

// eslint-disable-next-line jest/no-identical-title
test('returns true if grading period not closed and and group id is not locked', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('in_closed_grading_period', false)
  equal(assignment.canMove(), true)
})

QUnit.module('Assignment#inClosedGradingPeriod as a non admin', {
  setup() {
    fakeENV.setup({current_user_roles: ['teacher'], current_user_is_admin: false})
  },
  teardown() {
    fakeENV.teardown()
  },
})

test("returns the value of 'in_closed_grading_period' when isAdmin is false", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('in_closed_grading_period', true)
  equal(assignment.inClosedGradingPeriod(), true)
  assignment.set('in_closed_grading_period', false)
  equal(assignment.inClosedGradingPeriod(), false)
})

QUnit.module('Assignment#inClosedGradingPeriod as an admin', {
  setup() {
    fakeENV.setup({current_user_is_admin: true})
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('returns true when isAdmin is true', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('in_closed_grading_period', true)
  equal(assignment.inClosedGradingPeriod(), false)
  assignment.set('in_closed_grading_period', false)
  equal(assignment.inClosedGradingPeriod(), false)
})

QUnit.module('Assignment#gradingType as a setter')

test("sets the record's grading type", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('grading_type', 'points')
  assignment.gradingType('percent')
  equal(assignment.gradingType(), 'percent')
  equal(assignment.get('grading_type'), 'percent')
})

QUnit.module('Assignment#submissionType')

test("returns 'none' if record's submission_types is ['none']", () => {
  const assignment = new Assignment({
    name: 'foo',
    id: '12',
  })
  assignment.set('submission_types', ['none'])
  equal(assignment.submissionType(), 'none')
})

test("returns 'on_paper' if record's submission_types includes on_paper", () => {
  const assignment = new Assignment({
    name: 'foo',
    id: '13',
  })
  assignment.set('submission_types', ['on_paper'])
  equal(assignment.submissionType(), 'on_paper')
})

test('returns online submission otherwise', () => {
  const assignment = new Assignment({
    name: 'foo',
    id: '14',
  })
  assignment.set('submission_types', ['online_upload'])
  equal(assignment.submissionType(), 'online')
})

QUnit.module('Assignment#expectsSubmission')

test('returns false if assignment submission type is not online', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set({
    submission_types: ['external_tool', 'on_paper'],
  })
  equal(assignment.expectsSubmission(), false)
})

test('returns true if an assignment submission type is online', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set({submission_types: ['online']})
  equal(assignment.expectsSubmission(), true)
})

QUnit.module('Assignment#allowedToSubmit')

test('returns false if assignment is locked', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set({submission_types: ['online']})
  assignment.set({locked_for_user: true})
  equal(assignment.allowedToSubmit(), false)
})

test('returns true if an assignment is not locked', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set({submission_types: ['online']})
  assignment.set({locked_for_user: false})
  equal(assignment.allowedToSubmit(), true)
})

test('returns false if a submission is not expected', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set({
    submission_types: ['external_tool', 'on_paper', 'attendance'],
  })
  equal(assignment.allowedToSubmit(), false)
})

QUnit.module('Assignment#withoutGradedSubmission')

test('returns false if there is a submission', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set({submission: new Submission({submission_type: 'online'})})
  equal(assignment.withoutGradedSubmission(), false)
})

test('returns true if there is no submission', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set({submission: null})
  equal(assignment.withoutGradedSubmission(), true)
})

test('returns true if there is a submission, but no grade', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set({submission: new Submission()})
  equal(assignment.withoutGradedSubmission(), true)
})

test('returns false if there is a submission and a grade', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set({submission: new Submission({grade: 305})})
  equal(assignment.withoutGradedSubmission(), false)
})

QUnit.module('Assignment#acceptsOnlineUpload')

test('returns true if record submission types includes online_upload', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', ['online_upload'])
  equal(assignment.acceptsOnlineUpload(), true)
})

test("returns false if submission types doesn't include online_upload", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', [])
  equal(assignment.acceptsOnlineUpload(), false)
})

QUnit.module('Assignment#acceptsOnlineURL')

test('returns true if assignment allows online url', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', ['online_url'])
  equal(assignment.acceptsOnlineURL(), true)
})

test("returns false if submission types doesn't include online_url", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', [])
  equal(assignment.acceptsOnlineURL(), false)
})

QUnit.module('Assignment#acceptsMediaRecording')

test('returns true if submission types includes media recordings', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', ['media_recording'])
  equal(assignment.acceptsMediaRecording(), true)
})

QUnit.module('Assignment#acceptsOnlineTextEntries')

test('returns true if submission types includes online text entry', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', ['online_text_entry'])
  equal(assignment.acceptsOnlineTextEntries(), true)
})
