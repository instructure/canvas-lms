define [
  'Backbone'
  'underscore'
  'jst/content_migrations/SelectContent'
  'jst/courses/roster/createUsersWrapper'
  'compiled/views/DialogFormView'
], (Backbone, _,  template, wrapperTemplate, DialogFormView) -> 
  class SelectContentView extends DialogFormView
    events: _.extend({}, @::events,
      'click .testCheckbox' : 'updateModel'
    )

    template: template
    wrapperTemplate: wrapperTemplate
    
    updateModel: (event) -> 
      if($(event.target).is(':checked'))
        @model.set('select_everything', true)
      else
        @model.set('select_everything', false)

    submit: (event) => 
      attr = _.pick @model.attributes, "id", "workflow_state", "user_id"
      @model.clear(silent: true)
      @model.set attr

      dfd = super
      dfd?.done => 
        @model.trigger 'continue'
