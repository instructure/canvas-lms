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
import {act, render, fireEvent, waitFor, screen} from '@testing-library/react'
import ComputerPanel from '../ComputerPanel'
import {ACCEPTED_FILE_TYPES} from '../acceptedMediaFileTypes'
import {vi} from 'vitest'

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
    SELECT_SUPPORTED_FILE_TYPE: 'Please select a file of a supported type',
    CHOOSE_FILE_TO_UPLOAD: 'Please choose a file',
    ENTER_FILE_NAME: 'Please enter a file name',
  },
  SelectStrings: {
    USE_ARROWS: 'Use arrow keys to navigate options.',
    LIST_COLLAPSED: 'List collapsed.',
    LIST_EXPANDED: 'List expanded.',
    OPTION_SELECTED: '{option} selected.',
  },
}

const LIVE_REGION_ID = 'flash_screenreader_holder'

interface ComputerPanelProps {
  theFile: File | null
  setFile: (file: File | null) => void
  hasUploadedFile: boolean
  setHasUploadedFile: (uploaded: boolean) => void
  label: string
  uploadMediaTranslations: typeof uploadMediaTranslations
  accept: string[]
  userLocale: string
  liveRegion: () => HTMLElement | null
  updateSubtitles: () => boolean
  useStudioPlayer: boolean
}

function createPanel(overrideProps: Partial<ComputerPanelProps>, ref?: React.Ref<any>) {
  return (
    <ComputerPanel
      ref={ref}
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
      useStudioPlayer={false}
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

  it('shows an editable text input for title if a valid file is added', async () => {
    const aFile = new File(['foo'], 'foo.mov', {
      type: 'video/quicktime',
    })
    const setFile = (file: File | null) =>
      rerender(
        createPanel({
          setFile,
          theFile: file,
          hasUploadedFile: true,
        }),
      )
    const {rerender, getByLabelText, getByPlaceholderText} = renderPanel({setFile})
    const dropZone = getByLabelText(/Upload File/, {selector: 'input'})
    fireEvent.change(dropZone, {
      target: {
        files: [aFile],
      },
    })
    const titleInput = getByPlaceholderText('File name')
    if (!(titleInput instanceof HTMLInputElement)) {
      throw new Error('Expected titleInput to be an HTMLInputElement')
    }
    expect(titleInput.value).toEqual('foo.mov')
    fireEvent.change(titleInput, {target: {value: 'Awesome video'}})
    expect(titleInput.value).toEqual('Awesome video')
  })

  describe('validation', () => {
    describe('file', () => {
      it('shows an error if not defined', () => {
        const ref = React.createRef<{ updateValidationMessages: () => void }>()
        const { getByText } = render(createPanel({}, ref))
        act(() => ref.current?.updateValidationMessages())
        expect(getByText('Please choose a file')).toBeVisible()
      })

      it('shows an error if rejected', () => {
        const notAMediaFile = new File(['foo'], 'foo.txt', {type: 'text/plain'})
        const {getByLabelText, getByText} = renderPanel()
        const dropZone = getByLabelText(/Upload File/, {selector: 'input'})
        fireEvent.change(dropZone, {
          target: {
            files: [notAMediaFile],
          },
        })
        expect(getByText('Please select a file of a supported type')).toBeVisible()
      })
    })

    describe('file name', () => {
      it('shows an error if blank', () => {
        const ref = React.createRef<{ updateValidationMessages: () => void }>()
        const aFile = new File(['foo'], 'foo.mov', {
          type: 'video/quicktime',
        })
        const { getByPlaceholderText, getByText } = render(createPanel({
          theFile: aFile,
          hasUploadedFile: true,
        }, ref))

        const titleInput = getByPlaceholderText('File name')
        fireEvent.change(titleInput, {target: {value: ''}})

        act(() => ref.current?.updateValidationMessages())
        expect(getByText('Please enter a file name')).toBeVisible()
      })
    })
  })

  describe('file preview', () => {
    beforeEach(() => {
      vi.mock('@instructure/studio-player', () => ({
        StudioPlayer: vi.fn(() => <div data-testid="studio-player" data-test-id="studio-player" />),
      }))
    })

    afterEach(() => {
      vi.clearAllMocks()
      vi.resetModules()
    })

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

    it('Does not render the StudioPlayer if the flag is not enabled', async () => {
      const aFile = new File(['foo'], 'foo.mov', {
        type: 'video/quicktime',
      })
      const {queryByTestId} = renderPanel({
        theFile: aFile,
        hasUploadedFile: true,
        useStudioPlayer: false,
      })

      expect(queryByTestId('studio-player')).not.toBeInTheDocument()
    })

    it('Renders the StudioPlayer if the flag is enabled', async () => {
      const aFile = new File(['foo'], 'foo.mp4', {
        type: 'video/mp4',
      })
      const setFile = vi.fn()
      const setHasUploadedFile = vi.fn()

      const {getByLabelText, getByTestId, queryByTestId, rerender} = renderPanel({
        setFile,
        setHasUploadedFile,
        label: 'Upload File',
        useStudioPlayer: true,
      })

      // Verify StudioPlayer is not rendered before file upload
      expect(queryByTestId('studio-player')).not.toBeInTheDocument()

      // Trigger the file upload
      const dropZone = getByLabelText(/Upload File/, {selector: 'input'})
      fireEvent.change(dropZone, {
        target: {
          files: [aFile],
        },
      })

      rerender(
        createPanel({
          setFile,
          setHasUploadedFile,
          label: 'Upload File',
          useStudioPlayer: true,
          theFile: aFile,
          hasUploadedFile: true,
        }),
      )

      await waitFor(() => {
        const player = getByTestId('studio-player')
        expect(player).toBeInTheDocument()
      })

      expect(setFile).toHaveBeenCalledWith(aFile)
      expect(setHasUploadedFile).toHaveBeenCalledWith(true)
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
      const setFile = vi.fn()
      const setHasUploadedFile = vi.fn()
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

    it('shows closed captions panel when uploading videos', async () => {
      renderPanel({
        theFile: new File(['bits'], 'dummy-video.mp4', {
          lastModified: 1568991600840,
          type: 'video/mp4',
        }),
        hasUploadedFile: true,
      })

      const ccCheckbox = await screen.findByRole('checkbox', {name: 'Add CC/Subtitles'})
      fireEvent.click(ccCheckbox)

      expect(screen.getByText('Add CC/Subtitles')).toBeInTheDocument()
    })

    it('shows closed captions panel when uploading audios', async () => {
      renderPanel({
        theFile: new File(['bits'], 'dummy-audio.mp3', {
          lastModified: 1568991600840,
          type: 'audio/mp3',
        }),
        hasUploadedFile: true,
      })

      const ccCheckbox = await screen.findByRole('checkbox', {name: 'Add CC/Subtitles'})
      fireEvent.click(ccCheckbox)

      expect(screen.getByText('Add CC/Subtitles')).toBeInTheDocument()
    })
  })
})
