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
import {act} from 'react-dom/test-utils'
import ComputerPanel from '../ComputerPanel'
import {ACCEPTED_FILE_TYPES} from '../acceptedMediaFileTypes'

// polyfill URL.createObjectURL
if (window.URL) {
  window.URL = {
    createObjectURL: file => {
      return {
        label: file.name,
        src: 'blob://junk'
      }
    }
  }
}

const uploadMediaTranslations = {
  UploadMediaStrings: {
    ADD_CLOSED_CAPTIONS_OR_SUBTITLES: 'Add CC/Subtitles',
    CLEAR_FILE_TEXT: 'Clear selected file',
    CLOSE_TEXT: 'Close',
    CLOSED_CAPTIONS_CHOOSE_FILE: 'Choose caption file',
    CLOSED_CAPTIONS_SELECT_LANGUAGE: 'Select Language',
    COMPUTER_PANEL_TITLE: 'Computer',
    DRAG_DROP_CLICK_TO_BROWSE: 'Drop and drop, or click to browse your computer',
    DRAG_FILE_TEXT: 'Drag a file here',
    EMBED_PANEL_TITLE: 'Embed',
    EMBED_VIDEO_CODE_TEXT: 'Embed Code',
    INVALID_FILE_TEXT: 'Invalid File',
    LOADING_MEDIA: 'Loading...',
    RECORD_PANEL_TITLE: 'Record',
    SUBMIT_TEXT: 'Submit',
    UPLOADING_ERROR: 'Upload Error',
    UPLOAD_MEDIA_LABEL: 'Upload Media'
  }
}

function renderPanel(overrideProps = {}) {
  return render(
    <ComputerPanel
      theFile={null}
      setFile={() => {}}
      hasUploadedFile={false}
      setHasUploadedFile={() => {}}
      label="Upload File"
      uploadMediaTranslations={uploadMediaTranslations}
      accept={ACCEPTED_FILE_TYPES}
      languages={[{id: 'en', label: 'english'}]}
      liveRegion={() => null}
      updateSubtitles={() => false}
      {...overrideProps}
    />
  )
}

describe('UploadMedia: ComputerPanel', () => {
  it('shows a failure message if the file is rejected', () => {
    const notAMediaFile = new File(['foo'], 'foo.txt', {type: 'text/plain'})
    const {getByLabelText, getByText} = renderPanel()
    const dropZone = getByLabelText(/Upload File/, {selector: 'input'})
    fireEvent.change(dropZone, {
      target: {
        files: [notAMediaFile]
      }
    })
    expect(getByText('Invalid File')).toBeVisible()
  })

  it('accepts video files', () => {
    const aFile = new File(['foo'], 'foo.mov', {
      type: 'video/quicktime'
    })
    const {getByLabelText, queryByText} = renderPanel()
    const dropZone = getByLabelText(/Upload File/, {selector: 'input'})
    fireEvent.change(dropZone, {
      target: {
        files: [aFile]
      }
    })
    expect(queryByText('Invalid File')).toBeNull()
  })

  it('clears error messages if a valid file is added', () => {
    const notAMediaFile = new File(['foo'], 'foo.txt', {
      type: 'text/plain'
    })
    const aMediaFile = new File(['foo'], 'foo.mov', {
      type: 'video/quicktime'
    })
    const {getByLabelText, getByText, queryByText} = renderPanel()
    const dropZone = getByLabelText(/Upload File/, {selector: 'input'})
    fireEvent.change(dropZone, {
      target: {
        files: [notAMediaFile]
      }
    })
    expect(getByText('Invalid File')).toBeVisible()
    fireEvent.change(dropZone, {
      target: {
        files: [aMediaFile]
      }
    })

    expect(queryByText('Invalid File')).toBeNull()
  })

  describe('file preview', () => {
    it('Renders a video player preview if afile type is a video', async () => {
      const aFile = new File(['foo'], 'foo.mp4', {
        type: 'video/mp4'
      })
      const {getByText} = renderPanel({theFile: aFile, hasUploadedFile: true})
      const playButton = await waitForElement(() => getByText('Play'))
      expect(playButton).toBeInTheDocument()
    })

    it('clicking the trash button removes the file preview', async () => {
      const aFile = new File(['foo'], 'foo.mov', {
        type: 'video/quicktime'
      })
      const setFile = jest.fn()
      const setHasUploadedFile = jest.fn()
      const {getByText} = renderPanel({
        theFile: aFile,
        setFile,
        setHasUploadedFile,
        hasUploadedFile: true
      })
      const clearButton = await waitForElement(() => getByText('Clear selected file'))
      expect(clearButton).toBeInTheDocument()
      act(() => {
        fireEvent.click(clearButton)
      })
      expect(setHasUploadedFile).toHaveBeenCalledWith(false)
      expect(setFile).toHaveBeenCalledWith(null)
    })
  })
})
