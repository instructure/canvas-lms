define [
  'Backbone'
  'underscore'
  'jst/content_migrations/SelectContent'
  'jst/EmptyDialogFormWrapper'
  'jst/content_migrations/ContentCheckboxCollection'
  'compiled/views/DialogFormView'
  'compiled/views/CollectionView'
  'compiled/collections/content_migrations/ContentCheckboxCollection'
  'compiled/views/content_migrations/ContentCheckboxView'
], (Backbone, _, template, wrapperTemplate, checkboxCollectionTemplate, DialogFormView, CollectionView , CheckboxCollection, CheckboxView) ->
  class SelectContentView extends DialogFormView

    els:
      '.form-dialog-content' : '$formDialogContent'

    template: template
    wrapperTemplate: wrapperTemplate

    # Remove attributes from the model that shouldn't be sent by picking
    # them out of the original attributes, clearning the model then
    # re-setting the model. Trigger the models continue event which 
    # will start polling the progress bar again. See the
    # ProgressingMigrationView for the 'continue' event handler. 
    # 
    # @api private

    submit: (event) =>
      attr = _.pick @model.attributes, "id", "workflow_state", "user_id"
      @model.clear(silent: true)
      @model.set attr

      dfd = super
      dfd?.done =>
        @model.trigger 'continue'

    # Fetch top level checkboxes that have lower level checkboxes.
    # If the dialog has been opened before it will cache the old 
    # dialog window and re-open it instead of fetching the 
    # check boxes again. 
    # @api private

    firstOpen: =>
      super

      @checkboxCollection ||= new CheckboxCollection null,
                                courseID: @model?.course_id
                                migrationID: @model?.get('id')
                                isTopLevel: true


      @checkboxCollectionView ||= new CollectionView
                                    collection: @checkboxCollection
                                    itemView: CheckboxView
                                    el: @$formDialogContent
                                    template: checkboxCollectionTemplate

      dfd = @checkboxCollection.fetch()
      @$el.disableWhileLoading dfd
      @checkboxCollectionView.render()
