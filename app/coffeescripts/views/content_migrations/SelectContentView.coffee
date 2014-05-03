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
  'compiled/views/content_migrations/KeyboardNavigationForTree'
  'compiled/views/content_migrations/ExpandCollapseContentSelectTreeItems'
  'compiled/views/content_migrations/CheckingCheckboxesForTree'
  'compiled/views/content_migrations/ScrollPositionForTree'
], (Backbone, $, _, I18n, template, wrapperTemplate, checkboxCollectionTemplate, DialogFormView, CollectionView , CheckboxCollection, CheckboxView, KeyboardNavigationForTree, ExpandCollapseContentSelectTreeItems, CheckingCheckboxesForTree, ScrollPositionForTree) ->
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
        @$tree = @$el.find('ul[role=tree]')

        new KeyboardNavigationForTree(@$tree)
        new ExpandCollapseContentSelectTreeItems(@$tree)
        new CheckingCheckboxesForTree(@$tree)
        new ScrollPositionForTree(@$tree, @$formDialogContent)

        @$el.on 'click', "#cancelSelect", => @close()
        @$el.on "change", "input[type=checkbox]", @setSubmitButtonState

      @checkboxCollectionView.render()

    # You must have at least one checkbox selected in order to submit the form. Disable the submit
    # button if there are not items selected.

    setSubmitButtonState: =>
      buttonState = true
      @$el.find('input[type=checkbox]').each ->
        if this.checked
          buttonState = false

      @$selectContentBtn.prop('disabled', buttonState)

