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

import $ from 'jquery'
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.instructure_misc_plugins'
import '@canvas/loading-image'

$(document).on('click', '.visibility_help_link', event => {
  event.preventDefault()
  let $dialog = $('#visibility_help_dialog')
  if ($dialog.length === 0) {
    $dialog = $('<div/>').attr('id', 'visibility_help_dialog').hide().appendTo('body').dialog({
      autoOpen: false,
      title: '',
      width: 330,
      modal: true,
      zIndex: 1000,
    })

    $('#course_course_visibility option').each((_i, element) => {
      $dialog.append($('<div/>').append($('<b/>', {text: element.innerText})))
      $dialog.append(
        $('<div/>', {text: ENV.COURSE_VISIBILITY_OPTION_DESCRIPTIONS[element.value] || ''})
      )
    })
  }
  $dialog.dialog('open')
})
