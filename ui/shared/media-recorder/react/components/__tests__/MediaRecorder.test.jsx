// /*
//  * Copyright (C) 2018 - present Instructure, Inc.
//  *
//  * This file is part of Canvas.
//  *
//  * Canvas is free software: you can redistribute it and/or modify it under
//  * the terms of the GNU Affero General Public License as published by the Free
//  * Software Foundation, version 3 of the License.
//  *
//  * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
//  * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
//  * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
//  * details.
//  *
//  * You should have received a copy of the GNU Affero General Public License along
//  * with this program. If not, see <http://www.gnu.org/licenses/>.
//  */

import MediaRecorderComponent, {fileWithExtension} from '../MediaRecorder'

describe('MediaRecorder', () => {
  describe('saveFile', () => {
    let mediaRecorder
    let mockOnSaveFile
    let mockDialog
    let mockDialogContent
    let mockDialogButtons

    beforeEach(() => {
      mockDialogContent = document.createElement('div')
      mockDialogButtons = document.createElement('div')
      mockDialog = document.createElement('div')
      mockDialog.classList.add('ui-dialog')
      mockDialog.appendChild(mockDialogContent)
      mockDialog.appendChild(mockDialogButtons)
      mockDialogContent.classList.add('ui-dialog-content')
      mockDialogButtons.classList.add('ui-dialog-buttonpane')

      document.body.appendChild(mockDialog)

      mockOnSaveFile = jest.fn()
      mediaRecorder = new MediaRecorderComponent({
        onSaveFile: mockOnSaveFile,
      })
    })

    afterEach(() => {
      document.body.removeChild(mockDialog)
      jest.restoreAllMocks()
    })

    it('displays a spinner in the dialog when saving a file', () => {
      const testFile = new File(['test content'], 'test-file.mp4', {type: 'video/mp4'})
      mediaRecorder.saveFile(testFile)

      expect(mockDialogContent.querySelector('#media-spinner-container')).not.toBeNull()
      expect(mockDialogButtons.style.display).toBe('none')
      expect(mockOnSaveFile).toHaveBeenCalledWith(testFile)
    })
  })

  describe('fileWithExtension', () => {
    it('returns same file if it already has extension', () => {
      const file = new File(['bits'], 'dummy-video.mp4')
      const newFile = fileWithExtension(file)
      expect(newFile).toBe(file)
    })

    it('adds extension by mime type', () => {
      const file = new File(['bits'], 'dummy-video', {
        type: 'video/mp4',
      })
      const newFile = fileWithExtension(file)
      expect(newFile.name).toBe('dummy-video.mp4')
    })

    it('adds default extension if no mime type', () => {
      const file = new File(['bits'], 'dummy-video')
      const newFile = fileWithExtension(file)
      expect(newFile.name).toBe('dummy-video.webm')
    })

    it('retains properties', () => {
      const file = new File(['bits'], 'dummy-audio', {
        type: 'audio/mpeg',
        lastModified: 123456,
      })
      const newFile = fileWithExtension(file)
      expect(newFile.name).toBe('dummy-audio.mp3')
      expect(newFile.lastModified).toBe(123456)
      expect(newFile.type).toBe('audio/mpeg')
    })

    it('handles files that end with a period', () => {
      const file = new File(['bits'], 'dummy-audio.', {
        type: 'audio/mpeg',
        lastModified: 123456,
      })
      const newFile = fileWithExtension(file)
      expect(newFile.name).toBe('dummy-audio.mp3')
    })

    it('converts mime type to extension', () => {
      const file = new File(['bits'], 'dummy-media.', {
        type: 'video/quicktime',
        lastModified: 123456,
      })
      const newFile = fileWithExtension(file)
      expect(newFile.name).toBe('dummy-media.mov')
    })
  })
})
