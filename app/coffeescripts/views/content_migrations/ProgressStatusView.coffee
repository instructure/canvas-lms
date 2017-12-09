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
  'jst/content_migrations/ProgressStatus'
  'i18n!content_migrations'
], (Backbone, template, I18n) ->
  class ProgressingStatusView extends Backbone.View
    template: template
    initialize: ->
      super
      @progress = @model.progressModel
      @model.on 'change:workflow_state', @render
      @progress.on 'change:workflow_state', @render

    render: ->
      if statusView = @model.collection?.view?.getStatusView(@model)
        @$el.html(statusView)
      else
        super

    toJSON: ->
      json = super
      json.statusLabel = @statusLabel()
      json.status = @status(humanize: true)
      json

    # a map of which bootstrap label to display for
    # a given workflow state. Defaults to nothing
    # workflow_state: 'label-class'
    # ie:
    #   'success: 'label-success'

    statusLabelClassMap:
      completed: 'label-success'
      completed_with_issues: 'label-warning'
      failed: 'label-important'
      running: 'label-info'

    # Status label css class is determined depending on the status a current item is in.
    # Status labels are mapped to the statusLabel hash. This string should be a css class.
    #
    # @returns statusLabel (type: string)
    # @api private

    statusLabel: -> @statusLabelClassMap[@statusLabelKey()]

    # Returns the key for the status label map.
    #
    # @returns key (for statusLabelClassMap)
    # @api private

    statusLabelKey: ->
      count = @model.get('migration_issues_count')
      status = @status()

      if @status() == 'completed' and count
        return 'completed_with_issues'
      else
        return @status()

    # Status of the current migration or migration progress. Checks the migration
    # first. If the migration is completed or failed we don't need to check
    # the status of the actual migration progress model since it most likely
    # wasn't pulled anyway and doesn't have a workflow_state that makes sense.
    # Only if the migration's workflow state isn't failed or completed do we
    # use the migration progress models workflow state.
    #
    # Options can be
    #   humanize: true (returns the status humanized)
    #
    #   ie:
    #     workflow_state = 'waiting_for_select'
    #     @status(humanize: true) # => "Waiting for select"
    #
    # @expects options (type: object)
    # @returns status (type: string)
    # @api private

    statusLabelMap:
      queued: -> I18n.t("Queued")
      running: -> I18n.t("Running")
      completed: -> I18n.t("Completed")
      failed: -> I18n.t("Failed")
      waiting_for_select: -> I18n.t("Waiting for Selection")
      pre_processing: -> I18n.t("Pre-processing")

    status: (options={})->
      humanize = options.humanize
      migrationState = @model.get('workflow_state')
      progressState = @progress.get('workflow_state')

      status = if migrationState != "running" then migrationState else progressState || "queued"

      if humanize
        translation = @statusLabelMap[status]
        if translation
          status = translation()
        else # just in case i missed one
          status = status.charAt(0).toUpperCase() + status.substring(1).toLowerCase()
          status = status.replace(/_/g, " ")

      status
