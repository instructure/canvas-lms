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
import {render, fireEvent, waitFor, screen} from '@testing-library/react'
import UploadMedia, {UploadMediaModal} from '../UploadMedia'
import getTranslations from '../getTranslations'

jest.mock('../getTranslations', () => jest.fn(locale => Promise.resolve({[locale]: {}})))
const actual = jest.requireActual('../saveMediaRecording')
const saveMediaRecordingSpy = jest.spyOn(actual, 'default')

const uploadMediaTranslations = {
  UploadMediaStrings: {
    CLEAR_FILE_TEXT: 'Clear selected file',
    CLOSE_TEXT: 'Close',
    COMPUTER_PANEL_TITLE: 'Computer',
    DRAG_DROP_CLICK_TO_BROWSE: 'Drag and drop, or click to browse your computer',
    DRAG_FILE_TEXT: 'Drag a file here',
    INVALID_FILE_TEXT: 'Invalid File',
    LOADING_MEDIA: 'Loading...',
    RECORD_PANEL_TITLE: 'Record',
    SUBMIT_TEXT: 'Submit',
    UPLOADING_ERROR: 'Upload Error',
    UPLOAD_MEDIA_LABEL: 'Upload Media',
    MEDIA_RECORD_NOT_AVAILABLE: 'Record not available',
    PROGRESS_LABEL: 'Making progress',
    ADD_CLOSED_CAPTIONS_OR_SUBTITLES: 'Add CC/Subtitles',
  },
}

function makeProps(overrideProps = {}) {
  return {
    rcsConfig: {
      contextType: 'course',
      contextId: '17',
      origin: 'http://host:port',
      jwt: 'whocares',
    },
    open: true,
    liveRegion: () => null,
    onStartUpload: () => {},
    onComplete: () => {},
    onDismiss: () => {},
    tabs: {record: false, upload: true},
    uploadMediaTranslations,
    userLocale: 'en',
    ...overrideProps,
  }
}

function renderComponent(overrideProps = {}) {
  return render(<UploadMediaModal {...makeProps(overrideProps)} />)
}

