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
