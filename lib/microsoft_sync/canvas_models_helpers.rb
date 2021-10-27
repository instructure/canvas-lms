# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

#
# Helpers for Canvas models, kept separate from the models because they are
# used only for Microsoft Sync purposes and may rely on MicrosoftSync things.
#
module MicrosoftSync
  class CanvasModelsHelpers
    # Returns the number of members if it is greater than the max, otherwise returns false.
    def self.max_enrollment_members_reached?(course)
      n_distinct_users_reached?(course, MicrosoftSync::MembershipDiff::MAX_ENROLLMENT_MEMBERS)
    end

    # Returns the number of owners if it is greater than the max, otherwise returns false.
    def self.max_enrollment_owners_reached?(course)
      n_distinct_users_reached?(
        course,
        MicrosoftSync::MembershipDiff::MAX_ENROLLMENT_OWNERS,
        MicrosoftSync::MembershipDiff::OWNER_ENROLLMENT_TYPES
      )
    end

    private_class_method def self.n_distinct_users_reached?(course, max, types = nil)
      scope = course.enrollments.microsoft_sync_relevant
      scope = scope.where(type: types) if types
      scope.select(:user_id).limit(max + 1).distinct.count > max
    end
  end
end
