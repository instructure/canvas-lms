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

import {find, defer, reduce, throttle} from 'lodash'
import $ from 'jquery'

let $document, $window
const CLASS_ATTRIBUTE = 'ui-cnvs-scrollable'
const SCROLL_RATE = 10

let $footer = ($window = $document = null)
const p = str => parseInt(str, 10)

export default {
  afterRender() {
    if (this._rendered) return

    this.$el.addClass(CLASS_ATTRIBUTE)
    this.$el.css('overflowY', 'auto')

    this._initializeDragAndDropHandling()
    defer(() => this._initializeAutoResize())

    return (this._rendered = true)
  },

  _initializeAutoResize() {
    if (!$window) $window = $(window)
    // This procedure for finding $minHeightParent is not optimal. It's an
    // attempt to find the first container with a min-height. (There will be
    // at least one, the #main div whose min-height is 450px.) The number 30
    // here is a weak way to skip over a more recent parent container whose
    // min-height is inexplicably set to 30px.
    const minHeightParent = find(this.$el.parents(), el => p($(el).css('minHeight')) > 30)
    if (!minHeightParent) return // bail out; probably in a test
    const $minHeightParent = $(minHeightParent)
    const oldMaxHeight = $minHeightParent.css('maxHeight')
    $minHeightParent.css('maxHeight', $minHeightParent.css('minHeight'))
    let verticalOffset = $minHeightParent.offset().top || 0
    verticalOffset += p($minHeightParent.css('paddingTop'))
    this._minHeight = $minHeightParent.height() + verticalOffset
    $minHeightParent.css('maxHeight', oldMaxHeight)
    $window.resize(throttle(() => this._resize(), 50))
    return this._resize()
  },

  _resize() {
    if (!$footer) $footer = $('#footer')
    if (!$document) $document = $(document)
    const bottomSpacing = reduce(
      this.$el.parents(),
      (sum, el) => {
        const $el = $(el)
        sum += p($el.css('marginBottom'))
        sum += p($el.css('paddingBottom'))
        return (sum += p($el.css('borderBottomWidth')))
      },
      0
    )
    this._resize = function () {
      const offsetTop = this.$el.offset().top
      let availableHeight = $window.height()
      availableHeight -= $footer.outerHeight(true)
      availableHeight -= offsetTop
      availableHeight -= bottomSpacing
      return this.$el.height(Math.max(availableHeight, this._minHeight - offsetTop))
    }
    return this._resize()
  },

  _initializeDragAndDropHandling() {
    this.$el.on('dragstart', (_event, _ui) => (this._$pointerScrollable = this.$el))

    this.$el.on('drag', ({pageX, pageY}, ui) => {
      clearTimeout(this._checkScrollTimeout)
      this._checkScroll = () => {
        ui.helper.hide()
        const $pointerElement = $(document.elementFromPoint(pageX, pageY))
        ui.helper.show()
        let $scrollable = $pointerElement.closest(`.${CLASS_ATTRIBUTE}`)
        if (!$scrollable.length) $scrollable = this._$pointerScrollable
        const scrollTop = $scrollable.scrollTop()
        const offsetTop = $scrollable.offset().top
        if (scrollTop > 0 && ui.offset.top < offsetTop) {
          $scrollable.scrollTop(scrollTop - SCROLL_RATE)
        } else if (ui.offset.top + ui.helper.height() > offsetTop + $scrollable.height()) {
          $scrollable.scrollTop(scrollTop + SCROLL_RATE)
        }
        this._$pointerScrollable = $scrollable
        return (this._checkScrollTimeout = setTimeout(this._checkScroll, 50))
      }
      return this._checkScroll()
    })

    return this.$el.on('dragstop', (_event, _ui) => clearTimeout(this._checkScrollTimeout))
  },
}
