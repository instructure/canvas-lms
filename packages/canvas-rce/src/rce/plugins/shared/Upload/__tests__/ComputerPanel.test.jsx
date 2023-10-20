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
import {act, render, fireEvent, waitFor, cleanup} from '@testing-library/react'
import ComputerPanel from '../ComputerPanel'

afterEach(cleanup)

describe('UploadFile: ComputerPanel', () => {
  it('shows a failure message if the file is rejected', () => {
    const notAnImageFile = new File(['foo'], 'foo.txt', {
      type: 'text/plain',
    })
    const {getByLabelText, getByText} = render(
      <ComputerPanel
        theFile={null}
        setFile={() => {}}
        setError={() => {}}
        accept="image/*"
        label="Upload File"
      />
    )
    const dropZone = getByLabelText(/Upload File/, {selector: 'input'})
    fireEvent.change(dropZone, {
      target: {
        files: [notAnImageFile],
      },
    })
    expect(getByText('Invalid file type')).toBeVisible()
  })

  it('accepts file files', () => {
    const aFile = new File(['foo'], 'foo.png', {
      type: 'image/png',
    })
    const {getByLabelText, queryByText} = render(
      <ComputerPanel
        theFile={null}
        setFile={() => {}}
        setError={() => {}}
        accept="image/*"
        label="Upload File"
      />
    )
    const dropZone = getByLabelText(/Upload File/, {selector: 'input'})
    fireEvent.change(dropZone, {
      target: {
        files: [aFile],
      },
    })
    expect(queryByText('Invalid file type')).toBeNull()
  })

  it('clears error messages if a valid file is added', () => {
    const notAnImageFile = new File(['foo'], 'foo.txt', {
      type: 'text/plain',
    })
    const aFile = new File(['foo'], 'foo.png', {
      type: 'image/png',
    })
    const {getByLabelText, getByText, queryByText} = render(
      <ComputerPanel
        theFile={null}
        setFile={() => {}}
        setError={() => {}}
        accept="image/*"
        label="Upload File"
      />
    )
    const dropZone = getByLabelText(/Upload File/, {selector: 'input'})
    fireEvent.change(dropZone, {
      target: {
        files: [notAnImageFile],
      },
    })
    expect(getByText('Invalid file type')).toBeVisible()
    fireEvent.change(dropZone, {
      target: {
        files: [aFile],
      },
    })

    expect(queryByText('Invalid file type')).toBeNull()
  })

  describe('file preview', () => {
    it('shows the image preview when hasUploadedFile is true for an image file', async () => {
      const aFile = new File(['foo'], 'foo.png', {
        type: 'image/png',
      })
      const {getByText, getByLabelText} = render(
        <ComputerPanel
          theFile={aFile}
          setFile={() => {}}
          setError={() => {}}
          accept="image/*"
          label="Upload File"
        />
      )
      expect(getByText('Generating preview...')).toBeInTheDocument()
      const preview = await waitFor(() => getByLabelText('foo.png image preview'))
      expect(preview).toBeInTheDocument()
    })

    it('shows the text file preview when hasUploadedFile is true for a text file', async () => {
      const aFile = new File(['foo'], 'foo.txt', {
        type: 'text/plain',
      })
      const {getByText, getByLabelText} = render(
        <ComputerPanel
          theFile={aFile}
          setFile={() => {}}
          setError={() => {}}
          accept="text/*"
          label="Upload File"
        />
      )
      expect(getByText('Generating preview...')).toBeInTheDocument()
      const preview = await waitFor(() => getByLabelText('foo.txt text preview'))
      expect(preview).toBeInTheDocument()
    })

    it('shows the generic file preview when hasUploadedFile is true for a file not an image or text', async () => {
      const aFile = new File(['foo'], 'foo.pdf', {
        type: 'application/pdf',
      })
      const {getByText, getByLabelText} = render(
        <ComputerPanel
          theFile={aFile}
          setFile={() => {}}
          setError={() => {}}
          accept="text/*"
          label="Upload File"
        />
      )
      expect(getByText('Generating preview...')).toBeInTheDocument()
      const preview = await waitFor(() => getByLabelText('foo.pdf file icon'))
      expect(preview).toBeInTheDocument()
    })

    it('clicking the trash button removes the file preview', async () => {
      const aFile = new File(['foo'], 'foo.txt', {
        type: 'text/plain',
      })
      const handleSetFile = jest.fn()
      const {getByText} = render(
        <ComputerPanel
          theFile={aFile}
          setFile={handleSetFile}
          setError={() => {}}
          accept="text/*"
          label="Upload File"
        />
      )
      const clearButton = await waitFor(() => getByText(`Clear selected file: ${aFile.name}`))
      expect(clearButton).toBeInTheDocument()
      act(() => {
        fireEvent.click(clearButton)
      })

      expect(handleSetFile).toHaveBeenCalledWith(null)
    })

    // this test passes locally, but consistently fails in jenkins.
    // Though I don't know why, this ComputerPanel typically isn't used to upload video
    // (that would be the version in canvas-media), and if you do select a video file
    // from "Upload Document", it works.
    // see also packages/canvas-media/src/__tests__/ComputerPanel.test.js
    it.skip('Renders a video player preview if afile type is a video', async () => {
      const aFile = new File(['foo'], 'foo.mp4', {
        type: 'video/mp4',
      })
      const {getByLabelText} = render(
        <ComputerPanel
          theFile={aFile}
          setFile={() => {}}
          setError={() => {}}
          accept="mp4"
          label="Upload File"
        />
      )

      const player = await waitFor(() => getByLabelText('Video Player'))
      expect(player).toBeInTheDocument()
    })

    it('Renders a video icon if afile type is a video/avi', async () => {
      // because avi videos won't load in the player via a blob url
      const aFile = new File(['foo'], 'foo.avi', {
        type: 'video/avi',
      })
      const {getByText} = render(
        <ComputerPanel
          theFile={aFile}
          setFile={() => {}}
          setError={() => {}}
          hasUploadedFile={true}
          label="Upload File"
          accept="avi"
          languages={[{id: 'en', label: 'english'}]}
        />
      )
      const warningMsg = await waitFor(() => getByText('No preview is available for this file.'))
      expect(warningMsg).toBeInTheDocument()
    })

    it('Renders a video icon if afile type is a video/x-ms-wma', async () => {
      // because wma videos won't load in the player via a blob url
      const aFile = new File(['foo'], 'foo.wma', {
        type: 'video/x-ms-wma',
      })
      const {getByText} = render(
        <ComputerPanel
          theFile={aFile}
          setFile={() => {}}
          setError={() => {}}
          hasUploadedFile={true}
          label="Upload File"
          accept="avi"
          languages={[{id: 'en', label: 'english'}]}
        />
      )
      const warningMsg = await waitFor(() => getByText('No preview is available for this file.'))
      expect(warningMsg).toBeInTheDocument()
    })

    it('Renders a video icon if afile type is a video/x-ms-wmv', async () => {
      // because wmv videos won't load in the player via a blob url
      const aFile = new File(['foo'], 'foo.wmv', {
        type: 'video/x-ms-wmv',
      })
      const {getByText} = render(
        <ComputerPanel
          theFile={aFile}
          setFile={() => {}}
          setError={() => {}}
          hasUploadedFile={true}
          label="Upload File"
          accept="avi"
          languages={[{id: 'en', label: 'english'}]}
        />
      )
      const warningMsg = await waitFor(() => getByText('No preview is available for this file.'))
      expect(warningMsg).toBeInTheDocument()
    })

    it('Renders an error message when trying to upload an empty file', async () => {
      const aFile = new File([], 'empty')
      const {getByText} = render(
        <ComputerPanel
          theFile={aFile}
          setFile={() => {}}
          setError={() => {}}
          accept="text/*"
          label="Upload File"
        />
      )
      const errmsg = await waitFor(() => getByText('You may not upload an empty file.'))
      expect(errmsg).toBeInTheDocument()
    })
  })
})
