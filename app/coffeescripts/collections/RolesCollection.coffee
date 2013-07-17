define [
  'Backbone'
  'underscore'
  'compiled/models/Role'
], (Backbone, _, Role) ->
  class RolesCollection extends Backbone.Collection
    model: Role

    sortOrder: [
      "NoPermissions"
      "AccountMembership"
      "StudentEnrollment"
      "TaEnrollment"
      "TeacherEnrollment"
      "DesignerEnrollment"
      "ObserverEnrollment"
    ]

    # Method Summary
    #   Roles are ordered by base_role_type then alphabetically within those
    #   base role types. The order that these base role types live is defined
    #   by the sortOrder array. There is a special case however. AccountAdmin
    #   role always goes first. This uses the index of the sortOrder to ensure
    #   the correct order since comparator is just using _.sort in it's 
    #   underlining implementation which is just ordering based on alphabetical
    #   correctness. 
    # @api backbone override
    comparator: (role) -> 
      base_role_type= role.get 'base_role_type'
      index = _.indexOf @sortOrder, base_role_type
      role_name = role.get 'role'

      position_string = "#{index}_#{base_role_type}_#{role_name}"

      if base_role_type == role_name then position_string = "#{index}_#{base_role_type}"
      if role_name == "AccountAdmin" then position_string = "0_#{base_role_type}"

      position_string