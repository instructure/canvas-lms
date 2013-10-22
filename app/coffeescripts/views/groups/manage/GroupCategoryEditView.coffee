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

    close: ->
      super
      # detach our custom handler from the bound element
      $(document).off 'keyup', @checkEsc
      # return focus using the closure from our parent view
      @options.focusReturnsTo?().focus()

    openAgain: ->
      super
      # reset the form contents
      @render()
      # auto-focus the first input
      @$el.find('input:first').focus()
      # attach a custom handler because the bound element is outside this view's scope
      $(document).on 'keyup', @checkEsc
      # override jQueryUI escKey handler to use our own
      @$el.dialog("option", "closeOnEscape", false)

    checkEsc: (e) =>
      @close() if e.keyCode is 27 # escape

    toggleSelfSignup: ->
      disabled = !@$selfSignupToggle.prop('checked')
      @$selfSignupControls.css opacity: if disabled then 0.5 else 1
      @$selfSignupControls.find(':input').prop 'disabled', disabled

    toJSON: ->
      json = @model.present()
      _.extend {},
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
