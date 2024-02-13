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
import $ from 'jquery'
import {result} from 'lodash'
import Backbone from '@canvas/backbone'
import 'jqueryui/dialog'

const I18n = useI18nScope('dialog')

extend(DialogBaseView, Backbone.View)

// # A Backbone View to extend for creating a jQuery dialog.
// #
// # Define options for the dialog as an object using the dialogOptions key,
// # those options will be merged with the defaultOptions object.
// # Begin with id and title options.
function DialogBaseView() {
  this.cancel = this.cancel.bind(this)
  return DialogBaseView.__super__.constructor.apply(this, arguments)
}

DialogBaseView.prototype.initialize = function () {
  DialogBaseView.__super__.initialize.apply(this, arguments)
  this.initDialog()
  return this.setElement(this.dialog)
}

DialogBaseView.prototype.defaultOptions = function () {
  return {
    // # id:
    // # title:
    autoOpen: false,
    width: 420,
    resizable: false,
    buttons: [],
    destroy: false,
  }
}

DialogBaseView.prototype.initDialog = function () {
  const opts = {
    ...this.defaultOptions(),
    buttons: [
      {
        text: I18n.t('#buttons.cancel', 'Cancel'),
        class: 'cancel_button',
        click: (function (_this) {
          return function (e) {
            return _this.cancel(e)
          }
        })(this),
      },
      {
        text: I18n.t('#buttons.update', 'Update'),
        class: 'btn-primary',
        click: (function (_this) {
          return function (e) {
            return _this.update(e)
          }
        })(this),
      },
    ],
    modal: true,
    zIndex: 1000,
    ...result(this, 'dialogOptions'),
  }
  this.dialog = $('<div id="' + opts.id + '"></div>')
    .appendTo('body')
    .dialog(opts)
  if (opts.containerId) {
    this.dialog.parent().attr('id', opts.containerId)
  }
  $('.ui-resizable-handle').attr('aria-hidden', true)
  return this.dialog
}

// # Sample
// #
// # render: ->
// #   @$el.html someTemplate()
// #   this

DialogBaseView.prototype.show = function () {
  return this.dialog.dialog('open')
}

DialogBaseView.prototype.close = function () {
  if (this.options.destroy) {
    return this.dialog.dialog('destroy')
  } else {
    return this.dialog.dialog('close')
  }
}

DialogBaseView.prototype.update = function (_e) {
  // eslint-disable-next-line no-throw-literal
  throw 'Not yet implemented'
}

DialogBaseView.prototype.cancel = function (e) {
  e.preventDefault()
  return this.close()
}

export default DialogBaseView
