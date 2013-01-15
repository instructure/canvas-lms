define [
  'Backbone'
  'jquery'
  'underscore'
  'compiled/fn/preventDefault'
  'jquery.toJSON'
  'jquery.disableWhileLoading'
  'jquery.instructure_forms'
], (Backbone, $, _, preventDefault) ->

  ##
  # Sets model data from a form, saves it, and displays errors returned in a
  # failed request.
  #
  # @event submit
  #
  # @event fail
  #   @signature `(errors, jqXHR, status, statusText)`
  #   @param errors - the validation errors, each error has the form $input
  #                   and the $errorBox attached to it for easy access
  #
  # @event success
  #   @signature `(response, status, jqXHR)`
  class ValidatedFormView extends Backbone.View

    tagName: 'form'

    className: 'validated-form-view'

    events:
      submit: 'submit'

    ##
    # Sets the model data from the form and saves it. Called when the form
    # submits, or can be called programatically.
    # set @saveOpts in your vew to to pass opts to Backbone.sync (like multipart: true if you have
    # a file attachment).  if you want the form not to be re-enabled after save success (because you
    # are navigating to a new page, set dontRenableAfterSaveSuccess to true on your view)
    #
    # @api public
    # @returns jqXHR
    submit: preventDefault ->
      @$el.hideErrors()

      data = @getFormData()
      errors = @validateBeforeSave data, {}

      if _.keys(errors).length == 0
        disablingDfd = new $.Deferred()
        saveDfd = @model
          .save(data, @saveOpts)
          .then(@onSaveSuccess, @onSaveFail)
          .fail -> disablingDfd.reject()

        unless @dontRenableAfterSaveSuccess
          saveDfd.done -> disablingDfd.resolve()

        @$el.disableWhileLoading disablingDfd
        @trigger 'submit'
        saveDfd
      else
        @showErrors errors
        null

    ##
    # Converts the form to an object. Override this if the form's input names
    # don't match the model/API fields
    getFormData: ->
      @$el.toJSON()

    ##
    # Override this to perform pre-save validations.  Return errors that can
    # show with the showErrors format below
    validateBeforeSave: -> {}

    onSaveSuccess: =>
      @trigger 'success', arguments...

    onSaveFail: (xhr) =>
      errors = {}
      errors = @parseErrorResponse xhr.responseText
      @showErrors errors
      @trigger 'fail', errors, arguments...

    ##
    # Parses the response body into an error object `@showErrors` understands.
    # Override for API end-points that don't follow convention, needs to return
    # something that looks like this:
    #
    #   {
    #     <field1>: [errors],
    #     <field2>: [errors]
    #   }
    #
    # For example:
    #
    #   {
    #     first_name: [
    #       {
    #         type: 'required'
    #         message: 'First name is required'
    #       },
    #       {
    #         type: 'no_numbers',
    #         message: "First name can't contain numbers"
    #       }
    #     ]
    #   }
    parseErrorResponse: (response) ->
      $.parseJSON(response).errors

    showErrors: (errors) ->
      for fieldName, field of errors
        $input = @findField fieldName
        html = (message for {message} in field).join('</p><p>')
        $input.errorBox "<div>#{html}</div>"
        field.$input = $input
        field.$errorBox = $input.data 'associated_error_box'

    ##
    # Errors are displayed relative to the field to which they belong. If
    # the key of the error in the response doesn't match the name attribute
    # of the form input element, configure a selector here.
    #
    # For example, given a form field like this:
    #
    #   <input name="user[first_name]">
    #
    # and an error response like this:
    #
    #   {errors: { first_name: {...} }}
    #
    # you would do this:
    #
    #   fieldSelectors:
    #     first_name: '[name=user[first_name]]'
    fieldSelectors: null

    findField: (field) ->
      selector = @fieldSelectors?[field] or "[name=#{field}]"
      $el = @$(selector)
      if $el.data('rich_text')
        $el = $el.next('.mceEditor').find(".mceIframeContainer")
      $el

