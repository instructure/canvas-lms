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

import React from 'react'
import {render, fireEvent, waitForElement} from '@testing-library/react'
import ComputerPanel from '../ComputerPanel'

function makeTranslationProps() {
  return {
    UploadMediaStrings: {
      CLEAR_FILE_TEXT: 'Clear File',
      INVALID_FILE_TEXT: 'Invalid file type',
      DRAG_DROP_CLICK_TO_BROWSE: 'drag and drop or clik to browse'
    }
  }
}

describe('UploadFile: ComputerPanel', () => {
  it('shows a failure message if the file is rejected', () => {
    const notAnImageFile = new File(['foo'], 'foo.txt', {
      type: 'text/plain'
    })
    const handleSetFile = jest.fn()
    const handleSetHasUploadedFile = jest.fn()
    const {getByLabelText, getByText} = render(
      <ComputerPanel
        theFile={null}
        setFile={handleSetFile}
        hasUploadedFile={false}
        setHasUploadedFile={handleSetHasUploadedFile}
        accept="image/*"
        uploadMediaTranslations={makeTranslationProps()}
        label="Upload File"
      />
    )
    const dropZone = getByLabelText(/Upload File/, {selector: 'input'})
    fireEvent.change(dropZone, {
      target: {
        files: [notAnImageFile]
      }
    })
    expect(getByText('Invalid file type')).toBeVisible()
  })

  it('accepts file files', () => {
    const aFile = new File(['foo'], 'foo.png', {
      type: 'image/png'
    })
    const handleSetFile = jest.fn()
    const handleSetHasUploadedFile = jest.fn()
    const {getByLabelText, queryByText} = render(
      <ComputerPanel
        theFile={null}
        setFile={handleSetFile}
        hasUploadedFile={false}
        setHasUploadedFile={handleSetHasUploadedFile}
        accept="image/*"
        uploadMediaTranslations={makeTranslationProps()}
        label="Upload File"
      />
    )
    const dropZone = getByLabelText(/Upload File/, {selector: 'input'})
    fireEvent.change(dropZone, {
      target: {
        files: [aFile]
      }
    })
    expect(queryByText('Invalid file type')).toBeNull()
  })

  it('clears error messages if a valid file is added', () => {
    const notAnImageFile = new File(['foo'], 'foo.txt', {
      type: 'text/plain'
    })
    const aFile = new File(['foo'], 'foo.png', {
      type: 'image/png'
    })
    const handleSetFile = jest.fn()
    const handleSetHasUploadedFile = jest.fn()
    const {getByLabelText, getByText, queryByText} = render(
      <ComputerPanel
        theFile={null}
        setFile={handleSetFile}
        hasUploadedFile={false}
        setHasUploadedFile={handleSetHasUploadedFile}
        uploadMediaTranslations={makeTranslationProps()}
        accept="image/*"
        label="Upload File"
      />
    )
    const dropZone = getByLabelText(/Upload File/, {selector: 'input'})
    fireEvent.change(dropZone, {
      target: {
        files: [notAnImageFile]
      }
    })
    expect(getByText('Invalid file type')).toBeVisible()
    fireEvent.change(dropZone, {
      target: {
        files: [aFile]
      }
    })

    expect(queryByText('Invalid file type')).toBeNull()
  })

  it('Renders a video player preview if a file type is a video', async () => {
    global.URL.createObjectURL = jest.fn(() => 'www.blah.com')
    const handleSetFile = jest.fn()
    const handleSetHasUploadedFile = jest.fn()
    const aFile = new File(['foo'], 'foo.mp4', {
      type: 'video/mp4'
    })
    const {getByText} = render(
      <ComputerPanel
        theFile={aFile}
        setFile={handleSetFile}
        uploadMediaTranslations={makeTranslationProps()}
        hasUploadedFile
        setHasUploadedFile={handleSetHasUploadedFile}
        accept="mp4"
        label="Upload File"
      />
    )
    const playButton = await waitForElement(() => getByText('Play'))
    expect(playButton).toBeInTheDocument()
  })
})
