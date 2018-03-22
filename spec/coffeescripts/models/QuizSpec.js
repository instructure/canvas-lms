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
import Quiz from 'compiled/models/Quiz'
import Assignment from 'compiled/models/Assignment'
import DateGroup from 'compiled/models/DateGroup'
import AssignmentOverrideCollection from 'compiled/collections/AssignmentOverrideCollection'
import 'jquery.ajaxJSON'

QUnit.module('Quiz', {
  setup() {
    this.quiz = new Quiz({
      id: 1,
      html_url: 'http://localhost:3000/courses/1/quizzes/24'
    })
    this.ajaxStub = this.stub($, 'ajaxJSON')
  },
  teardown() {}
})

test('#initialize ignores assignment if not given', function() {
  ok(!this.quiz.get('assignment'))
})

test('#initialize sets assignment', function() {
  const assign = {
    id: 1,
    title: 'Foo Bar'
  }
  this.quiz = new Quiz({assignment: assign})
  equal(this.quiz.get('assignment').constructor, Assignment)
})

test('#initialize ignores assignment_overrides if not given', function() {
  ok(!this.quiz.get('assignment_overrides'))
})

test('#initialize assigns assignment_override collection', function() {
  this.quiz = new Quiz({assignment_overrides: []})
  equal(this.quiz.get('assignment_overrides').constructor, AssignmentOverrideCollection)
})

test('#initialize should set url from html url', function() {
  equal(this.quiz.get('url'), 'http://localhost:3000/courses/1/quizzes/1')
})

test('#initialize should set edit_url from html url', function() {
  equal(this.quiz.get('edit_url'), 'http://localhost:3000/courses/1/quizzes/1/edit')
})

test('#initialize should set publish_url from html url', function() {
  equal(this.quiz.get('publish_url'), 'http://localhost:3000/courses/1/quizzes/publish')
})

test('#initialize should set unpublish_url from html url', function() {
  equal(this.quiz.get('unpublish_url'), 'http://localhost:3000/courses/1/quizzes/unpublish')
})

test('#initialize should set title_label from title', function() {
  this.quiz = new Quiz({
    title: 'My Quiz!',
    readable_type: 'Quiz'
  })
  equal(this.quiz.get('title_label'), 'My Quiz!')
})

test('#initialize should set title_label from readable_type', function() {
  this.quiz = new Quiz({readable_type: 'Quiz'})
  equal(this.quiz.get('title_label'), 'Quiz')
})

test('#initialize defaults unpublishable to true', function() {
  ok(this.quiz.get('unpublishable'))
})

test('#initialize sets unpublishable to false', function() {
  this.quiz = new Quiz({unpublishable: false})
  ok(!this.quiz.get('unpublishable'))
})

test('#initialize sets publishable from can_unpublish and published', function() {
  this.quiz = new Quiz({
    can_unpublish: false,
    published: true
  })
  ok(!this.quiz.get('unpublishable'))
})

test('#initialize sets question count', function() {
  this.quiz = new Quiz({
    question_count: 1,
    published: true
  })
  equal(this.quiz.get('question_count_label'), '1 Question')
  this.quiz = new Quiz({
    question_count: 2,
    published: true
  })
  equal(this.quiz.get('question_count_label'), '2 Questions')
})

test('#initialize sets possible points count with no points', function() {
  this.quiz = new Quiz()
  equal(this.quiz.get('possible_points_label'), '')
})

test('#initialize sets possible points count with 0 points', function() {
  this.quiz = new Quiz({points_possible: 0})
  equal(this.quiz.get('possible_points_label'), '')
})

test('#initialize sets possible points count with 1 points', function() {
  this.quiz = new Quiz({points_possible: 1})
  equal(this.quiz.get('possible_points_label'), '1 pt')
})

test('#initialize sets possible points count with 2 points', function() {
  this.quiz = new Quiz({points_possible: 2})
  equal(this.quiz.get('possible_points_label'), '2 pts')
})

test('#initialize points possible to null if ungraded survey', function() {
  this.quiz = new Quiz({
    points_possible: 5,
    quiz_type: 'survey'
  })
  equal(this.quiz.get('possible_points_label'), '')
})

test('#publish saves to the server', function() {
  this.quiz.publish()
  ok(this.ajaxStub.called)
})

test('#publish sets published attribute to true', function() {
  this.quiz.publish()
  ok(this.quiz.get('published'))
})

test('#unpublish saves to the server', function() {
  this.quiz.unpublish()
  ok(this.ajaxStub.called)
})

test('#unpublish sets published attribute to false', function() {
  this.quiz.unpublish()
  ok(!this.quiz.get('published'))
})

QUnit.module('Quiz#multipleDueDates')

test('checks for multiple due dates from assignment overrides', () => {
  const quiz = new Quiz({
    all_dates: [{title: 'Winter'}, {title: 'Summer'}]
  })
  ok(quiz.multipleDueDates())
})

test('checks for no multiple due dates from quiz overrides', () => {
  const quiz = new Quiz()
  ok(!quiz.multipleDueDates())
})

QUnit.module('Quiz#allDates')

test('gets the due dates from the assignment overrides', () => {
  const dueAt = new Date('2013-08-20T11:13:00Z')
  const dates = [
    new DateGroup({
      due_at: dueAt,
      title: 'Everyone'
    })
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

test('gets the due date for section instead of null', function() {
  const dueAt = new Date('2013-11-27T11:01:00Z')
  const quiz = new Quiz({
    all_dates: [
      {
        due_at: null,
        title: 'Everyone'
      },
      {
        due_at: dueAt,
        title: 'Summer'
      }
    ]
  })
  this.stub(quiz, 'multipleDueDates').returns(false)
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

test('includes multipleDueDates', () => {
  const quiz = new Quiz({
    all_dates: [{title: 'Summer'}, {title: 'Winter'}]
  })
  const json = quiz.toView()
  deepEqual(json.multipleDueDates, true)
})

test('includes allDates', () => {
  const quiz = new Quiz({
    all_dates: [{title: 'Summer'}, {title: 'Winter'}]
  })
  const json = quiz.toView()
  equal(json.allDates.length, 2)
})

test('includes singleSectionDueDate', function() {
  const dueAt = new Date('2013-11-27T11:01:00Z')
  const quiz = new Quiz({
    all_dates: [
      {
        due_at: null,
        title: 'Everyone'
      },
      {
        due_at: dueAt,
        title: 'Summer'
      }
    ]
  })
  this.stub(quiz, 'multipleDueDates').returns(false)
  const json = quiz.toView()
  equal(json.singleSectionDueDate, dueAt.toISOString())
})
