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
$(document).ready(function() {
  var $saml_debug_info = $('#saml_debug_info'),
    $start_saml_debugging = $('#start_saml_debugging'),
    $stop_saml_debugging = $('#stop_saml_debugging'),
    $refresh_saml_debugging = $('#refresh_saml_debugging'),
    refresh_timer = null

  var stop_debugging = function() {
    clearTimeout(refresh_timer)
    $start_saml_debugging.show()
    $refresh_saml_debugging.hide()
    $stop_saml_debugging.hide()
    $saml_debug_info.html('')
    $saml_debug_info.hide()
  }

  var load_debug_data = function(new_debug_session) {
    clearTimeout(refresh_timer)
    var url = $start_saml_debugging.attr('href')
    if (new_debug_session) {
      url = url + '?start_debugging=true'
    }
    $.ajaxJSON(url, 'GET', {}, function(data) {
      if (data) {
        if (data.debugging) {
          $saml_debug_info.html($.raw(data.debug_data))
          $saml_debug_info.show()
          refresh_timer = setTimeout(function() {
            load_debug_data(false)
          }, 30000)
        } else {
          stop_debugging()
        }
      }
    })
  }

  $start_saml_debugging.click(function(event) {
    event.preventDefault()
    load_debug_data(true)
    $start_saml_debugging.hide()
    $refresh_saml_debugging.show()
    $stop_saml_debugging.show()
  })

  $refresh_saml_debugging.click(function(event) {
    event.preventDefault()
    load_debug_data(false)
  })

  $stop_saml_debugging.click(function(event) {
    event.preventDefault()
    stop_debugging()

    var url = $stop_saml_debugging.attr('href')
    $.ajaxJSON(url, 'GET', {}, function(data) {})
  })
})
