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

import $ from 'jquery'
import 'jquery-migrate'
import Quiz from '@canvas/quizzes/backbone/models/Quiz'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import DateGroup from '@canvas/date-group/backbone/models/DateGroup'
import AssignmentOverrideCollection from '@canvas/assignments/backbone/collections/AssignmentOverrideCollection'
import fakeENV from 'helpers/fakeENV'
import '@canvas/jquery/jquery.ajaxJSON'

QUnit.module('Quiz', {
  setup() {
    this.quiz = new Quiz({
      id: 1,
      html_url: 'http://localhost:3000/courses/1/quizzes/24',
    })
    this.ajaxStub = sandbox.stub($, 'ajaxJSON')
  },
  teardown() {},
})

test('#initialize ignores assignment if not given', function () {
  ok(!this.quiz.get('assignment'))
})

test('#initialize sets assignment', function () {
  const assign = {
    id: 1,
    title: 'Foo Bar',
  }
  this.quiz = new Quiz({assignment: assign})
  equal(this.quiz.get('assignment').constructor, Assignment)
})

test('#initialize ignores assignment_overrides if not given', function () {
  ok(!this.quiz.get('assignment_overrides'))
})

test('#initialize assigns assignment_override collection', function () {
  this.quiz = new Quiz({assignment_overrides: []})
  equal(this.quiz.get('assignment_overrides').constructor, AssignmentOverrideCollection)
})

test('#initialize should set url from html url', function () {
  equal(this.quiz.get('url'), 'http://localhost:3000/courses/1/quizzes/1')
})

test('#initialize should set edit_url from html url', function () {
  equal(this.quiz.get('edit_url'), 'http://localhost:3000/courses/1/quizzes/1/edit')
})

test('#initialize should set publish_url from html url', function () {
  equal(this.quiz.get('publish_url'), 'http://localhost:3000/courses/1/quizzes/publish')
})

test('#initialize should set unpublish_url from html url', function () {
  equal(this.quiz.get('unpublish_url'), 'http://localhost:3000/courses/1/quizzes/unpublish')
})

test('#initialize should set deletion_url from html url', function () {
  equal(this.quiz.get('deletion_url'), 'http://localhost:3000/courses/1/quizzes/1')
})

test('#initialize should set title_label from title', function () {
  this.quiz = new Quiz({
    title: 'My Quiz!',
    readable_type: 'Quiz',
  })
  equal(this.quiz.get('title_label'), 'My Quiz!')
})

test('#initialize should set title_label from readable_type', function () {
  this.quiz = new Quiz({readable_type: 'Quiz'})
  equal(this.quiz.get('title_label'), 'Quiz')
})

test('#initialize defaults unpublishable to true', function () {
  ok(this.quiz.get('unpublishable'))
})

test('#initialize sets unpublishable to false', function () {
  this.quiz = new Quiz({unpublishable: false})
  ok(!this.quiz.get('unpublishable'))
})

test('#initialize sets publishable from can_unpublish and published', function () {
  this.quiz = new Quiz({
    can_unpublish: false,
    published: true,
  })
  ok(!this.quiz.get('unpublishable'))
})

test('#initialize sets question count', function () {
  this.quiz = new Quiz({
    question_count: 1,
    published: true,
  })
  equal(this.quiz.get('question_count_label'), '1 Question')
  this.quiz = new Quiz({
    question_count: 2,
    published: true,
  })
  equal(this.quiz.get('question_count_label'), '2 Questions')
})

test('#initialize sets possible points count with no points', function () {
  this.quiz = new Quiz()
  equal(this.quiz.get('possible_points_label'), '')
})

test('#initialize sets possible points count with 0 points', function () {
  this.quiz = new Quiz({points_possible: 0})
  equal(this.quiz.get('possible_points_label'), '')
})

test('#initialize sets possible points count with 1 points', function () {
  this.quiz = new Quiz({points_possible: 1})
  equal(this.quiz.get('possible_points_label'), '1 pt')
})

