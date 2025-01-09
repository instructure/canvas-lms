/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import FileUploadQuestion from '../FileUploadQuestionView'
import File from '@canvas/files/backbone/models/File'
import $ from 'jquery'
import 'jquery-migrate'

describe('FileUploadQuestionView', () => {
  let view
  let model
  let oldEnv

  beforeEach(() => {
    oldEnv = window.ENV
    model = new File(
      {
        display_name: 'foobar.jpg',
        id: 1,
      },
      {preflightUrl: 'url.com'},
    )
    view = new FileUploadQuestion({model})

    document.body.innerHTML = '<div id="fixtures"></div>'
    $('<input value="C:\\fakepath\\file.upload.zip" class="file-upload hidden" />').appendTo(
      view.$el,
    )
    $('<input type="hidden" id="fileupload_in_progress" value="false"/>').appendTo(view.$el)
    view.$el.appendTo('#fixtures')
    view.render()
  })

  afterEach(() => {
    window.ENV = oldEnv
    view.remove()
    document.body.innerHTML = ''
  })

  it('sets file upload status to in_progress when file changes', () => {
    $('#fileupload_in_progress').val(false)
    const saveSpy = jest.spyOn(model, 'save').mockImplementation(() => Promise.resolve())

    expect($('#fileupload_in_progress').val()).toBe('false')

    // Mock the file input with a proper files array
    const mockFile = new File(['test'], 'test.txt', {type: 'text/plain'})
    Object.defineProperty(view.$fileUpload[0], 'files', {
      value: [mockFile],
      writable: true,
    })
    view.$fileUpload.val('C:\\fakepath\\file.upload.zip')

    view.checkForFileChange(new $.Event('keydown', {keyCode: 64}))

    expect($('#fileupload_in_progress').val()).toBe('true')
    saveSpy.mockRestore()
  })

  it('fires "attachmentManipulationComplete" event when processing attachment', () => {
    $('#fileupload_in_progress').val(true)
    const triggerSpy = jest.spyOn(view, 'trigger')

    expect(triggerSpy).not.toHaveBeenCalled()
    expect($('#fileupload_in_progress').val()).toBe('true')

    view.processAttachment()

    expect(triggerSpy).toHaveBeenCalledWith('attachmentManipulationComplete')
    expect($('#fileupload_in_progress').val()).toBe('false')
  })

  it('fires "attachmentManipulationComplete" event when deleting attachment', () => {
    const triggerSpy = jest.spyOn(view, 'trigger')

    expect(triggerSpy).not.toHaveBeenCalled()
    view.deleteAttachment(new $.Event('keydown', {keyCode: 64}))

    expect(triggerSpy).toHaveBeenCalledWith('attachmentManipulationComplete')
  })

  it('clears file input when deleting attachment', () => {
    expect(view.$fileUpload.val()).toBe('C:\\fakepath\\file.upload.zip')
    view.deleteAttachment(new $.Event('keydown', {keyCode: 64}))
    expect(view.$fileUpload.val()).toBe('')
  })
})
