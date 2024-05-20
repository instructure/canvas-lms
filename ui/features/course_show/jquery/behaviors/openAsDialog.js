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
import preventDefault from '@canvas/util/preventDefault'
import 'jqueryui/dialog'

$.fn.openAsDialog = function (options) {
  return this.click(
    preventDefault(e => {
      const $link = $(e.target)

      const opts = {
        width: 550,
        height: 500,
        title: $link.attr('title'),
        resizable: false,
        modal: true,
        zIndex: 1000,
        ...options,
      }

      const $dialog = $('<div>')
      const $iframe = $('<iframe>', {
        style: 'position:absolute;top:0;left:0;border:none',
        src: `${$link.attr('href')}?embedded=1&no_headers=1`,
      })
      $dialog.append($iframe)

      $dialog.on('dialogopen', () => {
        const $container = $dialog.closest('.ui-dialog-content')
        $iframe.height($container.outerHeight())
        $iframe.width($container.outerWidth())
      })
      return $dialog.dialog(opts)
    })
  )
}

$(() => $('a[data-open-as-dialog]').openAsDialog())

export default $
