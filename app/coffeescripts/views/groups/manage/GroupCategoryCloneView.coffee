define [
  'underscore'
  'i18n!groups'
  'compiled/views/DialogFormView'
  'jst/EmptyDialogFormWrapper'
  'jst/groups/manage/groupCategoryClone'
], (_, I18n, DialogFormView, wrapperTemplate, template) ->

  class GroupCategoryCloneView extends DialogFormView

    template: template
    wrapperTemplate: wrapperTemplate
    className: "form-dialog group-category-clone"
    cloneSuccess: false
    changeGroups: false

    defaults:
      width: 520
      height: 400
      title: I18n.t("Clone Group Set")

    events: _.extend {},
      DialogFormView::events
      'click .dialog_closer': 'close'
      'click .clone-options-toggle': 'toggleCloneOptions'

    openAgain: ->
      @cloneSuccess = false
      @changeGroups = false
      super
      # reset the form contents
      @render()
      $('.ui-dialog-titlebar-close').focus()

    toJSON: ->
      json = super
      json.displayCautionOptions = @options.openedFromCaution
      json

    toggleCloneOptions: ->
      cloneOption = @$("input:radio[name=clone_option]:checked").val()
      if cloneOption == "clone"
        @$('.cloned_category_name_option').show()
        @$('.cloned_category_name_option').attr('aria-hidden', false)
      else
        @$('.cloned_category_name_option').hide()
        @$('.cloned_category_name_option').attr('aria-hidden', true)

    submit: (event) ->
      event.preventDefault()

      data = @getFormData()

      if data['clone_option'] == 'do_not_clone'
        @changeGroups = true
        @close()
      else
        super(event)

    saveFormData: (data) ->
      @model.cloneGroupCategoryWithName(data['name'])

    onSaveSuccess: =>
      @cloneSuccess = true
      super
