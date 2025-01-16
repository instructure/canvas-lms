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
import Fixtures from '@canvas/grading/Fixtures'
import HistoryApi from '../HistoryApi'

describe('HistoryApi', () => {
  let courseId
  let getStub

  beforeEach(() => {
    courseId = 123
    getStub = jest.spyOn(axios, 'get').mockResolvedValue({
      status: 200,
      response: Fixtures.historyResponse(),
    })
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  const defaultParams = {
    params: {
      include: ['current_grade'],
      start_time: undefined,
      end_time: undefined,
    },
  }

  it('getGradebookHistory sends a request to the grade change audit url', () => {
    const url = `/api/v1/audit/grade_change/courses/${courseId}`
    HistoryApi.getGradebookHistory(courseId, {})
    expect(getStub).toHaveBeenCalledTimes(1)
    expect(getStub).toHaveBeenCalledWith(url, defaultParams)
  })

  it('getGradebookHistory requests with course and assignment', () => {
    const assignment = '21'
    const url = `/api/v1/audit/grade_change/courses/${courseId}/assignments/${assignment}`
    HistoryApi.getGradebookHistory(courseId, {assignment})
    expect(getStub).toHaveBeenCalledTimes(1)
    expect(getStub).toHaveBeenCalledWith(url, defaultParams)
  })

  it('getGradebookHistory requests with course and grader', () => {
    const grader = '22'
    const url = `/api/v1/audit/grade_change/courses/${courseId}/graders/${grader}`
    HistoryApi.getGradebookHistory(courseId, {grader})
    expect(getStub).toHaveBeenCalledTimes(1)
    expect(getStub).toHaveBeenCalledWith(url, defaultParams)
  })

  it('getGradebookHistory requests with course and student', () => {
    const student = '23'
    const url = `/api/v1/audit/grade_change/courses/${courseId}/students/${student}`
    HistoryApi.getGradebookHistory(courseId, {student})
    expect(getStub).toHaveBeenCalledTimes(1)
    expect(getStub).toHaveBeenCalledWith(url, defaultParams)
  })

  it('getGradebookHistory requests with course, assignment, and grader', () => {
    const grader = '22'
    const assignment = '210'
    const url = `/api/v1/audit/grade_change/courses/${courseId}/assignments/${assignment}/graders/${grader}`
    HistoryApi.getGradebookHistory(courseId, {assignment, grader})
    expect(getStub).toHaveBeenCalledTimes(1)
    expect(getStub).toHaveBeenCalledWith(url, defaultParams)
  })

  it('getGradebookHistory requests with course, assignment, and student', () => {
    const student = '23'
    const assignment = '210'
    const url = `/api/v1/audit/grade_change/courses/${courseId}/assignments/${assignment}/students/${student}`
    HistoryApi.getGradebookHistory(courseId, {assignment, student})
    expect(getStub).toHaveBeenCalledTimes(1)
    expect(getStub).toHaveBeenCalledWith(url, defaultParams)
  })

  it('getGradebookHistory requests with course, grader, and student', () => {
    const grader = '23'
    const student = '230'
    const url = `/api/v1/audit/grade_change/courses/${courseId}/graders/${grader}/students/${student}`
    HistoryApi.getGradebookHistory(courseId, {grader, student})
    expect(getStub).toHaveBeenCalledTimes(1)
    expect(getStub).toHaveBeenCalledWith(url, defaultParams)
  })

  it('getGradebookHistory requests with course, assignment, grader, and student', () => {
    const grader = '22'
    const assignment = '220'
    const student = '2200'
    const url = `/api/v1/audit/grade_change/courses/${courseId}/assignments/${assignment}/graders/${grader}/students/${student}`
    HistoryApi.getGradebookHistory(courseId, {assignment, grader, student})
    expect(getStub).toHaveBeenCalledTimes(1)
    expect(getStub).toHaveBeenCalledWith(url, defaultParams)
  })

  it('getGradebookHistory requests with course and override grades', () => {
    const url = `/api/v1/audit/grade_change/courses/${courseId}/assignments/override`
    HistoryApi.getGradebookHistory(courseId, {showFinalGradeOverridesOnly: true})
    expect(getStub).toHaveBeenCalledWith(url, defaultParams)
  })

  it('getGradebookHistory filters by override grades combined with other parameters', () => {
    const grader = '22'
    const student = '2200'
    const url = `/api/v1/audit/grade_change/courses/${courseId}/assignments/override/graders/${grader}/students/${student}`
    HistoryApi.getGradebookHistory(courseId, {
      grader,
      showFinalGradeOverridesOnly: true,
      student,
    })
    expect(getStub).toHaveBeenCalledWith(url, defaultParams)
  })

  it('getNextPage makes an axios get request', () => {
    const url = encodeURI(
      'http://example.com/grades?include[]=current_grade&page=42&per_page=100000000',
    )
    HistoryApi.getNextPage(url)
    expect(getStub).toHaveBeenCalledTimes(1)
    expect(getStub).toHaveBeenCalledWith(url)
  })
})
