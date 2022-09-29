//
// Copyright (C) 2013 - present Instructure, Inc.
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

// Floating sticky
//
// allows an element to float (using fixed positioning) as the user
// scrolls, "sticking" to the top of the window. the difference from
// a regular sticky implementation is that the element is constrained
// by a containing element (or top and bottom elements), allowing the
// element to float and stick, but only within the given bounds.
//
// to use, simply call .floatingSticky(containing_element) on a
// jQuery object. optionally the top or bottom constraining element
// can be overridden by providing {top:...} or {bottom:...} as the
// last argument when calling .floatingSticky(...).
//
// the returned array has a floating sticky instance for each object
// in the jQuery set, allowing calls to reposition() (in case the
// element should be repositioned outside of a scroll/resize event)
// or remove() to remove the floating sticky instance from the
// element.

let instanceID = 0

class FloatingSticky {
  constructor(el, container, options = {}) {
    this.instanceID = `floatingSticky${instanceID++}`

    this.$window = $(window)
    this.$el = $(el)
    this.$top = $(options.top || container)
    this.$bottom = $(options.bottom || container)

    this.$el.data('floatingSticky', this)

    this.$window.on(`scroll.${this.instanceID} resize.${this.instanceID}`, () => this.reposition())
    this.reposition()
  }

  remove() {
    this.$window.off(this.instanceID)
    return this.$el.data('floatingSticky', null)
  }

  reposition() {
    let newTop
    let windowTop = this.$window.scrollTop()
    const windowHeight = this.$window.height()

    // handle overscroll (up or down)
    if (windowTop < 0) {
      windowTop = 0
    } else {
      windowTop = Math.min(windowTop, document.body.scrollHeight - windowHeight)
    }

    // handle top of container
    const containerTop = this.$top.offset().top
    if (windowTop < containerTop) {
      if (windowTop === 0) {
        newTop = containerTop
      } else {
        newTop = containerTop - windowTop
      }

      // handle bottom of container
    } else {
      newTop = 0
      const elHeight = this.$el.height()
      const containerBottom = this.$bottom.offset().top + this.$bottom.height()

      // stay within the container
      if (windowTop + elHeight > containerBottom) {
        newTop = containerBottom - elHeight - windowTop
      }

      // but don't go above the container
      if (newTop < containerTop - windowTop) {
        newTop = containerTop - windowTop
      }
    }

    return this.$el.css({
      top: newTop,
    })
  }
}

$.fn.floatingSticky = function (container, options = {}) {
  return this.map(function () {
    return $(this).data('floatingSticky') || new FloatingSticky(this, container, options)
  })
}

export default FloatingSticky
