/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

/* eslint-disable no-void */

import {extend} from '@canvas/backbone/utils'
import Backbone from '@canvas/backbone'
import template from '../../../jst/subviews/ChooseMigrationFile.handlebars'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('content_migrations')

extend(ChooseMigrationFile, Backbone.View)

function ChooseMigrationFile() {
  return ChooseMigrationFile.__super__.constructor.apply(this, arguments)
}

ChooseMigrationFile.prototype.template = template

ChooseMigrationFile.prototype.els = {
  '#migrationFileUpload': '$migrationFileUpload',
}

ChooseMigrationFile.prototype.events = {
  'change #migrationFileUpload': 'setAttributes',
}

ChooseMigrationFile.optionProperty('fileSizeLimit')

ChooseMigrationFile.prototype.setAttributes = function (event) {
  const filename = event.target.value.replace(/^.*\\/, '')
  const fileElement = this.$migrationFileUpload[0]
  return this.model.set('pre_attachment', {
    size: this.fileSize(fileElement),
    name: filename,
    fileElement,
    no_redirect: true,
  })
}

// TODO
//   Handle cases for file size from IE browsers
// @api private
ChooseMigrationFile.prototype.fileSize = function (fileElement) {
  let ref
  return (ref = fileElement.files) != null ? ref[0].size : void 0
}

// Validates this form element. This validates method is a convention used
// for all sub views.
// ie:
//   error_object = {fieldName:[{type:'required', message: 'This is wrong'}]}
// -----------------------------------------------------------------------
// @expects void
// @returns void | object (error)
// @api private
ChooseMigrationFile.prototype.validations = function () {
  const errors = {}
  const preAttachment = this.model.get('pre_attachment')
  const fileErrors = []
  const fileElement = preAttachment != null ? preAttachment.fileElement : void 0
  if (!((preAttachment != null ? preAttachment.name : void 0) && fileElement)) {
    fileErrors.push({
      type: 'required',
      message: I18n.t('file_required', 'You must select a file to import content from'),
    })
  } else if (this.fileSize(fileElement) > this.fileSizeLimit) {
    fileErrors.push({
      type: 'upload_limit_exceeded',
      message: I18n.t('file_too_large', 'Your migration cannot exceed %{file_size}', {
        file_size: this.humanReadableSize(this.fileSizeLimit),
      }),
    })
  }
  if (fileErrors.length) {
    errors.file = fileErrors
  }
  return errors
}

// Converts a size to a human readible string. "size" should be in
// bytes to stay consistent with the javascript files api.
// --------------------------------------------------------------
// @expects size (bytes | string(in bytes))
// @returns readableString (string)
// @api private
ChooseMigrationFile.prototype.humanReadableSize = function (size) {
  size = parseFloat(size)
  const units = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
  let i = 0
  while (size >= 1024) {
    size /= 1024
    ++i
  }
  return size.toFixed(1) + ' ' + units[i]
}

export default ChooseMigrationFile
