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
import {View} from '@canvas/backbone'
import '../../jquery/outerclick'

export default class PopoverMenuView extends View {
  static initClass() {
    // @ts-expect-error - Backbone View property
    this.prototype.defaults = {zIndex: 1}

    // @ts-expect-error - Backbone View property
    this.prototype.events = {
      mousedown: 'disableHide',
      mouseup: 'delayedEnableHide',
      click: 'cancelHide',
      focusin: 'cancelHide',
      focusout: 'hidePopover',
      outerclick: 'hidePopover',
      keyup: 'checkEsc',
    }
  }

  disableHide() {
    // @ts-expect-error - Backbone View property
    return (this.hideDisabled = true)
  }

  enableHide() {
    // @ts-expect-error - Backbone View property
    return (this.hideDisabled = false)
  }

  delayedEnableHide() {
    setTimeout(() => this.enableHide(), 0)
  }

  hidePopover() {
    // @ts-expect-error - Backbone View property
    if (!this.hideDisabled) return this.hide() // call the hide function without any arguments.
  }

  // @ts-expect-error - Legacy Backbone typing
  showBy($target, focus = false) {
    this.cancelHide()
    return setTimeout(() => {
      // IE needs this to happen async frd
      // @ts-expect-error - Backbone View property
      this.render()
      this.attachElement($target)
      // @ts-expect-error - Backbone View property
      this.$el.show()
      // @ts-expect-error - Backbone View property
      this.setElement(this.$el)
      // @ts-expect-error - Backbone View property
      this.$el.zIndex(this.options.zIndex)
      // @ts-expect-error - Backbone View property
      if (typeof this.setWidth === 'function') {
        // @ts-expect-error - Backbone View property
        this.setWidth()
      }
      // @ts-expect-error - Backbone View property
      this.$el.position({
        // @ts-expect-error - Backbone View property
        my: this.my || 'right-22 top-47',
        // @ts-expect-error - Backbone View property
        at: this.at || 'right center',
        of: $target,
        collision: 'none',
        // @ts-expect-error - Legacy Backbone typing
        using: coords => {
          // @ts-expect-error - Backbone View property
          const content = this.$el.find('.popover-content')
          // @ts-expect-error - Backbone View property
          this.$el.css({top: coords.top, left: coords.left})
          // @ts-expect-error - Backbone View property
          return this.setPopoverContentHeight(this.$el, content, $('#content'))
        },
      })

      // Because the popover is rendered after the triggering mouse event,
      // it doesn’t receive the original mousedown that would have set hideDisabled.
      // To prevent the outerclick (triggered by the mouseup) from immediately hiding
      // the popover, we manually disable hiding for a short time.
      // @ts-expect-error - Backbone View property
      this.hideDisabled = true
      setTimeout(() => {
        // @ts-expect-error - Backbone View property
        this.hideDisabled = false
      }, 150)

      if (focus) {
        // @ts-expect-error - Backbone View property
        if (typeof this.focus === 'function') {
          // @ts-expect-error - Backbone View property
          this.focus()
        }
      }
      // @ts-expect-error - Backbone View property
      return this.trigger('open', {target: $target})
    }, 20)
  }

  // @ts-expect-error - Legacy Backbone typing
  setPopoverContentHeight(popover, content, parent) {
    const parentBound = parent.offset().top + parent.height()
    const popoverOffset = popover.offset().top
    const popoverHeader = popover.find('.popover-title').outerHeight()
    const defaultHeight = parseInt(content.css('maxHeight'), 10)
    const newHeight = parentBound - popoverOffset - popoverHeader
    return content.css({maxHeight: Math.min(defaultHeight, newHeight)})
  }

  cancelHide() {
    // @ts-expect-error - Backbone View property
    return clearTimeout(this.hideTimeout)
  }

  hide(escapePressed = false) {
    // @ts-expect-error - Backbone View property
    return (this.hideTimeout = setTimeout(() => {
      // @ts-expect-error - Backbone View property
      this.$el.detach()
      // @ts-expect-error - Backbone View property
      return this.trigger('close', {escapePressed})
    }, 100))
  }

  // @ts-expect-error - Legacy Backbone typing
  checkEsc(e) {
    if (e.keyCode === 27) return this.hide(true) // escape
  }

  // @ts-expect-error - Legacy Backbone typing
  attachElement($target) {
    // @ts-expect-error - Backbone View property
    return this.$el.insertAfter($target)
  }
}
PopoverMenuView.initClass()
