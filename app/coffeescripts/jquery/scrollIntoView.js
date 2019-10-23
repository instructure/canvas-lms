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

// depends on the scrollable ancestor being the first positioned
// ancestor. if it's not, it won't work
export default $.fn.scrollIntoView = function(options = {}) {
  const $container = options.container || this.offsetParent()
  const containerTop = $container.scrollTop()
  const containerBottom = containerTop + $container.height()
  let elemTop = this[0].offsetTop
  let elemBottom = elemTop + $(this[0]).outerHeight()
  if (options.ignore && options.ignore.border) {
    elemTop += parseInt(
      $(this[0])
        .css('border-top-width')
        .replace('px', '')
    )
    elemBottom -= parseInt(
      $(this[0])
        .css('border-bottom-width')
        .replace('px', '')
    )
  }
  if (elemTop < containerTop || options.toTop) {
    return $container.scrollTop(elemTop)
  } else if (elemBottom > containerBottom) {
    return $container.scrollTop(elemBottom - $container.height())
  }
}
