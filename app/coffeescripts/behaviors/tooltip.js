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

// #
// add the [data-tooltip] attribute and title="<tooltip contents>" to anything you want to give a tooltip:
//
// usage: (see Styleguide)
//   <a data-tooltip title="pops up on top center">default</a>
//   <a data-tooltip="top" title="same as default">top</a>
//   <a data-tooltip="right" title="should be right center">right</a>
//   <a data-tooltip="bottom" title="should be bottom center">bottom</a>
//   <a data-tooltip="left" title="should be left center">left</a>
//   <a data-tooltip='{"track":true}' title="this toolstip will stay connected to mouse as it moves around">
//     tooltip that tracks mouse
//   </a>
//   <button data-tooltip title="any type of element can have a tooltip" class="btn">
//     button with tooltip
//   </button>

import _ from 'underscore'
import $ from 'jquery'
import htmlEscape from 'str/htmlEscape'
import sanitizeHtml from 'jsx/shared/sanitizeHtml'
import 'jqueryui/tooltip'

const tooltipsToShortCirtuit = {}
const shortCircutTooltip = target => tooltipsToShortCirtuit[target] || tooltipsToShortCirtuit[target[0]]

const tooltipUtils = {
  setPosition (opts) {
    function caret () {
      if ((opts.tooltipClass || '').match('popover')) {
        return 30
      } else {
        return 5
      }
    }

    const collision = opts.force_position === 'true' ? 'none' : 'flipfit'
    const positions = {
      right: {
        my: 'left center',
        at: `right+${caret()} center`,
        collision,
      },
      left: {
        my: 'right center',
        at: `left-${caret()} center`,
        collision,
      },
      top: {
        my: 'center bottom',
        at: `center top-${caret()}`,
        collision,
      },
      bottom: {
        my: 'center top',
        at: `center bottom+${caret()}`,
        collision,
      },
    }
    if (opts.position in positions) {
      opts.position = positions[opts.position]
    }
  }
}

// create a custom widget that inherits from the default jQuery UI
// tooltip but extends the open method with a setTimeout wrapper so
// that our browser can scroll to the tabbed focus element before
// positioning the tooltip relative to window.
$.widget('custom.timeoutTooltip', $.ui.tooltip, {
  _open (event, target, content) {
    if (shortCircutTooltip(target)) return null

    // Converts arguments to an array
    const args = Array.prototype.slice.call(arguments, 0)
    args.splice(2, 1, htmlEscape(content).toString())
    // if you move very fast, it's possible that
    // @timeout will be defined
    if (this.timeout) return

    const apply = this._superApply.bind(this, args)
    this.timeout = setTimeout(() => {
      // make sure close will be called
      delete this.timeout
      // remove extra handlers we added, super will add them back
      this._off(target, 'mouseleave focusout keyup')
      apply()
    }, 200)
    // this is from the jquery ui tooltip _open
    // we need to bind events to trigger close so that the
    // timeout is cleared when we mouseout / or leave focus
    return this._on(target, {
      mouseleave: 'close',
      focusout: 'close',
      keyup (event) {
        if (event.keyCode === $.ui.keyCode.ESCAPE) {
          const fakeEvent = $.Event(event)
          fakeEvent.currentTarget = target[0]
          return this.close(fakeEvent, true)
        }
      },
    })
  },

  close (event) {
    if (this.timeout) {
      clearTimeout(this.timeout)
      delete this.timeout
      return
    }
    return this._superApply([event, true])
  },
})


// you can provide a 'using' option to jqueryUI position (which gets called by jqueryui Tooltip to
// position it on the screen), it will be passed the position cordinates and a feedback object which,
// among other things, tells you where it positioned it relative to the target. we use it to add some
// css classes that handle putting the pointer triangle (aka: caret) back to the trigger.
function using (position, feedback) {
  return $(this).css(position).removeClass('left right top bottom center middle vertical horizontal').addClass([
    // one of: "left", "right", "center"
    feedback.horizontal,

    // one of "top", "bottom", "middle"
    feedback.vertical,

    // if tooltip was positioned mostly above/below trigger then: "vertical"
    // else since the tooltip was positioned more to the left or right: "horizontal"
    feedback.important,
  ].join(' '))
}

$('body').on('mouseenter focusin', '[data-tooltip]', function (event) {
  const $this = $(this)
  let opts = $this.data('tooltip')

  // allow specifying position by simply doing <a data-tooltip="left">
  // and allow shorthand top|bottom|left|right positions like <a data-tooltip='{"position":"left"}'>
  if (['right', 'left', 'top', 'bottom'].includes(opts)) opts = { position: opts}
  if (!opts) opts = {}
  if (!opts.position) opts.position = 'top'

  tooltipUtils.setPosition(opts)
  if (opts.collision) opts.position.collision = opts.collision

  if (!opts.position.using) opts.position.using = using

  if ($this.data('html-tooltip-title')) {
    opts.content = function () {
      return $.raw(sanitizeHtml($(this).data('html-tooltip-title')))
    }
    opts.items = '[data-html-tooltip-title]'
  }

  if ($this.data('tooltip-class')) opts.tooltipClass = $this.data('tooltip-class')

  $this.removeAttr('data-tooltip').timeoutTooltip(opts).timeoutTooltip('open').click(() => $this.timeoutTooltip('close'))
})

const restartTooltip = event => (tooltipsToShortCirtuit[event.target] = false)

const stopTooltip = event => (tooltipsToShortCirtuit[event.target] = true)

$(window).bind('detachTooltip', stopTooltip)
$(window).bind('reattachTooltip', restartTooltip)

export default tooltipUtils
