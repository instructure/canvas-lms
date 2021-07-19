# frozen_string_literal: true

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
  # the root of all the magic for a blueprint course
  # is created when a course is marked as a blueprint
  # stores the locking (aka restrictions) settings
  # and links it to all the other models for handling associations and sync

  # NOTE: at some point we can use this model if we decide to allow collections of objects within a course to be pushed out
  # instead of the entire course, but for now that's what we'll roll with

  belongs_to :course
  belongs_to :root_account, :class_name => 'Account'

  # these store which pieces of blueprint content are locked (and how)
  has_many :master_content_tags, :class_name => "MasterCourses::MasterContentTag", :inverse_of => :master_template
  # links the blueprint to its associated courses
  has_many :child_subscriptions, :class_name => "MasterCourses::ChildSubscription", :inverse_of => :master_template
  # sync events
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
  before_create :set_root_account_id

  after_save :invalidate_course_cache
  after_update :sync_default_restrictions

  after_destroy :destroy_subscriptions_later

  def set_defaults
    unless self.default_restrictions.present?
      self.default_restrictions = {:content => true}
    end
  end

  def set_root_account_id
    self.root_account_id = self.course.root_account_id
  end

  def invalidate_course_cache
    if self.saved_change_to_workflow_state?
      Rails.cache.delete(self.class.course_cache_key(self.course))
    end
  end

  def sync_default_restrictions
    if self.use_default_restrictions_by_type
      if self.saved_change_to_use_default_restrictions_by_type? || self.saved_change_to_default_restrictions_by_type?
        MasterCourses::RESTRICTED_OBJECT_TYPES.each do |type|
          new_type_restrictions = self.default_restrictions_by_type[type] || {}
          count = self.master_content_tags.where(:use_default_restrictions => true, :content_type => type).
            update_all(:restrictions => new_type_restrictions)
          next unless count > 0

          old_type_restrictions = self.default_restrictions_by_type_before_last_save[type] || {}
          if new_type_restrictions.any?{|setting, locked| locked && !old_type_restrictions[setting]} # tightened restrictions
            self.touch_all_content_for_tags(type)
          end
        end
      end
    else
      if self.saved_change_to_default_restrictions?
        count = self.master_content_tags.where(:use_default_restrictions => true).
          update_all(:restrictions => self.default_restrictions)
        if count > 0 && self.default_restrictions.any?{|setting, locked| locked && !self.default_restrictions_before_last_save[setting]} # tightened restrictions
          self.touch_all_content_for_tags
        end
      end
    end
  end

  def destroy_subscriptions_later
    delay_if_production(n_strand: ["master_courses_destroy_subscriptions", self.course.global_root_account_id],
      priority: Delayed::LOW_PRIORITY).destroy_subscriptions
  end

  def destroy_subscriptions
    self.child_subscriptions.active.each(&:destroy)
  end

  def touch_all_content_for_tags(only_content_type=nil)
    content_types = only_content_type ?
      [only_content_type] :
      self.master_content_tags.where(:use_default_restrictions => true).distinct.pluck(:content_type)
    content_types.each do |content_type|
      klass = content_type.constantize
      klass.where(klass.primary_key => self.master_content_tags.where(:use_default_restrictions => true,
        :content_type => content_type).select(:content_id)).touch_all
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

  def self.master_course_for_child_course(course_id)
    course_id = course_id.id if course_id.is_a?(Course)
    mt_table = self.table_name
    cs_table = MasterCourses::ChildSubscription.table_name
    Course.joins("INNER JOIN #{MasterCourses::MasterTemplate.quoted_table_name} ON #{mt_table}.course_id=courses.id AND #{mt_table}.workflow_state='active'").
      joins("INNER JOIN #{MasterCourses::ChildSubscription.quoted_table_name} ON #{cs_table}.master_template_id=#{mt_table}.id AND #{cs_table}.workflow_state='active'").
      where("#{cs_table}.child_course_id = ?", course_id).first
  end

  def self.preload_index_data(templates)
    child_counts = MasterCourses::ChildSubscription.active.where(:master_template_id => templates).
      joins(:child_course).where.not(:courses => {:workflow_state => "deleted"}).group(:master_template_id).count
    last_export_times = Hash[MasterCourses::MasterMigration.where(:master_template_id => templates, :workflow_state => "completed").
      order(:master_template_id, id: :desc).pluck(Arel.sql("DISTINCT ON (master_template_id) master_template_id, imports_completed_at"))]

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
    "#{self.class.migration_id_prefix(self.shard.id, self.id)}#{Digest::SHA256.hexdigest(prepend + key)}"
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

  def associated_course_count
    self.child_subscriptions.active.count
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
    MasterCourses::CONTENT_TYPES_FOR_DELETIONS.each do |klass|
      item_scope = case klass
      when 'Attachment'
        course.attachments.where(:file_state => 'deleted')
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

  def default_restrictions_by_type_for_api
    default_restrictions_by_type.map{|k, v| [k.constantize.table_name.singularize, v] }.to_h
  end

  def self.create_associations_from_sis(root_account, associations, messages, migrating_user=nil)
    associations.keys.each_slice(50) do |master_sis_ids|
      templates = self.active.for_full_course.joins(:course).
        where(:courses => {:root_account_id => root_account, :sis_source_id => master_sis_ids}).
        select("#{self.table_name}.*, courses.sis_source_id AS sis_source_id, courses.account_id AS account_id").to_a
      if templates.count != master_sis_ids.count
        (master_sis_ids - templates.map(&:sis_source_id)).each do |missing_id|
          associations[missing_id].each do |target_course_id|
            messages << "Unknown blueprint course \"#{missing_id}\" for course \"#{target_course_id}\""
          end
        end
      end


      templates.each do |template|
        needs_migration = false
        associations[template.sis_source_id].each_slice(50) do |associated_sis_ids|
          data = root_account.all_courses.where(:sis_source_id => associated_sis_ids).not_master_courses.
            joins("LEFT OUTER JOIN #{MasterCourses::ChildSubscription.quoted_table_name} AS mcs ON mcs.child_course_id=courses.id AND mcs.workflow_state<>'deleted'").
            joins(sanitize_sql(["LEFT OUTER JOIN #{CourseAccountAssociation.quoted_table_name} AS caa ON
              caa.course_id=courses.id AND caa.account_id = ?", template.account_id])).
            pluck(:id, :sis_source_id, "mcs.master_template_id", "caa.id")

          if data.count != associated_sis_ids
            (associated_sis_ids - data.map{|r| r[1]}).each do |invalid_id|
              messages << "Cannot associate course \"#{invalid_id}\" - is a blueprint course"
            end
          end
          data.each do |id, associated_sis_id, master_template_id, course_association_id|
            if master_template_id
              if master_template_id != template.id
                messages << "Cannot associate course \"#{associated_sis_id}\" - is associated to another blueprint course"
              end # otherwise we don't need to do anything - it's already associated
            elsif course_association_id.nil?
              messages << "Cannot associate course \"#{associated_sis_id}\" - is not in the same or lower account as the blueprint course"
            else
              needs_migration = true
              template.add_child_course!(id)
            end
          end
        end

        if migrating_user && needs_migration
          MasterCourses::MasterMigration.start_new_migration!(template, migrating_user, :retry_later => true)
        end
      end
    end
  end
end
