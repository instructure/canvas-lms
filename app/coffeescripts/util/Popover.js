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

// you can provide a 'using' option to jqueryUI position
// it will be passed the position cordinates and a feedback object which,
// among other things, tells you where it positioned it relative to the target. we use it to add some
// css classes that handle putting the pointer triangle (aka: caret) back to the trigger.
function using (position, feedback) {
  if (position.top < 0) position.top = 0
  return $(this)
    .css(position)
    .toggleClass('carat-bottom', feedback.vertical === 'bottom')
}

let idCounter = 0
const activePopovers = []

function trapFocus(element) {
  const focusableEls = element.querySelectorAll('a[href], button, textarea, input[type="text"], input[type="radio"], input[type="checkbox"], select');
  const firstFocusableEl = focusableEls[0];
  const lastFocusableEl = focusableEls[focusableEls.length - 1];
  const KEYCODE_TAB = 9;

  element.addEventListener('keydown', function(e) {
      const isTabPressed = (e.key === 'Tab' || e.keyCode === KEYCODE_TAB);
      if (!isTabPressed) {
          return;
      }
      if ( e.shiftKey ) /* shift + tab */ {
          if (document.activeElement === firstFocusableEl) {
              lastFocusableEl.focus();
              e.preventDefault();
          }
      } else /* tab */ {
          if (document.activeElement === lastFocusableEl) {
              setTimeout(() => {
                firstFocusableEl.focus();
              })
              e.preventDefault();
          }
      }

  });
}


export default class Popover {

  ignoreOutsideClickSelector = '.ui-dialog'

  constructor (triggerEvent, content, options = {}) {
    this.content = content
    this.options = options
    this.trigger = $(triggerEvent.currentTarget)
    this.triggerAction = triggerEvent.type
    this.focusTrapped = false
    this.el = $(this.content).addClass('carat-bottom').data('popover', this).keydown((event) => {
      // if the user hits the escape key, reset the focus to what it was.
      if (event.keyCode === $.ui.keyCode.ESCAPE) this.hide()

      // If the user tabs or shift-tabs away, close.
      if (event.keyCode !== $.ui.keyCode.TAB) return

      const tabbables = $(':tabbable', this.el)
      const index = $.inArray(event.target, tabbables)
      if (index === -1) return

      if (event.shiftKey) {
        if (!this.focusTrapped && index === 0) this.hide()
      } else {
        if (!this.focusTrapped && index === tabbables.length - 1) this.hide()
      }
    })

    this.el.delegate('.popover_close', 'keyclick click', (event) => {
      event.preventDefault()
      this.hide()
    })

    this.show(triggerEvent)
  }

  trapFocus (element) {
    this.focusTrapped = true
    trapFocus(element)
  }

  show (triggerEvent) {
    // when the popover is open, we don't want SR users to be able to navigate to the flash messages
    let popoverToHide
    $.screenReaderFlashMessageExclusive('')

    while ((popoverToHide = activePopovers.pop())) {
      popoverToHide.hide()
    }
    activePopovers.push(this)
    const id = `popover-${idCounter++}`
    this.trigger.attr({
      'aria-expanded': true,
      'aria-controls': id,
    })
    this.previousTarget = triggerEvent.currentTarget

    this.el
      .attr({id})
      .appendTo(document.body)
      .show()
    this.position()
    if (triggerEvent.type !== 'mouseenter') {
      this.el.find(':tabbable').first().focus()
      setTimeout(() => this.el.find(':tabbable').first().focus(), 100)
    }

    document.querySelector('#application').setAttribute('aria-hidden', 'true')

    // handle sticking the carat right above where you clicked on the button, bounded by the dialog
    this.el.find('.ui-menu-carat').remove()
    const additionalOffset = this.options.manualOffset || 0
    const differenceInOffset = this.trigger.offset().left - this.el.offset().left
    const actualOffset = triggerEvent.pageX - this.trigger.offset().left
    const leftBound = Math.max(0, this.trigger.width() / 2 - this.el.width() / 2) + 20
    const rightBound = this.trigger.width() - leftBound
    const caratOffset = Math.min(Math.max(leftBound, actualOffset), rightBound) + differenceInOffset + additionalOffset
    $('<span class="ui-menu-carat"><span /></span>').css('left', caratOffset).prependTo(this.el)

    this.positionInterval = setInterval(this.position, 200)
    $(window).click(this.outsideClickHandler)
  }

  hide () {
    // remove this from the activePopovers array
    for (let index = 0; index < activePopovers.length; index++) {
      const popover = activePopovers[index]
      if (this === popover) {
        activePopovers.splice(index, 1)
      }
    }

    this.el.detach()
    this.trigger.attr('aria-expanded', false)
    clearInterval(this.positionInterval)
    $(window).unbind('click', this.outsideClickHandler)
    this.restoreFocus()

    if (activePopovers.length === 0) {
      document.querySelector('#application').setAttribute('aria-hidden', 'false')
    }
  }

  // uses a fat arrow so that it has a unique guid per-instance for jquery event unbinding
  outsideClickHandler = (event) => {
    if (!$(event.target).closest(this.el.add(this.trigger).add(this.ignoreOutsideClickSelector)).length) {
      this.hide()
    }
  }

  position = () => this.el.position({
    my: `center ${this.options.verticalSide === 'bottom' ? 'top' : 'bottom'}`,
    at: `center ${this.options.verticalSide || 'top'}`,
    of: this.trigger,
    offset: `0px ${this.offsetPx()}px`,
    within: 'body',
    collision: `flipfit ${this.options.verticalSide ? 'none' : 'flipfit'}`,
    using,
  })

  offsetPx () {
    const offset = this.options.verticalSide === 'bottom' ? 10 : -10
    if (this.options.invertOffset) {
      return offset * -1
    } else {
      return offset
    }
  }

  restoreFocus () {
    // set focus back to the previously focused item.
    if (this.previousTarget && $(this.previousTarget).is(':visible')) {
      this.previousTarget.focus()
    }
  }
}
