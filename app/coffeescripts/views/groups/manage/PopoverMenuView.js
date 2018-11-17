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
import {View} from 'Backbone'
import '../../../jquery/outerclick'

export default class PopoverMenuView extends View {
  static initClass() {
    this.prototype.defaults = {zIndex: 1}

    this.prototype.events = {
      mousedown: 'disableHide',
      mouseup: 'enableHide',
      click: 'cancelHide',
      focusin: 'cancelHide',
      focusout: 'hidePopover',
      outerclick: 'hidePopover',
      keyup: 'checkEsc'
    }
  }

  disableHide() {
    return (this.hideDisabled = true)
  }

  enableHide() {
    return (this.hideDisabled = false)
  }

  hidePopover() {
    if (!this.hideDisabled) return this.hide() // call the hide function without any arguments.
  }

  showBy($target, focus = false) {
    this.cancelHide()
    return setTimeout(() => {
      // IE needs this to happen async frd
      this.render()
      this.attachElement($target)
      this.$el.show()
      this.setElement(this.$el)
      this.$el.zIndex(this.options.zIndex)
      if (typeof this.setWidth === 'function') {
        this.setWidth()
      }
      this.$el.position({
        my: this.my || 'left+6 top-47',
        at: this.at || 'right center',
        of: $target,
        collision: 'none',
        using: coords => {
          const content = this.$el.find('.popover-content')
          this.$el.css({top: coords.top, left: coords.left})
          return this.setPopoverContentHeight(this.$el, content, $('#content'))
        }
      })

      if (focus) {
        if (typeof this.focus === 'function') {
          this.focus()
        }
      }
      return this.trigger('open', {target: $target})
    }, 20)
  }

  setPopoverContentHeight(popover, content, parent) {
    const parentBound = parent.offset().top + parent.height()
    const popoverOffset = popover.offset().top
    const popoverHeader = popover.find('.popover-title').outerHeight()
    const defaultHeight = parseInt(content.css('maxHeight'))
    const newHeight = parentBound - popoverOffset - popoverHeader
    return content.css({maxHeight: Math.min(defaultHeight, newHeight)})
  }

  cancelHide() {
    return clearTimeout(this.hideTimeout)
  }

  hide(escapePressed = false) {
    return (this.hideTimeout = setTimeout(() => {
      this.$el.detach()
      return this.trigger('close', {escapePressed})
    }, 100))
  }

  checkEsc(e) {
    if (e.keyCode === 27) return this.hide(true) // escape
  }

  attachElement($target) {
    return this.$el.insertAfter($target)
  }
}
PopoverMenuView.initClass()
