#
# Copyright (C) 2012 - present Instructure, Inc.
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
  'underscore'
  'i18n!external_feeds'
  '../ValidatedFormView'
  '../../models/ExternalFeed'
  'jst/ExternalFeeds/IndexView'
  '../../fn/preventDefault'
  'jquery'
  'jquery.toJSON'
  '../../jquery.rails_flash_notifications'
], (_, I18n, ValidatedFormView, ExternalFeed, template, preventDefault, $) ->

  class IndexView extends ValidatedFormView

    template: template

    el: '#right-side'

    events:
      'submit #add_external_feed_form' : 'submit'
      'click [data-delete-feed-id]' : 'deleteFeed'

    initialize: ->
      super
      @createPendingModel()
      @collection.on 'all', @render, this
      @render()

    createPendingModel: ->
      @model = new ExternalFeed

    validateBeforeSave: (data) ->
      errors = {}
      if !data.url or $.trim(data.url.toString()).length == 0
        errors["url"] = [
          message: I18n.t 'Feed URL is required'
        ]
      errors

    toJSON: ->
      json = @collection.toJSON()
      json.cid = @cid
      json.ENV = window.ENV if window.ENV?
      json

    render: ->
      if @collection.length || @options.permissions.create
        $('body').addClass('with-right-side')
        super

    deleteFeed: preventDefault (event) ->
      id = @$(event.target).data('deleteFeedId')
      @collection.get(id).destroy success: ->
        $.screenReaderFlashMessage(I18n.t('External feed was deleted'))

    getFormData: ->
      @$('#add_external_feed_form').toJSON()

    onSaveSuccess: =>
      super
      $.screenReaderFlashMessage(I18n.t('External feed was added'))
      @collection.add(@model)
      @createPendingModel()
