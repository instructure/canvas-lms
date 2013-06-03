define [
  'compiled/views/SelectView',
  'jst/courses/roster/roleSelect'
], (SelectView, template) ->

  class RoleSelectView extends SelectView
    @optionProperty 'rolesCollection'
    template: template

    attach: ->
      @rolesCollection.on 'add reset remove change', @render

    toJSON: ->
      roles: @rolesCollection.toJSON()
      selectedRole: if @el.selectedOptions?.length
        this.el.selectedOptions[0].value
      else
        ""
