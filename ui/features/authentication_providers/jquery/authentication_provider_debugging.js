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
import {raw} from '@instructure/html-escape'

$(document).ready(() => {
  const $start_debugging = $('.start_debugging'),
    $stop_debugging = $('.stop_debugging'),
    $refresh_debugging = $('.refresh_debugging')

  const stop_debugging = function ($link) {
    const $container = $link.closest('div.debugging')
    $container.find('.start_debugging').show()
    $container.find('.refresh_debugging').hide()
    $container.find('.stop_debugging').hide()
    const debug_data = $container.find('.debug_data')
    debug_data.html('')
    debug_data.hide()
  }

  const load_debug_data = function ($link, new_debug_session) {
    const url = $link.attr('href')
    let method = 'GET'
    let debug_data
    if (new_debug_session) {
      method = 'PUT'
    }
    $.ajaxJSON(url, method, {}, data => {
      if (data) {
        if (data.debugging) {
          debug_data = $link.closest('div.debugging').find('.debug_data')
          debug_data.html(raw(data.debug_data))
          debug_data.show()
        } else {
          stop_debugging()
        }
      }
    })
  }

  $start_debugging.click(event => {
    event.preventDefault()
    const $link = $(event.target)
    load_debug_data($link, true)
    $link.hide()
    const $container = $link.closest('div.debugging')
    $container.find('.refresh_debugging').show()
    $container.find('.stop_debugging').show()
  })

  $refresh_debugging.click(event => {
    event.preventDefault()
    load_debug_data($(event.target), false)
  })

  $stop_debugging.click(event => {
    event.preventDefault()
    const $link = $(event.target)
    stop_debugging($link)

    const url = $link.attr('href')
    $.ajaxJSON(url, 'DELETE', {}, _data => {})
  })
})
