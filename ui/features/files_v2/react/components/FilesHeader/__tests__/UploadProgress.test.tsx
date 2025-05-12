/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import UploadProgress from '../UploadProgress'
import FileUploader from '@canvas/files/react/modules/FileUploader'

function makeUploader(name: string) {
  const uploader = new FileUploader({file: new File(['foo'], name, {type: 'text/plain'})})
  uploader.roundProgress = jest.fn().mockReturnValue(50)
  return uploader
}

let defaultProps: {uploader: ReturnType<typeof makeUploader>}

beforeEach(() => {
  defaultProps = {
    uploader: makeUploader('foo.txt'),
  }
})

const renderComponent = (props = {}) => {
  return render(<UploadProgress {...defaultProps} {...props} />)
}

describe('UploadProgress', () => {
  describe('renders progress bar', () => {
    it('with progress message', () => {
      renderComponent()
      const progressBar = document.body.querySelector('progress')
      expect(progressBar).toHaveAttribute('value', '50')
      expect(progressBar).toHaveAttribute(
        'aria-valuetext',
        'foo.txt - 50 percent uploaded 50 / 100',
      )
    })

    it('with success message', () => {
      defaultProps.uploader.roundProgress = jest.fn().mockReturnValue(100)
      renderComponent()
      const progressBar = document.body.querySelector('progress')
      expect(progressBar).toHaveAttribute('value', '100')
      expect(progressBar).toHaveAttribute(
        'aria-valuetext',
        'foo.txt uploaded successfully! 100 / 100',
      )
    })

    it('with error message', () => {
      defaultProps.uploader.roundProgress = jest.fn().mockReturnValue(50)
      defaultProps.uploader.error = {message: 'Error uploading file.'}
      renderComponent()
      const progressBar = document.body.querySelector('progress')
      expect(progressBar).toHaveAttribute('value', '50')
      expect(progressBar).toHaveAttribute('aria-valuetext', 'Error: Error uploading file. 50 / 100')
    })
  })

  describe('renders message', () => {
    it('when fails', () => {
      defaultProps.uploader.roundProgress = jest.fn().mockReturnValue(50)
      defaultProps.uploader.error = {message: 'Error uploading file.'}
      renderComponent()
      expect(screen.getByText('File failed to upload. Please try again.')).toBeInTheDocument()
    })
  })

  it('render abort button', () => {
    defaultProps.uploader.canAbort = jest.fn().mockReturnValue(true)
    renderComponent()
    expect(screen.getByText('Cancel upload')).toBeInTheDocument()
  })
})
