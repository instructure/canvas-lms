# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module QuizzesNext
  class QuizSerializer < Canvas::APISerializer
    include PermissionsSerializer

    root :quiz

    attributes :id,
               :title,
               :description,
               :quiz_type,
               :due_at,
               :lock_at,
               :unlock_at,
               :published,
               :points_possible,
               :can_update,
               :assignment_id,
               :assignment_group_id,
               :migration_id,
               :only_visible_to_overrides,
               :post_to_sis,
               :allowed_attempts,
               :permissions,
               :html_url,
               :mobile_url,
               :can_duplicate,
               :course_id,
               :original_course_id,
               :original_assignment_id,
               :workflow_state,
               :original_assignment_name,
               :original_quiz_id,
               :require_lockdown_browser,
               :require_lockdown_browser_for_results,
               :require_lockdown_browser_monitor,
               :lockdown_browser_monitor_data,
               :access_code,
               :in_paced_course

    def_delegators :@controller

    def quiz_type
      "quizzes.next"
    end

    def published
      object.published?
    end

    def assignment_id
      object.id
    end

    def can_update
      object.grants_right?(current_user, :update)
    end

    def html_url
      controller.send(:course_assignment_url, context, object)
    end

    def mobile_url
      controller.send(:course_assignment_url, context, quiz, persist_headless: 1, force_user: 1)
    end

    def can_duplicate
      object.can_duplicate?
    end

    def course_id
      object.context.id
    end

    def original_course_id
      object.duplicate_of&.context_id
    end

    def original_assignment_id
      object.duplicate_of&.id
    end

    def original_quiz_id
      object.migrate_from_id
    end

    def original_assignment_name
      object.duplicate_of&.title
    end

    def stringify_ids?
      !!(accepts_jsonapi? || stringify_json_ids?)
    end

    def require_lockdown_browser
      object.settings&.dig("lockdown_browser", "require_lockdown_browser") || false
    end

    def require_lockdown_browser_for_results
      object.settings&.dig("lockdown_browser", "require_lockdown_browser_for_results") || false
    end

    def require_lockdown_browser_monitor
      object.settings&.dig("lockdown_browser", "require_lockdown_browser_monitor") || false
    end

    def lockdown_browser_monitor_data
      object.settings&.dig("lockdown_browser", "lockdown_browser_monitor_data")
    end

    def access_code
      object.settings&.dig("lockdown_browser", "access_code")
    end

    def in_paced_course
      context.account.feature_enabled?(:course_paces) && context.try(:enable_course_paces)
    end
  end
end
