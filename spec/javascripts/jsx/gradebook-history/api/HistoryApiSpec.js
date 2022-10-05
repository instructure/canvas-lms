/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import axios from '@canvas/axios'
import Fixtures from '../Fixtures'
import HistoryApi from 'ui/features/gradebook_history/react/api/HistoryApi'

QUnit.module('HistoryApi', {
  setup() {
    this.courseId = 123

    this.getStub = sandbox.stub(axios, 'get').returns(
      Promise.resolve({
        status: 200,
        response: Fixtures.historyResponse(),
      })
    )
  },
})

test('getGradebookHistory sends a request to the grade change audit url', function () {
  const url = `/api/v1/audit/grade_change/courses/${this.courseId}`
  HistoryApi.getGradebookHistory(this.courseId, {})
  strictEqual(this.getStub.callCount, 1)
  strictEqual(this.getStub.getCall(0).args[0], url)
})

test('getGradebookHistory requests with course and assignment', function () {
  const assignment = '21'
  const url = `/api/v1/audit/grade_change/courses/${this.courseId}/assignments/${assignment}`
  HistoryApi.getGradebookHistory(this.courseId, {assignment})
  strictEqual(this.getStub.callCount, 1)
  strictEqual(this.getStub.getCall(0).args[0], url)
})

test('getGradebookHistory requests with course and grader', function () {
  const grader = '22'
  const url = `/api/v1/audit/grade_change/courses/${this.courseId}/graders/${grader}`
  HistoryApi.getGradebookHistory(this.courseId, {grader})
  strictEqual(this.getStub.callCount, 1)
  strictEqual(this.getStub.getCall(0).args[0], url)
})

test('getGradebookHistory requests with course and student', function () {
  const student = '23'
  const url = `/api/v1/audit/grade_change/courses/${this.courseId}/students/${student}`
  HistoryApi.getGradebookHistory(this.courseId, {student})
  strictEqual(this.getStub.callCount, 1)
  strictEqual(this.getStub.getCall(0).args[0], url)
})

test('getGradebookHistory requests with course, assignment, and grader', function () {
  const grader = '22'
  const assignment = '210'
  const url = `/api/v1/audit/grade_change/courses/${this.courseId}/assignments/${assignment}/graders/${grader}`
  HistoryApi.getGradebookHistory(this.courseId, {assignment, grader})
  strictEqual(this.getStub.callCount, 1)
  strictEqual(this.getStub.getCall(0).args[0], url)
})

test('getGradebookHistory requests with course, assignment, and student', function () {
  const student = '23'
  const assignment = '210'
  const url = `/api/v1/audit/grade_change/courses/${this.courseId}/assignments/${assignment}/students/${student}`
  HistoryApi.getGradebookHistory(this.courseId, {assignment, student})
  strictEqual(this.getStub.callCount, 1)
  strictEqual(this.getStub.getCall(0).args[0], url)
})

test('getGradebookHistory requests with course, grader, and student', function () {
  const grader = '23'
  const student = '230'
  const url = `/api/v1/audit/grade_change/courses/${this.courseId}/graders/${grader}/students/${student}`
  HistoryApi.getGradebookHistory(this.courseId, {grader, student})
  strictEqual(this.getStub.callCount, 1)
  strictEqual(this.getStub.getCall(0).args[0], url)
})

test('getGradebookHistory requests with course, assignment, grader, and student', function () {
  const grader = '22'
  const assignment = '220'
  const student = '2200'
  const url = `/api/v1/audit/grade_change/courses/${this.courseId}/assignments/${assignment}/graders/${grader}/students/${student}`
  HistoryApi.getGradebookHistory(this.courseId, {assignment, grader, student})
  strictEqual(this.getStub.callCount, 1)
  strictEqual(this.getStub.getCall(0).args[0], url)
})

test('getGradebookHistory requests with course and override grades', function () {
  const url = `/api/v1/audit/grade_change/courses/${this.courseId}/assignments/override`

  HistoryApi.getGradebookHistory(this.courseId, {showFinalGradeOverridesOnly: true})
  strictEqual(this.getStub.getCall(0).args[0], url)
})

test('getGradebookHistory filters by override grades combined with other parameters', function () {
  const grader = '22'
  const student = '2200'
  const url = `/api/v1/audit/grade_change/courses/${this.courseId}/assignments/override/graders/${grader}/students/${student}`

  HistoryApi.getGradebookHistory(this.courseId, {
    grader,
    showFinalGradeOverridesOnly: true,
    student,
  })
  strictEqual(this.getStub.getCall(0).args[0], url)
})

test('getNextPage makes an axios get request', function () {
  const url = encodeURI(
    'http://example.com/grades?include[]=current_grade&page=42&per_page=100000000'
  )
  HistoryApi.getNextPage(url)
  strictEqual(this.getStub.callCount, 1)
  strictEqual(this.getStub.getCall(0).args[0], url)
})
