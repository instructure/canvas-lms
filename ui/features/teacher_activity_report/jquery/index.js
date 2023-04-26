/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import 'tablesorter'

$(function () {
  $.tablesorter.addParser({
    id: 'days_or_never',
    is() {
      return false
    },
    format(s) {
      const str = $.trim(s)
      const val = parseInt(str, 10) || 0
      return -1 * (str === 'never' ? Number.MAX_VALUE : val)
    },
    type: 'number',
  })
  $.tablesorter.addParser({
    id: 'data-number',
    is() {
      return false
    },
    format(s, table, td) {
      return $(td).attr('data-number')
    },
    type: 'number',
  })
  const has_user_notes = $('.report').hasClass('has_user_notes')
  const params = {
    headers: {
      0: {
        sorter: 'data-number',
      },
      1: {
        sorter: 'days_or_never',
      },
    },
  }
  if (has_user_notes) {
    params.headers[2] = {
      sorter: 'days_or_never',
    }
  }
  params.headers[4 + (has_user_notes ? 1 : 0)] = {
    sorter: 'data-number',
  }
  params.headers[5 + (has_user_notes ? 1 : 0)] = {
    sorter: false,
  }
  return $('.report').tablesorter(params)
})
