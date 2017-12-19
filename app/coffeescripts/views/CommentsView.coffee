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
  'Backbone'
  'underscore'
  '../fn/preventDefault'
  'jst/CommentsView'

  # needed by CommentsView
  'jst/_avatar'
], (Backbone, _, preventDefault, template) ->

  class CommentsView extends Backbone.View

    template: template

    events:
      'submit form' : 'addNewComment'
      'click [data-delete-comment]': 'deleteComment'

    initialize: ->
      super
      @render()
      @model.entries.on 'all', @render

    toJSON: ->
      entries: @model.entries.map (entry) ->
        _.extend entry.toJSON(),
          author:    entry.author()
          editor:    entry.editor()
          canDelete: entry.author()?.id is ENV.current_user?.id
      currentUser: ENV.current_user

    deleteComment: preventDefault ({target}) ->
      id = @$(target).data('deleteComment')
      @model.entries.get(id).destroy()

    addNewComment: preventDefault ->
      return unless message = @$('[name="message"]').val()
      entry = @model.entries.create
        # convert newlines to breaks before we send it to the server
        message: message.replace(/\n/g, "<br />")
      # wait till after the sync request to set user_id because API chokes if it is present
      # but set it so that it doesn't show up in the view as 'unknown author'
      entry.set 'user_id', ENV.current_user_id
