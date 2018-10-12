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
  'Backbone'
  'jst/conversations/contextMessage'
], ({View}, template) ->

  class ContextMessageView extends View

    tagName: 'li'

    template: template

    events:
      'click a.context-more': 'toggle'
      'click .delete-btn': 'triggerRemoval'

    initialize: ->
      super
      @model.set(isCondensable: @model.get('body').length > 180)
      @model.set(isCondensed: true)

    toJSON: ->
      json = super
      if json.isCondensable && json.isCondensed
        json.body = json.body.substr(0, 180).replace(/\W\w*$/, '')
      json

    toggle: (e) ->
      e.preventDefault()
      @model.set(isCondensed: !@model.get('isCondensed'))
      @render()
      @$('a').focus()

    triggerRemoval: ->
      @model.trigger("removeView", { view: @ })
