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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import htmlEscape, {raw} from '@instructure/html-escape'
import authenticity_token from '@canvas/authenticity-token'
import './jquery.ajaxJSON'
import 'jqueryui/dialog'
import 'jquery-scroll-to-visible'
import 'jquery-scroll-to-visible/jquery.scrollTo'

const I18n = useI18nScope('instructure_misc_plugins')

$.fn.setOptions = function (prompt, options) {
  let result = prompt ? "<option value=''>" + htmlEscape(prompt) + '</option>' : ''

  if (options == null) {
    options = []
  }

  options.forEach(opt => {
    const optHtml = htmlEscape(opt)
    result += '<option value="' + optHtml + '">' + optHtml + '</option>'
  })

  return this.html(raw(result))
}

// this function is to prevent you from doing all kinds of expesive operations on a
// jquery object that doesn't actually have any elements in it
// it is similar and inspired by http://www.slideshare.net/paul.irish/perfcompression (slide #42)
// to use it do something like:
// $("a .bunch #of .nodes").ifExists(function(orignalQuery){
//   //  'this' points to the original jquery object (in this case, $("a .bunch #of .nodes") );
//   // orignalQuery is the same as 'this';
//   this.slideUp().dialog().show();
// });
$.fn.ifExists = function (func) {
  this.length && func.call(this, this)
  return this
}

// Returns the width of the browser's scroll bars.
$.fn.scrollbarWidth = function () {
  const $div = $(
      '<div style="width:50px;height:50px;overflow:hidden;position:absolute;top:-200px;left:-200px;"><div style="height:100px;"></div>'
    ).appendTo(this),
    $innerDiv = $div.find('div')
  // Append our div, do our calculation and then remove it
  const w1 = $innerDiv.innerWidth()
  $div.css('overflow-y', 'scroll')
  const w2 = $innerDiv.innerWidth()
  $div.remove()
  return w1 - w2
}

/**
 * jQuery plugin to animate an element by reducing its opacity to create a dimming effect.
 *
 * @param {number} speed - The duration of the animation in milliseconds.
 * @returns {jQuery} - The jQuery object for chaining.
 */
$.fn.dim = function (speed) {
  return this.animate({opacity: 0.4}, speed)
}

/**
 * jQuery plugin to animate an element by increasing its opacity to remove a dimming effect.
 *
 * @param {number} speed - The duration of the animation in milliseconds.
 * @returns {jQuery} - The jQuery object for chaining.
 */
$.fn.undim = function (speed) {
  return this.animate({opacity: 1.0}, speed)
}

// Helper for deleting objects from the DOM and db.
//  url: URL to pass DELETE message.  If none provided,
//    behaves as if the request were a success.  Useful for testing.
//  message: Confirmation message
//  cancelled: Function to handle cancel.
//  confirmed: Function to handle confirm, before submit.
//  success: What to do on success.  If none provided, fades
//    out the element and removes it from the DOM.
//  error: Error.
//  dialog: If present, do a jquery.ui.dialog instead of a confirm(). If an
//    object, it will be merged into the dialog options.
$.fn.confirmDelete = function (options) {
  options = $.extend({}, $.fn.confirmDelete.defaults, options)
  const $object = this
  let $dialog = null
  let result = true
  options.noMessage = options.noMessage || options.no_message
  const onContinue = function () {
    if (!result) {
      if (options.cancelled && $.isFunction(options.cancelled)) {
        options.cancelled.call($object)
      }
      return
    }
    if (!options.confirmed) {
      options.confirmed = function () {
        $object.dim()
      }
    }
    options.confirmed.call($object)
    if (options.url) {
      if (!options.success) {
        options.success = function (_data) {
          $object.fadeOut('slow', () => {
            $object.remove()
          })
        }
      }
      const data = options.prepareData ? options.prepareData.call($object, $dialog) : {}
      data.authenticity_token = authenticity_token()
      $.ajaxJSON(
        options.url,
        'DELETE',
        data,
        data_ => {
          options.success.call($object, data_)
        },
        (data_, request, status, error) => {
          if (options.error && $.isFunction(options.error)) {
            options.error.call($object, data_, request, status, error)
          } else {
            $.ajaxJSON.unhandledXHRs.push(request)
          }
        }
      )
    } else {
      if (!options.success) {
        options.success = function () {
          $object.fadeOut('slow', () => {
            $object.remove()
          })
        }
      }
      options.success.call($object)
    }
  }
  if (options.message && !options.noMessage && !$.skipConfirmations) {
    if (options.dialog) {
      result = false
      const dialog_options = typeof options.dialog === 'object' ? options.dialog : {}
      const confirmation_class = options.url.includes('assignments') ? 'btn-danger' : 'btn-primary'
      $dialog = $(options.message).dialog(
        $.extend(
          {},
          {
            modal: true,
            close: onContinue,
            buttons: [
              {
                text: I18n.t('#buttons.cancel', 'Cancel'),
                click() {
                  $(this).dialog('close')
                }, // ; onContinue();
              },
              {
                text: I18n.t('#buttons.delete', 'Delete'),
                class: confirmation_class,
                click() {
                  result = true
                  $(this).dialog('close')
                },
              },
            ],
            zIndex: 1000,
          },
          dialog_options
        )
      )
      return
    } else {
      // eslint-disable-next-line no-alert
      result = window.confirm(options.message)
    }
  }
  onContinue()
}
$.fn.confirmDelete.defaults = {
  get message() {
    return I18n.t('confirms.default_delete_thing', 'Are you sure you want to delete this?')
  },
}

