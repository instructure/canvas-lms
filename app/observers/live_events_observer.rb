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
  observe :content_export,
          :content_migration,
          :course,
          :discussion_entry,
          :discussion_topic,
          :enrollment,
          :enrollment_state,
          :group,
          :group_category,
          :group_membership,
          :wiki_page,
          :assignment,
          :assignment_group,
          :submission,
          :attachment,
          :user,
          :user_account_association,
          :account_notification,
          :course_section,
          :context_module,
          :context_module_progression,
          :content_tag

  NOP_UPDATE_FIELDS = [ "updated_at", "sis_batch_id" ].freeze
  def after_update(obj)
    changes = obj.saved_changes
    return nil if changes.except(*NOP_UPDATE_FIELDS).empty?

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
end
