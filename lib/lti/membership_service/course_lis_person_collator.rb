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
      attr_reader :context, :user

      def initialize(context, user, opts={})
        super(opts)
        @context = context
        @user = user
      end

      private

      def users
        @users ||= user_scope.
          preload(:communication_channels, :not_ended_enrollments).
          offset(@page * @per_page).
          limit(@per_page + 1)
      end

      def user_scope
        options = {
          enrollment_type: ['teacher', 'ta', 'designer', 'observer', 'student'],
          include_inactive_enrollments: false
        }

        @user_scope ||= @user.nil? ? @context.current_users : UserSearch.scope_for(@context, @user, options)
      end

      def generate_roles(user)
        enrollments = user.not_ended_enrollments.select { |e| e.course_id == @context.id }
        enrollments.map do |enrollment|
          case enrollment.type
          when 'TeacherEnrollment'
            IMS::LIS::Roles::Context::URNs::Instructor
          when 'TaEnrollment'
            IMS::LIS::Roles::Context::URNs::TeachingAssistant
          when 'DesignerEnrollment'
            IMS::LIS::Roles::Context::URNs::ContentDeveloper
          when 'StudentEnrollment'
            IMS::LIS::Roles::Context::URNs::Learner
          when 'ObserverEnrollment'
            IMS::LIS::Roles::Context::URNs::Learner_NonCreditLearner
          end
        end.compact.uniq
      end
    end
  end
end
