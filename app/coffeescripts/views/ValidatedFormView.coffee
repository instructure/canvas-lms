define [
  'Backbone'
  'compiled/views/ValidatedMixin'
  'jquery'
  'underscore'
  'compiled/fn/preventDefault'
  'jquery.toJSON'
  'jquery.disableWhileLoading'
  'jquery.instructure_forms'
], (Backbone, ValidatedMixin, $, _) ->

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

    @mixin ValidatedMixin

    tagName: 'form'

    className: 'validated-form-view'

    events:
      submit: 'submit'

    ##
    # Sets the model data from the form and saves it. Called when the form
    # submits, or can be called programatically.
    # set @saveOpts in your view to to pass opts to Backbone.sync (like multipart: true if you have
    # a file attachment).  if you want the form not to be re-enabled after save success (because you
    # are navigating to a new page, set dontRenableAfterSaveSuccess to true on your view)
    #
    # NOTE: If you are uploading a file attachment, be careful! our
    # syncWithMultipart extension doesn't call toJSON on your model!
    #
    # @api public
    # @returns jqXHR
    submit: (event) ->
      event?.preventDefault()
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
      errors = @parseErrorResponse xhr
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
      if response.status is 422
        {authenticity_token: "invalid"}
      else
        try
          $.parseJSON(response.responseText).errors
        catch error
          {}
