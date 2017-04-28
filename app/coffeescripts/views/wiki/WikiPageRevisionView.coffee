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
  'jquery'
  'underscore'
  'Backbone'
  'jst/wiki/WikiPageRevision'
], ($, _, Backbone, template) ->

  class WikiPageRevisionView extends Backbone.View
    tagName: 'li'
    className: 'revision clearfix'
    template: template

    events:
      'click .restore-link': 'restore'
      'keydown .restore-link': 'restore'

    els:
      '.revision-details': '$revisionButton'

    initialize: ->
      super
      @model.on 'change', => @render()

    render: ->
      hadFocus = @$revisionButton?.is(':focus')
      super
      if (hadFocus)
        @$revisionButton.focus()

    afterRender: ->
      super
      @$el.toggleClass('selected', !!@model.get('selected'))
      @$el.toggleClass('latest', !!@model.get('latest'))

    toJSON: ->
      latest = @model.collection?.latest
      json = _.extend {}, super,
        IS:
          LATEST: !!@model.get('latest')
          SELECTED: !!@model.get('selected')
          LOADED: !!@model.get('title') && !!@model.get('body')
      json.IS.SAME_AS_LATEST = json.IS.LOADED && (@model.get('title') == latest?.get('title')) && (@model.get('body') == latest?.get('body'))
      json.updated_at = $.datetimeString(json.updated_at)
      json.edited_by = json.edited_by?.display_name
      json

    windowLocation: ->
      return window.location;

    restore: (ev) ->
      if (ev?.type == 'keydown')
        return if ev.keyCode != 13
      ev?.preventDefault()
      @model.restore().done (attrs) =>
        if @pages_path
          @windowLocation().href = "#{@pages_path}/#{attrs.url}/revisions"
        else
          @windowLocation().reload()
