module Types
  CourseType = GraphQL::ObjectType.define do
    name "Course"

    implements GraphQL::Relay::Node.interface

    global_id_field :id
    field :_id, !types.ID, "legacy canvas id", property: :id
    field :name, !types.String
    field :courseCode, types.String,
      "course short name",
      property: :course_code
    field :workflowState, !CourseWorkflowState,
      property: :workflow_state

    connection :assignmentsConnection do
      type AssignmentType.connection_type
      resolve -> (course, _, ctx) {
        Assignments::ScopedToUser.new(course, ctx[:current_user]).scope
      }
    end

    connection :sectionsConnection do
      type SectionType.connection_type
      resolve -> (course, _, ctx) {
        course.active_course_sections.
          order(CourseSection.best_unicode_collation_key('name'))
      }
    end

    connection :usersConnection do
      type UserType.connection_type
      resolve ->(course, _, ctx) {
        if course.grants_any_right?(ctx[:current_user], ctx[:session],
            :read_roster, :view_all_grades, :manage_grades)
          UserSearch.scope_for(course, ctx[:current_user], {})
        else
          nil
        end
      }
    end
  end

  CourseWorkflowState = GraphQL::EnumType.define do
    name "CourseWorkflowState"
    description "States that Courses can be in"
    value "created"
    value "claimed"
    value "available"
    value "completed"
    value "deleted"
  end
end
