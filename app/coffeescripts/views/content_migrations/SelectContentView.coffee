define [
  'Backbone'
  'underscore'
  'jst/content_migrations/SelectContent'
  'jst/courses/roster/createUsersWrapper'
  'compiled/views/DialogFormView'
  'compiled/views/CollectionView'
  'compiled/views/content_migrations/MainCheckboxGroupView'
  'compiled/collections/content_migrations/MainCheckboxGroupCollection'
], (Backbone, _,  template, wrapperTemplate, DialogFormView, CollectionView, MainCheckboxGroupView, MainCheckboxGroupCollection) -> 
  class SelectContentView extends DialogFormView

    els: 
      '.form-dialog-content' : '$formDialogContent'

    template: template
    wrapperTemplate: wrapperTemplate

    # Form data returns nothing since we are syncing it to the model. 
    #
    # @api ValidatedFormView override

    getFormData: -> {}
    
    # Remove attributes from the model that shouldn't be sent by picking
    # them out of the original attributes, clearning the model then
    # re-setting the model. Trigger the models continue event which 
    # will start polling the progress bar again. See the
    # ProgressingMigrationView for the 'continue' event handler. 
    # 
    # @api private

    submit: (event) => 
      attr = _.pick @model.attributes, "id", "workflow_state", "user_id", "copy"
      @model.clear(silent: true)
      @model.set attr

      dfd = super
      dfd?.done => 
        @model.trigger 'continue'

    # Fetch the MainCheckboxGroups then open the dialog. Render the 
    # checkboxes in the dialog when done loading. Cache the fetch 
    # so it doesn't try to load more checkboxes every time you open
    # the dialog box.
    #
    # @api private

    open: => 
      super
      @mcgCollection ||= new MainCheckboxGroupCollection null,
                                   courseID: @model?.course_id
                                   migrationModel: @model

      @mcgCollectionView ||= new CollectionView
                               collection: @mcgCollection
                               itemView: MainCheckboxGroupView
                               el: @$formDialogContent

      dfd = @mcgCollection.fetch()
      @$el.disableWhileLoading dfd
      @mcgCollectionView.render()
