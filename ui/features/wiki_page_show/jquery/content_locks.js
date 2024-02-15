/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import htmlEscape from '@instructure/html-escape'
import '@canvas/content-locks/jquery/lock_reason'
import '@canvas/datetime/jquery' /* datetimeString */
import 'jqueryui/dialog'

const I18n = useI18nScope('content_locks')

if (!('INST' in window)) window.INST = {}

$(document).ready(function () {
  $(document).on('click', '.content_lock_icon', function (event) {
    if ($(this).data('lock_reason')) {
      event.preventDefault()
      const data = $(this).data('lock_reason')
      const type = data.type
      const $reason = $('<div/>')
      $reason.html(htmlEscape(INST.lockExplanation(data, type)))
      let $dialog = $('#lock_reason_dialog')
      if ($dialog.length === 0) {
        $dialog = $('<div/>').attr('id', 'lock_reason_dialog')
        $('body').append($dialog.hide())
        const $div =
          "<div class='lock_reason_content'></div><div class='button-container'><button type='button' class='btn' >" +
          htmlEscape(I18n.t('buttons.ok_thanks', 'Ok, Thanks')) +
          '</button></div>'
        $dialog.append($div)
        $dialog.find('.button-container .btn').click(() => {
          $dialog.dialog('close')
        })
      }
      $dialog.find('.lock_reason_content').empty().append($reason)
      $dialog.dialog({
        title: I18n.t('titles.content_is_locked', 'Content Is Locked'),
        modal: true,
        zIndex: 1000,
      })
    }
  })
})
