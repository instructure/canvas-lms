# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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
  class AssignmentPolicy
    extend DatesOverridable::ClassMethods
    attr_reader :assignment

    def initialize(assignment)
      @assignment = assignment
    end

    def should_dispatch_assignment_due_date_changed?
      accepting_messages? &&
      assignment.changed_in_state(:published, :fields => :due_at) &&
      !just_published? &&
      !AssignmentPolicy.due_dates_equal?(assignment.due_at, assignment.due_at_before_last_save)
    end

    def should_dispatch_assignment_changed?
      accepting_messages? &&
      assignment.published? &&
      !assignment.muted? &&
      !just_published? &&
      (assignment.saved_change_to_points_possible? || assignment.assignment_changed)
    end

    def should_dispatch_assignment_created?
      return false unless context_sendable?

      published_on_create? || just_published?
    end

    def should_dispatch_submissions_posted?
      context_sendable? && assignment.posting_params_for_notifications.present?
    end

    private

    def context_sendable?
      assignment.context.available? &&
        !assignment.context.concluded?
    end

    def accepting_messages?
      context_sendable? &&
        !assignment.just_created
    end

    def created_before(time)
      assignment.created_at < time
    end

    def published_on_create?
      assignment.just_created && assignment.published?
    end

    def just_published?
      assignment.saved_change_to_workflow_state? && assignment.published?
    end
  end
end
