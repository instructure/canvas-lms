//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import {View} from '@canvas/backbone'
import template from '../../jst/fileUploadQuestionState.handlebars'
import uploadedOrRemovedTemplate from '../../jst/fileUploadedOrRemoved.handlebars'
import '@canvas/jquery/jquery.instructure_forms'
import '@canvas/jquery/jquery.disableWhileLoading'

export default class FileUploadQuestion extends View {
  static initClass() {
    // TODO: Handle quota errors?
    // TODO: Handle upload errors?

    this.prototype.els = {
      '.file-upload': '$fileUpload',
      '.file-upload-btn': '$fileDialogButton',
      '.attachment-id': '$attachmentID',
      '.file-upload-box': '$fileUploadBox',
      '#fileupload_in_progress': '$fileUploadInprogress',
    }

    this.prototype.events = {
      'change input[type=file]': 'checkForFileChange',
      'click .file-upload-btn': 'openFileBrowser',
      'click .delete-attachment': 'deleteAttachment',
    }
  }

  checkForFileChange(event) {
    // Stop the bubbling of the event so the question doesn't
    // get marked as read before the file is uploaded.
    event.preventDefault()
    event.stopPropagation()
    if (this.$fileUpload.val()) {
      this.removeFileStatusMessage()
      this.model.set('file', this.$fileUpload[0])
      this.$fileUploadInprogress.val(true)
      const dfrd = this.model.save(null, {success: this.processAttachment.bind(this)})
      return this.$fileUploadBox.disableWhileLoading(dfrd)
    }
  }

  openFileBrowser(event) {
    event.preventDefault()
    return this.$fileUpload.click()
  }

  render() {
    super.render(...arguments)
    // This unfortunate bit of browser detection is here because IE9
    // will throw an error if you programatically call "click" on the
    // input file element, get the file element, and submit a form.
    // For now, remove the input rendered in ERB-land, and the template is
    // responsible for rendering a fallback to a regular input type=file
    const isIE = false
    this.$fileUploadBox.html(template({...this.model.present(), isIE}))
    this.$fileUpload = this.$('.file-upload')
    return this
  }

  removeFileStatusMessage() {
    return this.$fileUploadBox.siblings('.file-status').remove()
  }

  // For now we'll just process the first one.
  processAttachment(_attachment) {
    this.$attachmentID.val(this.model.id).trigger('change')
    this.$fileUploadInprogress.val(false)
    this.$fileUploadBox.addClass('file-upload-box-with-file')
    this.render()
    this.$fileUploadBox
      .parent()
      .append(uploadedOrRemovedTemplate({...this.model.present(), fileUploaded: true}))
    return this.trigger('attachmentManipulationComplete')
  }

  // For now we'll just remove it from the form, but not actually delete it
  // using the API in case teacher's need to see any uploaded files a
  // student may upload.
  deleteAttachment(event) {
    event.preventDefault()
    this.$attachmentID.val('').trigger('change')
    this.$fileUploadBox.removeClass('file-upload-box-with-file')
    this.$fileUpload.val(null)
    const oldModel = this.model.present()
    this.model.clear()
    this.removeFileStatusMessage()
    this.render()
    this.$fileUploadBox.parent().append(uploadedOrRemovedTemplate(oldModel))
    return this.trigger('attachmentManipulationComplete')
  }
}
FileUploadQuestion.initClass()
