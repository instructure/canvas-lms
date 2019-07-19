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

import AttemptTab from '../AttemptTab'
import {mockAssignment, mockSubmission, submissionGraphqlMock} from '../../test-utils'
import {MockedProvider} from 'react-apollo/test-utils'
import React from 'react'
import {render} from '@testing-library/react'

describe('ContentTabs', () => {
  describe('the submission type is online_upload', () => {
    const mockedAssignment = mockAssignment({
      submissionTypes: ['online_upload']
    })

    it('renders the file upload tab when the submission is unsubmitted', () => {
      const mockedSubmission = mockSubmission({
        state: 'unsubmitted'
      })

      const {getByTestId} = render(
        <MockedProvider mocks={submissionGraphqlMock()} addTypename>
          <AttemptTab assignment={mockedAssignment} submission={mockedSubmission} />
        </MockedProvider>
      )

      expect(getByTestId('upload-pane')).toBeInTheDocument()
    })

    it('renders the file preview tab when the submission is submitted', () => {
      const {getByTestId} = render(
        <MockedProvider mocks={submissionGraphqlMock()} addTypename>
          <AttemptTab assignment={mockedAssignment} submission={mockSubmission()} />
        </MockedProvider>
      )

      expect(getByTestId('assignments_2_submission_preview')).toBeInTheDocument()
    })
  })

  describe('the submission type is online_text_entry', () => {
    const mockedAssignment = mockAssignment({
      submissionTypes: ['online_text_entry']
    })

    it('renders the text entry tab', () => {
      const {getByTestId} = render(
        <MockedProvider mocks={submissionGraphqlMock()} addTypename>
          <AttemptTab assignment={mockedAssignment} submission={mockSubmission()} />
        </MockedProvider>
      )

      expect(getByTestId('text-entry')).toBeInTheDocument()
    })
  })
})
