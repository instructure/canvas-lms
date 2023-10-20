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
import {act, render, fireEvent, waitFor} from '@testing-library/react'
import ComputerPanel from '../ComputerPanel'
import {ACCEPTED_FILE_TYPES} from '../acceptedMediaFileTypes'

const uploadMediaTranslations = {
  UploadMediaStrings: {
    ADD_CLOSED_CAPTIONS_OR_SUBTITLES: 'Add CC/Subtitles',
    CLEAR_FILE_TEXT: 'Clear selected file',
    CLOSE_TEXT: 'Close',
    CLOSED_CAPTIONS_CHOOSE_FILE: 'Choose caption file',
    CLOSED_CAPTIONS_SELECT_LANGUAGE: 'Select Language',
    COMPUTER_PANEL_TITLE: 'Computer',
    DRAG_DROP_CLICK_TO_BROWSE: 'Drag and drop, or click to browse your computer',
    DRAG_FILE_TEXT: 'Drag a file here',
    INVALID_FILE_TEXT: 'Invalid File',
    LOADING_MEDIA: 'Loading...',
    RECORD_PANEL_TITLE: 'Record',
    SUBMIT_TEXT: 'Submit',
    UPLOADING_ERROR: 'Upload Error',
    UPLOAD_MEDIA_LABEL: 'Upload Media',
  },
  SelectStrings: {
    USE_ARROWS: 'Use arrow keys to navigate options.',
    LIST_COLLAPSED: 'List collapsed.',
    LIST_EXPANDED: 'List expanded.',
    OPTION_SELECTED: '{option} selected.',
  },
}

const LIVE_REGION_ID = 'flash_screenreader_holder'

function createPanel(overrideProps) {
  return (
    <ComputerPanel
      theFile={null}
      setFile={() => {}}
      hasUploadedFile={false}
      setHasUploadedFile={() => {}}
      label="Upload File"
      uploadMediaTranslations={uploadMediaTranslations}
      accept={ACCEPTED_FILE_TYPES}
      userLocale="en"
      liveRegion={() => document.getElementById(LIVE_REGION_ID)}
      updateSubtitles={() => false}
      {...overrideProps}
    />
  )
}

function renderPanel(overrideProps = {}) {
  return render(createPanel(overrideProps))
}

