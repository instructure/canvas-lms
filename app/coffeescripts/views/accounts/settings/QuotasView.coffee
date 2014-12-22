define [
  'jquery'
  'i18n!accounts'
  'compiled/views/ValidatedFormView'
  'str/htmlEscape'
  'jst/accounts/settings/Quotas'
  'compiled/jquery.rails_flash_notifications'
], ($, I18n, ValidatedFormView, htmlEscape, template) ->

  class QuotasView extends ValidatedFormView
    template: template

    @INTEGER_REGEX = /^[+-]?\d+$/

    tag: 'form'
    id: 'default-quotas'
    className: 'form-horizontal account_settings'
    integerFields: ['default_storage_quota_mb', 'default_user_storage_quota_mb', 'default_group_storage_quota_mb']

    events:
      'submit': 'submit'

    initialize: ->
      @events ||= []
      @els ||= []
      for integerField in @integerFields
        @events["input [name=\"#{integerField}\"]"] = 'validate'
        @els["[name=\"#{integerField}\"]"] = "$#{integerField}"

      @on('success', @submitSuccess)
      @on('fail', @submitFail)
      super

    toJSON: ->
      data = super
      data.root_account = @model.get('root_account')
      data

    submitSuccess: ->
      $.flashMessage(I18n.t('default_account_quotas_updated', 'Default account quotas updated'))

    submitFail: (errors) ->
      unknownFailure = true
      for integerField in @integerFields
        unknownFailure = false if integerField of errors

      if unknownFailure
        $.flashError(I18n.t('default_account_quotas_not_updated', 'Default account quotas were not updated'))

    validateFormData: (data) ->
      errors = {}

      for integerField in @integerFields
        unless data[integerField].match(@constructor.INTEGER_REGEX)
          errors[integerField] = [
            type: 'integer_required'
            message: I18n.t('integer_required', 'An integer value is required')
          ]

      errors

    # allow invalid forms to submit (e.g. IE9 when it fails to fire the input event, which would clear the error)
    validateBeforeSave: ->
      {}

    hideErrors: ->
      control_groups = @$('div.control-group.error')
      control_groups.removeClass('error')
      control_groups.find('.help-inline').remove()

    showErrors: (errors) ->
      for integerField in @integerFields
        control_group = @["$#{integerField}"].closest('div.control-group')
        messages = errors[integerField]
        control_group.toggleClass('error', messages?)
        if messages
          helpInline = $('<span class="help-inline"></span>')
          helpInline.html((htmlEscape(message) for {message} in messages).join('<br/>'))
          control_group.find('.controls').append(helpInline)
