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
import Backbone from '@canvas/backbone'
import template from '../../jst/ExternalContentReturnView.handlebars'
import iframeAllowances from '@canvas/external-apps/iframeAllowances'
import {handleExternalContentMessages} from '../../messages'

extend(ExternalContentReturnView, Backbone.View)

function ExternalContentReturnView() {
  this._contentCancel = this._contentCancel.bind(this)
  this._contentReady = this._contentReady.bind(this)
  this.removeDialog = this.removeDialog.bind(this)
  this.handleAlertBlur = this.handleAlertBlur.bind(this)
  return ExternalContentReturnView.__super__.constructor.apply(this, arguments)
}

function focusOnOpen() {
  const titleClose = $(this).parent().find('.ui-dialog-titlebar-close')
  if (titleClose.length) {
    titleClose.trigger('focus')
  }
}

ExternalContentReturnView.prototype.template = template

ExternalContentReturnView.optionProperty('launchType')

ExternalContentReturnView.optionProperty('launchParams')

ExternalContentReturnView.optionProperty('displayAsModal')

ExternalContentReturnView.prototype.defaults = {
  displayAsModal: true,
}

ExternalContentReturnView.prototype.els = {
  'iframe.tool_launch': '$iframe',
}

ExternalContentReturnView.prototype.events = {
  'focus .before_external_content_info_alert': 'handleAlertFocus',
  'focus .after_external_content_info_alert': 'handleAlertFocus',
  'blur .before_external_content_info_alert': 'handleAlertBlur',
  'blur .after_external_content_info_alert': 'handleAlertBlur',
}

ExternalContentReturnView.prototype.handleAlertFocus = function (e) {
  $(e.target).removeClass('screenreader-only')
  return this.$el.find('iframe').addClass('info_alert_outline')
}

ExternalContentReturnView.prototype.handleAlertBlur = function (e) {
  $(e.target).addClass('screenreader-only')
  return this.$el.find('iframe').removeClass('info_alert_outline')
}

ExternalContentReturnView.prototype.attach = function () {
  return this.model.on(
    'change',
    (function (_this) {
      return function () {
        return _this.render()
      }
    })(this)
  )
}

ExternalContentReturnView.prototype.toJSON = function () {
  const json = ExternalContentReturnView.__super__.toJSON.apply(this, arguments)
  json.allowances = iframeAllowances()
  json.launch_url = this.model.launchUrl(this.launchType, this.launchParams)
  return json
}

ExternalContentReturnView.prototype.afterRender = function () {
  this.attachLtiEvents()
  const settings = this.model.get(this.launchType) || {}
  let ref
  this.$iframe.width('100%')
  this.$iframe.height(settings.selection_height)
  if (this.displayAsModal) {
    return this.$el.dialog({
      title: ((ref = this.model.get(this.launchType)) != null ? ref.label : void 0) || '',
      width: settings.selection_width,
      height: settings.selection_height,
      resizable: true,
      close: this.removeDialog,
      open: focusOnOpen,
      modal: true,
      zIndex: 1000,
    })
  }
}

ExternalContentReturnView.prototype.attachLtiEvents = function () {
  this.detachLtiEvents = handleExternalContentMessages({
    ready: this._contentReady,
    cancel: this._contentCancel,
  })
}

ExternalContentReturnView.prototype.removeDialog = function () {
  this.detachLtiEvents()
  return this.remove()
}

ExternalContentReturnView.prototype._contentReady = function (data) {
  this.trigger('ready', data)
  return this.removeDialog()
}

ExternalContentReturnView.prototype._contentCancel = function () {
  this.trigger('cancel', {})
  return this.removeDialog()
}

export default ExternalContentReturnView
