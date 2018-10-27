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
  class EnrollmentWorkflowState < Types::BaseEnum
    graphql_name "EnrollmentWorkflowState"
    value "invited"
    value "creation_pending"
    value "active"
    value "deleted"
    value "rejected"
    value "completed"
    value "inactive"
  end

  class EnrollmentTypeType < Types::BaseEnum
    graphql_name "EnrollmentType"
    value "StudentEnrollment"
    value "TeacherEnrollment"
    value "TaEnrollment"
    value "ObserverEnrollment"
    value "DesignerEnrollment"
    value "StudentViewEnrollment"
  end

  class EnrollmentType < ApplicationObjectType
    graphql_name "Enrollment"

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface

    alias :enrollment :object

    global_id_field :id
    field :_id, ID, "legacy canvas id", method: :id, null: false

    field :user, UserType, null: true
    def user
      load_association(:user)
    end

    field :course, CourseType, null: true
    def course
      load_association(:course)
    end

    field :section, SectionType, null: true
    def section
      load_association(:course_section)
    end

    field :state, EnrollmentWorkflowState, method: :workflow_state, null: false

    field :type, EnrollmentTypeType, null: false

    field :grades, GradesType, null: true do
      argument :grading_period_id, ID,
        "The grading period to return grades for. If not specified, will use the current grading period (or the course grade for courses that don't use grading periods)",
        required: false,
        prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("GradingPeriod")
    end
    DEFAULT_GRADING_PERIOD = "default_grading_period"
    def grades(grading_period_id: DEFAULT_GRADING_PERIOD)
      Loaders::AssociationLoader.for(Enrollment, [:scores, :user, :course]).
        load(enrollment).then do
          if grading_period_id == DEFAULT_GRADING_PERIOD
            Loaders::CurrentGradingPeriodLoader.load(enrollment.course).then { |gp, _|
              load_grades(gp&.id)
            }
          else
            load_grades(grading_period_id)
          end
        end
    end

    def load_grades(grading_period_id)
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

      grades.grants_right?(current_user, :read) ?
        grades :
        nil
    end
    private :load_grades

    field :last_activity_at, DateTimeType, null: true
  end
end
