//
// Copyright (C) 2014 - present Instructure, Inc.
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

import I18n from 'i18n!feature_flags'
import DialogBaseView from '../DialogBaseView'
import template from 'jst/feature_flags/featureFlagDialog'

export default class FeatureFlagDialog extends DialogBaseView {
  static initClass() {
    this.optionProperty('deferred')

    this.optionProperty('message')

    this.optionProperty('title')

    this.optionProperty('hasCancelButton')

    this.prototype.template = template

    this.prototype.labels = {
      okay: I18n.t('#buttons.okay', 'Okay'),
      cancel: I18n.t('#buttons.cancel', 'Cancel')
    }
  }

  dialogOptions() {
    const options = {
      title: this.title,
      height: 300,
      width: 500,
      buttons: [{text: this.labels.okay, click: this.onConfirm.bind(this), class: 'btn-primary'}],
      open: this.onOpen.bind(this),
      close: this.onClose.bind(this)
    }
    if (this.hasCancelButton) {
      options.buttons.unshift({text: this.labels.cancel, click: this.onCancel.bind(this)})
    }
    return options
  }

  onOpen(_e) {
    this.okay = false
  }

  onClose(_e) {
    if (this.okay) {
      return this.deferred.resolve()
    } else {
      return this.deferred.reject()
    }
  }

  onCancel(_e) {
    this.close()
  }

  onConfirm(_e) {
    this.okay = this.hasCancelButton
    this.close()
  }

  toJSON() {
    return {message: this.message}
  }
}
FeatureFlagDialog.initClass()
