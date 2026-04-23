# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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
  class InstructorUserInfoType < ApplicationObjectType
    field :_id, ID, "legacy canvas id", method: :id, null: false
    field :avatar_url, UrlType, null: true do
      description "The avatar URL for the user"
    end
    field :email, String, null: true
    field :name, String, null: false
    field :short_name, String, null: true
    field :sortable_name, String, null: true

    def avatar_url
      AvatarHelper.avatar_url_for_user(object, context[:request], root_account: context[:domain_root_account], use_fallback: false)
    end

    def email
      object.email_cached? ? object.email : nil
    end
  end

  class InstructorCourseInfoType < ApplicationObjectType
    field :_id, ID, "legacy canvas id", method: :id, null: false
    field :course_code, String, null: true
    field :name, String, null: false
  end

  class InstructorEnrollmentInfoType < ApplicationObjectType
    field :course, InstructorCourseInfoType, null: false
    field :enrollment_state, String, null: false, method: :state
    field :role, EnrollmentRoleType, null: false
    field :type, String, null: false
  end

  class InstructorWithEnrollmentsType < ApplicationObjectType
    connection_type_class TotalCountConnection

    field :enrollments, [InstructorEnrollmentInfoType], null: false
    field :user, InstructorUserInfoType, null: false
  end
end
