/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import * as GradesApi from '../GradesApi'
import FakeServer, {
  jsonBodyFromRequest,
  pathFromRequest,
} from '@canvas/network/NaiveRequestDispatch/__tests__/FakeServer'

describe('GradeSummary GradesApi', () => {
  let server

  beforeEach(() => {
    server = new FakeServer()
  })

  afterEach(() => {
    server.teardown()
  })

  describe('.bulkSelectProvisionalGrades()', () => {
    const url = `/api/v1/courses/1201/assignments/2301/provisional_grades/bulk_select`

    test('sends a request to select a provisional grade', async () => {
      server.for(url).respond({status: 200, body: {}})
      await GradesApi.bulkSelectProvisionalGrades('1201', '2301', ['4601', '4602'])
      const request = server.receivedRequests[0]
      expect(pathFromRequest(request)).toBe(url)
    })

    test('sends a PUT request', async () => {
      server.for(url).respond({status: 200, body: {}})
      await GradesApi.bulkSelectProvisionalGrades('1201', '2301', ['4601', '4602'])
      const request = server.receivedRequests[0]
      expect(request.method).toBe('PUT')
    })

    test('includes provisional grade ids in the request body', async () => {
      server.for(url).respond({status: 200, body: {}})
      await GradesApi.bulkSelectProvisionalGrades('1201', '2301', ['4601', '4602'])
      const request = server.receivedRequests[0]
      const json = jsonBodyFromRequest(request)
      expect(json.provisional_grade_ids).toEqual(['4601', '4602'])
    })

    test('does not catch failures', async () => {
      server.for(url).respond({status: 500, body: {error: 'server error'}})
      await expect(
        GradesApi.bulkSelectProvisionalGrades('1201', '2301', ['4601', '4602'])
      ).rejects.toThrow('500')
    })
  })

  describe('.selectProvisionalGrade()', () => {
    const url = `/api/v1/courses/1201/assignments/2301/provisional_grades/4601/select`

    test('sends a request to select a provisional grade', async () => {
      server.for(url).respond({status: 200, body: {}})
      await GradesApi.selectProvisionalGrade('1201', '2301', '4601')
      const request = server.receivedRequests[0]
      expect(pathFromRequest(request)).toBe(url)
    })

    test('sends a PUT request', async () => {
      server.for(url).respond({status: 200, body: {}})
      await GradesApi.selectProvisionalGrade('1201', '2301', '4601')
      const request = server.receivedRequests[0]
      expect(request.method).toBe('PUT')
    })

    test('does not catch failures', async () => {
      server.for(url).respond({status: 500, body: {error: 'server error'}})
      await expect(GradesApi.selectProvisionalGrade('1201', '2301', '4601')).rejects.toThrow('500')
    })
  })

  describe('.updateProvisionalGrade()', () => {
    const url = `/courses/1201/gradebook/update_submission`

    let responseBody
    let submission

    beforeEach(() => {
      responseBody = [{submission: {id: '2501', provisional_grade_id: '4601'}}]
      submission = {
        assignmentId: '2301',
        final: true,
        grade: 10,
        gradedAnonymously: false,
      }
    })

    test('sends a request to update a provisional grade', async () => {
      server.for(url).respond({status: 200, body: responseBody})
      await GradesApi.updateProvisionalGrade('1201', submission)
      const request = server.receivedRequests[0]
      expect(pathFromRequest(request)).toBe(url)
    })

    test('sends a POST request', async () => {
      server.for(url).respond({status: 200, body: responseBody})
      await GradesApi.updateProvisionalGrade('1201', submission)
      const request = server.receivedRequests[0]
      expect(request.method).toBe('POST')
    })

    test('includes submission data in the request body', async () => {
      server.for(url).respond({status: 200, body: responseBody})
      await GradesApi.updateProvisionalGrade('1201', submission)
      const request = server.receivedRequests[0]
      const json = jsonBodyFromRequest(request)
      expect(json.submission).toBeDefined()
    })

    test('camel-cases the submission assignment id', async () => {
      server.for(url).respond({status: 200, body: responseBody})
      await GradesApi.updateProvisionalGrade('1201', submission)
      const request = server.receivedRequests[0]
      const json = jsonBodyFromRequest(request)
      expect(json.submission.assignment_id).toBe('2301')
    })

    test('includes the submission "final" field', async () => {
      server.for(url).respond({status: 200, body: responseBody})
      await GradesApi.updateProvisionalGrade('1201', submission)
      const request = server.receivedRequests[0]
      const json = jsonBodyFromRequest(request)
      expect(json.submission.final).toBe(true)
    })

    test('uses the submission score for the "grade" field', async () => {
      server.for(url).respond({status: 200, body: responseBody})
      await GradesApi.updateProvisionalGrade('1201', submission)
      const request = server.receivedRequests[0]
      const json = jsonBodyFromRequest(request)
      expect(json.submission.grade).toBe(10)
    })

    test('includes the submission "graded_anonymously" field', async () => {
      server.for(url).respond({status: 200, body: responseBody})
      await GradesApi.updateProvisionalGrade('1201', submission)
      const request = server.receivedRequests[0]
      const json = jsonBodyFromRequest(request)
      expect(json.submission.graded_anonymously).toBe(false)
    })

    test('sets the submission "provisional" field to true', async () => {
      server.for(url).respond({status: 200, body: responseBody})
      await GradesApi.updateProvisionalGrade('1201', submission)
      const request = server.receivedRequests[0]
      const json = jsonBodyFromRequest(request)
      expect(json.submission.provisional).toBe(true)
    })

    test('camel-cases the returned submission', async () => {
      server.for(url).respond({status: 200, body: responseBody})
      const updatedSubmission = await GradesApi.updateProvisionalGrade('1201', submission)
      const expected = {id: '2501', provisionalGradeId: '4601'}
      expect(updatedSubmission).toEqual(expected)
    })

    test('does not catch failures', async () => {
      server.for(url).respond({status: 500, body: {error: 'server error'}})
      await expect(GradesApi.updateProvisionalGrade('1201', submission)).rejects.toThrow('500')
    })
  })
})
