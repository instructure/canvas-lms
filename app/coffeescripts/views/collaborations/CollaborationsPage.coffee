#
# Copyright (C) 2013 Instructure, Inc.
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
#

define [
  'jquery'
  'underscore'
  'Backbone'
  'compiled/views/collaborations/CollaborationView'
  'compiled/views/collaborations/CollaborationFormView'
], ($, {each, reject}, {View}, CollaborationView, CollaborationFormView) ->
  class CollaborationsPage extends View
    events:
      'click .add_collaboration_link': 'addCollaboration'
      'keyclick .add_collaboration_link': 'addCollaboration'

    initialize: ->
      super
      @cacheElements()
      @createViews()
      @attachEvents()

    # Internal: Set up page state on load.
    #
    # Returns nothing.
    initPageState: =>
      if $('#collaborations .collaboration:visible').length is 0
        @addFormView.render(false)
        @$addLink.hide()

    cacheElements: ->
      @$addLink = $('.add_collaboration_link')
      @$addForm = $('#new_collaboration')
      @$noCollaborationsMessage = $('#no_collaborations_message')

    createViews: ->
      @addFormView = new CollaborationFormView(el: @$addForm)
      @collaborationViews = $('div.collaboration').map ->
        new CollaborationView(el: $(this))

    attachEvents: ->
      @addFormView.on('hide', @onFormHide)
                  .on('error', @onFormError)
      each @collaborationViews, (view) =>
        view.on('delete', @onCollaborationDelete)

    addCollaboration: (e) ->
      e.preventDefault()
      @$addLink.hide()
      @addFormView.render()
      @$el.scrollTo(@addFormView.$el)

    onCollaborationDelete: (deletedView) =>
      @collaborationViews = reject @collaborationViews, (view) ->
        view is deletedView
      if @collaborationViews.length is 0
        @$noCollaborationsMessage.show()
        @addFormView.render(false)

    onFormHide: =>
      @$addLink.show()
      @$addLink.focus()

    onFormError: ($input, message) =>
      $input.focus().errorBox(message)
