define [
  'jquery'
  'i18n!accounts'
  'compiled/models/Course'
  'compiled/models/Group'
  'compiled/views/ValidatedFormView'
  'str/htmlEscape'
  'jst/accounts/settings/ManualQuotas'
  'compiled/jquery.rails_flash_notifications'
], ($, I18n, Course, Group, ValidatedFormView, htmlEscape, template) ->

  class ManualQuotasView extends ValidatedFormView
    template: template

    @INTEGER_REGEX = /^[+-]?\d+$/

    tag: 'form'
    id: 'manual-quotas'
    className: 'form-horizontal'

    els:
      '#manual_quotas_type': '$type'
      '#manual_quotas_id': '$id'
      '#manual_quotas_quota': '$quota'
      '#manual_quotas_result': '$result'
      '#manual_quotas_link': '$link'

    fields: ['type', 'id', 'quota']
    integerFields: ['id', 'quota']

    initialize: ->
      @events ||= []
      @events["input #manual_quotas_id"] = 'validate'
      @events["input #manual_quotas_quota"] = 'validate'
      @events["click #manual_quotas_find_button"] = 'findItem'

      @on('success', @submitSuccess)
      @on('fail', @submitFail)
      super

    afterRender: ->
      @$id.keypress (e) =>
        @findItem() if e.keyCode is $.ui.keyCode.ENTER
      @$result.hide()

    submitSuccess: ->
      $.flashMessage(I18n.t('quota_updated', 'Quota updated'))

    submitFail: (errors) ->
      $.flashError(I18n.t('quota_not_updated', 'Quota was not updated'))

    getFormData: ->
      data = {}
      for field in @fields
        data[field] = @["$#{field}"].val()
      data

    saveFormData: ->
      @model.save({storage_quota_mb: @$quota.val()}, @saveOpts)

    validateFormData: (data) ->
      errors = {}

      for integerField in @integerFields
        unless data[integerField] == '' || data[integerField].match(@constructor.INTEGER_REGEX)
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

    findItem: ->
      @hideErrors()
      data = @getFormData()
      @model = null

      if data.type == 'course'
        @model = new Course(id: data.id)
        path = '/courses'
        type = I18n.t('course_type', 'course')
      else if data.type == 'group'
        @model = new Group(id: data.id)
        path = '/groups'
        type = I18n.t('group_type', 'group')

      if @model
        @model.urlRoot = '/api/v1' + path
        @model.path = path
        @model.type = type

        @disablingDfd = new $.Deferred()
        @$result.hide()
        @$el.disableWhileLoading @disablingDfd

        @model.fetch(error: @findError, success: @findSuccess)

    findError: (model, error) =>
      @disablingDfd.reject()
      @hideErrors()

      if error.status == 401
        errors = {id: [{
          type: 'not_authorized'
          message: I18n.t('find_not_authorized', 'You are not authorized to access that %{type}', {type: model.type})
        }]}
      else
        errors = {id: [{
          type: 'not_found'
          message: I18n.t('find_not_found', 'Could not find a %{type} with that ID', {type: model.type})
        }]}
        
      @showErrors(errors)

    findSuccess: =>
      @$link.text(@model.get('name'))
      @$link.attr('href', @model.path + '/' + @model.get('id'))

      @$quota.val(@model.get('storage_quota_mb'))
      @$result.show()

      @disablingDfd.resolve()



