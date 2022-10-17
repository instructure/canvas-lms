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

const inputMethods = {
  disableInputs(inputs) {
    const $body = $('body'),
      $inputCover = $('<div />', {class: 'input_cover'})

    $inputCover.on('mouseleave', function () {
      $(this).remove()
    })

    $(inputs).on('mouseenter', function () {
      const $el = $(this),
        $cover = $inputCover.clone(true)

      $cover.css({
        height: $el.height() + 12,
        width: $el.width() + 12,
        position: 'absolute',
        left: $el.offset().left - 6,
        top: $el.offset().top - 6,
        zIndex: 15,
        background: 'url(/images/blank.png) 0 0 repeat',
      })

      $body.append($cover)
    })
  },

  setWidths(selector) {
    $(selector || '.answer input[type=text]').each(function () {
      $(this).width($(this).val().length * 9.5)
    })
  },
}

export default inputMethods
