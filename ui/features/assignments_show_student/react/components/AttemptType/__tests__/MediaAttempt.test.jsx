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

import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import MediaAttempt from '../MediaAttempt'
import MediaPlayer from '@instructure/ui-media-player'
import {mockAssignmentAndSubmission} from '@canvas/assignments/graphql/studentMocks'
import React from 'react'
import StudentViewContext from '../../Context'
import {enableFetchMocks} from 'jest-fetch-mock'

enableFetchMocks()

// We need to set up a mock, as for some reason, jest.spyOn does not work on the original MediaPlayer
jest.mock('@instructure/ui-media-player', () => {
  const mockPlayer = jest.fn(() => null)
  mockPlayer.propTypes = {}
  return {
    MediaPlayer: mockPlayer,
  }
})

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
        title: 'dope video',
        mediaType: 'video',
        mediaTracks: [],
        mediaSources: [],
      },
    },
  },
}

const makeProps = async overrides => {
  const assignmentAndSubmission = await mockAssignmentAndSubmission(overrides)
  return {
    ...assignmentAndSubmission,
    createSubmissionDraft: jest.fn(),
    updateUploadingFiles: jest.fn(),
    setIframeURL: jest.fn(),
    uploadingFiles: false,
    focusOnInit: false,
  }
}

// LS-1339  created to figure out why these are failing
describe('MediaAttempt', () => {
  global.ENV = {current_user: {id: '1'}}
  describe('unsubmitted', () => {
    it('renders record and upload buttons', async () => {
      const props = await makeProps()
      const {getByTestId} = render(<MediaAttempt {...props} />)
      expect(getByTestId('open-record-media-modal-button')).toBeInTheDocument()
      expect(getByTestId('open-upload-media-modal-button')).toBeInTheDocument()
    })

    it('moves focus to the record media modal button after render if focusOnInit is true', async () => {
      const props = await makeProps()
      props.focusOnInit = true
      const {getByTestId} = render(<MediaAttempt {...props} />)
      expect(getByTestId('open-record-media-modal-button')).toHaveFocus()
    })

    it('enables media modal buttons for students', async () => {
      const props = await makeProps()
      const {getByTestId} = render(<MediaAttempt {...props} />)
      expect(getByTestId('open-record-media-modal-button')).not.toBeDisabled()
      expect(getByTestId('open-upload-media-modal-button')).not.toBeDisabled()
    })

    it('disables media modal button for observers', async () => {
      const props = await makeProps()
      const {getByTestId} = render(
        <StudentViewContext.Provider value={{allowChangesToSubmission: false, isObserver: true}}>
          <MediaAttempt {...props} />
        </StudentViewContext.Provider>
      )
      expect(getByTestId('open-record-media-modal-button')).toBeDisabled()
      expect(getByTestId('open-upload-media-modal-button')).toBeDisabled()
    })

    it('does not move focus to the media modal button after render if focusOnInit is false', async () => {
      const props = await makeProps()
      const {getByTestId} = render(<MediaAttempt {...props} />)
      expect(getByTestId('open-record-media-modal-button')).not.toHaveFocus()
      expect(getByTestId('open-upload-media-modal-button')).not.toHaveFocus()
    })

    it('renders the current submission draft', async () => {
      const props = await makeProps(submissionDraftOverrides)
      const {getByTestId} = render(<MediaAttempt {...props} />)
      expect(getByTestId('media-recording')).toBeInTheDocument()
    })

    it('renders an iframe if iframeURL is given', async () => {
      const props = await makeProps(submissionDraftOverrides)
      const wrapper = render(
        <MediaAttempt {...props} iframeURL="https://www.youtube.com/embed/U9t-slLl30E" />
      )
      expect(wrapper.getByTitle('preview')).toBeInTheDocument()
    })

    it('removes the current submission draft when the media is removed', async () => {
      const props = await makeProps(submissionDraftOverrides)
      const {getByTestId} = render(<MediaAttempt {...props} />)
      const trashButton = getByTestId('remove-media-recording')
      await userEvent.click(trashButton)

      expect(props.createSubmissionDraft).toHaveBeenCalledWith({
        variables: {
          id: '1',
          activeSubmissionType: 'media_recording',
          attempt: 1,
        },
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
            title: 'dope_vid.mov',
          },
          state: 'submitted',
        },
      })
      const {getByTestId, queryByTestId} = render(
        <MediaAttempt {...props} uploadingFiles={false} />
      )
      expect(queryByTestId('remove-media-recording')).not.toBeInTheDocument()
      expect(getByTestId('media-recording')).toBeInTheDocument()
    })

    it('sets default cc when auto_show_cc is enabled', async () => {
      const playerSpy = jest.spyOn(MediaPlayer, 'MediaPlayer')
      const props = await makeProps({
        Submission: {
          mediaObject: {
            _id: 'm-123456',
            id: '1',
            title: 'dope_vid.mov',
            mediaTracks: [
              {
                _id: 3,
                locale: 'fr',
                type: 'captions',
                language: 'fr',
              },
              {
                _id: 1,
                locale: 'en',
                type: 'captions',
                language: 'en',
              },
              {
                _id: 2,
                locale: 'es',
                type: 'captions',
                language: 'es',
              },
            ],
          },
          state: 'submitted',
        },
      })
      global.ENV = {auto_show_cc: true, current_user: {id: '1'}}
      render(<MediaAttempt {...props} uploadingFiles={false} />)
      expect(playerSpy).toHaveBeenCalledWith(expect.objectContaining({autoShowCaption: 'en'}), {})
    })
  })

  describe('graded', () => {
    it('renders without a mediaObject', async () => {
      const props = await makeProps({
        Submission: {
          mediaObject: null,
          state: 'graded',
        },
      })
      render(<MediaAttempt {...props} uploadingFiles={false} />)
      // doesn't render anything, so nothing to check for
      // expect no errors to be thrown
    })
  })

  // This will crash given the media modal requires browser specifics
  // fwiw get a real browser or test with selenium
  // it('opens media modal when button is clicked', async () => {
  // const assignment = await mockAssignment()
  // const {getByText, getByTestId} = render(<MediaAttempt assignment={assignment} />)
  // const editButton = getByTestId('media-modal-launch-button')
  // userEvent.click(editButton)
  // expect(
  // await waitFor(() => getByText('drag and drop or clik to browse'))
  // ).toBeInTheDocument()
  // })
})
