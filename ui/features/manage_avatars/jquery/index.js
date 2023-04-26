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
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_misc_plugins'

const I18n = useI18nScope('manage_avatars')
/* showIf */

$(document).ready(function () {
  $(document).on('click', '.update_avatar_link', function (event) {
    event.preventDefault()
    const $link = $(this)
    if ($link.attr('data-state') === 'none') {
      // eslint-disable-next-line no-alert
      const result = window.confirm(
        I18n.t('prompts.delete_avatar', "Are you sure you want to delete this user's profile pic?")
      )
      if (!result) {
        return
      }
    } else if ($link.attr('data-state') === 'locked') {
      // eslint-disable-next-line no-alert
      const result = window.confirm(
        I18n.t(
          'prompts.lock_avatar',
          'Locking this picture will approve it and prevent the user from updating it.  Continue?'
        )
      )
      if (!result) {
        return
      }
    }
    const $td = $link.parents('td')
    const url = $td.find('.user_avatar_url').attr('href')
    $td
      .find('.progress')
      .text(I18n.t('messages.updating', 'Updating...'))
      .css('visibility', 'visible')
    $.ajaxJSON(
      url,
      'PUT',
      {'avatar[state]': $link.attr('data-state')},
      data => {
        $td
          .find('.lock_avatar_link')
          .showIf(data.avatar_state !== 'locked')
          .end()
          .find('.unlock_avatar_link')
          .showIf(data.avatar_state === 'locked')
          .end()
          .find('.reject_avatar_link')
          .showIf(data.avatar_state !== 'none')
          .end()
          .find('.approve_avatar_link')
          .hide()
        if (data.avatar_state === 'none') {
          $td.parents('tr').find('.avatar img').attr('src', '/images/dotted_pic.png')
        }
        $td.parents('tr').attr('class', data.avatar_state)
        $td.find('.progress').css('visibility', 'hidden')
      },
      _data => {
        $td
          .find('.progress')
          .text(I18n.t('errors.update_failed', 'Update failed, please try again'))
          .css('visibility', 'visible')
      }
    )
  })
})
