define [
  'i18n!external_tools'
  'jquery'
  'jst/ExternalTools/EditView'
  'compiled/views/ValidatedFormView'
  'str/htmlEscape'
  'compiled/jquery/fixDialogButtons'
], (I18n, $, template, ValidatedFormView, htmlEscape) ->

  class EditView extends ValidatedFormView
    template: template
    tagName: 'form'
    id: 'external_tool_form'

    className: 'validated-form-view form-horizontal bootstrap-form'

    events:
      'change #external_tool_config_type': 'onConfigTypeChange'

    initialize: ->
      super
      @title = @options.title || I18n.t 'dialog_title_edit_tool', 'Edit External Tool'

    afterRender: ->
      super
      @$el.dialog
        title: @title
        width: 520
        height: "auto"
        resizable: true
        close: => @$el.remove()
        buttons: [
          class: "btn-primary"
          text: I18n.t 'submit', 'Submit'
          'data-text-while-loading': I18n.t 'saving', 'Saving...'
          click: => @submit()
        ]
      @onConfigTypeChange()
      @$el.submit (e) =>
        @submit()
        return false
      this

    submit: ->
      this.$el.parent().find('.btn-primary').removeClass('ui-state-hover')
      super

    onConfigTypeChange: ->
      configType = @$('#external_tool_config_type').val()
      @$('.config_type').hide().attr('aria-expanded', false)
      @$(".config_type.#{configType}").show().attr('aria-expanded', true)

    showErrors: (errors) ->
      @removeErrors()
      for fieldName, field of errors
        $input = @findField fieldName
        html = (@translations[message] or message for {message} in field).join('</p><p>')
        @addError($input, html)

    removeErrors: ->
      @$('.error .help-inline').remove()
      @$('.control-group').removeClass('error')
      @$('.alert.alert-error').remove()

    addError: (input, message) ->
      input = $(input)
      input.parents('.control-group').addClass('error')
      input.after("<span id='#{htmlEscape input.attr("name")}_error_message' class='help-inline'>#{htmlEscape message}</span>")
      input.attr('aria-describedby', "#{input.attr('name')}_error_message")
      input.attr('aria-invalid', 'true')
      input.one 'keypress', ->
        $(this).parents('.control-group').removeClass('error')
        input.removeAttr('aria-describedby')
        $(this).removeAttr('aria-invalid')
        $(this).parents('.control-group').find('.help-inline').remove()

    onSaveFail: (xhr) =>
      super
      message = I18n.t 'generic_error', 'There was an error in processing your request'
      @$el.prepend("<div class='alert alert-error'>#{htmlEscape message}</span>")
      delay = (ms, func) -> setTimeout func, ms
      delay 1, -> @$("[aria-invalid='true']").first().focus()


