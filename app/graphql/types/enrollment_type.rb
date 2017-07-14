module Types
  EnrollmentType = GraphQL::ObjectType.define do
    name "Enrollment"

    implements GraphQL::Relay::Node.interface
    global_id_field :id
    field :_id, !types.ID, "legacy canvas id", property: :id

    field :user, UserType do
      resolve ->(enrollment, _, ctx) {
        Loaders::IDLoader.for(User).load(enrollment.user_id)
      }
    end
    field :course, CourseType do
      resolve ->(enrollment, _, _) {
        Loaders::IDLoader.for(Course).load(enrollment.course_id)
      }
    end
    field :section, SectionType do
      resolve ->(enrollment, _, _) {
        Loaders::IDLoader.for(CourseSection).load(enrollment.course_section_id)
      }
    end

    field :state, !EnrollmentWorkflowState, property: :workflow_state

    field :type, !EnrollmentTypeType
  end

  EnrollmentWorkflowState = GraphQL::EnumType.define do
    name "EnrollmentWorkflowState"
    value "invited"
    value "creation_pending"
    value "active"
    value "deleted"
    value "rejected"
    value "completed"
  end

  EnrollmentTypeType = GraphQL::EnumType.define do
    name "EnrollmentType"
    value "StudentEnrollment"
    value "TeacherEnrollment"
    value "TaEnrollment"
    value "ObserverEnrollment"
    value "DesignerEnrollment"
    value "StudentViewEnrollment"
  end
end
