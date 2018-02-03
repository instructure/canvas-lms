#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery',
  'Backbone',
  'jst/ExternalTools/ExternalContentReturnView',
  'jsx/external_apps/lib/iframeAllowances'
], ($, Backbone, template, iframeAllowances) ->

  class ExternalContentReturnView extends Backbone.View
    template: template
    @optionProperty 'launchType'
    @optionProperty 'launchParams'
    @optionProperty 'displayAsModal'

    defaults:
      displayAsModal: true

    els:
      'iframe.tool_launch': "$iframe"

    events:
      'focus .before_external_content_info_alert': 'handleAlertFocus'
      'focus .after_external_content_info_alert': 'handleAlertFocus'
      'blur .before_external_content_info_alert': 'handleAlertBlur'
      'blur .after_external_content_info_alert': 'handleAlertBlur'

    handleAlertFocus: (e) ->
      $(e.target).removeClass('screenreader-only')
      @$el.find('iframe').addClass('info_alert_outline')

    handleAlertBlur: (e) =>
      $(e.target).addClass('screenreader-only')
      @$el.find('iframe').removeClass('info_alert_outline')

    attach: ->
      @model.on 'change', => @render()

    toJSON: ->
      json = super
      json.allowances = iframeAllowances()
      json.launch_url = @model.launchUrl(@launchType, @launchParams)
      json

    afterRender: ->
      @attachLtiEvents()
      settings = @model.get(@launchType) || {}
      @$iframe.width '100%'
      @$iframe.height settings.selection_height
      if @displayAsModal
        @$el.dialog
          title: @model.get(@launchType)?.label || ''
          width: settings.selection_width
          height: settings.selection_height
          resizable: true
          close: @removeDialog

    attachLtiEvents: ->
      $(window).on 'externalContentReady', @_contentReady
      $(window).on 'externalContentCancel', @_contentCancel

    detachLtiEvents: ->
      $(window).off 'externalContentReady', @_contentReady
      $(window).off 'externalContentCancel', @_contentCancel

    removeDialog: =>
      @detachLtiEvents()
      @remove()

    _contentReady: (event, data) =>
      @trigger 'ready', data
      @removeDialog()

    _contentCancel: (event, data) =>
      @trigger 'cancel', data
      @removeDialog()
