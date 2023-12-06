# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

class LiveEventsObserver < ActiveRecord::Observer
  observe :account_notification,
          :assignment_group,
          :assignment_override,
          :assignment,
          :attachment,
          :content_export,
          :content_migration,
          :content_tag,
          :context_module_progression,
          :context_module,
          :conversation_message,
          :conversation,
          :course_section,
          :course,
          :discussion_entry,
          :discussion_topic,
          :enrollment_state,
          :enrollment,
          :group_category,
          :group_membership,
          :group,
          :learning_outcome_group,
          :learning_outcome_result,
          :learning_outcome,
          :outcome_proficiency,
          :outcome_calculation_method,
          :outcome_friendly_description,
          :rubric_assessment,
          :sis_batch,
          :submission_comment,
          :submission,
          :user_account_association,
          :user,
          :wiki_page,
          "MasterCourses::MasterTemplate",
          "MasterCourses::MasterMigration",
          "MasterCourses::ChildSubscription",
          "MasterCourses::MasterContentTag"

  NOP_UPDATE_FIELDS = ["updated_at", "sis_batch_id"].freeze
  def after_update(obj)
    changes = obj.saved_changes
    return nil unless changes.except(*NOP_UPDATE_FIELDS).any? || obj.class.try(:emit_live_events_on_any_update?)

    obj.class.connection.after_transaction_commit do
      Canvas::LiveEventsCallbacks.after_update(obj, changes)
    end
  end

  def after_create(obj)
    obj.class.connection.after_transaction_commit do
      Canvas::LiveEventsCallbacks.after_create(obj)
    end
  end

  def after_destroy(obj)
    obj.class.connection.after_transaction_commit do
      Canvas::LiveEventsCallbacks.after_destroy(obj)
    end
  end

  def after_save(obj)
    obj.class.connection.after_transaction_commit do
      Canvas::LiveEventsCallbacks.after_save(obj)
    end
  end
end
