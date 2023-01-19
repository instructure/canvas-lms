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
import {render, fireEvent, waitFor} from '@testing-library/react'
import UploadFileModal from '../UploadFileModal'

describe('UploadFileModal', () => {
  let modalProps
  beforeEach(() => {
    modalProps = {
      editor: {},
      trayProps: {
        contextType: 'course',
        contextId: 17,
        source: {},
      },
      contentProps: {
        session: {usageRightsRequired: true},
        loadSession: () => {},
      },
      onSubmit: () => {},
      onDismiss: () => {},
      panels: ['COMPUTER', 'URL'],
      label: 'Upload Stuff',
      accept: '*/*',
    }
  })
  afterEach(() => {
    modalProps = null
  })

  it('renders', () => {
    const {getByText} = render(<UploadFileModal {...modalProps} />)

    expect(getByText('Upload Stuff')).toBeInTheDocument()
    expect(getByText('Computer')).toBeInTheDocument()
    expect(getByText('URL')).toBeInTheDocument()
  })

  describe('Usage Rights', () => {
    it('is rendered expanded when in a course context and rights are required', () => {
      const {getByText} = render(<UploadFileModal {...modalProps} />)

      expect(getByText('Usage Rights (required)')).toBeInTheDocument()
      expect(getByText('Usage Right:')).toBeInTheDocument()
      expect(getByText('Copyright Holder:')).toBeInTheDocument()
    })

    it('is not rendered in non-course context', () => {
      modalProps.trayProps.contextType = 'user'
      const {queryByText} = render(<UploadFileModal {...modalProps} />)

      expect(queryByText('Usage Rights (required)')).not.toBeInTheDocument()
    })

    it('is not rendered if not required', () => {
      modalProps.contentProps.session.usageRightsRequired = false
      const {queryByText} = render(<UploadFileModal {...modalProps} />)

      expect(queryByText('Usage Rights (required)')).not.toBeInTheDocument()
    })

    it('disables the Submit button on the Computer panel unless set', () => {
      modalProps.panels = ['COMPUTER']
      const {getByText} = render(<UploadFileModal {...modalProps} />)
      expect(getByText('Submit').closest('button').disabled).toBe(true)
      // would like to see the button get enabled when a value is set,
      // but the components aren't setup in a way to make that practical.
    })

    it('enables the Submit button on the URL panel even if not set', async () => {
      modalProps.panels = ['URL']
      const {getByText, getByLabelText} = render(<UploadFileModal {...modalProps} />)
      await waitFor(() => getByLabelText('File URL'))
      const urlinput = getByLabelText('File URL')
      fireEvent.change(urlinput, {target: {value: 'http://example.com/'}})
      await waitFor(() => expect(getByText('Submit').closest('button').disabled).toBe(false))
    })
  })

  describe('Image Attributes', () => {
    it('is rendered when uploading only images', () => {
      modalProps.accept = 'image/*'
      const {getByText} = render(<UploadFileModal {...modalProps} />)

      expect(getByText('Attributes')).toBeInTheDocument()
    })

    it('is not renderedd when uploading anything other than images', () => {
      modalProps.accept = '*/*'
      const {queryByText} = render(<UploadFileModal {...modalProps} />)

      expect(queryByText('Attributes')).not.toBeInTheDocument()
    })

    it('is not renderedd when requireA11yAttributes is false', () => {
      modalProps.accept = '*/*'
      modalProps.requireA11yAttributes = false

      const {queryByText} = render(<UploadFileModal {...modalProps} />)

      expect(queryByText('Attributes')).not.toBeInTheDocument()
    })
  })
})
