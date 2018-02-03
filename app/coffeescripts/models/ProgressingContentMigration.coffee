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
  '../models/ContentMigrationProgress'
  '../collections/ContentMigrationIssueCollection'
], (Backbone, ProgressModel, IssuesCollection) ->

  # Summary
  #   Represents a model that is progressing through its
  #   workflow_state steps.

  class ProgressingContentMigration extends Backbone.Model
    initialize: (attr, options) ->
      super
      @course_id = @collection?.course_id || options?.course_id || @get('course_id')
      @buildChildren()
      @pollIfRunning()
      @syncProgressUrl()

    # Create child associations for this model. Each
    # ProgressingMigration should have a ProgressModel
    # and an IssueCollection
    #
    # Creates:
    #   @progressModel
    #   @issuesCollection
    #
    # @api private

    buildChildren: ->
      @progressModel     = new ProgressModel
                             url: @get('progress_url')
                             course_id: @course_id

      @issuesCollection  = new IssuesCollection null,
                             course_id: @course_id
                             content_migration_id: @get('id')

    # Logic to determin if we need to start polling progress. Progress
    # shouldn't need to be polled unless this migration is in a running
    # state.
    #
    # @api private

    pollIfRunning: -> @progressModel.poll() if @get('workflow_state') == 'running' || @get('workflow_state') == 'pre_processing'

    # Sometimes the progress url for this progressing migration might change or
    # be added after initialization. If this happens, the @progressModel's url needs
    # to be updated to reflect the change.
    #
    # @api private

    syncProgressUrl: ->
      @on 'change:progress_url', => @progressModel.set('url', @get('progress_url'))

