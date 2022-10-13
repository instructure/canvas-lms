/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {
  determineSubmissionSelection,
  makeSubmissionUpdateRequest,
} from '../SpeedGraderStatusMenuHelpers'
import moxios from 'moxios'

describe('determineSubmissionSelection', () => {
  let submission

  beforeEach(() => {
    submission = {
      excused: false,
      late: false,
      missing: false,
    }
  })

  it('returns none if no status attributes are "true"', () => {
    expect(determineSubmissionSelection(submission)).toEqual('none')
  })

  it('returns late if late attribute is "true" and excused attribute is "false', () => {
    submission.late = true
    expect(determineSubmissionSelection(submission)).toEqual('late')
  })

  it('returns missing if missing attribute is "true" and all other status attributes are "false"', () => {
    submission.missing = true
    expect(determineSubmissionSelection(submission)).toEqual('missing')
  })

  it('returns excused if excused attribute is true regardless of other status attribute values', () => {
    submission.late = true
    submission.missing = true
    submission.excused = true
    expect(determineSubmissionSelection(submission)).toEqual('excused')
  })
})

describe('makeSubmissionUpdateRequest', () => {
  let data
  let isAnonymous
  let courseId
  let submission

  function setupMocks() {
    moxios.stubRequest('/api/v1/courses/1/assignments/2/submissions/3', {
      status: 200,
      response: {},
    })
  }

  beforeEach(() => {
    data = {latePolicyStatus: 'none'}
    isAnonymous = false
    courseId = 1
    submission = {
      assignment_id: 2,
      user_id: 3,
    }

    moxios.install()
    setupMocks()
  })

  afterEach(() => {
    moxios.uninstall()
  })

  it('makes a request to the proper endpoint', function (done) {
    makeSubmissionUpdateRequest(submission, isAnonymous, courseId, data)
    moxios.wait(() => {
      const request = moxios.requests.mostRecent()
      expect(request.url).toEqual('/api/v1/courses/1/assignments/2/submissions/3')
      done()
    })
  })

  it('makes a request to the "anonymous" endpoint if the assignment is anonymous', function (done) {
    isAnonymous = true
    submission.anonymous_id = 'i9Z1a'
    makeSubmissionUpdateRequest(submission, isAnonymous, courseId, data)
    moxios.wait(() => {
      const request = moxios.requests.mostRecent()
      expect(request.url).toEqual(
        `/api/v1/courses/1/assignments/2/anonymous_submissions/${submission.anonymous_id}`
      )
      done()
    })
  })

  it('makes a request with the expected params underscored properly when submission status is "none"', function (done) {
    const expectedData = {
      submission: {
        assignment_id: 2,
        late_policy_status: 'none',
        user_id: 3,
      },
    }

    makeSubmissionUpdateRequest(submission, isAnonymous, courseId, data)
    moxios.wait(() => {
      const request = moxios.requests.mostRecent()
      expect(JSON.parse(request.config.data)).toEqual(expectedData)
      done()
    })
  })

  it('makes a request with the expected params underscored properly when submission status is "missing"', function (done) {
    data = {latePolicyStatus: 'missing'}

    const expectedData = {
      submission: {
        assignment_id: 2,
        late_policy_status: 'missing',
        user_id: 3,
      },
    }

    makeSubmissionUpdateRequest(submission, isAnonymous, courseId, data)
    moxios.wait(() => {
      const request = moxios.requests.mostRecent()
      expect(JSON.parse(request.config.data)).toEqual(expectedData)
      done()
    })
  })

  it('makes a request with the expected params underscored properly when submission status is "late"', function (done) {
    data = {latePolicyStatus: 'late', secondsLateOverride: 100}

    const expectedData = {
      submission: {
        assignment_id: 2,
        late_policy_status: 'late',
        seconds_late_override: 100,
        user_id: 3,
      },
    }

    makeSubmissionUpdateRequest(submission, isAnonymous, courseId, data)
    moxios.wait(() => {
      const request = moxios.requests.mostRecent()
      expect(JSON.parse(request.config.data)).toEqual(expectedData)
      done()
    })
  })

  it('makes a request with the expected params underscored properly when submission status is "excused"', function (done) {
    data = {excuse: true}

    const expectedData = {
      submission: {
        assignment_id: 2,
        excuse: true,
        user_id: 3,
      },
    }

    makeSubmissionUpdateRequest(submission, isAnonymous, courseId, data)
    moxios.wait(() => {
      const request = moxios.requests.mostRecent()
      expect(JSON.parse(request.config.data)).toEqual(expectedData)
      done()
    })
  })
})
