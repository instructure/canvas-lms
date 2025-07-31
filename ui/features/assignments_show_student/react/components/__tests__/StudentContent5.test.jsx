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

import React from 'react'
import {MockedProvider} from '@apollo/client/testing'
import {render} from '@testing-library/react'
import {
  mockAssignmentAndSubmission,
  mockQuery,
  mockSubmission,
} from '@canvas/assignments/graphql/studentMocks'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'
import StudentContent from '../StudentContent'
import ContextModuleApi from '../../apis/ContextModuleApi'

injectGlobalAlertContainers()

jest.mock('../AttemptSelect')

jest.mock('../../apis/ContextModuleApi')

jest.mock('../../../../../shared/immersive-reader/ImmersiveReader', () => {
  return {
    initializeReaderButton: jest.fn(),
  }
})

describe('Assignment Student Content View', () => {
  let oldEnv

  beforeEach(() => {
    oldEnv = window.ENV
    window.ENV = {...window.ENV}
    ContextModuleApi.getContextModuleData.mockResolvedValue({})
  })

  afterEach(() => {
    window.ENV = oldEnv
  })

  describe('originality report', () => {
    it('is rendered when a submission exists with turnitinData attached and the assignment is available with a text entry submission', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {submissionType: 'online_text_entry'},
      })

      props.submission.originalityData = {
        submission_1: {
          similarity_score: 10,
          state: 'acceptable',
          report_url: 'http://example.com',
          status: 'scored',
          data: '{}',
        },
      }
      props.assignment.env.originalityReportsForA2Enabled = true
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('originality_report')).toBeInTheDocument()
    })

    it('is not rendered when the originality reports for a2 FF is not enabled', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {submissionType: 'online_text_entry'},
      })
      props.submission.originalityData = {
        submission_1: {
          similarity_score: 10,
          state: 'acceptable',
          report_url: 'http://example.com',
          status: 'scored',
          data: '{}',
        },
      }
      props.assignment.env.originalityReportsForA2Enabled = false
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('originality_report')).not.toBeInTheDocument()
    })

    it('is not rendered when the originality report is not visibile to the student', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {submissionType: 'online_text_entry'},
      })
      props.submission.originalityData = {
        submission_1: {
          similarity_score: 10,
          state: 'acceptable',
          report_url: 'http://example.com',
          status: 'scored',
          data: '{}',
        },
      }
      const today = new Date()
      const tomorrow = new Date(today)
      tomorrow.setDate(tomorrow.getDate() + 1)
      props.assignment.dueAt = tomorrow.toString()
      props.assignment.originalityReportVisibility = 'after_due_date'
      props.assignment.env.originalityReportsForA2Enabled = true
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('originality_report')).not.toBeInTheDocument()
    })

    it('is rendered when the originality report is visibile to the student', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {submissionType: 'online_text_entry'},
      })
      props.submission.originalityData = {
        submission_1: {
          similarity_score: 10,
          state: 'acceptable',
          report_url: 'http://example.com',
          status: 'scored',
          data: '{}',
        },
      }
      const today = new Date()
      const yesterday = new Date(today)
      yesterday.setDate(yesterday.getDate() - 1)
      props.assignment.dueAt = yesterday.toString()
      props.assignment.originalityReportVisibility = 'after_due_date'
      props.assignment.env.originalityReportsForA2Enabled = true
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('originality_report')).toBeInTheDocument()
    })

    it('is rendered when a submission exists with turnitinData attached and the assignment is available with a online upload submission with only one attachment', async () => {
      const file = {
        _id: '1',
        displayName: 'file_1.png',
        id: '1',
        mimeClass: 'image',
        submissionPreviewUrl: '/preview_url',
        thumbnailUrl: '/thumbnail_url',
        url: '/url',
      }
      const props = await mockAssignmentAndSubmission({
        Submission: {submissionType: 'online_upload', attachments: [file]},
      })
      props.submission.originalityData = {
        attachment_1: {
          similarity_score: 10,
          state: 'acceptable',
          report_url: 'http://example.com',
          status: 'scored',
          data: '{}',
        },
      }
      props.assignment.env.originalityReportsForA2Enabled = true
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('originality_report')).toBeInTheDocument()
    })

    it('is not rendered when a submission exists with turnitinData attached and the assignment is available with a online upload submission with more than one attachment', async () => {
      const files = [
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
          _id: '1',
          displayName: 'file_1.png',
          id: '1',
          mimeClass: 'image',
          submissionPreviewUrl: '/preview_url',
          thumbnailUrl: '/thumbnail_url',
          url: '/url',
        },
      ]
      const props = await mockAssignmentAndSubmission({
        Submission: {submissionType: 'online_upload', attachments: files},
      })
      props.submission.turnitinData = [
        {
          similarity_score: 10,
          state: 'acceptable',
          report_url: 'http://example.com',
          status: 'scored',
          data: '{}',
        },
        {
          similarity_score: 10,
          state: 'acceptable',
          report_url: 'http://example.com',
          status: 'scored',
          data: '{}',
        },
      ]
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('originality_report')).not.toBeInTheDocument()
    })

    it('is not rendered when no submission object is present', async () => {
      const props = await mockAssignmentAndSubmission({Query: {submission: null}})
      props.allSubmissions = [{id: '1', _id: '1'}]
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('originality_report')).not.toBeInTheDocument()
    })

    it('is not rendered when there is no current user', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.currentUser = null
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('originality_report')).not.toBeInTheDocument()
    })

    it('is not rendered when the assignment has not been unlocked yet', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.modulePrereq = 'simulate not null'
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('originality_report')).not.toBeInTheDocument()
    })

    it('is not rendered when the assignment has uncompleted prerequisites', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.unlockDate = 'soon'
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('originality_report')).not.toBeInTheDocument()
    })

    it('is not rendered when the submission has no turnitinData', async () => {
      const props = await mockAssignmentAndSubmission()
      props.submission.turnitinData = null
      props.assignment.env.unlockDate = 'soon'
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('originality_report')).not.toBeInTheDocument()
    })
  })

  describe('render AnonymousLabel with ungraded submission', () => {
    let props
    beforeAll(async () => {
      props = await mockAssignmentAndSubmission()
      props.submission = {
        ...props.submission,
        hideGradeFromStudent: false,
        grade: null,
      }
    })

    it('not renders the anonymous label', () => {
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('assignment-student-anonymous-label')).not.toBeInTheDocument()
    })
  })

  describe('render AnonymousLabel hiding grade from student submission', () => {
    let props
    beforeAll(async () => {
      props = await mockAssignmentAndSubmission()
      props.submission = {
        ...props.submission,
        hideGradeFromStudent: true,
        grade: 10,
      }
    })

    it('not renders the anonymous label', () => {
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('assignment-student-anonymous-label')).not.toBeInTheDocument()
    })
  })

  describe('renderAnonymousLabel with graded submission', () => {
    let props
    beforeAll(async () => {
      props = await mockAssignmentAndSubmission()
      props.submission = {
        ...props.submission,
        hideGradeFromStudent: false,
        grade: 10,
      }
    })

    it('renders a label graded anonymously', () => {
      props.submission.gradedAnonymously = true
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('assignment-student-anonymus-label')).toHaveTextContent(
        'Anonymous Grading:yes',
      )
    })

    it('renders a label graded visibly', () => {
      props.submission.gradedAnonymously = false
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('assignment-student-anonymus-label')).toHaveTextContent(
        'Anonymous Grading:no',
      )
    })
  })
})
