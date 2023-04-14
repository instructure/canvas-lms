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

import {extend} from '@canvas/backbone/utils'
import Backbone from '@canvas/backbone'
import template from '../../../jst/subviews/FolderPicker.handlebars'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('content_migrations')

extend(FolderPickerView, Backbone.View)

function FolderPickerView() {
  return FolderPickerView.__super__.constructor.apply(this, arguments)
}

FolderPickerView.prototype.template = template

FolderPickerView.optionProperty('folderOptions')

FolderPickerView.prototype.els = {
  '.migrationUploadTo': '$migrationUploadTo',
}

FolderPickerView.prototype.events = {
  'change .migrationUploadTo': 'setAttributes',
}

FolderPickerView.prototype.setAttributes = function (_event) {
  return this.model.set(
    'settings',
    this.$migrationUploadTo.val()
      ? {
          folder_id: this.$migrationUploadTo.val(),
        }
      : // eslint-disable-next-line no-void
        void 0
  )
}

FolderPickerView.prototype.toJSON = function (json) {
  json = FolderPickerView.__super__.toJSON.apply(this, arguments)
  json.folderOptions = this.folderOptions || ENV.FOLDER_OPTIONS
  return json
}

// Validates this form element. This validates method is a convention used
// for all sub views.
// ie:
//   error_object = {fieldName:[{type:'required', message: 'This is wrong'}]}
// -----------------------------------------------------------------------
// @expects void
// @returns void | object (error)
// @api private

FolderPickerView.prototype.validations = function () {
  const errors = {}
  const settings = this.model.get('settings')
  // eslint-disable-next-line no-void
  if (!(settings != null ? settings.folder_id : void 0)) {
    errors.migrationUploadTo = [
      {
        type: 'required',
        message: I18n.t('You must select a folder to upload your migration to'),
      },
    ]
  }
  return errors
}

export default FolderPickerView