test('#initialize sets possible points count with 2 points', function () {
  this.quiz = new Quiz({points_possible: 2})
  equal(this.quiz.get('possible_points_label'), '2 pts')
})

test('#initialize sets possible points count with 1.23 points', function () {
  this.quiz = new Quiz({points_possible: 1.23})
  equal(this.quiz.get('possible_points_label'), '1.23 pts')
})

test('#initialize points possible to null if ungraded survey', function () {
  this.quiz = new Quiz({
    points_possible: 5,
    quiz_type: 'survey',
  })
  equal(this.quiz.get('possible_points_label'), '')
})

test('#publish saves to the server', function () {
  this.quiz.publish()
  ok(this.ajaxStub.called)
})

test('#publish sets published attribute to true', function () {
  this.quiz.publish()
  ok(this.quiz.get('published'))
})

test('#unpublish saves to the server', function () {
  this.quiz.unpublish()
  ok(this.ajaxStub.called)
})

test('#unpublish sets published attribute to false', function () {
  this.quiz.unpublish()
  ok(!this.quiz.get('published'))
})

QUnit.module('Quiz#multipleDueDates')

test('checks for multiple due dates from assignment overrides', () => {
  const quiz = new Quiz({
    all_dates: [{title: 'Winter'}, {title: 'Summer'}],
  })
  ok(quiz.multipleDueDates())
})

test('checks for no multiple due dates from quiz overrides', () => {
  const quiz = new Quiz()
  ok(!quiz.multipleDueDates())
})

QUnit.module('Quiz.Next', {
  setup() {
    this.quiz = new Quiz({
      id: 7,
      html_url: 'http://localhost:3000/courses/1/assignments/7',
      assignment_id: 7,
      quiz_type: 'quizzes.next',
    })
    this.ajaxStub = sandbox.stub($, 'ajaxJSON')
  },
  teardown() {},
})

test('#initialize model record id', function () {
  equal(this.quiz.id, 'assignment_7')
})

test('#initialize should set url from html url', function () {
  equal(this.quiz.get('url'), 'http://localhost:3000/courses/1/assignments/7')
})

test('#initialize should set build_url from html url', function () {
  equal(this.quiz.get('build_url'), 'http://localhost:3000/courses/1/assignments/7')
})

test('#initialize should set edit_url from html url', function () {
  equal(this.quiz.get('edit_url'), 'http://localhost:3000/courses/1/assignments/7/edit?quiz_lti')
})

test('#initialize should set publish_url from html url', function () {
  equal(this.quiz.get('publish_url'), 'http://localhost:3000/courses/1/assignments/publish/quiz')
})

test('#initialize should set unpublish_url from html url', function () {
  equal(
    this.quiz.get('unpublish_url'),
    'http://localhost:3000/courses/1/assignments/unpublish/quiz'
  )
})

test('#initialize should set deletion_url from html url', function () {
  equal(this.quiz.get('deletion_url'), 'http://localhost:3000/courses/1/assignments/7')
})

