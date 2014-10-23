define [
  'Backbone'
  'jst/content_migrations/ProgressStatus'
], (Backbone, template) -> 
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
    
    status: (options={})-> 
      humanize = options.humanize
      migrationState = @model.get('workflow_state')
      progressState = @progress.get('workflow_state')

      status = if migrationState != "running" then migrationState else progressState || "queued"

      if humanize
        status = status.charAt(0).toUpperCase() + status.substring(1).toLowerCase()
        status = status.replace(/_/g, " ")

      status
