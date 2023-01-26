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

/*
will make the element semi-transparent and disable any :inputs untill a defferred completes.
example:

$('#some_form').disableWhileLoading($.ajaxJSON(...), {buttons: ['.send_button' : 'Sending...'}});

or

var promise = $.ajaxJSON(...);
$('#form').disableWhileLoading(promise, {
  buttons: {
    '.send_button' : 'Sending...'
  }
});

*/
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import './jquery.ajaxJSON'
import 'spin.js/jquery.spin'

const I18n = useI18nScope('disableWhileLoading')

function eraseFromArray(array, victim) {
  array.forEach((prospect, index) => {
    if (prospect === victim) array.splice(index, 1)
  })
}

$.fn.disableWhileLoading = function (deferred, options) {
  return this.each(function () {
    const opts = $.extend(true, {}, $.fn.disableWhileLoading.defaults, options)
    const $this = $(this)
    const data = $this.data()
    const thingsToWaitOn =
      data.disabledWhileLoadingDeferreds || (data.disabledWhileLoadingDeferreds = [])
    const myDeferred = $.Deferred()

    $.when(...thingsToWaitOn).done(() => {
      let dataKey
      let $disabledArea
      let $inputsToDisable
      let $spinHolder
      let previousSpinHolderDisplay
      let disabled = false

      const disabler = setTimeout(() => {
        dataKey = 'disabled_' + $.guid++
        $disabledArea = $this.add($this.nextAll('.ui-dialog-buttonpane'))
        disabled = true
        //  todo: replace .andSelf with .addBack when JQuery is upgraded.
        $inputsToDisable = $disabledArea
          .find('*')
          .andSelf()
          .filter(':input')
          .not(':disabled,[type=file],[name="authenticity_token"]')
        $inputsToDisable.prop('disabled', true)

        if (opts.noSpinner) {
          $spinHolder = null
        } else {
          const $foundSpinHolder = $this.find('.spin_holder')
          $spinHolder = $foundSpinHolder.length ? $foundSpinHolder : $this
          previousSpinHolderDisplay = $spinHolder.css('display')
          $spinHolder.show().spin(options)
          $($spinHolder.data().spinner.el).css({'max-width': '100px'})
        }

        $disabledArea.css('opacity', function (_i, _currentOpacity) {
          $(this).data(dataKey + 'opacityBefore', this.style.opacity || 1)
          return opts.opacity
        })
        $.each(opts.buttons, function (selector, text) {
          // if you pass an array to $.each the first arg is indexInArray, we need second arg
          if ($.isArray(opts.buttons)) {
            selector = text
            text = null
          }
          $disabledArea.find(selector).text(function (i, currentText) {
            $(this).data(dataKey, currentText)
            return (
              text ||
              $(this).data('textWhileLoading') ||
              ($(this).is('.ui-button-text') &&
                $(this).closest('.ui-button').data('textWhileLoading')) ||
              // if nothing was passed in as the text value or if they pass an array for opts.buttons,
              // just use a default loading... text.
              I18n.t('loading', 'Loading...')
            )
          })
        })
      }, 13)

      $.when(deferred).always(function () {
        clearTimeout(disabler)
        if (disabled) {
          if ($spinHolder) {
            $spinHolder.css('display', previousSpinHolderDisplay).spin(false) // stop spinner
          }
          $disabledArea.css('opacity', function () {
            return $(this).data(dataKey + 'opacityBefore') || 1
          })
          $inputsToDisable.prop('disabled', false)
          $.each(opts.buttons, function (selector, _text) {
            if (typeof selector === 'number') selector = '' + this // for arrays
            $disabledArea.find(selector).text(function () {
              return $(this).data(dataKey)
            })
          })
          eraseFromArray(thingsToWaitOn, myDeferred) // speed up so that $.when doesn't have to look at myDeferred any more
          myDeferred.resolve()
          if (opts.onComplete) {
            opts.onComplete()
          }
        }
      })
    })
    thingsToWaitOn.push(myDeferred)
  })
}
$.fn.disableWhileLoading.defaults = {
  opacity: 0.5,
  buttons: ['button[type="submit"], .ui-dialog-buttonpane .ui-button .ui-button-text'],
}
