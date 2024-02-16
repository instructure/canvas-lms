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

/* eslint-disable no-void */

import {extend} from '@canvas/backbone/utils'
import $ from 'jquery'
import ValidatedFormView from './ValidatedFormView'
import preventDefault from '@canvas/util/preventDefault'
import wrapper from '../../jst/DialogFormWrapper.handlebars'
import 'jqueryui/dialog'
import '@canvas/util/jquery/fixDialogButtons'

export const isSmallTablet = !window.matchMedia('(min-width: 550px)').matches

export const getResponsiveWidth = function (tabletWidth, desktopWidth) {
  if (isSmallTablet) {
    return tabletWidth
  } else {
    return desktopWidth
  }
}

extend(DialogFormView, ValidatedFormView)

// Creates a form dialog.
//
// - Wraps your template in a form (don't need a form tag or button controls
//   in the template)
//
// - Handles saving the model to the server
//
// usage:
//
//   handlebars:
//     <p>
//       <label><input name="first_name" value="{{first_name}}"/></label>
//     </p>
//
//   coffeescript:
//     new DialogFormView
//       template: someTemplate
//       model: someModel
//       trigger: '#editSettings'
//
function DialogFormView() {
  this.onSaveSuccess = this.onSaveSuccess.bind(this)
  this.renderElAgain = this.renderElAgain.bind(this)
  this.firstRenderEl = this.firstRenderEl.bind(this)
  this.toggle = this.toggle.bind(this)
  return DialogFormView.__super__.constructor.apply(this, arguments)
}

DialogFormView.prototype.defaults = {
  // the element selector that opens the dialog, if false, no trigger logic
  // will be established
  trigger: false,
  // will figure out the title from the trigger if null
  title: null,
  width: null,
  height: null,
  minWidth: null,
  minHeight: null,
  fixDialogButtons: true,
}

DialogFormView.prototype.$dialogAppendTarget = $('body')

DialogFormView.prototype.className = 'dialogFormView'

// creates the form wrapper, with button controls
// override in subclasses at will
DialogFormView.prototype.wrapperTemplate = wrapper

DialogFormView.prototype.initialize = function () {
  DialogFormView.__super__.initialize.apply(this, arguments)
  this.setTrigger()
  this.open = this.firstOpen
  return (this.renderEl = this.firstRenderEl)
}

// the function to open the dialog.  will be set to either @firstOpen or
// @openAgain depending on the state of the view
//
// @api public
DialogFormView.prototype.open = null

// @api public
DialogFormView.prototype.close = function () {
  let ref, ref1
  // could be calling this from the close event
  // so we want to check if it's open
  if ((ref = this.dialog) != null ? ref.isOpen() : void 0) {
    this.dialog.close()
  }
  return (ref1 = this.focusReturnsTo()) != null ? ref1.focus() : void 0
}

// @api public
DialogFormView.prototype.toggle = function () {
  let ref
  if ((ref = this.dialog) != null ? ref.isOpen() : void 0) {
    return this.close()
  } else {
    return this.open()
  }
}

// @api public
DialogFormView.prototype.remove = function () {
  let ref, ref1
  DialogFormView.__super__.remove.apply(this, arguments)
  if ((ref = this.$trigger) != null) {
    ref.off('.dialogFormView')
  }
  if ((ref1 = this.$dialog) != null) {
    ref1.remove()
  }
  this.open = this.firstOpen
  return (this.renderEl = this.firstRenderEl)
}

// lazy init on first open
// @api private
DialogFormView.prototype.firstOpen = function () {
  this.insert()
  this.render()
  this.setupDialog()
  this.openAgain()
  return (this.open = this.openAgain)
}

// @api private
DialogFormView.prototype.openAgain = function () {
  this.dialog.open()
  return this.dialog.focusable.focus()
}

// @api private
DialogFormView.prototype.insert = function () {
  return this.$el.appendTo(this.$dialogAppendTarget)
}

// If your trigger isn't rendered after this view (like a parent view
// contains the trigger) then you can set this manually (like in the
// parent views afterRender), otherwise it'll use the options.
//
// @api public
DialogFormView.prototype.setTrigger = function (el) {
  if (el) {
    this.options.trigger = el
  }
  if (!this.options.trigger) {
    return
  }
  this.$trigger = $(this.options.trigger)
  return this.attachTrigger()
}

// @api private
DialogFormView.prototype.attachTrigger = function () {
  let ref
  return (ref = this.$trigger) != null
    ? ref.on('click.dialogFormView', preventDefault(this.toggle))
    : void 0
}

// the function to render the element.  it will either be firstRenderEl or
// renderElAgain depending on the state of the view
//
// @api private
DialogFormView.prototype.renderEl = null

DialogFormView.prototype.firstRenderEl = function () {
  this.$el.html(this.wrapperTemplate(this.toJSON()))
  this.renderElAgain()
  // reassign: only render the outlet now
  return (this.renderEl = this.renderElAgain)
}

// @api private
DialogFormView.prototype.renderElAgain = function () {
  const html = this.template(this.toJSON())
  return this.$el.find('.outlet').html(html)
}

// @api private
DialogFormView.prototype.getDialogTitle = function () {
  let ref
  return (
    this.options.title ||
    ((ref = this.$trigger) != null ? ref.attr('title') : void 0) ||
    this.getAriaTitle()
  )
}

DialogFormView.prototype.getAriaTitle = function () {
  let ref
  const ariaID = (ref = this.$trigger) != null ? ref.attr('aria-describedby') : void 0
  return $('#' + ariaID).text()
}

// @api private
DialogFormView.prototype.setupDialog = function () {
  const opts = {
    autoOpen: false,
    title: this.getDialogTitle(),
    close: (function (_this) {
      return function () {
        _this.close()
        return _this.trigger('close')
      }
    })(this),
    open: (function (_this) {
      return function () {
        return _this.trigger('open')
      }
    })(this),
    modal: true,
    zIndex: 1000,
  }
  opts.width = this.options.width
  opts.height = this.options.height
  opts.minWidth = this.options.minWidth
  opts.minHeight = this.options.minHeight
  this.$el.dialog(opts)
  if (this.options.fixDialogButtons) {
    this.$el.fixDialogButtons()
  }
  this.dialog = this.$el.data('ui-dialog')
  return $('.ui-resizable-handle').attr('aria-hidden', true)
}

DialogFormView.prototype.setDimensions = function (width, height) {
  width = width != null ? width : this.options.width
  height = height != null ? height : this.options.height
  const opts = {
    width,
    height,
  }
  return this.$el.dialog(opts)
}

// @api private
DialogFormView.prototype.onSaveSuccess = function () {
  DialogFormView.__super__.onSaveSuccess.apply(this, arguments)
  return this.close()
}

// @api private
DialogFormView.prototype.focusReturnsTo = function () {
  let id
  if (!this.$trigger) {
    return null
  }
  if ((id = this.$trigger.data('focusReturnsTo'))) {
    return $('#' + id)
  } else {
    return this.$trigger
  }
}

export default DialogFormView
