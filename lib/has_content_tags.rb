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
    send_later(:update_associated_content_tags) if @associated_content_tags_need_updating != false
  end

  def update_associated_content_tags
    ContentTag.update_for(self) if @associated_content_tags_need_updating
  end

  def check_if_associated_content_tags_need_updating
    @associated_content_tags_need_updating = false
    return if self.new_record?
    return if self.respond_to?(:context_type) && %w{SisBatch Folder}.include?(self.context_type)
    @associated_content_tags_need_updating = true if self.respond_to?(:title_changed?) && self.title_changed?
    @associated_content_tags_need_updating = true if self.respond_to?(:name_changed?) && self.name_changed?
    @associated_content_tags_need_updating = true if self.respond_to?(:display_name_changed?) && self.display_name_changed?
    @associated_content_tags_need_updating = true if self.respond_to?(:points_possible_changed?) && self.points_possible_changed?
    @associated_content_tags_need_updating = true if self.respond_to?(:workflow_state_changed?) && self.workflow_state_changed? || self.workflow_state == 'deleted'
    @associated_content_tags_need_updating = true if self.is_a?(Attachment) && self.locked_changed?
  end

  def self.included(klass)
    klass.send(:after_save, :update_associated_content_tags)
    klass.send(:before_save, :check_if_associated_content_tags_need_updating)
  end

  def locked_cache_key(user)
    keys = ['_locked_for4', self, user]
    unlocked_at = self.respond_to?(:unlock_at) ? self.unlock_at : nil
    locked_at = self.respond_to?(:lock_at) ? self.lock_at : nil
    keys << (unlocked_at ? unlocked_at > Time.zone.now : false)
    keys << (locked_at ? locked_at < Time.zone.now : false)
    keys.cache_key
  end

  def clear_locked_cache(user)
    Rails.cache.delete locked_cache_key(user)
  end

  def relock_modules!(relocked_modules=[], student_ids=nil)
    ContextModule.where(:id => ContentTag.where(:content_id => self, :content_type => self.class.to_s).not_deleted.select(:context_module_id)).each do |mod|
      mod.relock_progressions(relocked_modules, student_ids)
    end
  end
end