describe('Upload Media', () => {
  describe('default export', () => {
    it('loads translations', async () => {
      render(<UploadMedia {...makeProps({userLocale: 'es'})} />)
      await waitFor(() => expect(getTranslations).toHaveBeenCalledWith('es'))
    })
  })

  describe('renders the selected tabs', () => {
    it('renders Computer', () => {
      renderComponent({tabs: {record: false, upload: true}})
      expect(screen.getByText('Computer')).toBeInTheDocument()
    })

    it('renders Computer without RCS info', () => {
      renderComponent({tabs: {record: false, upload: true}, rcsConfig: {}})
      expect(screen.getByText('Computer')).toBeInTheDocument()
    })

    it('renders Computer and Record', () => {
      renderComponent({tabs: {record: true, upload: true}})
      expect(screen.getByText('Computer')).toBeInTheDocument()
      expect(screen.getByText('Record')).toBeInTheDocument()
    })
  })

  describe('when a tab is clicked', () => {
    it('does not change selectedPanel if there is only one tab visible', () => {
      renderComponent({tabs: {record: false, upload: true}})
      const tab = screen.getByRole('tab', {name: 'Computer'})
      const setStateSpy = jest.spyOn(UploadMediaModal.prototype, 'setState')
      fireEvent.click(tab)
      expect(setStateSpy).not.toHaveBeenCalledWith(expect.objectContaining({selectedPanel: 0}))
      setStateSpy.mockRestore()
    })

    it('changes selectedPanel if there are multiple tabs visible', () => {
      renderComponent({tabs: {record: true, upload: true}})
      const tab = screen.getByRole('tab', {name: 'Computer'})
      const setStateSpy = jest.spyOn(UploadMediaModal.prototype, 'setState')
      fireEvent.click(tab)
      expect(setStateSpy).toHaveBeenCalledWith(expect.objectContaining({selectedPanel: 0}))
      setStateSpy.mockRestore()
    })
  })

  describe('when the modal is closed', () => {
    const computerPanel = 0

    it('sets the selectedPanel to "Computer" when "Computer" is the only visible tab', () => {
      renderComponent({tabs: {record: false, upload: true}})
      const closeButton = screen.getAllByRole('button', {name: 'Close'})[0]
      const setStateSpy = jest.spyOn(UploadMediaModal.prototype, 'setState')
      fireEvent.click(closeButton)
      expect(setStateSpy).toHaveBeenCalledWith(
        expect.objectContaining({selectedPanel: computerPanel})
      )
      setStateSpy.mockRestore()
    })

    it('sets the selectedPanel to "Computer" when both tabs are visible', () => {
      renderComponent({tabs: {record: true, upload: true}})
      const closeButton = screen.getAllByRole('button', {name: 'Close'})[0]
      const setStateSpy = jest.spyOn(UploadMediaModal.prototype, 'setState')
      fireEvent.click(closeButton)
      expect(setStateSpy).toHaveBeenCalledWith(
        expect.objectContaining({selectedPanel: computerPanel})
      )
      setStateSpy.mockRestore()
    })
  })

  describe('when the tabs prop changes', () => {
    it('recomputes the selected panel', () => {
      const setStateSpy = jest.spyOn(UploadMediaModal.prototype, 'setState')

      // Initial render with no tabs
      const {rerender} = render(
        <UploadMediaModal
          rcsConfig={{
            contextType: 'course',
            contextId: '17',
            origin: 'http://host:port',
            jwt: 'whocares',
          }}
          open={true}
          liveRegion={() => null}
          onStartUpload={() => {}}
          onComplete={() => {}}
          onDismiss={() => {}}
          tabs={{record: false, upload: false}}
          uploadMediaTranslations={uploadMediaTranslations}
          userLocale="en"
        />
      )

      // rerender, setting the record tab to true
      rerender(
        <UploadMediaModal
          rcsConfig={{
            contextType: 'course',
            contextId: '17',
            origin: 'http://host:port',
            jwt: 'whocares',
          }}
          open={true}
          liveRegion={() => null}
          onStartUpload={() => {}}
          onComplete={() => {}}
          onDismiss={() => {}}
          tabs={{record: false, upload: true}}
          uploadMediaTranslations={uploadMediaTranslations}
          userLocale="en"
        />
      )

      expect(setStateSpy).toHaveBeenCalledWith({selectedPanel: 0})

      setStateSpy.mockRestore()
    })

    it('recomputes the selected panel when the current selected panel is no longer visible', () => {
      const setStateSpy = jest.spyOn(UploadMediaModal.prototype, 'setState')

      // Initial render with upload tab
      const {rerender} = render(
        <UploadMediaModal
          rcsConfig={{
            contextType: 'course',
            contextId: '17',
            origin: 'http://host:port',
            jwt: 'whocares',
          }}
          open={true}
          liveRegion={() => null}
          onStartUpload={() => {}}
          onComplete={() => {}}
          onDismiss={() => {}}
          tabs={{record: false, upload: true}}
          uploadMediaTranslations={uploadMediaTranslations}
          userLocale="en"
        />
      )

      // rerender, showing the record tab and hiding the upload tab
      rerender(
        <UploadMediaModal
          rcsConfig={{
            contextType: 'course',
            contextId: '17',
            origin: 'http://host:port',
            jwt: 'whocares',
          }}
          open={true}
          liveRegion={() => null}
          onStartUpload={() => {}}
          onComplete={() => {}}
          onDismiss={() => {}}
          tabs={{record: true, upload: false}}
          uploadMediaTranslations={uploadMediaTranslations}
          userLocale="en"
        />
      )

      expect(setStateSpy).toHaveBeenLastCalledWith({selectedPanel: 1})

      setStateSpy.mockRestore()
    })
  })

  describe('only enable Submit button when ready', () => {
    let computerFile

    beforeEach(() => {
      computerFile = new File(['bits'], 'dummy-video.mp4', {
        lastModifiedDate: 1568991600840,
        type: 'video/mp4',
      })
    })

    it('is disabled before ComputerPanel gets a file', () => {
      renderComponent({tabs: {upload: true}})
      expect(screen.getByText('Submit').closest('button')).toHaveAttribute('disabled')
    })

    it('is enabled once ComputerPanel has a file', () => {
      renderComponent({tabs: {upload: true}, computerFile})
      expect(screen.getByText('Submit').closest('button')).not.toHaveAttribute('disabled')
    })

    it('is enabled while uploading if disableSubmitWhileUploading is false', () => {
      renderComponent({
        disableSubmitWhileUploading: false,
        onStartUpload: jest.fn(),
        tabs: {upload: true},
        computerFile,
      })

      fireEvent.click(screen.getByText('Submit'))
      expect(screen.getByText('Submit').closest('button')).not.toBeDisabled()
    })

    it('is disabled while uploading if disableSubmitWhileUploading is true', () => {
      renderComponent({
        disableSubmitWhileUploading: true,
        onStartUpload: jest.fn(),
        tabs: {upload: true},
        computerFile,
      })

      fireEvent.click(screen.getByText('Submit'))
      expect(screen.getByText('Submit').closest('button')).toBeDisabled()
    })

    it('is disabled while uploading if file title is empty', () => {
      computerFile = new File(['bits'], 'dummy-video.mp4', {
        lastModifiedDate: 1568991600840,
        type: 'video/mp4',
      })
      renderComponent({
        disableSubmitWhileUploading: false,
        onStartUpload: jest.fn(),
        tabs: {upload: true},
        computerFile,
      })
      const submitButton = screen.getByText('Submit').closest('button')
      const titleInput = screen.getByPlaceholderText('File name')
      fireEvent.change(titleInput, {target: {value: ''}})
      expect(submitButton).toBeDisabled()
      fireEvent.change(titleInput, {target: {value: 'Awesome video'}})
      expect(submitButton).toBeEnabled()
    })
    // the submit button is not rendered for the record tab
  })

  describe('on submitting results', () => {
    beforeEach(() => {
      saveMediaRecordingSpy.mockClear()
    })

    it('calls onStartUpload when uploading', async () => {
      const onStartUpload = jest.fn()
      renderComponent({
        onStartUpload,
        tabs: {upload: true},
        computerFile: new File(['bits'], 'dummy-video.mp4', {
          lastModifiedDate: 1568991600840,
          type: 'video/mp4',
        }),
      })
      fireEvent.click(screen.getByText('Submit'))
      expect(onStartUpload).toHaveBeenCalled()
    })

    it('adds file extension by mime type', () => {
      renderComponent({
        tabs: {upload: true},
        computerFile: new File(['bits'], 'dummy-video', {
          lastModifiedDate: 1568991600840,
          type: 'video/mp4',
        }),
      })
      fireEvent.click(screen.getByText('Submit'))
      expect(saveMediaRecordingSpy.mock.calls[0][0].userEnteredTitle).toBe('dummy-video.mp4')
    })

    it('adds default file extension when no mime type', () => {
      renderComponent({
        tabs: {upload: true},
        computerFile: new File(['bits'], 'dummy-video', {
          lastModifiedDate: 1568991600840,
        }),
      })
      fireEvent.click(screen.getByText('Submit'))
      expect(saveMediaRecordingSpy.mock.calls[0][0].userEnteredTitle).toBe('dummy-video.webm')
    })

    it('does not add file extension if period in name', () => {
      renderComponent({
        tabs: {upload: true},
        computerFile: new File(['bits'], 'dummy.video', {
          lastModifiedDate: 1568991600840,
        }),
      })
      fireEvent.click(screen.getByText('Submit'))
      expect(saveMediaRecordingSpy.mock.calls[0][0].userEnteredTitle).toBe('dummy.video')
    })

    it('handles files that end with a period', () => {
      renderComponent({
        tabs: {upload: true},
        computerFile: new File(['bits'], 'dummyvideo.', {
          lastModifiedDate: 1568991600840,
        }),
      })
      fireEvent.click(screen.getByText('Submit'))
      expect(saveMediaRecordingSpy.mock.calls[0][0].userEnteredTitle).toBe('dummyvideo.webm')
    })

    it('converts mime type to extension', () => {
      renderComponent({
        tabs: {upload: true},
        computerFile: new File(['bits'], 'dummyvideo.', {
          lastModifiedDate: 1568991600840,
          type: 'video/quicktime'
        }),
      })
      fireEvent.click(screen.getByText('Submit'))
      expect(saveMediaRecordingSpy.mock.calls[0][0].userEnteredTitle).toBe('dummyvideo.mov')
    })
    // the rest is tested via saveMediaRecording.test.js
  })
})
