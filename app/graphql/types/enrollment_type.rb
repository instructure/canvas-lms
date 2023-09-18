# frozen_string_literal: true

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

  class EnrollmentFilterInputType < Types::BaseInputObject
    graphql_name "EnrollmentFilterInput"

    argument :types, [EnrollmentTypeType], required: false, default_value: nil
    argument :associated_user_ids,
             [ID],
             prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("User"),
             required: false,
             default_value: []
    argument :states, [EnrollmentWorkflowState], required: false, default_value: nil
  end

  class EnrollmentType < ApplicationObjectType
    graphql_name "Enrollment"

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface
    implements Interfaces::AssetStringInterface

    alias_method :enrollment, :object

    global_id_field :id

    field :user, UserType, null: true
    def user
      load_association(:user)
    end

    field :associated_user, UserType, null: true
    def associated_user
      load_association(:associated_user)
    end

    field :course, CourseType, null: true
    def course
      load_association(:course)
    end

    field :course_section_id, ID, null: true

    field :section, SectionType, null: true
    def section
      load_association(:course_section)
    end

    field :state, EnrollmentWorkflowState, method: :workflow_state, null: false

    field :type, EnrollmentTypeType, null: false

    field :sis_import_id, ID, null: true
    def sis_import_id
      enrollment.sis_batch_id
    end

    field :grades, GradesType, null: true do
      argument :grading_period_id,
               ID,
               "The grading period to return grades for. If not specified, will use the current grading period (or the course grade for courses that don't use grading periods)",
               required: false,
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("GradingPeriod")
    end
    DEFAULT_GRADING_PERIOD = "default_grading_period"
    def grades(grading_period_id: DEFAULT_GRADING_PERIOD)
      Promise.all([
                    load_association(:scores),
                    load_association(:user),
                    load_association(:course)
                  ]).then do
        if grading_period_id == DEFAULT_GRADING_PERIOD
          Loaders::CurrentGradingPeriodLoader.load(enrollment.course).then do |gp, _|
            load_grades(gp&.id)
          end
        else
          load_grades(grading_period_id)
        end
      end
    end

    def load_grades(grading_period_id)
      grades = if grading_period_id
                 enrollment.find_score(grading_period_id: grading_period_id.to_i)
               else
                 enrollment.find_score(course_score: true)
               end

      # make a dummy score so that the grade object is always returned (if
      # the user has permission to read it)
      if grades.nil?
        score_attrs = if grading_period_id
                        { enrollment:, grading_period_id: }
                      else
                        { enrollment:, course_score: true }
                      end

        grades = Score.new(score_attrs)
      end

      if grades.grants_right?(current_user, :read)
        grades
      else
        nil
      end
    end
    private :load_grades

    field :last_activity_at, DateTimeType, null: true
    def last_activity_at
      return nil unless enrollment.user == current_user || enrollment.course.grants_right?(current_user, session, :read_reports)

      object.last_activity_at
    end

    field :total_activity_time, Integer, null: true
    def total_activity_time
      return nil unless enrollment.user == current_user || enrollment.course.grants_right?(current_user, session, :read_reports)

      object.total_activity_time
    end

    field :sis_role, String, null: true

    field :html_url, UrlType, null: true
    def html_url
      return nil unless context[:course]

      GraphQLHelpers::UrlHelpers.course_user_url(
        course_id: context[:course].id,
        id: enrollment.user.id,
        host: context[:request].host_with_port
      )
    end

    field :can_be_removed, Boolean, null: true
    def can_be_removed
      return nil unless context[:course]

      (!enrollment.defined_by_sis? ||
        context[:domain_root_account].grants_any_right?(
          current_user,
          context[:session],
          :manage_account_settings,
          :manage_sis
        )
      ) && enrollment.can_be_deleted_by(current_user, context[:course], context[:session])
    end

    field :concluded, Boolean, null: true
    def concluded
      return nil unless enrollment.user == current_user

      # restrict_enrollments_to_section_dates means that students enrollment is based on section dates
      if enrollment.course_section.restrict_enrollments_to_section_dates && !enrollment.course_section.end_at.nil?
        return enrollment.course_section.end_at < Time.zone.now
      end

      # restrict_enrollments_to_course_dates means that course participation is set to course
      if enrollment.course.restrict_enrollments_to_course_dates && !enrollment.course.end_at.nil?
        return true if enrollment.course.end_at < Time.zone.now
      end

      # Since teachers can access courses after the course is concluded, enrollment.active! is not enough for inbox purposes
      !enrollment.active?
    end
  end
end
