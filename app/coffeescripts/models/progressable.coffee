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
  '../models/Progress'
  'underscore'
], (Progress, _) ->

  # Mixin to models that work with the Progress API.
  #
  # When you call `save` on your model, and the server returns
  # a `progress_url` attribute, this mixin will set up a progress model
  # and start polling 
  #
  # The progress model is availabel via @progressModel.
  #
  # @event progressResolved - fires when the progress is complete

  progressable =

    initialize: ->
      @progressModel = new Progress
      @attachProgressable()

    # Returns the progressModel.pollDfd instead of the @save deferred
    saveWithProgressDeferred: ->
      @save()
      @progressModel.pollDfd

    attachProgressable: ->
      @on 'change:progress_url', (model, url) =>
        @progressModel.set({url, workflow_state: 'queued'})
      @progressModel.on 'complete', =>
        @fetch success: =>
          @trigger 'progressResolved'