QUnit.module('Quiz.Next with manage enabled', {
  setup() {
    fakeENV.setup({
      PERMISSIONS: {manage: true},
    })
    this.quiz = new Quiz({
      id: 7,
      html_url: 'http://localhost:3000/courses/1/assignments/7',
      assignment_id: 7,
      quiz_type: 'quizzes.next',
    })
    this.ajaxStub = sandbox.stub($, 'ajaxJSON')
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('#initialize should set url as edit_url', function () {
  equal(this.quiz.get('url'), 'http://localhost:3000/courses/1/assignments/7/edit?quiz_lti')
})

QUnit.module('Quiz#allDates')

test('gets the due dates from the assignment overrides', () => {
  const dueAt = new Date('2013-08-20T11:13:00Z')
  const dates = [
    new DateGroup({
      due_at: dueAt,
      title: 'Everyone',
    }),
  ]
  const quiz = new Quiz({all_dates: dates})
  const allDates = quiz.allDates()
  const first = allDates[0]
  equal(`${first.dueAt}`, `${dueAt}`)
  equal(first.dueFor, 'Everyone')
})

test('gets empty due dates when there are no dates', () => {
  const quiz = new Quiz()
  deepEqual(quiz.allDates(), [])
})

test('gets the due date for section instead of null', () => {
  const dueAt = new Date('2013-11-27T11:01:00Z')
  const quiz = new Quiz({
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
  sandbox.stub(quiz, 'multipleDueDates').returns(false)
  deepEqual(quiz.singleSectionDueDate(), dueAt.toISOString())
})

test('returns due_at when only one date/section are present', () => {
  const date = Date.now()
  const quiz = new Quiz({name: 'Taco party!'})
  quiz.set('due_at', date)
  deepEqual(quiz.singleSectionDueDate(), quiz.dueAt())
})

QUnit.module('Quiz#toView')

test("returns the quiz's dueAt", () => {
  const date = Date.now()
  const quiz = new Quiz({name: 'foo'})
  quiz.dueAt(date)
  const json = quiz.toView()
  deepEqual(json.dueAt, date)
})

test("returns quiz's lockAt", () => {
  const lockAt = Date.now()
  const quiz = new Quiz({name: 'foo'})
  quiz.lockAt(lockAt)
  const json = quiz.toView()
  deepEqual(json.lockAt, lockAt)
})

test("includes quiz's unlockAt", () => {
  const unlockAt = Date.now()
  const quiz = new Quiz({name: 'foo'})
  quiz.unlockAt(unlockAt)
  const json = quiz.toView()
  deepEqual(json.unlockAt, unlockAt)
})

test('includes htmlUrl', () => {
  const quiz = new Quiz({url: 'http://example.com/quizzes/1'})
  const json = quiz.toView()
  deepEqual(json.htmlUrl, 'http://example.com/quizzes/1')
})

test('includes buildUrl', () => {
  const quiz = new Quiz({
    id: '1',
    url: 'http://example.com/quizzes/1',
    html_url: 'http://example.com/quizzes/1',
  })
  const json = quiz.toView()
  deepEqual(json.buildUrl, 'http://example.com/quizzes/1')
})

test('includes multipleDueDates', () => {
  const quiz = new Quiz({
    all_dates: [{title: 'Summer'}, {title: 'Winter'}],
  })
  const json = quiz.toView()
  deepEqual(json.multipleDueDates, true)
})

test('includes allDates', () => {
  const quiz = new Quiz({
    all_dates: [{title: 'Summer'}, {title: 'Winter'}],
  })
  const json = quiz.toView()
  equal(json.allDates.length, 2)
})

test('includes singleSectionDueDate', () => {
  const dueAt = new Date('2013-11-27T11:01:00Z')
  const quiz = new Quiz({
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
  sandbox.stub(quiz, 'multipleDueDates').returns(false)
  const json = quiz.toView()
  equal(json.singleSectionDueDate, dueAt.toISOString())
})

QUnit.module('Quiz#duplicate')

test('make ajax call with right url when duplicate is called', () => {
  const assignmentID = '200'
  const courseID = '123'
  const quiz = new Quiz({
    name: 'foo',
    id: assignmentID,
    course_id: courseID,
  })
  const spy = sandbox.spy($, 'ajaxJSON')
  quiz.duplicate()
  ok(spy.withArgs(`/api/v1/courses/${courseID}/assignments/${assignmentID}/duplicate`).calledOnce)
})

QUnit.module('Quiz#duplicate_failed')

test('make ajax call with right url when duplicate_failed is called', () => {
  const assignmentID = '200'
  const originalAssignmentID = '42'
  const courseID = '123'
  const originalCourseID = '234'
  const quiz = new Quiz({
    name: 'foo',
    id: assignmentID,
    original_assignment_id: originalAssignmentID,
    course_id: courseID,
    original_course_id: originalCourseID,
  })
  const spy = sandbox.spy($, 'ajaxJSON')
  quiz.duplicate_failed()
  ok(
    spy.withArgs(
      `/api/v1/courses/${originalCourseID}/assignments/${originalAssignmentID}/duplicate?target_assignment_id=${assignmentID}&target_course_id=${courseID}`
    ).calledOnce
  )
})

QUnit.module('Quiz#retry_migration')

test('make ajax call with right url when retry_migration is called', () => {
  const assignmentID = '200'
  const originalQuizID = '42'
  const courseID = '123'
  const quiz = new Quiz({
    name: 'foo',
    id: assignmentID,
    original_quiz_id: originalQuizID,
    course_id: courseID,
  })
  const spy = sandbox.spy($, 'ajaxJSON')
  quiz.retry_migration()
  ok(
    spy.withArgs(
      `/api/v1/courses/${courseID}/content_exports?export_type=quizzes2&quiz_id=${originalQuizID}&include[]=migrated_quiz`
    ).calledOnce
  )
})

QUnit.module('Assignment#pollUntilFinishedLoading (duplicate)', {
  setup() {
    this.clock = sinon.useFakeTimers()
    this.quiz = new Quiz({workflow_state: 'duplicating'})
    sandbox.stub(this.quiz, 'fetch').returns($.Deferred().resolve())
  },
  teardown() {
    this.clock.restore()
  },
})

test('polls for updates (duplicate)', function () {
  this.quiz.pollUntilFinishedLoading(4000)
  this.clock.tick(2000)
  notOk(this.quiz.fetch.called)
  this.clock.tick(3000)
  ok(this.quiz.fetch.called)
})

test('stops polling when the quiz has finished duplicating', function () {
  this.quiz.pollUntilFinishedLoading(3000)
  this.quiz.set({workflow_state: 'unpublished'})
  this.clock.tick(3000)
  ok(this.quiz.fetch.calledOnce)
  this.clock.tick(3000)
  ok(this.quiz.fetch.calledOnce)
})

QUnit.module('Assignment#pollUntilFinishedLoading (migration)', {
  setup() {
    this.clock = sinon.useFakeTimers()
    this.quiz = new Quiz({workflow_state: 'migrating'})
    sandbox.stub(this.quiz, 'fetch').returns($.Deferred().resolve())
  },
  teardown() {
    this.clock.restore()
  },
})

test('polls for updates (migration)', function () {
  this.quiz.pollUntilFinishedLoading(4000)
  this.clock.tick(2000)
  notOk(this.quiz.fetch.called)
  this.clock.tick(3000)
  ok(this.quiz.fetch.called)
})

test('stops polling when the quiz has finished migrating', function () {
  this.quiz.pollUntilFinishedLoading(3000)
  this.quiz.set({workflow_state: 'unpublished'})
  this.clock.tick(3000)
  ok(this.quiz.fetch.calledOnce)
  this.clock.tick(3000)
  ok(this.quiz.fetch.calledOnce)
})

QUnit.module('Assignment#pollUntilFinishedLoading (importing)', {
  setup() {
    this.clock = sinon.useFakeTimers()
    this.quiz = new Quiz({workflow_state: 'importing'})
    sandbox.stub(this.quiz, 'fetch').returns($.Deferred().resolve())
  },
  teardown() {
    this.clock.restore()
  },
})

test('polls for updates (importing)', function () {
  this.quiz.pollUntilFinishedLoading(4000)
  this.clock.tick(2000)
  notOk(this.quiz.fetch.called)
  this.clock.tick(3000)
  ok(this.quiz.fetch.called)
})

test('stops polling when the quiz has finished importing', function () {
  this.quiz.pollUntilFinishedLoading(3000)
  this.quiz.set({workflow_state: 'unpublished'})
  this.clock.tick(3000)
  ok(this.quiz.fetch.calledOnce)
  this.clock.tick(3000)
  ok(this.quiz.fetch.calledOnce)
})
