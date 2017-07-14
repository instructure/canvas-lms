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

    field :enrollments, types[EnrollmentType] do
      argument :courseId, !types.ID,
        "only return enrollments for this course",
        # TODO: we're going to want to be able to re-use this
        prepare: ->(relay_or_legacy_id, ctx) {
          if relay_or_legacy_id =~ /\A\d+\Z/
            relay_or_legacy_id
          else
            type, id = GraphQL::Schema::UniqueWithinType.decode(relay_or_legacy_id)
            if (type != "Course" || id.nil?)
              GraphQL::ExecutionError.new("must provide a valid courseId")
            else
              id
            end
          end
        }

      resolve ->(user, args, ctx) do
        Loaders::IDLoader.for(Course).load(args[:courseId]).then do |course|
          if course.grants_any_right? ctx[:current_user], :read_roster, :view_all_grades, :manage_grades
            UserCourseEnrollmentLoader.for(course, ctx[:current_user]).load(user.id)
          else
            nil
          end
        end
      end
    end
  end
end

class UserCourseEnrollmentLoader < Loaders::ForeignKeyLoader
  def initialize(course, user)
    scope = course.
      apply_enrollment_visibility(course.all_enrollments, user).
      active_or_pending
    super(scope, :user_id)
  end
end

