//
// Copyright (C) 2015 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import DialogBaseView from '@canvas/dialog-base-view'
import template from './RelockModulesDialog.handlebars'

const I18n = useI18nScope('modules')

export default class RelockModulesDialog extends DialogBaseView {
  renderIfNeeded(data) {
    if (data.relock_warning) {
      this.module_id = data.id
      return this.render().show()
    }
  }

  dialogOptions() {
    return {
      id: 'relock_modules_dialog',
      title: I18n.t('requirements_changed', 'Requirements Changed'),
      buttons: [
        {
          text: I18n.t('relock_modules', 'Re-Lock Modules'),
          click: () => this.relock(),
        },
        {
          text: I18n.t('continue', 'Continue'),
          class: 'btn-primary',
          click: e => this.cancel(e),
        },
      ],
      modal: true,
      zIndex: 1000,
    }
  }

  relock() {
    const url = `/api/v1/courses/${ENV.COURSE_ID}/modules/${this.module_id}/relock`
    return this.dialog.disableWhileLoading($.ajaxJSON(url, 'PUT', {}, () => this.close()))
  }
}
RelockModulesDialog.prototype.template = template
