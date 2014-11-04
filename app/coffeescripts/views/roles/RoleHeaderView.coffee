define [
  'i18n!roles'
  'jquery'
  'underscore'
  'Backbone'
  'compiled/views/roles/NewRoleView'
  'jst/roles/roleHeader'
], (I18n, $, _, Backbone, NewRoleView, template) ->
  class RoleHeaderView extends Backbone.View
    template: template
    tagName: 'th'
    className: 'roleHeader'

    events:
      "click a.delete_role" : "removeRole"

    @optionProperty 'base_role_types'

    initialize: ->
      super
      @model.on 'destroying', @addLoadingHeader
      @roleview = new NewRoleView
        base_role_types: @base_role_types
        title: I18n.t('Edit Role')
        editing: true
        model: @model
        label_id: @model.get('id')
        parent: this

    # Method Summary
    #   Replace the Roles header with a deleting indicator
    # @api private
    addLoadingHeader: =>
      @$el.find('a').replaceWith('<img class="loading-icon" src="/images/ajax-reload-animated.gif">')

    # Method Summary
    #   Are you able to edit this role? You can edit/delete
    #   a role if it's not one of the static roles.
    # @api private


    # Method Summary
    #   We add attributes to JSON that gets passed into the
    #   handlebars template so we can manipulate the template.
    # @api backbone override
    toJSON: ->
      json = super
      if @model.editable()
        json['editable'] = true
        if @base_role_types.length > 1
          base_type = @model.get("base_role_type")
          base_label = _.find(@base_role_types, (type) => type.value == base_type).label
          json['baseRoleTip'] = I18n.t('based_on_type', "Based on %{base_type}", {base_type: base_label})
      json

    # Method Summary
    #  Destroys the model. This will send a DELETE request to the model.
    #  If this role is in a collection (most likely is) it will automatically
    #  be removed from the collection and the collections remove event will
    #  be triggered.
    #
    #  Make sure the user knows that if there are any enrollments on this role
    #  it will be frozen.
    # @api private
    removeRole: (event) ->
      event.preventDefault()

      if confirm I18n.t "role.remove_role_confirmation", "If there are any users with this role, they will keep the current permissions but you will not be able to create new users with this role. Click ok to continue deleting this role."
        @model.destroy
          error: (model, response) =>
            alert "#{model.role} could not be remove, contact your site admin if this continues."
            @removeLoadingIcon()
          wait: true

    # Method Summary
    #   This is called after render to ensure column header is set for accessiblity.
    # @api custom backbone override
    afterRender: ->
      @roleview.setTrigger @$el.find('a.edit_role')
      @$el.attr('role', 'columnheader')

    # Method Summary
    #   Remove the loading icon
    # @api private
    removeLoadingIcon: ->
      @$el.find(".loading-icon").remove()

