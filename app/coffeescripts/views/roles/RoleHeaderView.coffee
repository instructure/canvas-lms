define [
  'i18n!editor'
  'jquery'
  'underscore'
  'Backbone'
  'jst/roles/roleHeader'
], (I18n, $, _, Backbone, template) -> 
  class RoleHeaderView extends Backbone.View
    template: template
    tagName: 'th'
    className: 'roleHeader'

    # Static roles are role's that cannot be deleted. 
    # The delete link will not show up next to their
    # name.
    staticRoles: [
      'AccountAdmin'
      'AccountMembership'
      'StudentEnrollment'
      'TeacherEnrollment'
      'TaEnrollment'
      'ObserverEnrollment'
      'DesignerEnrollment'
    ]

    events: 
      "click a" : "removeRole"

    # Method Summary
    #   Are you abled to delete this role? You can delete
    #   a role if it's not one of the static roles.
    # @api private
    deletable: -> 
      !_.contains @staticRoles, @model.get('role')

    # Method Summary
    #   We add attributes to JSON that gets passed into the 
    #   handlebars template so we can manipulate the template.
    # @api backbone override
    toJSON: -> 
      json = super
      json['deletable'] = @deletable()
      json['showBaseRoleType'] = @showBaseRoleType()
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
    removeRole: -> 
      if confirm I18n.t "role.remove_role_confirmation", "If there are any users with this role, they will keep the current permissions but you will not be able to create new users with this role. Click ok to continue deleting this role."
        @model.destroy
          error: (model, response) -> 
            alert "#{model.role} could not be remove, contact your site admin if this continues."
          wait: true

    # Method Summary
    #   Under the actual role name we display the base role type. We don't do 
    #   this for every type of base_role_type however. These base_role_types 
    #   we hide because it's implied. This gets used in the template to determin
    #   what should be shown.
    # @api private
    showBaseRoleType: -> 
      !_.contains ["AccountAdmin", "NoPermissions", "AccountMembership"], @model.get('base_role_type')

    # Method Summary
    #   This is called after render to ensure column header is set for accessiblity.
    # @api custom backbone override
    afterRender: ->
      @$el.attr('role', 'columnheader')




