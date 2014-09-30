define [
  'underscore'
  'i18n!groups'
  'compiled/views/DialogFormView'
  'jst/EmptyDialogFormWrapper'
  'jst/groups/manage/groupCategoryEdit'
  'str/htmlEscape'
], (_, I18n, DialogFormView, wrapperTemplate, template, h) ->

  class GroupCategoryEditView extends DialogFormView

    template: template
    wrapperTemplate: wrapperTemplate
    className: "form-dialog group-category-edit"

    defaults:
      width: 500
      height: if ENV.allow_self_signup then 360 else 210
      title: I18n.t('edit_group_set', 'Edit Group Set')
      fixDialogButtons: false

    els:
      '.self-signup-help': '$selfSignupHelp'
      '.self-signup-description': '$selfSignup'
      '.self-signup-toggle': '$selfSignupToggle'
      '.self-signup-controls': '$selfSignupControls'

    events: _.extend {},
      DialogFormView::events
      'click .dialog_closer': 'close'
      'click .self-signup-toggle': 'toggleSelfSignup'

    afterRender: ->
      @toggleSelfSignup()

    openAgain: ->
      super
      # reset the form contents
      @render()
      # auto-focus the first input
      @$('input:first').focus()

    toggleSelfSignup: ->
      disabled = !@$selfSignupToggle.prop('checked')
      @$selfSignupControls.css opacity: if disabled then 0.5 else 1
      @$selfSignupControls.find(':input').prop 'disabled', disabled

    validateFormData: (data, errors) ->
      groupLimit = @$("[name=group_limit]")
      if groupLimit.length and !groupLimit[0].validity.valid
        {"group_limit": [{message: I18n.t('group_limit_number', 'Group limit must be a number') }]}

    toJSON: ->
      json = @model.present()
      _.extend {},
        ENV: ENV,
        json,
        enable_self_signup: json.self_signup
        restrict_self_signup: json.self_signup is 'restricted'
        group_limit: """
          <input name="group_limit"
                 type="number"
                 min="2"
                 class="input-micro"
                 value="#{h(json.group_limit ? '')}">
          """
