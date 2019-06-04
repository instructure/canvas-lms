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
import {MockedProvider} from 'react-apollo/test-utils'
import {mockSubmission} from '../../test-utils'
import React from 'react'
import {render, waitForElement} from 'react-testing-library'
import {SUBMISSION_ATTACHMENTS_QUERY} from '../../assignmentData'

let mocks

describe('AttemptTab', () => {
  describe('file preview', () => {
    beforeEach(() => {
      mocks = [
        {
          request: {
            query: SUBMISSION_ATTACHMENTS_QUERY,
            variables: {
              submissionId: '22'
            }
          },
          result: {
            data: {
              submission: {
                attachments: [
                  {
                    __typename: 'Attachment',
                    submissionPreviewUrl: '/some_dope_url',
                    displayName: 'some_dope_file.pdf'
                  }
                ],
                __typename: 'Submission'
              }
            }
          }
        }
      ]
    })

    it('renders an error page if the graphql query fails', async () => {
      mocks[0].result = {
        errors: {
          message: 'oops I failed!',
          __typename: 'Errors'
        }
      }
      const {getByText} = render(
        <MockedProvider mocks={mocks} addTypename>
          <AttemptTab submission={mockSubmission()} />
        </MockedProvider>
      )

      const errorMessage = await waitForElement(() => getByText('Sorry, Something Broke'))
      expect(errorMessage).toBeInTheDocument()
    })

    it('renders the docviewer iframe if we have a previewable file', async () => {
      const {getByTestId, getByText} = render(
        <MockedProvider mocks={mocks} addTypename>
          <AttemptTab submission={mockSubmission()} />
        </MockedProvider>
      )

      const docviewerIframe = await waitForElement(() =>
        getByTestId('assignments_2_submission_preview')
      )
      expect(docviewerIframe).toBeInTheDocument()
      expect(getByText('some_dope_file.pdf')).toBeInTheDocument()
    })

    it('renders a message indicating the file has no preview for non-previewable files', async () => {
      mocks[0].result.data.submission.attachments[0].submissionPreviewUrl = null
      const {getByText} = render(
        <MockedProvider mocks={mocks} addTypename>
          <AttemptTab submission={mockSubmission()} />
        </MockedProvider>
      )

      expect(
        await waitForElement(() => getByText('No preview available for file'))
      ).toBeInTheDocument()
    })
  })
})
