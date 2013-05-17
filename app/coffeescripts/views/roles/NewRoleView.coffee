define [
  'i18n!editor'
  'jquery'
  'underscore'
  'Backbone'
  'jst/roles/newRole'
  'compiled/models/Role'
  'compiled/models/Account'
], (I18n, $, _, Backbone, template, Role, Account) -> 
  class NewRoleView extends Backbone.View
    template: template

    els: 
      "input[type=text]" : "$role_name"
      "select" : "$base_role_type"

    events: 
      "click button" : "createRole"
      "submit form" : "createRole"

    # Method Summary
    #   We need base role types so we know what types the user can
    #   select from. We also need to know if this is for admin roles. 
    #   If it is, the user can only select one type of base_role_type
    #   which is "AccountMembership" See the template for better
    #   understanding.
    # @api backbone override
    initialize: -> 
      super
      @base_role_types = @options?.base_role_types
      @adminRoles = @options?.admin_roles

    # Method Summary
    #  JSON is dumped into the template so we are adding some logic
    #  checks we can use to display certain information.
    # @api backbone override
    toJSON: -> 
      json = super
      json['base_role_types'] = @base_role_types
      json['adminRoles'] = @adminRoles
      json

    # Method Summary
    #   This will grab values out of the newRole view and save them
    #   as attributes when creating a new role. @collection.create 
    #   will create a new role and if it is successful, add it to
    #   the collection. We also clear the form apon success. We 
    #   wait: true which means, wait until the request comes back
    #   before adding the role to the collection.
    # @api private
    createRole: (event) -> 
      event.preventDefault()

      role_name = @$role_name.val()
      base_role_type = @$base_role_type.val()
       
      attributes = 
        base_role_type: base_role_type
        role: role_name
        account: ENV.CURRENT_ACCOUNT.account

      @$el.find("a.dropdown-toggle").after('<img class="loading-icon" src="/images/ajax-reload-animated.gif">')
      @collection.create attributes,
        success: (model) => 
          @clearForm()
        error: => 
          alert I18n.t "role.duplicate_role_error", "Could not create this role because a role with this name already exists. Please try a different name"
          @clearForm()
        wait: true

    # Method Summary
    #   Clear all variables in the form.
    # @api private
    clearForm: -> 
      @$role_name.val('')
      @$base_role_type.val('')
      @$el.find(".loading-icon").remove()
      