// Watches the given element's location.href for any changes
// to the fragment ("#...") and calls the provided function
// when there are any.
// $(document).fragmentChange(function(event, hash) { alert(hash); });
$.fn.fragmentChange = function (fn) {
  if (fn && fn !== true) {
    const query = (window.location.search || '').replace(/^\?/, '').split('&')
    // The URL can hard-code a hash regardless of what's
    // actually shown in the hash by specifying a query
    // parameter, hash=some_hash
    let query_hash = null
    for (let i = 0; i < query.length; i++) {
      const item = query[i]
      if (item && item.indexOf('hash=') === 0) {
        query_hash = '#' + item.substring(5)
      }
    }
    this.bind('document_fragment_change', fn)
    const $doc = this
    let found = false
    // Can only be used on the root document,
    // will not work on an iframe, for example.
    for (let i = 0; i < $._checkFragments.fragmentList.length; i++) {
      const obj = $._checkFragments.fragmentList[i]
      if (obj.doc[0] === $doc[0]) {
        found = true
      }
    }
    if (!found) {
      $._checkFragments.fragmentList.push({
        doc: $doc,
        fragment: '',
      })
    }
    $(window).bind('hashchange', $._checkFragments)
    setTimeout(() => {
      if (query_hash && query_hash.length > 0) {
        $doc.triggerHandler('document_fragment_change', query_hash)
      } else if ($doc && $doc[0] && $doc[0].location && $doc[0].location.hash.length > 0) {
        $doc.triggerHandler('document_fragment_change', $doc[0].location.hash)
      }
    }, 500)
  } else {
    this.triggerHandler('document_fragment_change', this[0].location.hash)
  }
  return this
}
$._checkFragments = function () {
  const list = $._checkFragments.fragmentList
  for (let idx = 0; idx < list.length; idx++) {
    const obj = list[idx]
    const $doc = obj.doc
    if ($doc[0].location.hash !== obj.fragment) {
      $doc.triggerHandler('document_fragment_change', $doc[0].location.hash)
      obj.fragment = $doc[0].location.hash
      $._checkFragments.fragmentList[idx] = obj
    }
  }
}
$._checkFragments.fragmentList = []
// Triggers a click only if the anchor tag isn't disabled.
$.fn.clickLink = function () {
  const $obj = this.eq(0)
  if (!$obj.hasClass('disabled_link')) {
    $obj.click()
  }
}

/**
 * jQuery plugin to conditionally show or hide elements based on a boolean value or function.
 *
 * @param {boolean|Function} bool - The condition to determine whether to show or hide the elements.
 * @returns {jQuery} - The jQuery object for chaining.
 */
$.fn.showIf = function (bool) {
  if ($.isFunction(bool)) {
    return this.each(function (_index) {
      $(this).showIf(bool.call(this))
    })
  }
  if (bool) {
    this.show()
  } else {
    this.hide()
  }
  return this
}

/**
 * jQuery plugin to conditionally disable or enable elements based on a boolean value or function.
 *
 * @param {boolean|Function} bool - The condition to determine whether to disable or enable the elements.
 * @returns {jQuery} - The jQuery object for chaining.
 */
$.fn.disableIf = function (bool) {
  if ($.isFunction(bool)) {
    bool = bool.call(this)
  }
  this.prop('disabled', !!bool)
  return this
}

/**
 * jQuery plugin to create and manipulate indicators for elements.
 *
 * @param {Object|string} options - Options for configuring the indicator behavior or 'remove' to remove existing indicators.
 * @param {Object} options.offset - The offset of the indicator relative to the element.
 * @param {Object} options.container - The container for the indicator.
 * @param {boolean} options.singleFlash - Whether to have a single flash effect on the indicator.
 * @param {boolean} options.scroll - Whether to scroll to make the indicator visible.
 */