describe('UploadMedia: ComputerPanel', () => {
  beforeEach(() => {
    const liveRegion = document.createElement('div')
    liveRegion.id = LIVE_REGION_ID
    liveRegion.setAttribute('role', 'alert')
    document.body.appendChild(liveRegion)

    window.matchMedia =
      window.matchMedia ||
      (() => ({
        matches: false,
        addListener: () => {},
        removeListener: () => {},
      }))
  })

  afterEach(() => {
    const liveRegion = document.getElementById(LIVE_REGION_ID)
    if (liveRegion) {
      document.body.removeChild(liveRegion)
    }
  })

  it('shows a failure message if the file is rejected', () => {
    const notAMediaFile = new File(['foo'], 'foo.txt', {type: 'text/plain'})
    const {getByLabelText, getByText} = renderPanel()
    const dropZone = getByLabelText(/Upload File/, {selector: 'input'})
    fireEvent.change(dropZone, {
      target: {
        files: [notAMediaFile],
      },
    })
    expect(getByText('Invalid File')).toBeVisible()
  })

  it('shows an editable text input for title if a valid file is added', async () => {
    const aFile = new File(['foo'], 'foo.mov', {
      type: 'video/quicktime',
    })
    const setFile = file =>
      rerender(
        createPanel({
          setFile,
          theFile: file,
          hasUploadedFile: true,
        })
      )
    const {rerender, getByLabelText, getByPlaceholderText} = renderPanel({setFile})
    const dropZone = getByLabelText(/Upload File/, {selector: 'input'})
    fireEvent.change(dropZone, {
      target: {
        files: [aFile],
      },
    })
    const titleInput = getByPlaceholderText('File name')
    expect(titleInput.value).toEqual('foo.mov')
    fireEvent.change(titleInput, {target: {value: 'Awesome video'}})
    expect(titleInput.value).toEqual('Awesome video')
  })

  describe('file preview', () => {
    // this test passes locally, but consistently fails in jenkins.
    // Though I don't know why, this ComputerPanel typically isn't used to upload video
    // (that would be the version in canvas-media), and if you do select a video file
    // from "Upload Document", it works.
    // see also packages/canvas-rce/src/rce/plugins/shared/Upload/__tests__/ComputerPanel.test.js
    it.skip('Renders a video player preview if afile type is a video', async () => {
      const aFile = new File(['foo'], 'foo.mp4', {
        type: 'video/mp4',
      })
      const {getAllByText} = renderPanel({theFile: aFile, hasUploadedFile: true})
      const playButton = await waitFor(() => getAllByText('Play'))
      expect(playButton[0].closest('button')).toBeInTheDocument()
    })

    it('Renders a video icon if afile type is a video/avi', async () => {
      // because avi videos won't load in the player via a blob url
      const aFile = new File(['foo'], 'foo.avi', {
        type: 'video/avi',
      })
      const {getByTestId, getByText} = renderPanel({theFile: aFile, hasUploadedFile: true})
      const icon = await waitFor(() => getByTestId('preview-video-icon'))
      expect(icon).toBeInTheDocument()
      expect(getByText('No preview is available for this file.')).toBeInTheDocument()
    })

    it('Renders a video icon if afile type is a video/x-ms-wma', async () => {
      // because avi videos won't load in the player via a blob url
      const aFile = new File(['foo'], 'foo.wma', {
        type: 'video/x-ms-wma',
      })
      const {getByTestId, getByText} = renderPanel({theFile: aFile, hasUploadedFile: true})
      const icon = await waitFor(() => getByTestId('preview-video-icon'))
      expect(icon).toBeInTheDocument()
      expect(getByText('No preview is available for this file.')).toBeInTheDocument()
    })

    it('Renders a video icon if afile type is a video/x-ms-wmv', async () => {
      // because avi videos won't load in the player via a blob url
      const aFile = new File(['foo'], 'foo.wmv', {
        type: 'video/x-ms-wmv',
      })
      const {getByTestId, getByText} = renderPanel({theFile: aFile, hasUploadedFile: true})
      const icon = await waitFor(() => getByTestId('preview-video-icon'))
      expect(icon).toBeInTheDocument()
      expect(getByText('No preview is available for this file.')).toBeInTheDocument()
    })

    it('clicking the trash button removes the file preview', async () => {
      const aFile = new File(['foo'], 'foo.mov', {
        type: 'video/quicktime',
      })
      const setFile = jest.fn()
      const setHasUploadedFile = jest.fn()
      const {getByText} = renderPanel({
        theFile: aFile,
        setFile,
        setHasUploadedFile,
        hasUploadedFile: true,
      })
      const clearButton = await waitFor(() => getByText('Clear selected file'))
      expect(clearButton).toBeInTheDocument()
      act(() => {
        fireEvent.click(clearButton)
      })
      expect(setHasUploadedFile).toHaveBeenCalledWith(false)
      expect(setFile).toHaveBeenCalledWith(null)
    })
  })
  describe('shows closed captions panel', () => {
    beforeEach(() => {
      window.matchMedia =
        window.matchMedia ||
        (() => ({
          matches: false,
          addListener: () => {},
          removeListener: () => {},
        }))
    })

    it('when uploading videos', async () => {
      HTMLElement.prototype.scrollIntoView = jest.fn()
      const aFile = new File(['foo'], 'foo.mov', {
        type: 'video/quicktime',
      })
      const setFile = file =>
        rerender(
          createPanel({
            setFile,
            theFile: file,
            hasUploadedFile: true,
          })
        )
      const {rerender, getByLabelText, getByTestId, getByRole} = renderPanel({setFile})
      const dropZone = getByLabelText(/Upload File/, {selector: 'input'})
      fireEvent.change(dropZone, {
        target: {
          files: [aFile],
        },
      })
      const ccCheckbox = getByRole('checkbox', {name: /Add CC\/Subtitles/})
      expect(ccCheckbox).not.toBeNull()
      fireEvent.click(ccCheckbox)
      await waitFor(() => {
        const ccPanel = getByTestId('ClosedCaptionPanel')
        expect(ccPanel).not.toBeNull()
      })
    })

    it('when uploading audios', async () => {
      HTMLElement.prototype.scrollIntoView = jest.fn()
      const aFile = new File(['foo'], 'foo.mp3', {
        type: 'audio/mp3',
      })
      const setFile = file =>
        rerender(
          createPanel({
            setFile,
            theFile: file,
            hasUploadedFile: true,
          })
        )
      const {rerender, getByLabelText, getByTestId, getByRole} = renderPanel({setFile})
      const dropZone = getByLabelText(/Upload File/, {selector: 'input'})
      fireEvent.change(dropZone, {
        target: {
          files: [aFile],
        },
      })
      const ccCheckbox = getByRole('checkbox', {name: /Add CC\/Subtitles/})
      expect(ccCheckbox).not.toBeNull()
      fireEvent.click(ccCheckbox)
      await waitFor(() => {
        const ccPanel = getByTestId('ClosedCaptionPanel')
        expect(ccPanel).not.toBeNull()
      })
    })
  })
})
