# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

module HasContentTags
  def update_associated_content_tags_later
    delay.update_associated_content_tags if @associated_content_tags_need_updating != false
  end

  def update_associated_content_tags
    ContentTag.update_for(self) if @associated_content_tags_need_updating
  end

  def check_if_associated_content_tags_need_updating
    @associated_content_tags_need_updating = false
    return if new_record?
    return if respond_to?(:context_type) && %w[SisBatch Folder].include?(context_type)

    @associated_content_tags_need_updating = true if respond_to?(:title_changed?) && title_changed?
    @associated_content_tags_need_updating = true if respond_to?(:name_changed?) && name_changed?
    @associated_content_tags_need_updating = true if respond_to?(:display_name_changed?) && display_name_changed?
    @associated_content_tags_need_updating = true if respond_to?(:points_possible_changed?) && points_possible_changed?
    @associated_content_tags_need_updating = true if (respond_to?(:workflow_state_changed?) && workflow_state_changed?) || workflow_state == "deleted"
    @associated_content_tags_need_updating = true if is_a?(Attachment) && locked_changed?
  end

  def self.included(klass)
    klass.send(:after_save, :update_associated_content_tags)
    klass.send(:before_save, :check_if_associated_content_tags_need_updating)
  end

  def locked_request_cache_key(user)
    keys = ["_locked_for4", self, user]
    unlocked_at = respond_to?(:unlock_at) ? unlock_at : nil
    locked_at = respond_to?(:lock_at) ? lock_at : nil
    keys << (unlocked_at ? unlocked_at > Time.zone.now : false)
    keys << (locked_at ? locked_at < Time.zone.now : false)
    keys
  end

  def relock_modules!(relocked_modules = [], student_ids = nil)
    ContextModule.where(id: ContentTag.where(content_id: self, content_type: self.class.to_s).not_deleted.select(:context_module_id)).each do |mod|
      mod.relock_progressions(relocked_modules, student_ids)
    end
  end
end
