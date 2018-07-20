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
      all_participants - excluded_enrollment_users - inactive_section_users
    end

    private
    def all_participant_ids
      all_participants.map(&:id)
    end

    def all_participants
      @_all_participants ||= participants({
        include_observers: true,
        excluded_user_ids: excluded_ids,
        by_date: true
      })
    end

    def excluded_enrollment_users
      excluded_enrollments.map(&:user)
    end

    def excluded_enrollments
      Enrollment.where({
        user_id: all_participant_ids
      }).not_yet_started(context)
    end


    def inactive_section_users
      inactive_sections.map(&:user)
    end

    def inactive_sections
      Enrollment.where({
        user_id: all_participant_ids
      }).section_ended(context.id)
    end
  end
end
