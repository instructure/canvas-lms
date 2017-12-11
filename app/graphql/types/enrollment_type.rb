module Types
  EnrollmentType = GraphQL::ObjectType.define do
    name "Enrollment"

    implements GraphQL::Relay::Node.interface
    interfaces [Interfaces::TimestampInterface]

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

    field :grades, GradesType do
      argument :gradingPeriodId, types.ID,
        "The grading period to return grades for. If not specified, will use the current grading period (or the course grade for courses that don't use grading periods)",
        prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("GradingPeriod")

      resolve ->(enrollment, args, ctx) {
        grades_resolver = ->(grading_period_id) do
          grades = grading_period_id ?
            enrollment.find_score(grading_period_id: grading_period_id.to_i) :
            enrollment.find_score(course_score: true)

          # make a dummy score so that the grade object is always returned (if
          # the user has permission to read it)
          if grades.nil?
            score_attrs = grading_period_id ?
              {enrollment: enrollment, grading_period_id: grading_period_id} :
              {enrollment: enrollment, course_score: true}

            grades = Score.new(score_attrs)
          end

          grades.grants_right?(ctx[:current_user], :read) ?
            grades :
            nil
        end

        Loaders::AssociationLoader.for(Enrollment, [:scores, :user, :course])
          .load(enrollment).then do
            if grading_period_id = args[:gradingPeriodId]
              grades_resolver.call(grading_period_id)
            else
              CourseGradingPeriodLoader.load(enrollment.course).then { |gp|
                grades_resolver.call(gp&.id)
              }
            end
          end
      }
    end

    field :lastActivityAt, TimeType, property: :last_activity_at
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

class CourseGradingPeriodLoader < GraphQL::Batch::Loader
  # NOTE: this isn't really doing any batch loading currently. it's just here
  # to avoid re-computing which grading period goes to the same course (like
  # when fetching grades for all students in a course)
  # (if someone wants to modify the grading period stuff for batching then
  # thank you)
  def perform(courses)
    courses.each { |course|
      fulfill course, GradingPeriod.current_period_for(course)
    }
  end
end
