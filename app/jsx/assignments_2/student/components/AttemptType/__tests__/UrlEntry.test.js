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

import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import {mockSubmission} from '../../../mocks'
import UrlEntry from '../UrlEntry'

async function makeProps(overrides) {
  const submission = await mockSubmission(overrides)
  const props = {
    submission,
    createSubmissionDraft: jest.fn().mockResolvedValue({}),
    updateEditingDraft: jest.fn()
  }
  return props
}

describe('UrlEntry', () => {
  it('renders the website url input', async () => {
    const props = await makeProps({
      Submission: {
        submissionDraft: {
          activeSubmissionType: 'online_url',
          attachments: () => [],
          body: null,
          meetsAssignmentCriteria: false,
          url: null
        }
      }
    })
    const {getByTestId} = render(<UrlEntry {...props} />)

    expect(getByTestId('url-entry')).toBeInTheDocument()
  })

  it('renders an error message when given an invalid url', async () => {
    const props = await makeProps({
      Submission: {
        submissionDraft: {
          activeSubmissionType: 'online_url',
          attachments: () => [],
          body: null,
          meetsAssignmentCriteria: false,
          url: 'not a valid url'
        }
      }
    })
    const {getByText} = render(<UrlEntry {...props} />)

    expect(getByText('Please enter a valid url (e.g. http://example.com)')).toBeInTheDocument()
  })

  it('renders the preview button when the url is considered valid', async () => {
    const props = await makeProps({
      Submission: {
        submissionDraft: {
          activeSubmissionType: 'online_url',
          attachments: () => [],
          body: null,
          meetsAssignmentCriteria: true,
          url: 'http://www.valid.com'
        }
      }
    })
    const {getByTestId} = render(<UrlEntry {...props} />)

    expect(getByTestId('preview-button')).toBeInTheDocument()
  })

  it('opens a new window with the url when you press the preview button', async () => {
    const props = await makeProps({
      Submission: {
        submissionDraft: {
          activeSubmissionType: 'online_url',
          attachments: () => [],
          body: null,
          meetsAssignmentCriteria: true,
          url: 'http://www.reddit.com'
        }
      }
    })
    window.open = jest.fn()
    const {getByTestId} = render(<UrlEntry {...props} />)

    const previewButton = getByTestId('preview-button')
    fireEvent.click(previewButton)
    expect(window.open).toHaveBeenCalledTimes(1)
  })
})
