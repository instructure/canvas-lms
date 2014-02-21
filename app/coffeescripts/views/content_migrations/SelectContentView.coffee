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
], (Backbone, $, _, I18n, template, wrapperTemplate, checkboxCollectionTemplate, DialogFormView, CollectionView , CheckboxCollection, CheckboxView) ->
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

      @checkboxCollectionView ||= new CollectionView
                                    collection: @checkboxCollection
                                    itemView: CheckboxView
                                    el: @$formDialogContent
                                    template: checkboxCollectionTemplate

      dfd = @checkboxCollection.fetch()
      @$el.disableWhileLoading dfd
      @checkboxCollectionView.render()
      @bindEvents()

    # Bind events for the SelectContentView
    # returns nil

    bindEvents: ->
      @$el.on "change", "input[type=checkbox]", @bindCheckboxEvents
      @$el.on "click", ".checkbox-carrot", @bindCarrotEvents
      @$el.on "doneFetchingCheckboxes", ".checkbox-carrot", @bindDoneFetchingEvents
      @$el.on 'click', "#cancelSelect", => @close()

    # When we are done fetching checkboxes and displaying them, we want to make sure on the initial 
    # expantion the sublevel checkboxes are checked/unchecked according to the toplevel checkbox. 
    # The 'checkbox' param that is being passed in should be the top level checkbox that will be
    # used to determine the state of the rest of the sub level checkboxes.

    bindDoneFetchingEvents: (event, checkbox) => 
      $checkbox = $(checkbox)
      @checkCheckboxes(@findChildrenCheckboxes($checkbox), $checkbox.is(':checked'))

    # When clicking on a carrot next to a checkbox, it should toggle showing or hiding the checkbox
    # It also sets a data attribute on the carrot signifying that it's either open or closed
    # type: jQuery event

    bindCarrotEvents: (event) =>
      event.preventDefault()

      $target = $(event.currentTarget)
      $sublevelCheckboxes = $target.siblings('ul')

      if $target.data('state') == "open"
        $sublevelCheckboxes.hide()
        $target.data('state', 'closed')
        $target.find('i').removeClass('icon-arrow-down').addClass('icon-forward')
      else
        $sublevelCheckboxes.show()
        $target.data('state', 'open')
        $target.find('i').addClass('icon-arrow-down').removeClass('icon-forward')


      @triggerCheckboxFetches($target)

    # Triggering a checkbox fetch will trigger an event that pulls down via ajax
    # the checkboxes for any given view and carrot in that view. There is an edge case
    # with linked_resources where we need to also load the quizzes and discusssions 
    # checkboxes when the assignments checkboxes are selected so in order to accomplish
    # this we use the checkboxFetches object to facilitate that.

    triggerCheckboxFetches: ($checkbox) ->
      $checkbox.trigger('fetchCheckboxes')
      $checkboxType = $checkbox.data('type')

      if $checkboxType == 'assignments' || $checkboxType == 'quizzes' || $checkboxType == 'discussion_topics'
        @triggerLinkedResourcesCheckboxes()

    triggerLinkedResourcesCheckboxes: ->
      @$el.find('[data-type=quizzes]').trigger('fetchCheckboxes')
      @$el.find('[data-type=discussion_topics]').trigger('fetchCheckboxes')
      @$el.find('[data-type=assignments]').trigger('fetchCheckboxes')

    # Create events for checking and unchecking a checkbox. This is based on an aria-level.
    # If all checkboxes on a given level under a ul are checked then it's parents all the way up
    # the chain are checked. Same for unchecking. If 1 or more but not all checkboxes are checked
    # the parents are put into an intermediate state.

    bindCheckboxEvents: (event) =>
      event.preventDefault()
      $checkbox = $(event.currentTarget)

      @checkCheckboxes(@findChildrenCheckboxes($checkbox), $checkbox.is(':checked'))
      @checkSiblingCheckboxes($checkbox, false) # start recursion up the tree for 3 state checkboxes

      @setSubmitButtonState()

    # You must have at least one checkbox selected in order to submit the form. Disable the submit
    # button if there are not items selected.

    setSubmitButtonState: ->
      buttonState = true
      @$el.find('input[type=checkbox]').each ->
        if $(this).is(':checked')
          buttonState = false

      @$selectContentBtn.prop('disabled', buttonState)

    # Check children checkboxes. Take into consideration there might be thousands of checkboxes
    # so you have to do a setTimeout so things run smoothly.
    # returns nil

    checkCheckboxes: ($checkboxes, state) ->
      $checkboxes.each ->
        $checkbox = $(this)

        setTimeout ->
          $checkbox.prop
            indeterminate: false
            checked: state
        ,0

    # Checks all of the checkboxes next to each other to determine if the parent
    # should be in an indeterminate state. Recursively goes up the tree finding
    # the next parent. If one checkbox is is indeterminate then all of it's parents
    # become indeterminate.

    checkSiblingCheckboxes: ($checkbox, indeterminate) ->
      $parentCheckbox = @findParentCheckbox($checkbox)
      return unless $parentCheckbox
      
      if indeterminate || !@siblingsAreTheSame($checkbox)
        $parentCheckbox.prop
          indeterminate: true
          checked: false
        @checkSiblingCheckboxes($parentCheckbox, true)
      else
        $parentCheckbox.prop
          indeterminate: false
          checked: $checkbox.is(':checked')
        @checkSiblingCheckboxes($parentCheckbox, false)

    # Checks to see if the siblings are in the same state as the checkbox being
    # passed in. If all are in the same state ie: all are "checked" or "not checked" then
    # this will return true, else its false
    # returns bool

    siblingsAreTheSame: ($checkbox) ->
      sameAsChecked = true
      $checkbox.parents('li').first().siblings().find('input[type=checkbox]').each ->
        if $(this).is(':checked') != $checkbox.is(':checked') then sameAsChecked = false

      sameAsChecked

    # Does a jquery transversal to find the next parent checkbox avalible. If there is no
    # parent checkbox avalible returns false.
    # returns jQuery Object | false

    findParentCheckbox: ($checkbox) ->
      $parentCheckbox = $checkbox.parents('[role=treeitem]')
                           .eq(1).find('input[type=checkbox]')
                           .first()

      if $parentCheckbox.length == 0 then false else $parentCheckbox

    # Finds all children checkboxes given a checkbox
    # returns jQuery object
    
    findChildrenCheckboxes: ($checkbox) ->
      $childCheckboxes = $checkbox.parents('.checkbox')
                                 .siblings('ul')
                                 .find('li input[type=checkbox]')
