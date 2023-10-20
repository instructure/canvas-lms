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

import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import DialogFormView, {getResponsiveWidth} from '@canvas/forms/backbone/views/DialogFormView'

const I18n = useI18nScope('pages')

const dialogDefaults = {
  fixDialogButtons: false,
  title: I18n.t('delete_dialog_title', 'Delete Page'),
  width: getResponsiveWidth(240, 400),
  height: 'auto',
}

export default class WikiPageDeleteDialog extends DialogFormView {
  static initClass() {
    this.prototype.setViewProperties = false

    this.optionProperty('wiki_pages_path')
    this.optionProperty('focusOnCancel')
    this.optionProperty('onDelete')
  }

  wrapperTemplate() {
    return '<div class="outlet"></div>'
  }

  template() {
    return I18n.t('delete_confirmation', 'Are you sure you want to delete this page?')
  }

  initialize(options) {
    return super.initialize({...dialogDefaults, ...options})
  }

  submit(event) {
    if (event != null) {
      event.preventDefault()
    }

    const destroyDfd = this.model.destroy({wait: true})

    const dfd = $.Deferred()
    const page_title = this.model.get('title')
    const {wiki_pages_path} = this

    destroyDfd.then(() => {
      if (wiki_pages_path) {
        const expires = new Date()
        expires.setMinutes(expires.getMinutes() + 1)
        const path = '/' // should be wiki_pages_path, but IE will only allow *sub*directries to read the cookie, not the directory itself...
        $.cookie('deleted_page_title', page_title, {expires, path})
        return (window.location.href = wiki_pages_path)
      } else {
        $.flashMessage(
          I18n.t('notices.page_deleted', 'The page "%{title}" has been deleted.', {
            title: page_title,
          })
        )
        dfd.resolve()
        return this.close()
      }
    })

    destroyDfd.fail(() => {
      $.flashError(
        I18n.t('notices.delete_failed', 'The page "%{title}" could not be deleted.', {
          title: page_title,
        })
      )
      return dfd.reject()
    })

    return this.$el.disableWhileLoading(dfd)
  }

  close() {
    if (this.dialog != null ? this.dialog.isOpen() : undefined) {
      this.dialog.close()
    }
    if (this.buttonClicked === 'delete') {
      return this.onDelete != null ? this.onDelete() : undefined
    } else {
      return this.focusOnCancel != null ? this.focusOnCancel.focus() : undefined
    }
  }

  setupDialog() {
    super.setupDialog(...arguments)

    const form = this

    const buttons = [
      {
        class: 'btn',
        text: I18n.t('cancel_button', 'Cancel'),
        click: () => {
          this.buttonClicked = 'cancel'
          return form.$el.dialog('close')
        },
      },
      {
        class: 'btn btn-danger',
        text: I18n.t('delete_button', 'Delete'),
        'data-text-while-loading': I18n.t('deleting_button', 'Deleting...'),
        click: () => {
          this.buttonClicked = 'delete'
          return form.submit()
        },
      },
    ]
    return this.$el.dialog('option', 'buttons', buttons)
  }
}
WikiPageDeleteDialog.initClass()
