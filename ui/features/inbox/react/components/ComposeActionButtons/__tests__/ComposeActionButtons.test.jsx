/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {ComposeActionButtons} from '../ComposeActionButtons'

const createProps = overrides => {
  return {
    onAttachmentUpload: jest.fn(),
    onMediaUpload: overrides?.hasOwnProperty('onMediaUpload') ? overrides.onMediaUpload : jest.fn(),
    onCancel: jest.fn(),
    onSend: jest.fn(),
    isSending: false,
    ...overrides,
  }
}

describe('ComposeActionButtons', () => {
  describe('attachment upload', () => {
    it('triggers onAttachmentUpload when file is uploaded', () => {
      const props = createProps()
      const {getByTestId} = render(<ComposeActionButtons {...props} />)
      fireEvent.click(getByTestId('attachment-upload'))
      fireEvent.change(getByTestId('attachment-input'))
      expect(props.onAttachmentUpload).toHaveBeenCalled()
    })

    it('triggers onAttachmentUpload again when file was previously uploaded', async () => {
      const props = createProps()
      const {getByTestId} = render(<ComposeActionButtons {...props} />)

      const file = new File(['my-image'], 'my-image.png', {type: 'image/png'})
      const input = getByTestId('attachment-input')

      await userEvent.upload(input, file)

      input.value = ''

      await userEvent.upload(input, file)

      expect(props.onAttachmentUpload).toHaveBeenCalledTimes(2)
    })
  })

  describe('media upload', () => {
    it('calls onMediaUpload when clicked', () => {
      const props = createProps()
      const {getByTestId} = render(<ComposeActionButtons {...props} />)
      fireEvent.click(getByTestId('media-upload'))
      expect(props.onMediaUpload).toHaveBeenCalled()
    })

    describe('onMediaUpload is not provided', () => {
      it('does not render the button', () => {
        const props = createProps({onMediaUpload: null})
        const {queryByTestId} = render(<ComposeActionButtons {...props} />)
        expect(queryByTestId('media-upload')).toBe(null)
      })
    })

    it('disables the media upload button if hasMediaComment is true', () => {
      const props = createProps({hasMediaComment: true})
      const container = render(<ComposeActionButtons {...props} />)
      expect(container.getByTestId('media-upload')).toBeDisabled()
    })
  })

  describe('message cancel button', () => {
    it('calls onCancel when clicked', () => {
      const props = createProps()
      const {getByTestId} = render(<ComposeActionButtons {...props} />)
      fireEvent.click(getByTestId('cancel-button'))
      expect(props.onCancel).toHaveBeenCalled()
    })
  })

  describe('message send button', () => {
    it('calls onSend when clicked', () => {
      const props = createProps()
      const {getByTestId} = render(<ComposeActionButtons {...props} />)
      fireEvent.click(getByTestId('send-button'))
      expect(props.onSend).toHaveBeenCalled()
    })

    describe('isSending is true', () => {
      it('indicates sending state', () => {
        const {getByText} = render(<ComposeActionButtons {...createProps({isSending: true})} />)
        expect(getByText('Sending...')).toBeInTheDocument()
      })
    })
  })
})
