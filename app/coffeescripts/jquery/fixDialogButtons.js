//
// Copyright (C) 2012 - present Instructure, Inc.
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
import _ from 'underscore'
import preventDefault from '../fn/preventDefault'
import 'jqueryui/dialog'

$.fn.fixDialogButtons = function () {
  return this.each(function () {
    const $dialog = $(this)
    const $buttons = $dialog.find('.button-container:last .btn, button[type=submit]')
    if ($buttons.length) {
      $dialog.find('.button-container:last, button[type=submit]').hide()
      let buttons = $.map($buttons.toArray(), (button) => {
        const $button = $(button)
        let classes = $button.attr('class') || ''
        const id = $button.attr('id')

        // if you add the class 'dialog_closer' to any of the buttons,
        // clicking it will cause the dialog to close
        if ($button.is('.dialog_closer')) {
          $button.off('.fixdialogbuttons')
          $button.on('click.fixdialogbuttons', preventDefault(() => $dialog.dialog('close')))
        }

        if ($button.prop('type') === 'submit' && $button[0].form) {
          classes += ' button_type_submit'
        }

        return {
          text: $button.text(),
          'data-text-while-loading': $button.data('textWhileLoading'),
          click: () => $button.click(),
          class: classes,
          id
        }
      })
      // put the primary button(s) on the far right
      buttons = _.sortBy(buttons, button => (button.class.match(/btn-primary/) ? 1 : 0))
      $dialog.dialog('option', 'buttons', buttons)
    }
  })
}
