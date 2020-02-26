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
import {render, fireEvent, waitForElement, cleanup} from '@testing-library/react'
import {act} from 'react-dom/test-utils'
import ComputerPanel from '../ComputerPanel'

afterEach(cleanup)

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

  describe('file preview', () => {
    it('shows the image preview when hasUploadedFile is true for an image file', async () => {
      const aFile = new File(['foo'], 'foo.png', {
        type: 'image/png'
      })
      const handleSetFile = jest.fn()
      const handleSetHasUploadedFile = jest.fn()
      const {getByText, getByLabelText} = render(
        <ComputerPanel
          theFile={aFile}
          setFile={handleSetFile}
          hasUploadedFile
          setHasUploadedFile={handleSetHasUploadedFile}
          accept="image/*"
          label="Upload File"
        />
      )
      expect(getByText('Generating preview...')).toBeInTheDocument()
      const preview = await waitForElement(() => getByLabelText('foo.png image preview'))
      expect(preview).toBeInTheDocument()
    })

    it('shows the text file preview when hasUploadedFile is true for a text file', async () => {
      const aFile = new File(['foo'], 'foo.txt', {
        type: 'text/plain'
      })
      const handleSetFile = jest.fn()
      const handleSetHasUploadedFile = jest.fn()
      const {getByText, getByLabelText} = render(
        <ComputerPanel
          theFile={aFile}
          setFile={handleSetFile}
          hasUploadedFile
          setHasUploadedFile={handleSetHasUploadedFile}
          accept="text/*"
          label="Upload File"
        />
      )
      expect(getByText('Generating preview...')).toBeInTheDocument()
      const preview = await waitForElement(() => getByLabelText('foo.txt text preview'))
      expect(preview).toBeInTheDocument()
    })

    it('shows the generic file preview when hasUploadedFile is true for a file not an image or text', async () => {
      const aFile = new File(['foo'], 'foo.pdf', {
        type: 'application/pdf'
      })
      const handleSetFile = jest.fn()
      const handleSetHasUploadedFile = jest.fn()
      const {getByText, getByLabelText} = render(
        <ComputerPanel
          theFile={aFile}
          setFile={handleSetFile}
          hasUploadedFile
          setHasUploadedFile={handleSetHasUploadedFile}
          accept="text/*"
          label="Upload File"
        />
      )
      expect(getByText('Generating preview...')).toBeInTheDocument()
      const preview = await waitForElement(() => getByLabelText('foo.pdf file icon'))
      expect(preview).toBeInTheDocument()
    })

    it('clicking the trash button removes the file preview', async () => {
      const aFile = new File(['foo'], 'foo.txt', {
        type: 'text/plain'
      })
      const handleSetFile = jest.fn()
      const handleSetHasUploadedFile = jest.fn()
      const {getByText} = render(
        <ComputerPanel
          theFile={aFile}
          setFile={handleSetFile}
          hasUploadedFile
          setHasUploadedFile={handleSetHasUploadedFile}
          accept="text/*"
          label="Upload File"
        />
      )
      const clearButton = await waitForElement(() =>
        getByText(`Clear selected file: ${aFile.name}`)
      )
      expect(clearButton).toBeInTheDocument()
      act(() => {
        fireEvent.click(clearButton)
      })
      expect(handleSetHasUploadedFile).toHaveBeenCalledWith(false)
      expect(handleSetFile).toHaveBeenCalledWith(null)
    })

    it('Renders a video player preview if afile type is a video', async () => {
      const aFile = new File(['foo'], 'foo.mp4', {
        type: 'video/mp4'
      })
      const handleSetFile = jest.fn()
      const handleSetHasUploadedFile = jest.fn()
      const {getByText} = render(
        <ComputerPanel
          theFile={aFile}
          setFile={handleSetFile}
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
})
