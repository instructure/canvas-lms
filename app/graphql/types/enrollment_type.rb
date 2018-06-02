#
# Copyright (C) 2018 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

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

        Loaders::AssociationLoader.for(Enrollment, [:scores, :user, :course]).
          load(enrollment).then do
            if args.key?(:gradingPeriodId)
              grades_resolver.call(args[:gradingPeriodId])
            else
              Loaders::CurrentGradingPeriodLoader.load(enrollment.course).then { |gp, _|
                grades_resolver.call(gp&.id)
              }
            end
          end
      }
    end

    field :lastActivityAt, DateTimeType, property: :last_activity_at
  end

  EnrollmentWorkflowState = GraphQL::EnumType.define do
    name "EnrollmentWorkflowState"
    value "invited"
    value "creation_pending"
    value "active"
    value "deleted"
    value "rejected"
    value "completed"
    value "inactive"
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
