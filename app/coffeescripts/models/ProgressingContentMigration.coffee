define [
  'Backbone'
  'compiled/models/ContentMigrationProgress'
  'compiled/collections/ContentMigrationIssueCollection'
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

    pollIfRunning: -> @progressModel.poll() if @get('workflow_state') == 'running'

    # Sometimes the progress url for this progressing migration might change or 
    # be added after initialization. If this happens, the @progressModel's url needs
    # to be updated to reflect the change.
    #
    # @api private

    syncProgressUrl: -> 
      @on 'change:progress_url', => @progressModel.set('url', @get('progress_url'))

