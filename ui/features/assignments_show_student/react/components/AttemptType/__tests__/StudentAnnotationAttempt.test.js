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

import StudentAnnotationAttempt from '../StudentAnnotationAttempt'
import {render, waitFor} from '@testing-library/react'
import {mockAssignmentAndSubmission} from '@canvas/assignments/graphql/studentMocks'
import axios from '@canvas/axios'
import React from 'react'

async function makeProps(overrides) {
  const assignmentAndSubmission = await mockAssignmentAndSubmission(overrides)
  const props = {
    ...assignmentAndSubmission,
    title: 'Title',
    createSubmissionDraft: jest.fn().mockResolvedValue({}),
  }
  return props
}

describe('StudentAnnotationAttempt', () => {
  describe('when fetching canvadocs session fails', () => {
    beforeEach(() => {
      jest.spyOn(axios, 'post').mockRejectedValue({})
    })

    it('displays an error message', async () => {
      const props = await makeProps({})
      const {getByText} = render(<StudentAnnotationAttempt {...props} />)
      await waitFor(() => {
        expect(getByText('There was an error loading the document.')).toBeInTheDocument()
      })
    })
  })

  describe('when fetching canvadocs session succeeds', () => {
    let axiosMock
    beforeEach(() => {
      axiosMock = jest
        .spyOn(axios, 'post')
        .mockResolvedValue({data: {canvadocs_session_url: 'CANVADOCS_SESSION_URL'}})
    })

    it('renders an iframe for canvadocs', async () => {
      const props = await makeProps({})
      const {getByTestId} = render(<StudentAnnotationAttempt {...props} />)
      await waitFor(() => {
        expect(getByTestId('canvadocs-iframe')).toBeInTheDocument()
      })
    })

    it('sets the url of the iframe', async () => {
      const props = await makeProps({})
      const {getByTestId} = render(<StudentAnnotationAttempt {...props} />)
      await waitFor(() => {
        expect(getByTestId('canvadocs-iframe').src).toEqual(
          'http://localhost/CANVADOCS_SESSION_URL'
        )
      })
    })

    it('creates a submission draft when submission is unsubmitted', async () => {
      const props = await makeProps({
        Submission: {
          state: 'unsubmitted',
        },
      })
      render(<StudentAnnotationAttempt {...props} />)
      await waitFor(() => {
        expect(props.createSubmissionDraft).toHaveBeenCalled()
      })
    })

    it('does not create a submission draft when submission is submitted', async () => {
      const props = await makeProps({
        Submission: {
          state: 'submitted',
        },
      })
      render(<StudentAnnotationAttempt {...props} />)
      await waitFor(() => {
        expect(props.createSubmissionDraft).not.toHaveBeenCalled()
      })
    })

    it('sets submission_attempt=draft when attempt index is 0', async () => {
      const props = await makeProps({
        Submission: {
          state: 'graded',
          attempt: 0,
        },
      })

      render(<StudentAnnotationAttempt {...props} />)
      const params = {submission_attempt: 'draft', submission_id: '1'}
      await waitFor(() => {
        expect(axiosMock).toHaveBeenCalledWith('/api/v1/canvadoc_session', params)
      })
    })

    it('does not create a submission draft when submission is graded', async () => {
      const props = await makeProps({
        Submission: {
          state: 'graded',
        },
      })
      render(<StudentAnnotationAttempt {...props} />)
      await waitFor(() => {
        expect(props.createSubmissionDraft).not.toHaveBeenCalled()
      })
    })
  })
})
