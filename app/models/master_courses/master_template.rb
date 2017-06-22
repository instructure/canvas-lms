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

class MasterCourses::MasterTemplate < ActiveRecord::Base
  # NOTE: at some point we can use this model if we decide to allow collections of objects within a course to be pushed out
  # instead of the entire course, but for now that's what we'll roll with

  belongs_to :course
  has_many :master_content_tags, :class_name => "MasterCourses::MasterContentTag", :inverse_of => :master_template
  has_many :child_subscriptions, :class_name => "MasterCourses::ChildSubscription", :inverse_of => :master_template
  has_many :master_migrations, :class_name => "MasterCourses::MasterMigration", :inverse_of => :master_template

  belongs_to :active_migration, :class_name => "MasterCourses::MasterMigration"

  serialize :default_restrictions, Hash
  serialize :default_restrictions_by_type, Hash
  validate :require_valid_restrictions

  attr_accessor :child_course_count
  attr_writer :last_export_completed_at

  include Canvas::SoftDeletable

  include MasterCourses::TagHelper
  self.content_tag_association = :master_content_tags

  scope :for_full_course, -> { where(:full_course => true) }

  before_create :set_defaults

  after_save :invalidate_course_cache
  after_update :sync_default_restrictions

  def set_defaults
    unless self.default_restrictions.present?
      self.default_restrictions = {:content => true}
    end
  end

  def invalidate_course_cache
    if self.workflow_state_changed?
      Rails.cache.delete(self.class.course_cache_key(self.course))
    end
  end

  def sync_default_restrictions
    if self.use_default_restrictions_by_type
      if self.use_default_restrictions_by_type_changed? || self.default_restrictions_by_type_changed?
        MasterCourses::RESTRICTED_OBJECT_TYPES.each do |type|
          self.master_content_tags.where(:use_default_restrictions => true, :content_type => type).
            update_all(:restrictions => self.default_restrictions_by_type[type] || {})
        end
      end
    else
      if self.default_restrictions_changed?
        self.master_content_tags.where(:use_default_restrictions => true).update_all(:restrictions => self.default_restrictions)
      end
    end
  end

  def require_valid_restrictions
    if self.default_restrictions_changed?
      if (self.default_restrictions.keys - MasterCourses::LOCK_TYPES).any?
        self.errors.add(:default_restrictions, "Invalid settings")
      end
    end
    if self.default_restrictions_by_type_changed?
      if (self.default_restrictions_by_type.keys - MasterCourses::RESTRICTED_OBJECT_TYPES).any?
        self.errors.add(:default_restrictions_by_type, "Invalid content type")
      elsif self.default_restrictions_by_type.values.any?{|k, v| (k.keys - MasterCourses::LOCK_TYPES).any?}
        self.errors.add(:default_restrictions_by_type, "Invalid settings")
      end
    end
  end

  def self.course_cache_key(course_id)
    ["has_master_courses_templates", Shard.global_id_for(course_id)].cache_key
  end

  def self.is_master_course?(course_id)
    Rails.cache.fetch(course_cache_key(course_id)) do
      course_id = course_id.id if course_id.is_a?(Course)
      self.where(:course_id => course_id).active.exists?
    end
  end

  def self.set_as_master_course(course)
    self.unique_constraint_retry do
      template = course.master_course_templates.for_full_course.first_or_create
      template.undestroy unless template.active?
      template
    end
  end

  def self.remove_as_master_course(course)
    self.unique_constraint_retry do
      template = course.master_course_templates.active.for_full_course.first
      template.destroy && template if template.present?
    end
  end

  def self.full_template_for(course)
    course.master_course_templates.active.for_full_course.first
  end

  def self.preload_index_data(templates)
    child_counts = MasterCourses::ChildSubscription.active.where(:master_template_id => templates).group(:master_template_id).count
    last_export_times = Hash[MasterCourses::MasterMigration.where(:master_template_id => templates, :workflow_state => "completed").
      order("master_template_id, id DESC").pluck("DISTINCT ON (master_template_id) master_template_id, imports_completed_at")]

    templates.each do |template|
      template.child_course_count = child_counts[template.id] || 0
      template.last_export_completed_at = last_export_times[template.id]
    end
  end

  def self.migration_id_prefix(shard_id, id)
    "#{MasterCourses::MIGRATION_ID_PREFIX}#{shard_id}_#{id}_"
  end

  def migration_id_for(obj, prepend="")
    if obj.is_a?(Assignment) && submittable = obj.submittable_object
      obj = submittable # i.e. use the same migration id as the topic on a graded topic's assignment - same restrictions
    end
    key = obj.is_a?(ActiveRecord::Base) ? obj.global_asset_string : obj.to_s
    "#{self.class.migration_id_prefix(self.shard.id, self.id)}#{Digest::MD5.hexdigest(prepend + key)}"
  end

  def add_child_course!(child_course_or_id)
    MasterCourses::ChildSubscription.unique_constraint_retry do |retry_count|
      child_sub = self.child_subscriptions.where(:child_course_id => child_course_or_id).first_or_create!
      child_sub.undestroy if child_sub.deleted?
      child_sub
    end
  end

  def child_course_scope
    self.shard.activate do
      Course.shard(self.shard).not_deleted.where(:id => self.child_subscriptions.active.select(:child_course_id))
    end
  end

  def active_migration_running?
    self.active_migration && self.active_migration.still_running?
  end

  def last_export_started_at
    unless defined?(@last_export_started_at)
      @last_export_started_at = self.master_migrations.where(:workflow_state => "completed").order("id DESC").limit(1).pluck(:exports_started_at).first
    end
    @last_export_started_at
  end

  def last_export_completed_at
    unless defined?(@last_export_completed_at)
      @last_export_completed_at = self.master_migrations.where(:workflow_state => "completed").order("id DESC").limit(1).pluck(:imports_completed_at).first
    end
    @last_export_completed_at
  end

  def ensure_tag_on_export(obj)
    # even if there are no default restrictions we should still create the tags initially so know to touch the content if we lock it later
    load_tags! # does nothing if already loaded
    content_tag_for(obj)
    # TODO: make a thing if we change the defaults at some point and want to force them on all the existing tags
  end

  def preload_restrictions!
    @preloaded_restrictions ||= begin
      index = {}
      self.master_content_tags.pluck(:migration_id, :restrictions).each do |mig_id, restrictions|
        index[mig_id] = restrictions
      end
      index
    end
  end

  def find_preloaded_restriction(migration_id)
    @preloaded_restrictions[migration_id]
  end

  def deletions_since_last_export
    return {} unless last_export_started_at
    deletions_by_type = {}
    MasterCourses::ALLOWED_CONTENT_TYPES.each do |klass|
      item_scope = case klass
      when 'Attachment'
        course.attachments.where(:file_state => 'deleted')
      when 'WikiPage'
        course.wiki.wiki_pages.where(:workflow_state => 'deleted')
      else
        klass.constantize.where(:context_id => course, :context_type => 'Course', :workflow_state => 'deleted')
      end
      item_scope = item_scope.where('updated_at>?', last_export_started_at).select(:id)
      deleted_mig_ids = content_tags.where(content_type: klass, content_id: item_scope).pluck(:migration_id)
      deletions_by_type[klass] = deleted_mig_ids if deleted_mig_ids.any?
    end
    deletions_by_type
  end

  def default_restrictions_for(object)
    if self.use_default_restrictions_by_type
      if object.is_a?(Assignment) && submittable = object.submittable_object
        object = submittable
      end
      self.default_restrictions_by_type[object.class.base_class.name] || {}
    else
      self.default_restrictions
    end
  end
end
