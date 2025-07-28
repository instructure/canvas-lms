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

describe('SubmissionManager', () => {
  beforeAll(() => {
    window.INST = window.INST || {}
    window.INST.editorButtons = []
  })

  beforeEach(() => {
    ContextModuleApi.getContextModuleData.mockResolvedValue({})
  })

  describe('"Back to Attempt" button', () => {
    it('is rendered if a draft exists and a previous attempt is shown', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.submitted},
      })
      const latestSubmission = {attempt: 2, state: 'unsubmitted'}

      const {getByTestId} = renderInContext(
        {latestSubmission},
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>,
      )

      expect(getByTestId('back-to-attempt-button')).toBeInTheDocument()
    })

    it('includes the current attempt number', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.submitted},
      })
      const latestSubmission = {attempt: 2, state: 'unsubmitted'}

      const {getByTestId} = renderInContext(
        {latestSubmission},
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>,
      )
      const button = getByTestId('back-to-attempt-button')
      expect(button).toHaveTextContent('Back to Attempt 2')
    })

    it('is not rendered if no current draft exists', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.submitted},
      })

      const {queryByTestId} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('back-to-attempt-button')).not.toBeInTheDocument()
    })

    it('is not rendered if the current draft is selected', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.submitted},
      })
      const latestSubmission = props.submission

      const {queryByTestId} = renderInContext(
        {latestSubmission},
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('back-to-attempt-button')).not.toBeInTheDocument()
    })

    it('calls the showDraftAction function supplied by the context when clicked', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.submitted},
      })

      const latestSubmission = {
        activeSubmissionType: 'online_text_entry',
        attempt: 2,
        state: 'unsubmitted',
      }
      const showDraftAction = jest.fn()

      const {getByTestId} = renderInContext(
        {latestSubmission, showDraftAction},
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>,
      )

      act(() => {
        fireEvent.click(getByTestId('back-to-attempt-button'))
      })
      expect(showDraftAction).toHaveBeenCalled()
    })
  })
})
