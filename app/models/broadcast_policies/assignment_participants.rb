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

module BroadcastPolicies
  class AssignmentParticipants
    def initialize(assignment, excluded_ids=nil)
      @assignment = assignment
      @excluded_ids = excluded_ids
    end
    attr_reader :assignment, :excluded_ids
    delegate :context, :participants, to: :assignment

    def to
      all_participants
    end

    private

    def all_participants
      @_all_participants ||= participants({
        include_observers: true,
        excluded_user_ids: excluded_ids,
        by_date: true
      })
    end
  end
end
