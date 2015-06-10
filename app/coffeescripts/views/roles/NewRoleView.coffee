define [
  'i18n!editor'
  'jquery'
  'underscore'
  'Backbone'
  'compiled/views/DialogFormView'
  'jst/roles/newRole'
  'jst/EmptyDialogFormWrapper'
  'compiled/models/Role'
  'compiled/models/Account'
], (I18n, $, _, Backbone, DialogFormView, template, wrapper, Role, Account) ->
  class NewRoleView extends DialogFormView
    defaults:
      width: 500
      height: 240

    template: template
    wrapperTemplate: wrapper

    className: 'form-dialog'

    @optionProperty 'base_role_types'
    @optionProperty 'editing'
    @optionProperty 'label_id'
    @optionProperty 'parent'

    events: _.extend({}, @::events,
        'click .dialog_closer': 'close'
    )

    initialize: ->
      super
      unless @editing
        @model = new Role

    # Method Summary
    #  JSON is dumped into the template so we are adding some logic
    #  checks we can use to display certain information.
    # @api backbone override
    toJSON: -> 
      json = super
      if @editing
        base_type = @model.get('base_role_type')
        base_label = _.find(@base_role_types, (type) => type.value == base_type).label
        json['base_role_types'] = [{value: base_type, label: base_label}]
      else
        json['base_role_types'] = @base_role_types

      json['label_id'] = @label_id
      json['editable_type'] = (json['base_role_types'].length != 1)
      json

    onSaveSuccess: ->
      super
      if @editing
        @parent.render()
      else
        @collection.add(@model)
        @model = new Role
        @render()

    validateFormData: (data) ->
      errors = {}
      if data.label == ""
        errors["label"] = [{type: 'no_name_error', message: I18n.t('no_name_error', 'A name is required')}]
      errors