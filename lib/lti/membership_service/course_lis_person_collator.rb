# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

module Lti
  module MembershipService
    class CourseLisPersonCollator < LisPersonCollatorBase
      private

      def scope
        options = {
          enrollment_type: ['teacher', 'ta', 'designer', 'observer', 'student'],
          include_inactive_enrollments: false
        }

        @user_scope ||= @user.nil? ? context.current_users : UserSearch.scope_for(context, @user, options)
      end

      def generate_roles(user)
        enrollments = if user.association(:not_ended_enrollments).loaded?
                        user.not_ended_enrollments.select { |enr| enr.course_id == context.id }
                      else
                        user.not_ended_enrollments.where(course: context)
                      end
        enrollments.map do |enrollment|
          case enrollment.type
          when 'TeacherEnrollment'
            ::IMS::LIS::Roles::Context::URNs::Instructor
          when 'TaEnrollment'
            ::IMS::LIS::Roles::Context::URNs::TeachingAssistant
          when 'DesignerEnrollment'
            ::IMS::LIS::Roles::Context::URNs::ContentDeveloper
          when 'StudentEnrollment'
            ::IMS::LIS::Roles::Context::URNs::Learner
          when 'ObserverEnrollment'
            ::IMS::LIS::Roles::Context::URNs::Learner_NonCreditLearner
          end
        end.compact.uniq
      end
    end
  end
end
