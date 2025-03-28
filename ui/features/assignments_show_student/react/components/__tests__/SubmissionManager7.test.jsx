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

import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'
import {mockAssignmentAndSubmission} from '@canvas/assignments/graphql/studentMocks'
import {MockedProviderWithPossibleTypes as MockedProvider} from '@canvas/util/react/testing/MockedProviderWithPossibleTypes'
import {render, waitFor, within} from '@testing-library/react'
import React from 'react'
import ContextModuleApi from '../../apis/ContextModuleApi'
import StudentViewContext, {StudentViewContextDefaults} from '../Context'
import SubmissionManager from '../SubmissionManager'

jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
}))

// Mock the RCE so we can test text entry submissions without loading the whole
// editor
jest.mock('@canvas/rce/RichContentEditor')

jest.mock('../../apis/ContextModuleApi')

jest.mock('@canvas/do-fetch-api-effect')

jest.useFakeTimers()

function renderInContext(overrides = {}, children) {
  const contextProps = {...StudentViewContextDefaults, ...overrides}

  return render(
    <StudentViewContext.Provider value={contextProps}>{children}</StudentViewContext.Provider>,
  )
}

function gradedOverrides() {
  return {
    Submission: {
      rubricAssessmentsConnection: {
        nodes: [
          {
            _id: 1,
            score: 5,
            assessor: {_id: 1, name: 'assessor1', enrollments: []},
          },
          {
            _id: 2,
            score: 10,
            assessor: null,
          },
          {
            _id: 3,
            score: 8,
            assessor: {_id: 2, name: 'assessor2', enrollments: [{type: 'TaEnrollment'}]},
          },
        ],
      },
    },
  }
}

describe('SubmissionManager', () => {
  beforeAll(() => {
    window.INST = window.INST || {}
    window.INST.editorButtons = []
  })

  beforeEach(() => {
    ContextModuleApi.getContextModuleData.mockResolvedValue({})
  })

  describe('footer', () => {
    it('is rendered if at least one button can be shown', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {
          submissionTypes: ['online_text_entry'],
        },
        Submission: {...SubmissionMocks.submitted},
      })

      const {getByTestId} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>,
      )

      expect(getByTestId('student-footer')).toBeInTheDocument()
    })

    it('is not rendered if no buttons can be shown', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.submitted},
      })

      const {queryByTestId} = renderInContext(
        {allowChangesToSubmission: false},
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>,
      )

      expect(queryByTestId('student-footer')).not.toBeInTheDocument()
    })

    describe('modules', () => {
      let oldEnv

      beforeEach(() => {
        oldEnv = window.ENV
        window.ENV = {
          ...oldEnv,
          ASSIGNMENT_ID: '1',
          COURSE_ID: '1',
        }

        ContextModuleApi.getContextModuleData.mockClear()
      })

      afterEach(() => {
        window.ENV = oldEnv
      })

      it('renders next and previous module links if they exist for the assignment', async () => {
        const props = await mockAssignmentAndSubmission({
          Assignment: {
            submissionTypes: ['online_text_entry'],
          },
          Submission: {...SubmissionMocks.submitted},
        })

        ContextModuleApi.getContextModuleData.mockResolvedValue({
          next: {url: '/next', tooltipText: {string: 'some module'}},
          previous: {url: '/previous', tooltipText: {string: 'some module'}},
        })

        const {getByTestId} = render(
          <MockedProvider>
            <SubmissionManager {...props} />
          </MockedProvider>,
        )

        await waitFor(() => expect(ContextModuleApi.getContextModuleData).toHaveBeenCalled())
        const footer = getByTestId('student-footer')
        expect(
          within(footer).getByTestId('previous-assignment-btn', {name: /Previous/}),
        ).toBeInTheDocument()
        expect(
          within(footer).getByTestId('next-assignment-btn', {name: /Next/}),
        ).toBeInTheDocument()
      })

      it('does not render module buttons if no next/previous modules exist for the assignment', async () => {
        const props = await mockAssignmentAndSubmission({
          Assignment: {
            submissionTypes: ['online_text_entry'],
          },
          Submission: {...SubmissionMocks.submitted},
        })

        ContextModuleApi.getContextModuleData.mockResolvedValue({})

        const {queryByRole} = render(
          <MockedProvider>
            <SubmissionManager {...props} />
          </MockedProvider>,
        )

        await waitFor(() => expect(ContextModuleApi.getContextModuleData).toHaveBeenCalled())
        expect(queryByRole('link', {name: /Previous/})).not.toBeInTheDocument()
        expect(queryByRole('link', {name: /Next/})).not.toBeInTheDocument()
      })
    })
  })
})
