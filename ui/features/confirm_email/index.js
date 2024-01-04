/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

import $ from 'jquery'
import '@canvas/jquery/jquery.ajaxJSON'
import {useScope as useI18nScope} from '@canvas/i18n'
import preventDefault from '@canvas/util/preventDefault'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('profile')

$(() => {
  let resending = false

  $('.re_send_confirmation_link').click(
    preventDefault(function () {
      const $this = $(this)
      const text = $this.text()

      if (resending) return
      resending = true
      $this.text(I18n.t('resending', 'resending...'))

      $.ajaxJSON(
        $this.attr('href'),
        'POST',
        {},
        _data => {
          resending = false
          $this.text(text)
          $.flashMessage(I18n.t('done_resending', 'Done! Message delivery may take a few minutes.'))
        },
        _data => {
          resending = false
          $this.text(text)
          $.flashError(I18n.t('failed_resending', 'Request failed. Try again.'))
        }
      )
    })
  )
})
