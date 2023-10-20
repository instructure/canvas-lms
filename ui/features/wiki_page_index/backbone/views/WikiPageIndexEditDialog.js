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

import {useScope as useI18nScope} from '@canvas/i18n'
import DialogFormView, {getResponsiveWidth} from '@canvas/forms/backbone/views/DialogFormView'
import wrapperTemplate from '../../jst/WikiPageIndexEditDialog.handlebars'

const I18n = useI18nScope('pages')

const dialogDefaults = {
  fixDialogButtons: false,
  title: I18n.t('edit_dialog_title', 'Edit Page'),
  width: getResponsiveWidth(240, 450),
  height: 230,
  minHeight: 230,
}

export default class WikiPageIndexEditDialog extends DialogFormView {
  static initClass() {
    this.prototype.setViewProperties = false
    this.prototype.className = 'page-edit-dialog'

    this.prototype.returnFocusTo = null

    this.prototype.wrapperTemplate = wrapperTemplate
  }

  template() {
    return ''
  }

  initialize(options = {}) {
    this.returnFocusTo = options.returnFocusTo
    return super.initialize({...dialogDefaults, ...options})
  }

  setupDialog() {
    super.setupDialog(...arguments)

    const form = this

    // Add a close event for focus handling
    form.$el.on('dialogclose', (_event, _ui) => {
      return this.returnFocusTo != null ? this.returnFocusTo.focus() : undefined
    })

    const buttons = [
      {
        class: 'btn',
        text: I18n.t('cancel_button', 'Cancel'),
        click: () => {
          form.$el.dialog('close')
          return this.returnFocusTo != null ? this.returnFocusTo.focus() : undefined
        },
      },
      {
        class: 'btn btn-primary',
        text: I18n.t('save_button', 'Save'),
        'data-text-while-loading': I18n.t('saving_button', 'Saving...'),
        click: () => {
          form.submit()
          return this.returnFocusTo != null ? this.returnFocusTo.focus() : undefined
        },
      },
    ]
    return this.$el.dialog('option', 'buttons', buttons)
  }

  openAgain() {
    super.openAgain(...arguments)
    return this.$('[name="title"]').focus()
  }
}
WikiPageIndexEditDialog.initClass()
