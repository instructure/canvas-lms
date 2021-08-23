//
// Copyright (C) 2014 - present Instructure, Inc.
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

const $window = $(window)

// @method $.fn.is(':in_viewport')
//
// Checks whether an element is visible in the current window's scroll
// boundaries.
//
// An example of scrolling an element into view if it's not visible:
//
//     if (!$('#element').is(':in_viewport')) {
//       $('#element').scrollIntoView();
//     }
//
// Or, using $.fn.filter:
//
//     // iterate over all questions that are currently visible to the student:
//     $('.question').filter(':in_viewport').each(function() {
//     });
export default function in_viewport(el) {
  const $el = $(el)

  const vpTop = $window.scrollTop()
  const vpBottom = vpTop + $window.height()
  const elTop = $el.offset().top
  const elBottom = elTop + $el.height()

  return vpTop < elTop && vpBottom > elBottom
}

$.extend($.expr[':'], {in_viewport})
