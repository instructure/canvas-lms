define [
  'Backbone'
  'jquery'
  'underscore'
  'i18n!content_migrations'
  'jst/content_migrations/SelectContent'
  'jst/EmptyDialogFormWrapper'
  'jst/content_migrations/ContentCheckboxCollection'
  'compiled/views/DialogFormView'
  'compiled/views/CollectionView'
  'compiled/collections/content_migrations/ContentCheckboxCollection'
  'compiled/views/content_migrations/ContentCheckboxView'
  'compiled/views/content_migrations/NavigationForTree'
  'compiled/views/content_migrations/ExpandCollapseContentSelectTreeItems'
  'compiled/views/content_migrations/CheckingCheckboxesForTree'
  'compiled/views/content_migrations/ScrollPositionForTree'
], (Backbone, $, _, I18n, template, wrapperTemplate, checkboxCollectionTemplate, DialogFormView, CollectionView , CheckboxCollection, CheckboxView, NavigationForTree, ExpandCollapseContentSelectTreeItems, CheckingCheckboxesForTree, ScrollPositionForTree) ->
  class SelectContentView extends DialogFormView

    els:
      '.form-dialog-content' : '$formDialogContent'
      '#selectContentBtn'    : '$selectContentBtn'

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

      if _.isEmpty(@getFormData())
        event.preventDefault()
        alert(I18n.t('no_content_selected', 'You have not selected any content to import.'))
        return false
      else
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
                                ariaLevel: 1

      @checkboxCollectionView ||= new CollectionView
                                    collection: @checkboxCollection
                                    itemView: CheckboxView
                                    el: @$formDialogContent
                                    template: checkboxCollectionTemplate

      dfd = @checkboxCollection.fetch()
      @$el.disableWhileLoading dfd

      dfd.done =>
        @maintainTheTree(@$el.find('ul[role=tree]'))
        @selectContentDialogEvents()

      @checkboxCollectionView.render()

    # Private Methods

    # You must have at least one checkbox selected in order to submit the form. Disable the submit
    # button if there are not items selected.

    setSubmitButtonState: =>
      buttonState = true
      @$el.find('input[type=checkbox]').each ->
        if this.checked
          buttonState = false

      @$selectContentBtn.prop('disabled', buttonState)

    # Add SelectContent dialog box events. These events are general to the whole box.
    # Keeps everything in one place

    selectContentDialogEvents: =>
      @$el.on 'click', "#cancelSelect", => @close()
      @$el.on "change", "input[type=checkbox]", @setSubmitButtonState

    # These are the classes that help modify the tree. These methods will add events to the 
    # tree and keep things like scroll position correct as well as ensuring focus is being mantained.

    maintainTheTree: ($tree) =>
      new NavigationForTree($tree)
      new ExpandCollapseContentSelectTreeItems($tree)
      new CheckingCheckboxesForTree($tree)
      new ScrollPositionForTree($tree, @$formDialogContent)
