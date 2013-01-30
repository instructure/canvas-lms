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
    #   make a comment
    # @api backbone override
    comparator: (role) -> 
      base_role_type= role.get 'base_role_type'

      index = _.indexOf @sortOrder, base_role_type
      if base_role_type == role.get 'role' 
        return "#{index}_#{base_role_type}"
      else if role.get "role" == "AccountAdmin"
        return "0_#{base_role_type}"
      else
        return "#{index}_#{base_role_type}_#{role}"
      
