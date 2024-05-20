/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {extend} from '@canvas/backbone/utils'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@canvas/backbone'
import $ from 'jquery'
import 'jqueryui/dialog'

const I18n = useI18nScope('KeyboardNavDialog')

extend(KeyboardNavDialog, View)

function KeyboardNavDialog() {
  return KeyboardNavDialog.__super__.constructor.apply(this, arguments)
}

KeyboardNavDialog.prototype.el = '#keyboard_navigation'

KeyboardNavDialog.prototype.initialize = function () {
  KeyboardNavDialog.__super__.initialize.apply(this, arguments)
  // ¯\_(ツ)_/¯
  // this was only an express in the CoffeeScript
  // this.bindOpenKeys
  return this
}

// you're responsible for rendering the content via HB
// and passing it in
KeyboardNavDialog.prototype.render = function (html) {
  this.$el.html(html)
  return this
}

KeyboardNavDialog.prototype.bindOpenKeys = function () {
  let activeElement
  activeElement = null
  return $(document).keydown(
    (function (_this) {
      return function (e) {
        const isQuestionMark = e.keyCode === 191 && e.shiftKey
        if (isQuestionMark && !$(e.target).is(':input') && !ENV.disable_keyboard_shortcuts) {
          e.preventDefault()
          if (_this.$el.is(':visible')) {
            _this.$el.dialog('close')
            if (activeElement) {
              return $(activeElement).focus()
            }
          } else {
            activeElement = document.activeElement
            return _this.$el.dialog({
              title: I18n.t('titles.keyboard_shortcuts', 'Keyboard Shortcuts'),
              width: 400,
              height: 'auto',
              close() {
                $('li', this).attr('tabindex', '') // prevents chrome bsod
                if (activeElement) {
                  return $(activeElement).focus()
                }
              },
              modal: true,
              zIndex: 1000,
            })
          }
        }
      }
    })(this)
  )
}

export default KeyboardNavDialog
