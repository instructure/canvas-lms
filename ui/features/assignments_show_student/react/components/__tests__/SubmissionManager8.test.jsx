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

import {mockAssignmentAndSubmission} from '@canvas/assignments/graphql/studentMocks'
import {MockedProviderWithPossibleTypes as MockedProvider} from '@canvas/util/react/testing/MockedProviderWithPossibleTypes'
import {act, fireEvent, render, screen} from '@testing-library/react'
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

  describe('similarity pledge', () => {
    let props

    beforeEach(async () => {
      window.ENV.SIMILARITY_PLEDGE = {
        COMMENTS: 'hi',
        EULA_URL: 'http://someurl.com',
        PLEDGE_TEXT: 'some text',
      }

      props = await mockAssignmentAndSubmission({
        Assignment: {
          submissionTypes: ['online_text_entry', 'online_url'],
        },
        Submission: {
          submissionDraft: {
            activeSubmissionType: 'online_text_entry',
            body: 'some text here',
            meetsTextEntryCriteria: true,
            meetsUrlCriteria: true,
            url: 'http://www.google.com',
          },
        },
      })
    })

    afterEach(() => {
      delete window.ENV.SIMILARITY_PLEDGE
    })

    it('is rendered if pledge settings are provided', () => {
      const {getByLabelText} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>,
      )

      expect(getByLabelText(/I agree to the tool's/)).toBeInTheDocument()
    })

    it('is not rendered if no pledge settings are provided', () => {
      delete window.ENV.SIMILARITY_PLEDGE

      const {queryByLabelText} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>,
      )

      expect(queryByLabelText(/I agree to the tool's/)).not.toBeInTheDocument()
    })

    it('displays an error message if the user attempts to submit but has not agreed to the pledge', () => {
      const {getByTestId, getByLabelText} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>,
      )
      const submitButton = getByTestId('submit-button')
      act(() => {
        fireEvent.click(submitButton)
      })
      expect(getByLabelText(/You must agree to the submission pledge before you can submit the assignment/)).toBeInTheDocument()
    })

    it('removes the error message after the user agrees to the pledge', () => {
      const {getByTestId, getByLabelText, queryByLabelText} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>,
      )
      const submitButton = getByTestId('submit-button')
      act(() => {
        fireEvent.click(submitButton)
      })
      expect(getByLabelText(/You must agree to the submission pledge before you can submit the assignment/)).toBeInTheDocument()

      const agreementCheckbox = getByLabelText(/I agree to the tool's/)
      act(() => {
        fireEvent.click(agreementCheckbox)
      })
      expect(queryByLabelText(/You must agree to the submission pledge before you can submit the assignment/)).not.toBeInTheDocument()

    })
  })
})
