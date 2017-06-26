module Types
  QueryType = GraphQL::ObjectType.define do
    name "Query"

    field :node, GraphQL::Relay::Node.field

    field :legacyNode, GraphQL::Relay::Node.interface do
      description "Fetches an object given its type and legacy ID"
      argument :_id, !types.ID
      argument :type, !LegacyNodeType
      resolve ->(_, args, ctx) {
        GraphQLNodeLoader.load(args[:type], args[:_id], ctx)
      }
    end

    field :allCourses, types[CourseType] do
      description "All courses viewable by the current user"
      resolve ->(_, _, ctx) {
        # TODO: really need a way to share similar logic like this
        # with controllers in api/v1
        ctx[:current_user]&.cached_current_enrollments(preload_courses: true).
          index_by(&:course_id).values.
          sort_by! { |enrollment|
            Canvas::ICU.collation_key(enrollment.course.nickname_for(ctx[:current_user]))
          }.map(&:course)
      }
    end
  end
end