$.fn.indicate = function (options) {
  options = options || {}
  let $indicator
  if (options === 'remove') {
    $indicator = this.data('indicator')
    if ($indicator) {
      $indicator.remove()
    }
    return
  }
  $('.indicator_box').remove()
  let offset = this.offset()
  if (options && options.offset) {
    offset = options.offset
  }
  const width = this.width()
  const height = this.height()
  const zIndex = (options.container || this).zIndex()
  $indicator = $(document.createElement('div'))
  $indicator.css({
    width: width + 6,
    height: height + 6,
    top: offset.top - 3,
    left: offset.left - 3,
    zIndex: zIndex + 1,
    position: 'absolute',
    display: 'block',
    '-moz-border-radius': 5,
    opacity: 0.8,
    border: '2px solid #870',
    backgroundColor: '#fd0',
  })
  $indicator.addClass('indicator_box')
  $indicator.mouseover(function () {
    $(this)
      .stop()
      .fadeOut('fast', function () {
        $(this).remove()
      })
  })
  if (this.data('indicator')) {
    this.indicate('remove')
  }
  this.data('indicator', $indicator)
  $('body').append($indicator)
  if (options && options.singleFlash) {
    $indicator
      .hide()
      .fadeIn()
      .animate({opacity: 0.8}, 500)
      .fadeOut('slow', function () {
        $(this).remove()
      })
  } else {
    $indicator
      .hide()
      .fadeIn()
      .animate({opacity: 0.8}, 500)
      .fadeOut('slow')
      .fadeIn('slow')
      .animate({opacity: 0.8}, 2500)
      .fadeOut('slow', function () {
        $(this).remove()
      })
  }
  if (options && options.scroll) {
    $('html,body').scrollToVisible($indicator)
  }
}

/**
 * jQuery plugin to check if the first element in the collection has a vertical scrollbar.
 *
 * @returns {boolean} - `true` if the element has a vertical scrollbar, `false` otherwise.
 */
$.fn.hasScrollbar = function () {
  return this.length && this[0].clientHeight < this[0].scrollHeight
}

$.fn.log = function (msg) {
  // eslint-disable-next-line no-console
  console.log('%s: %o', msg, this)
  return this
}

// this is used if you want to fill the browser window with something inside #content but you want to also leave the footer and header on the page.
$.fn.fillWindowWithMe = function (options) {
  const opts = $.extend({minHeight: 400}, options),
    $this = $(this),
    $wrapper = $('#wrapper'),
    $main = $('#main'),
    $not_right_side = $('#not_right_side'),
    $window = $(window),
    $toResize = $(this).add(opts.alsoResize)

  function fillWindowWithThisElement() {
    $toResize.height(0)
    const spaceLeftForThis =
        $window.height() -
        ($wrapper.offset().top + $wrapper.outerHeight()) +
        ($main.height() - $not_right_side.height()),
      newHeight = Math.max(400, spaceLeftForThis)

    $toResize.height(newHeight)
    if ($.isFunction(opts.onResize)) {
      opts.onResize.call($this, newHeight)
    }
  }
  fillWindowWithThisElement()
  $window
    .unbind('resize.fillWindowWithMe')
    .bind('resize.fillWindowWithMe', fillWindowWithThisElement)
  return this
}

/**
 * jQuery plugin to automatically resize input elements based on their content.
 *
 * @param {Object} o - An options object for configuring the behavior.
 * @param {number} o.maxWidth - The maximum width of the input element (default: 1000).
 * @param {number} o.minWidth - The minimum width of the input element (default: 0).
 * @param {number} o.comfortZone - The comfort zone for resizing (default: 70).
 * @returns {jQuery} - The jQuery object for chaining.
 */
$.fn.autoGrowInput = function (o) {
  o = $.extend(
    {
      maxWidth: 1000,
      minWidth: 0,
      comfortZone: 70,
    },
    o
  )

  this.filter('input:text').each(function () {
    let val = ''
    const minWidth = o.minWidth || $(this).width()
    const input = $(this)
    const testSubject = $('<tester/>').css({
      position: 'absolute',
      top: -9999,
      left: -9999,
      width: 'auto',
      fontSize: input.css('fontSize'),
      fontFamily: input.css('fontFamily'),
      fontWeight: input.css('fontWeight'),
      letterSpacing: input.css('letterSpacing'),
      whiteSpace: 'nowrap',
    })
    const check = function () {
      setTimeout(() => {
        if (val === (val = input.val())) {
          return
        }

        // Enter new content into testSubject
        testSubject.text(val)

        // Calculate new width + whether to change
        const testerWidth = testSubject.width(),
          newWidth =
            testerWidth + o.comfortZone >= minWidth ? testerWidth + o.comfortZone : minWidth,
          currentWidth = input.width(),
          isValidWidthChange =
            (newWidth < currentWidth && newWidth >= minWidth) ||
            (newWidth > minWidth && newWidth < o.maxWidth)

        // Animate width
        if (isValidWidthChange) {
          input.width(newWidth)
        }
      })
    }

    testSubject.insertAfter(input)

    $(this).bind('keyup keydown blur update change', check)
  })

  return this
}

export default $
