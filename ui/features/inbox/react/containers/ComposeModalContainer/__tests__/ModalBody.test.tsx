/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {fireEvent, render, waitFor} from '@testing-library/react'
import ModalBody from '../ModalBody'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

injectGlobalAlertContainers()

describe('ModelBody', () => {
  const defaultProps = {
    attachments: [],
    bodyMessages: [],
    children: undefined,
    onBodyChange: jest.fn(),
    pastMessages: [],
    removeAttachment: jest.fn(),
    replaceAttachment: jest.fn(),
    modalError: '',
    mediaUploadFile: {},
    onRemoveMediaComment: jest.fn(),
  }

  describe('Attachments', () => {
    const mediaUploadFile = {
      mediaObject: {
        media_object: {
          media_id: '1',
          title: 'new video',
          media_type: 'video',
          media_tracks: [],
        },
      },
      uploadedFile: new Blob(),
    }

    const attachments = [{id: '1'}, {id: '2'}]

    it('does not render any attachments when none provided', () => {
      const {queryByTestId} = render(<ModalBody {...defaultProps} />)
      expect(queryByTestId('media-attachment')).not.toBeInTheDocument()
      expect(queryByTestId('attachment')).not.toBeInTheDocument()
    })

    it('does rended both media and regular attachments when provided', () => {
      const props = {...defaultProps, mediaUploadFile, attachments}
      const {queryByTestId, getAllByTestId, queryByText} = render(<ModalBody {...props} />)
      expect(queryByTestId('media-attachment')).toBeInTheDocument()
      expect(getAllByTestId('attachment')).toHaveLength(2)
      expect(queryByText('new video')).toBeInTheDocument()
    })

    it('does render only media attachments', () => {
      const props = {...defaultProps, mediaUploadFile}
      const {queryByTestId, queryByText} = render(<ModalBody {...props} />)
      expect(queryByTestId('media-attachment')).toBeInTheDocument()
      expect(queryByText('new video')).toBeInTheDocument()
      expect(queryByTestId('attachment')).not.toBeInTheDocument()
    })

    it('does render only regular attachments', () => {
      const props = {...defaultProps, attachments}
      const {queryByTestId, getAllByTestId, queryByText} = render(<ModalBody {...props} />)
      expect(getAllByTestId('attachment')).toHaveLength(2)
      expect(queryByTestId('media-attachment')).not.toBeInTheDocument()
      expect(queryByText('new video')).not.toBeInTheDocument()
    })

    it('displays remove button for media attachment and handles click', async () => {
      const props = {...defaultProps, mediaUploadFile}
      const {getByTestId} = render(<ModalBody {...props} />)

      fireEvent.mouseOver(getByTestId('removable-item'))
      await waitFor(() => getByTestId('remove-button'))
      fireEvent.click(getByTestId('remove-button'))
      expect(props.onRemoveMediaComment).toHaveBeenCalledTimes(1)
    })

    it('displays remove button for regular attachment and handles click', async () => {
      const props = {...defaultProps, attachments}
      const {getAllByTestId, getByTestId} = render(<ModalBody {...props} />)

      fireEvent.mouseOver(getAllByTestId('removable-item')[0])
      await waitFor(() => getByTestId('remove-button'))
      fireEvent.click(getByTestId('remove-button'))
      expect(props.removeAttachment).toHaveBeenCalledTimes(1)
    })

    it('renders user entered title when submitted', () => {
      const props = {...defaultProps, user_entered_title: 'renamed video'}
      const {queryByText} = render(<ModalBody {...props} />)
      expect(queryByText('renamed video')).not.toBeInTheDocument()
    })
  })
})
