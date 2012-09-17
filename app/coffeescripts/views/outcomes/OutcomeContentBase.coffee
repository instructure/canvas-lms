define [
  'i18n!outcomes'
  'jquery'
  'underscore'
  'compiled/views/ValidatedFormView'
  'tinymce.editor_box'
  'compiled/jquery.rails_flash_notifications'
  'jquery.disableWhileLoading'
  'compiled/tinymce',
], (I18n, $, _, ValidatedFormView) ->

  # Superclass for OutcomeView and OutcomeGroupView.
  # This view is used to show, add, edit, and delete outcomes and groups.
  class OutcomeContentBase extends ValidatedFormView

    # overriding superclass
    tagName: 'div'
    className: 'wrapper'

    events: _.extend
      'click .edit_button': 'edit'
      'click .cancel_button': 'cancel'
      'click .delete_button': 'delete'
      'keyup input.outcome_title': 'updateTitle'
    , ValidatedFormView::events

    # A validation key is the field name to validate.
    # The value is a function that takes the form
    # data from @getFormData() and should return
    # an error message if the field is invalid or undefined
    # if it is valid.
    validations:
      title: (data) ->
        if _.isEmpty data.title
          I18n.t('blank_error', 'Cannot be blank')

    # Returns true if there are no errors in @validations.
    # Also creates an @errors object for use in @showErrors()
    isValid: ->
      @errors = {}
      data = @getFormData()
      for fieldName, validation of @validations
        if errorMessage = validation data
          @errors[fieldName] = [{message: errorMessage}]
      _.isEmpty @errors

    # all options are optional
    initialize: (opts) ->
      @state = opts.state
      @_readOnly = opts.readOnly
      @on 'success', @success, this
      @on 'fail', @fail, this
      @setModelUrl()
      if ! @model.has('description') and @state isnt 'add'
        @state = 'loading'
        @$el.disableWhileLoading @model.fetch success: =>
          @state = opts.state
          @render()
      super()

    submit: (e) =>
      e.preventDefault()
      @setModelUrl()
      @getTinyMceCode()
      if @isValid()
        super e
      else
        @showErrors @errors

    success: ->
      if @state is 'add'
        @trigger 'addSuccess', @model
        $.flashMessage I18n.t 'flash.addSuccess', 'Creation successful'
      else
        $.flashMessage I18n.t 'flash.updateSuccess', 'Update successful'
      @state = 'show'
      @render()

    fail: ->
      $.flashError I18n.t 'flash.error', "An error occurred. Please try again later."

    getTinyMceCode: ->
      textarea = @$('textarea')
      textarea.val textarea.editorBox 'get_code'

    setModelUrl: ->
      @model.setUrlTo switch @state
        when 'add' then 'add'
        when 'delete' then 'delete'
        else 'edit'

    # overriding superclass
    getFormData: ->
      @$('form').toJSON()

    remove: ->
      @$el.hideErrors()
      @model.destroy() if @state is 'add' and @model.isNew()
      super arguments...

    cancel: (e) =>
      e.preventDefault()
      @resetModel()
      @$el.hideErrors()
      if @state is 'add'
        @$el.empty()
        @model.destroy()
        @state = 'show'
      else
        @state = 'show'
        @render()

    edit: (e) =>
      e.preventDefault()
      @state = 'edit'
      # save @model state
      @_modelAttributes = @model.toJSON()
      @render()

    delete: (e) =>
      e.preventDefault()
      return unless confirm I18n.t('confirm.delete', 'Are you sure you want to delete?')
      @state = 'delete'
      @setModelUrl()
      @$el.disableWhileLoading @model.destroy
        success: =>
          $.flashMessage I18n.t('flash.deleteSuccess', 'Deletion successful')
          @trigger 'deleteSuccess'
          @$el.empty()
          @remove()
        error: => $.flashError I18n.t('flash.deleteError', 'Something went wrong. Unable to delete at this time.')

    resetModel: ->
      @model.set @_modelAttributes

    # Called from subclasses in render.
    readyForm: ->
      setTimeout =>
        @$('textarea').editorBox() # tinymce
        @$('input:first').focus()

    readOnly: ->
      @_readOnly || ! @model.get 'can_edit'

    updateTitle: (e) =>
      @model.set 'title', e.currentTarget.value