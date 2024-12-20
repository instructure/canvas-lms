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

import 'jquery-migrate'
import '@canvas/jquery/jquery.ajaxJSON'
import Assignment from '../Assignment'
import fakeENV from '@canvas/test-utils/fakeENV'

QUnit.module('Assignment#toView', {
  setup() {
    fakeENV.setup({current_user_roles: ['teacher']})
  },
  teardown() {
    fakeENV.teardown()
  },
})

test("returns the assignment's name", () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.name('Todd')
  const json = assignment.toView()
  equal(json.name, 'Todd')
})

test("returns the assignment's dueAt", () => {
  const date = Date.now()
  const assignment = new Assignment({name: 'foo'})
  assignment.dueAt(date)
  const json = assignment.toView()
  equal(json.dueAt, date)
})

test("includes the assignment's description", () => {
  const description = 'Yo yo fasho'
  const assignment = new Assignment({name: 'foo'})
  assignment.description(description)
  const json = assignment.toView()
  equal(json.description, description)
})

test("includes the assignment's dueDateRequired", () => {
  const dueDateRequired = false
  const assignment = new Assignment({name: 'foo'})
  assignment.dueDateRequired(dueDateRequired)
  const json = assignment.toView()
  equal(json.dueDateRequired, dueDateRequired)
})

test("returns assignment's points possible", () => {
  const pointsPossible = 12
  const assignment = new Assignment({name: 'foo'})
  assignment.pointsPossible(pointsPossible)
  const json = assignment.toView()
  equal(json.pointsPossible, pointsPossible)
})

test("returns assignment's lockAt", () => {
  const lockAt = Date.now()
  const assignment = new Assignment({name: 'foo'})
  assignment.lockAt(lockAt)
  const json = assignment.toView()
  equal(json.lockAt, lockAt)
})

test("includes assignment's unlockAt", () => {
  const unlockAt = Date.now()
  const assignment = new Assignment({name: 'foo'})
  assignment.unlockAt(unlockAt)
  const json = assignment.toView()
  equal(json.unlockAt, unlockAt)
})

test("includes assignment's gradingType", () => {
  const gradingType = 'percent'
  const assignment = new Assignment({name: 'foo'})
  assignment.gradingType(gradingType)
  const json = assignment.toView()
  equal(json.gradingType, gradingType)
})

test("includes assignment's notifyOfUpdate", () => {
  const notifyOfUpdate = false
  const assignment = new Assignment({name: 'foo'})
  assignment.notifyOfUpdate(notifyOfUpdate)
  const json = assignment.toView()
  equal(json.notifyOfUpdate, notifyOfUpdate)
})

test("includes assignment's peerReviews", () => {
  const peerReviews = false
  const assignment = new Assignment({name: 'foo'})
  assignment.peerReviews(peerReviews)
  const json = assignment.toView()
  equal(json.peerReviews, peerReviews)
})

test("includes assignment's automaticPeerReviews value", () => {
  const autoPeerReviews = false
  const assignment = new Assignment({name: 'foo'})
  assignment.automaticPeerReviews(autoPeerReviews)
  const json = assignment.toView()
  equal(json.automaticPeerReviews, autoPeerReviews)
})

test('includes boolean indicating whether or not assignment accepts uploads', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', ['online_upload'])
  const json = assignment.toView()
  equal(json.acceptsOnlineUpload, true)
})

test('includes whether or not assignment accepts media recordings', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', ['media_recording'])
  const json = assignment.toView()
  equal(json.acceptsMediaRecording, true)
})

test('includes submissionType', () => {
  const assignment = new Assignment({
    name: 'foo',
    id: '16',
  })
  assignment.set('submission_types', ['on_paper'])
  const json = assignment.toView()
  equal(json.submissionType, 'on_paper')
})

test('includes acceptsOnlineTextEntries', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', ['online_text_entry'])
  const json = assignment.toView()
  equal(json.acceptsOnlineTextEntries, true)
})

test('includes acceptsOnlineURL', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.set('submission_types', ['online_url'])
  const json = assignment.toView()
  equal(json.acceptsOnlineURL, true)
})

test('includes allowedExtensions', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.allowedExtensions([])
  const json = assignment.toView()
  deepEqual(json.allowedExtensions, [])
})

test('includes htmlUrl', () => {
  const assignment = new Assignment({html_url: 'http://example.com/assignments/1'})
  const json = assignment.toView()
  equal(json.htmlUrl, 'http://example.com/assignments/1')
})

