define [
  'Backbone'
  'i18n!external_tools'
  'underscore'
  'jst/ExternalTools/AddAppView'
  'jquery.disableWhileLoading'
], (Backbone, I18n, _, template, disableWhileLoading) ->

  class AddAppView extends Backbone.View
    template: template

    tagName: 'form'
    id: 'add_app_form'
    className: 'validated-form-view form-horizontal bootstrap-form'

    initialize: ->
      super
      @app = @options.app

      @model.set 'name', @app.get('name')
      @model.set 'config_url', @app.get('config_url')
      @model.set 'description', @app.get('description')
      @model.set('config_type', 'by_url')

      @model.on 'error', @onSaveFail, this

      @configOptions = @app.get('config_options') || []

      if @app.get('any_key')
        @model.set 'consumer_key', 'N/A'
        @model.set 'shared_secret', 'N/A'
      else
        @configOptions = @keySecretConfigOptions().concat @configOptions

    afterRender: ->
      @$el.dialog
        title: I18n.t 'dialog_title_add_app', 'Add App'
        width: 520
        height: "auto"
        resizable: true
        close: =>
          @$el.remove()
        buttons: [
          class: "btn-primary"
          text: I18n.t 'submit', 'Submit'
          'data-text-while-loading': I18n.t 'saving', 'Saving...'
          click: => @submit()
        ]
      @$el.submit (e) =>
        @submit()
        return false
      this

    toJSON: =>
      json = super
      json.anyKey = @app.get('any_key')
      json.configOptions = []
      _.each @configOptions, (option) ->
        option.isCheckbox = true if option.type is 'checkbox'
        option.isText = true if option.type is 'text'
        json.configOptions.push option
      json

    submit: ->
      formData = @$el.getFormData()
      if @validate(formData)
        @model.set 'name', formData['canvas_app_name'] if formData['canvas_app_name']
        @model.set 'consumer_key', formData['consumer_key'] if formData['consumer_key']
        @model.set 'shared_secret', formData['shared_secret'] if formData['shared_secret']
        disablingDfd = new $.Deferred()
        @updateConfigUrl(formData)
        @model.save
          error: ->
            disablingDfd.reject()
          success: ->
            disablingDfd.resolve()
        @$el.disableWhileLoading disablingDfd

    updateConfigUrl: (formData) ->
      configUrl = @model.get('config_url')
      queryParams = {}
      queryParams[option['name']] = formData[option['name']] for option in @configOptions when formData[option['name']]
      delete queryParams['consumer_key']
      delete queryParams['shared_secret']
      newConfigUrl = @model.get('config_url') + (if configUrl.indexOf('?') != -1 then '&' else '?') + $.param(queryParams)
      @model.set('config_url', newConfigUrl)

    validate: (formData) ->
      @removeErrors()
      errors = (option for option in @configOptions when !formData[option['name']] && option['required'])
      @addError "input[name='#{error['name']}']", 'Required' for error in errors
      errors.length == 0

    removeErrors: ->
      @$('.error .help-inline').remove()
      @$('.control-group').removeClass('error')
      @$('.alert.alert-error').remove()

    addError: (input, message) ->
      input = @$(input)
      input.parents('.control-group').addClass('error')
      input.after("<span class='help-inline'>#{message}</span>")
      input.one 'keypress', ->
        $(this).parents('.control-group').removeClass('error')
        $(this).parents('.control-group').find('.help-inline').remove()

    onSaveFail: (model) =>
      message = I18n.t 'generic_error', 'There was an error in processing your request'
      @$el.prepend("<div class='alert alert-error'>#{message}</span>")

    keySecretConfigOptions: ->
      [
        {
          type: 'text'
          name: 'consumer_key'
          description: I18n.t 'consumer_key', 'Consumer Key'
          required: true
        },
        {
          type: 'text'
          name: 'shared_secret'
          description: I18n.t 'shared_secret', 'Shared Secret'
          required: true
        }
      ]

