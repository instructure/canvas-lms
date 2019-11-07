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
import MediaAttempt from '../MediaAttempt'
import {mockAssignmentAndSubmission} from '../../../mocks'
import React from 'react'

const submissionDraftOverrides = {
  Submission: {
    submissionDraft: {
      activeSubmissionType: 'media_recording',
      attachments: () => [],
      body: null,
      meetsMediaRecordingCriteria: true,
      mediaObject: {
        _id: 'm-123456',
        id: '1',
        title: 'dope video'
      }
    }
  }
}

const makeProps = async overrides => {
  const assignmentAndSubmission = await mockAssignmentAndSubmission(overrides)
  return {
    ...assignmentAndSubmission,
    createSubmissionDraft: jest.fn(),
    updateUploadingFiles: jest.fn(),
    uploadingFiles: false
  }
}

describe('MediaAttempt', () => {
  describe('unsubmitted', () => {
    it('renders the upload tab by default', async () => {
      const props = await makeProps()
      const {getByText} = render(<MediaAttempt {...props} />)
      expect(getByText('Record/Upload')).toBeInTheDocument()
      expect(getByText('Add Media')).toBeInTheDocument()
    })

    it('renders the current submission draft', async () => {
      const props = await makeProps(submissionDraftOverrides)
      const {getByTestId} = render(<MediaAttempt {...props} />)
      expect(getByTestId('media-recording')).toBeInTheDocument()
    })

    it('removes the current submission draft when the media is removed', async () => {
      const props = await makeProps(submissionDraftOverrides)
      const {getByTestId} = render(<MediaAttempt {...props} />)
      const trashButton = getByTestId('remove-media-recording')
      fireEvent.click(trashButton)

      expect(props.createSubmissionDraft).toHaveBeenCalledWith({
        variables: {
          id: '1',
          activeSubmissionType: 'media_recording',
          attempt: 1
        }
      })
    })
  })

  describe('submitted', () => {
    it('renders the current submission', async () => {
      const props = await makeProps({
        Submission: {
          mediaObject: {
            _id: 'm-123456',
            id: '1',
            title: 'dope_vid.mov'
          },
          state: 'submitted'
        }
      })
      const {getByTestId, queryByTestId} = render(
        <MediaAttempt {...props} uploadingFiles={false} />
      )
      expect(queryByTestId('remove-media-recording')).not.toBeInTheDocument()
      expect(getByTestId('media-recording')).toBeInTheDocument()
    })
  })

  // This will crash given the media modal requires browser specifics
  // fwiw get a real browser or test with selenium
  // it('opens media modal when button is clicked', async () => {
  // const assignment = await mockAssignment()
  // const {getByText, getByTestId} = render(<MediaAttempt assignment={assignment} />)
  // const editButton = getByTestId('media-modal-launch-button')
  // fireEvent.click(editButton)
  // expect(
  // await waitForElement(() => getByText('drag and drop or clik to browse'))
  // ).toBeInTheDocument()
  // })
})
