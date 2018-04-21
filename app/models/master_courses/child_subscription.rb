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

class MasterCourses::ChildSubscription < ActiveRecord::Base
  belongs_to :master_template, :class_name => "MasterCourses::MasterTemplate"
  belongs_to :child_course, :class_name => "Course"

  has_many :child_content_tags, :class_name => "MasterCourses::ChildContentTag", :inverse_of => :child_subscription

  validate :require_same_root_account

  def require_same_root_account
    # at some point we may want to expand this so it can be done across trusted root accounts
    # but for now make sure they're in the same root account so we don't have to worry about cross-shard course copies yet
    if self.child_course.root_account_id != self.master_template.course.root_account_id
      self.errors.add(:child_course_id, t("Child course must belong to the same root account as master course"))
    end
  end

  before_save :check_migration_id_deactivation

  after_save :invalidate_course_cache

  include Canvas::SoftDeletable

  include MasterCourses::TagHelper
  self.content_tag_association = :child_content_tags

  def invalidate_course_cache
    if self.saved_change_to_workflow_state?
      Rails.cache.delete(self.class.course_cache_key(self.child_course))
    end
  end

  def self.course_cache_key(course_id)
    ["has_master_course_subscriptions", Shard.global_id_for(course_id)].cache_key
  end

  def self.is_child_course?(course_id)
    Rails.cache.fetch(course_cache_key(course_id)) do
      course_id = course_id.id if course_id.is_a?(Course)
      self.where(:child_course_id => course_id).active.exists?
    end
  end

  def check_migration_id_deactivation
    # mess up the migration ids so restrictions no longer get applied
    if workflow_state_changed?
      if deleted? && workflow_state_was == 'active'
        self.add_deactivation_prefix!
      elsif active? && workflow_state_was == 'deleted'
        self.use_selective_copy = false # require a full import next time
        self.remove_deactivation_prefix!
      end
    end
  end

  def deactivation_prefix
    # a silly string to prepend onto all the bc object migration ids when we deactivate
    "deletedsub_#{self.id}_"
  end

  def add_deactivation_prefix!
    where_clause = ["migration_id LIKE ?", "#{MasterCourses::MasterTemplate.migration_id_prefix(self.shard.id, self.master_template_id)}%"]
    update_query = ["migration_id = concat(?, migration_id)", self.deactivation_prefix]
    update_content_in_child_course(where_clause, update_query)
  end

  def remove_deactivation_prefix!
    where_clause = ["migration_id LIKE ?", "#{deactivation_prefix}%"]
    update_query = ["migration_id = substr(migration_id, ?)", self.deactivation_prefix.length + 1]
    update_content_in_child_course(where_clause, update_query)
  end

  def update_content_in_child_course(where_clause, update_query)
    if self.child_content_tags.where(where_clause).update_all(update_query) > 0 # don't run all the rest of it if there's no reason to
      self.content_scopes_for_deactivation.each do |scope|
        scope.where(where_clause).update_all(update_query)
      end
    end
  end

  def content_scopes_for_deactivation
    # there are more things we've added the restrictor module to, but we may not bother actually restricting them in the end
    c = self.child_course
    [
      c.assignments,
      c.attachments,
      c.context_external_tools,
      c.discussion_topics,
      c.quizzes,
      c.wiki_pages
    ]
  end

  def last_migration_id
    child_course.content_migrations.where(child_subscription_id: self).order('id desc').limit(1).pluck(:id).first
  end
end
