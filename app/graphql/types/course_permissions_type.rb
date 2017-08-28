module Types
  CoursePermissionsType = GraphQL::ObjectType.define do
    name "CoursePermissions"

    field :manageGrades, types.Boolean, resolve: ->(perm_loader, _, ctx) {
      perm_loader.load(:manage_grades)
    }
    field :sendMessages, types.Boolean, resolve: ->(perm_loader, _, ctx) {
      perm_loader.load(:send_messages)
    }
    field :viewAllGrades, types.Boolean, resolve: ->(perm_loader, _, ctx) {
      perm_loader.load(:view_all_grades)
    }
    field :viewAnalytics, types.Boolean, resolve: ->(perm_loader, _, ctx) {
      perm_loader.load(:view_analytics)
    }
    field :becomeUser, types.Boolean, resolve: ->(perm_loader, _, ctx) {
      perm_loader.load(:become_user)
    }
  end
end
