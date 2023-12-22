/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
  getOriginalityData,
  isOriginalityReportVisible,
  originalityReportSubmissionKey,
} from '@canvas/grading/originalityReportHelper'
import {mockSubmission} from '../graphql/studentMocks'
import type {SubmissionOriginalityData} from '@canvas/grading/grading'

function submission(overrides = {}): {
  id: string
  _id: string
  submitted_at: string
  submissionType: string
  attachments: any[]
  originalityData: {
    [key: string]: SubmissionOriginalityData
  }
} {
  return {
    id: '1',
    _id: '1',
    submitted_at: '05 October 2011 14:48 UTC',
    submissionType: 'online_text_entry',
    originalityData: {
      'submission_1_2011-10-05T14:48:00Z': {
        provider: 'vericite',
        report_url: 'string',
        similarity_score: 0,
        state: 'scored',
        status: 'none',
      },
    },
    attachments: [],
    ...overrides,
  }
}

describe('originalityReportSubmissionKey', () => {
  it('returns the key for the submission', () => {
    expect(originalityReportSubmissionKey(submission())).toEqual(
      'submission_1_2011-10-05T14:48:00Z'
    )
  })

  it('returns the key for the camelized graphql submission', async () => {
    const gqlSubmission = await mockSubmission({
      // @ts-expect-error
      Submission: {
        submittedAt: '2011-10-05T14:48:00Z',
        id: 1,
      },
    })
    expect(originalityReportSubmissionKey(gqlSubmission)).toEqual(
      'submission_1_2011-10-05T14:48:00Z'
    )
  })

  describe('when the submission does not have a valid "submitted_at"', () => {
    const overrides = {
      submitted_at: 'banana',
    }

    it('returns the an empty string', () => {
      expect(originalityReportSubmissionKey(submission(overrides))).toEqual('')
    })
  })
})

describe('originalityReportVisibility', () => {
  it('returns true if visiblity setting not set', () => {
    expect(isOriginalityReportVisible(null, Date.now.toString(), 'needs_grading')).toBe(true)
  })

  it('returns true if visiblity setting is set to immediate', () => {
    expect(isOriginalityReportVisible('immediate', Date.now.toString(), 'needs_grading')).toBe(true)
  })

  it('returns false if visiblity setting is set to never', () => {
    expect(isOriginalityReportVisible('never', Date.now.toString(), 'needs_grading')).toBe(false)
  })

  it('returns false if visiblity setting is set to after_grading and the submisison has not been graded', () => {
    expect(isOriginalityReportVisible('after_grading', Date.now.toString(), 'needs_grading')).toBe(
      false
    )
  })

  it('returns true if visiblity setting is set to after_grading and the submisison has excused', () => {
    expect(isOriginalityReportVisible('after_grading', Date.now.toString(), 'excused')).toBe(true)
  })

  it('returns true if visiblity setting is set to after_grading and the submisison has been graded', () => {
    expect(isOriginalityReportVisible('after_grading', Date.now.toString(), 'graded')).toBe(true)
  })

  it('returns false if visiblity setting is set to after_due_date and the due date has not passed', () => {
    const today = new Date()
    const tomorrow = new Date(today)
    tomorrow.setDate(tomorrow.getDate() + 1)
    expect(isOriginalityReportVisible('after_due_date', tomorrow.toString(), 'graded')).toBe(false)
  })

  it('returns true if visiblity setting is set to after_due_date and the due date has passed', () => {
    const today = new Date()
    const yesterday = new Date(today)
    yesterday.setDate(yesterday.getDate() - 1)
    expect(isOriginalityReportVisible('after_due_date', yesterday.toString(), 'graded')).toBe(true)
  })
})

describe('getOriginalityData', () => {
  const originalityData = {
    attachment_1: {
      similarity_score: 0,
      state: 'acceptable',
      report_url: 'http://example.com',
      status: 'scored',
      data: '{}',
    },
    attachment_2: {
      similarity_score: 10,
      state: 'error',
      report_url: 'http://example.com',
      status: 'error',
      data: '{}',
    },
    attachment_3: {
      data: null,
    },
    submission_1: {
      similarity_score: 10,
      state: 'acceptable',
      report_url: 'http://example.com',
      status: 'scored',
      data: '{}',
    },
    'submission_4_2011-10-05T14:48:00Z': {
      similarity_score: 99,
      state: 'acceptable',
      report_url: 'http://example.com',
      status: 'scored',
      data: '{}',
    },
  }

  const attachments = [
    {
      _id: '1',
      displayName: 'file_1.png',
      id: '1',
      mimeClass: 'image',
      submissionPreviewUrl: '/preview_url',
      thumbnailUrl: '/thumbnail_url',
      url: '/url',
    },
    {
      _id: '2',
      displayName: 'file_1.png',
      id: '2',
      mimeClass: 'image',
      submissionPreviewUrl: '/preview_url',
      thumbnailUrl: '/thumbnail_url',
      url: '/url',
    },
    {
      _id: '3',
      displayName: 'file_1.png',
      id: '3',
      mimeClass: 'image',
      submissionPreviewUrl: '/preview_url',
      thumbnailUrl: '/thumbnail_url',
      url: '/url',
    },
  ]

  it('returns the camelized data if there is data associated with an attachment with a score and report', () => {
    const sub = submission({
      submissionType: 'online_upload',
      attachments,
      originalityData,
    })
    expect(getOriginalityData(sub, 0)).toEqual({
      score: 0,
      state: 'acceptable',
      reportUrl: 'http://example.com',
      status: 'scored',
    })
  })

  it('returns false if there is data associated with an attachment in an error state', () => {
    const sub = submission({submissionType: 'online_upload', attachments, originalityData})
    expect(getOriginalityData(sub, 1)).toBe(false)
  })

  it('returns false if there is no originality data associated with an attachment', () => {
    const sub = submission({submissionType: 'online_upload', attachments, originalityData})
    expect(getOriginalityData(sub, 2)).toBe(false)
  })

  it('returns the camelized data if there is originality data associated with the text entry using a gql submission', async () => {
    const gqlSubmission = await mockSubmission({
      // @ts-expect-error
      Submission: {
        id: 'asefasdfasdfasdfasdf',
        _id: 4,
        submittedAt: '2011-10-05T14:48:00Z',
        originalityData,
        submissionType: 'online_text_entry',
      },
    })
    expect(getOriginalityData(gqlSubmission, 0)).toEqual({
      score: 99,
      state: 'acceptable',
      reportUrl: 'http://example.com',
      status: 'scored',
    })
  })

  it('returns the camelized data if there is originality data associated with the text entry', () => {
    const sub = submission({submissionType: 'online_text_entry', attachments, originalityData})
    expect(getOriginalityData(sub, 0)).toEqual({
      score: 10,
      state: 'acceptable',
      reportUrl: 'http://example.com',
      status: 'scored',
    })
  })
})
