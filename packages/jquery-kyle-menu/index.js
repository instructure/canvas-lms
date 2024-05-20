//
// Copyright (C) 2011 - present Instructure, Inc.
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
import './monkey-patches'
import 'jqueryui/button'
import './popup'

/*
 * PLEASE READ BEFORE MODIFYING THIS FILE:
 * This provides the 'admin cog' menus amongst other things used throughout
 * Canvas.  It has been extensively tested for accessibility.  Before making
 * any changes to this file, please check with someone about the accessibility
 * repercussions of what you intend to do.
 */

export default class KyleMenu {
  constructor(trigger, options) {
    ;['onOpen', 'select', 'onClose', 'close', 'keepButtonActive'].forEach(
      m => (this[m] = this[m].bind(this))
    )
    this.$trigger = $(trigger).data('kyleMenu', this)
    this.$ariaMenuWrapper = this.$trigger.parent()
    this.opts = $.extend(true, {}, KyleMenu.defaults, options)

    if (!this.opts.noButton) {
      if (this.opts.buttonOpts.addDropArrow) {
        this.$trigger.append('<i class="icon-mini-arrow-down"></i>')
      }
      this.$trigger.button(this.opts.buttonOpts)

      // this is to undo the removal of the 'ui-state-active' class that jquery.ui.button
      // does by default on mouse out if the menu is still open
      this.$trigger.bind('mouseleave.button', this.keepButtonActive)
    }

    this.$menu = this.$trigger
      .next()
      .menu(this.opts.menuOpts)
      .popup(this.opts.popupOpts)
      .addClass('ui-kyle-menu use-css-transitions-for-show-hide')

    // passing an appendMenuTo option when initializing a kylemenu helps get around popup being hidden
    // by overflow:scroll on its parents
    // but by doing so we need to make sure that click events still get propagated up in case we
    // were delegating events to a parent container
    if (this.opts.appendMenuTo) {
      // to keep tab order when appended out of place
      this.$menu.on({
        keydown: e => {
          if (e.keyCode === $.ui.keyCode.TAB) {
            let tabKey
            if (e.shiftKey) {
              tabKey = {
                which: $.ui.keyCode.TAB,
                shiftKey: true,
              }
            } else {
              tabKey = {
                which: $.ui.keyCode.TAB,
              }
            }

            const pressTab = $.Event('keydown', tabKey)
            this.$trigger.focus().trigger(pressTab)
          }
        },
      })

      const popupInstance = this.$menu.data('popup')
      const _open = popupInstance.open
      const self = this
      // monkey patch just this plugin instance not $.ui.popup.prototype.open
      popupInstance.open = function () {
        self.$menu.appendTo(self.opts.appendMenuTo)
        return _open.apply(this, arguments)
      }

      this.$placeholder = $('<span style="display:none;">').insertAfter(this.$menu)
      this.$menu.bind('click', (...args) => this.$placeholder.trigger(...args))
    }

    // passing a notifyMenuActiveOn option when initializing a kylemenu helps
    // get around issue of page-specific parent elements needing to know when the menu
    // is active and removed. The value of the option is a CSS selector for a parent
    // element of the trigger.
    if (this.opts.notifyMenuActiveOnParent) {
      this.$notifyParent = this.$trigger.closest(this.opts.notifyMenuActiveOnParent)
    }

    this.$menu.on({
      menuselect: this.select,
      popupopen: this.onOpen,
      popupclose: this.onClose,
    })
  }

  onOpen(event) {
    this.$ariaMenuWrapper.attr('role', 'application')
    this.adjustCarat(event)
    this.$menu.addClass('ui-state-open')
    if (this.opts.notifyMenuActiveOnParent) this.$notifyParent.addClass('menu_active')
  }

  open() {
    this.$menu.popup('open')
  }

  select(e, ui) {
    let $target
    if ((e.originalEvent && e.originalEvent.type) !== 'click' && ($target = $(ui.item).find('a'))) {
      e.preventDefault()
      const el = $target[0]
      const event = document.createEvent('MouseEvent')
      event.initEvent('click', true, true)
      el.dispatchEvent(event)
    }
    this.close()
  }

  onClose() {
    if (this.opts.appendMenuTo) this.$menu.insertBefore(this.$placeholder)
    this.$trigger.removeClass('ui-state-active')
    this.$ariaMenuWrapper.removeAttr('role')
    this.$menu.removeClass('ui-state-open')
    if (this.opts.notifyMenuActiveOnParent) this.$notifyParent.removeClass('menu_active')

    // passing a returnFocusTo option when initializing a kylemenu provides an
    // interface to ensure focus is not lost and returned to the body. This was
    // introduced specifically to address the complexity of dynamically-
    // generated menus. This rule will not be honored if the returnFocusTo
    // element becomes disabled.
    if (this.opts.returnFocusTo && !this.opts.returnFocusTo.prop('disabled')) {
      // Wait for one frame to see if anything else has claimed focus.
      requestAnimationFrame(() => {
        if (document.body === document.activeElement) {
          // If focus still remains on the document body, return focus to the originating element.
          this.opts.returnFocusTo.focus()
        }
      })
    }
  }

  close() {
    this.$menu.hasClass('ui-state-open') && this.$menu.popup('close').removeClass('ui-state-open')
  }

  keepButtonActive() {
    if (this.$menu.is('.ui-state-open') && this.$trigger.is('.btn, .ui-button')) {
      this.$trigger.addClass('ui-state-active')
    }
  }

  // handle sticking the carat right below where you clicked on the button
  adjustCarat(event) {
    if (this.$carat) this.$carat.remove()
    if (this.$trigger.is('.btn, .ui-button')) this.$trigger.addClass('ui-state-active')

    const triggerWidth = this.$trigger.outerWidth()
    const triggerOffsetLeft = this.$trigger.offset().left

    // the menu may have flipped above the trigger
    const mbox = this.$menu[0].getBoundingClientRect()
    const tbox = this.$trigger[0].getBoundingClientRect()
    const caratIsBelow = mbox.top + mbox.height < tbox.top
    const caratY = mbox.height - 2

    // if it is a mouse event, it will have a 'pageX' otherwise use the middle of the trigger
    const pointToDropDownFrom = event.pageX || triggerOffsetLeft + triggerWidth / 2
    const differenceInOffset = triggerOffsetLeft - this.$menu.offset().left
    const actualOffset = pointToDropDownFrom - this.$trigger.offset().left
    const caratOffset = Math.min(Math.max(6, actualOffset), triggerWidth - 6) + differenceInOffset
    this.$carat = $('<span class="ui-menu-carat"><span /></span>').css('left', caratOffset)
    if (caratIsBelow) {
      this.$carat.css('top', caratY).css('transform', 'rotateX(180deg)')
    }
    this.$carat.prependTo(this.$menu)
  }

  static defaults = {
    popupOpts: {
      position: {
        my: 'center top',
        at: 'center bottom',
        offset: '0 10px',
        within: '#main',
        collision: 'flipfit',
      },
    },
    buttonOpts: {
      addDropArrow: true,
    },
  }
}

// expose jQuery plugin
$.fn.kyleMenu = function (options) {
  return this.each(function () {
    if (!$(this).data().kyleMenu) new KyleMenu(this, options)
  })
}
