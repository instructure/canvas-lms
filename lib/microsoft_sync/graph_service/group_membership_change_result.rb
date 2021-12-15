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

# Encapsulates the response from Microsoft when we try to add or remove a group of members or
# owners. Some of these additions or removals can fail for various reasons.
module MicrosoftSync
  class GraphService
    class GroupMembershipChangeResult
      NONEXISTENT_USER = :nonexistent_user

      delegate :to_json, :blank?, :present?, to: :issues_by_member_type

      def issues_by_member_type
        @issues_by_member_type ||= {}
      end

      def total_unsuccessful
        @total_unsuccessful ||= issues_by_member_type.values.sum(&:length)
      end

      def nonexistent_user_ids
        issues_by_member_type.values.map do |issues|
          issues.select { |_aad, issue| issue == NONEXISTENT_USER }.keys
        end.flatten.uniq
      end

      def add_issue(members_or_owners, user_id, reason)
        issues_by_member_type[members_or_owners] ||= {}
        issues_by_member_type[members_or_owners][user_id] = reason
      end
    end
  end
end