test('uses edit url for htmlUrl when managing a quiz_lti assignment', () => {
  const assignment = new Assignment({
    html_url: 'http://example.com/assignments/1',
    is_quiz_lti_assignment: true,
  })
  ENV.PERMISSIONS = {manage: true}
  const json = assignment.toView()
  equal(json.htmlUrl, 'http://example.com/assignments/1/edit?quiz_lti')
  ENV.PERMISSIONS = {}
  ENV.FLAGS = {}
})

test('uses htmlUrl when not managing a quiz_lti assignment', () => {
  const assignment = new Assignment({
    html_url: 'http://example.com/assignments/1',
    is_quiz_lti_assignment: true,
  })
  ENV.PERMISSIONS = {manage: false}
  const json = assignment.toView()
  equal(json.htmlUrl, 'http://example.com/assignments/1')
  ENV.PERMISSIONS = {}
  ENV.FLAGS = {}
})

test('includes htmlEditUrl', () => {
  const assignment = new Assignment({html_url: 'http://example.com/assignments/1'})
  const json = assignment.toView()
  equal(json.htmlEditUrl, 'http://example.com/assignments/1/edit')
})

test('includes htmlBuildUrl', () => {
  const assignment = new Assignment({html_url: 'http://example.com/assignments/1'})
  const json = assignment.toView()
  equal(json.htmlBuildUrl, 'http://example.com/assignments/1')
})

test('includes multipleDueDates', () => {
  const assignment = new Assignment({
    all_dates: [{title: 'Summer'}, {title: 'Winter'}],
  })
  const json = assignment.toView()
  equal(json.multipleDueDates, true)
})

test('includes allDates', () => {
  const assignment = new Assignment({
    all_dates: [{title: 'Summer'}, {title: 'Winter'}],
  })
  const json = assignment.toView()
  equal(json.allDates.length, 2)
})

test('includes singleSectionDueDate', () => {
  const dueAt = new Date('2013-11-27T11:01:00Z')
  const assignment = new Assignment({
    all_dates: [
      {
        due_at: null,
        title: 'Everyone',
      },
      {
        due_at: dueAt,
        title: 'Summer',
      },
    ],
  })
  sandbox.stub(assignment, 'multipleDueDates').returns(false)
  const json = assignment.toView()
  equal(json.singleSectionDueDate, dueAt.toISOString())
})

test('includes fields for isPage', () => {
  const assignment = new Assignment({submission_types: ['wiki_page']})
  const json = assignment.toView()
  notOk(json.hasDueDate)
  notOk(json.hasPointsPossible)
})

test('includes fields for isQuiz', () => {
  const assignment = new Assignment({submission_types: ['online_quiz']})
  const json = assignment.toView()
  ok(json.hasDueDate)
  notOk(json.hasPointsPossible)
})

test('returns omitFromFinalGrade', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.omitFromFinalGrade(true)
  const json = assignment.toView()
  ok(json.omitFromFinalGrade)
})

test('returns true when anonymousInstructorAnnotations is true', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.anonymousInstructorAnnotations(true)
  strictEqual(assignment.toView().anonymousInstructorAnnotations, true)
})

test('returns false when anonymousInstructorAnnotations is false', () => {
  const assignment = new Assignment({name: 'foo'})
  assignment.anonymousInstructorAnnotations(false)
  strictEqual(assignment.toView().anonymousInstructorAnnotations, false)
})

QUnit.module('Assignment#singleSection', {
  setup() {
    fakeENV.setup()
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('returns null when all_dates is null', () => {
  const assignment = new Assignment({})
  sandbox.stub(assignment, 'allDates').returns(null)
  equal(assignment.singleSection(), null)
})

test('returns null when there are multiple all_dates records', () => {
  const date = new Date('2022-02-15T11:13:00')
  const assignment = new Assignment({
    all_dates: [
      {
        lock_at: date,
        unlock_at: date,
        due_at: null,
        title: 'Section A',
      },
      {
        lock_at: date,
        unlock_at: date,
        due_at: null,
        title: 'Section B',
      },
      {
        lock_at: date,
        unlock_at: date,
        due_at: null,
        title: 'Section C',
      },
    ],
  })
  equal(assignment.singleSection(), null)
})

test('returns null when there are no records in all_dates', () => {
  const assignment = new Assignment({
    all_dates: [],
  })
  equal(assignment.singleSection(), null)
})

test('returns the first element in all_dates when the length is 1', () => {
  const assignment = new Assignment({
    all_dates: [
      {
        lock_at: new Date('2022-02-15T11:13:00'),
        unlock_at: new Date('2022-02-16T11:13:00'),
        due_at: new Date('2022-02-17T11:13:00'),
        title: 'Section A',
      },
    ],
  })
  deepEqual(assignment.singleSection(), assignment.allDates()[0])
})
