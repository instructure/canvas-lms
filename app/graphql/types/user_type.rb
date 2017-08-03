module Types
  UserType = GraphQL::ObjectType.define do
    #
    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    #   NOTE:
    #   when adding fields to this type, make sure you are checking the
    #   personal info exclusions as is done in +user_json+
    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    #
    name "User"

    implements GraphQL::Relay::Node.interface
    global_id_field :id
    field :_id, !types.ID, "legacy canvas id", property: :id

    field :name, types.String
    field :sortableName, types.String,
      "The name of the user that is should be used for sorting groups of users, such as in the gradebook.",
      property: :sortable_name
    field :shortName, types.String,
      "A short name the user has selected, for use in conversations or other less formal places through the site.",
      property: :short_name

    field :avatarUrl, types.String do
      resolve ->(user, _, ctx) {
        user.account.service_enabled?(:avatars) ?
          AvatarHelper.avatar_url_for_user(user, ctx[:request]) :
          nil
      }
    end
  end
end
