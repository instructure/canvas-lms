define [
  'Backbone'
  'formToJSON'
  'jquery.disableWhileLoading'
  'jquery.instructure_forms'
], ({View, Model}, formToJSON) ->

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
  class ValidatedFormView extends View

    tagName: 'form'

    className: 'validated-form-view'

    events: {'submit'}

    ##
    # When the form submits, the model's attributes are set from the form
    # and saved to the server. Make sure to pass in `model` to the options on
    # initialize
    model: Model.extend()

    ##
    # Sets the model data from the form and saves it. Called when the form
    # submits, or can be called programatically.
    #
    # @api public
    # @returns jqXHR
    submit: (event) ->
      event.preventDefault() if event
      data = @getFormData()
      dfd = @model.save(data).then @onSaveSuccess, @onSaveFail
      @$el.disableWhileLoading dfd
      @trigger 'submit'
      dfd

    ##
    # Converts the form to an object. Override this if the form's input names
    # don't match the model/API fields
    getFormData: ->
      @$el.toJSON()

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
      @$ selector

