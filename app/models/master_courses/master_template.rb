class MasterCourses::MasterTemplate < ActiveRecord::Base
  # NOTE: at some point we can use this model if we decide to allow collections of objects within a course to be pushed out
  # instead of the entire course, but for now that's what we'll roll with

  belongs_to :course
  has_many :master_content_tags, :class_name => "MasterCourses::MasterContentTag", :inverse_of => :master_template
  has_many :child_subscriptions, :class_name => "MasterCourses::ChildSubscription", :inverse_of => :master_template
  has_many :master_migrations, :class_name => "MasterCourses::MasterMigration", :inverse_of => :master_template

  belongs_to :active_migration, :class_name => "MasterCourses::MasterMigration"

  strong_params

  include Canvas::SoftDeletable

  scope :for_full_course, -> { where(:full_course => true) }

  after_save :invalidate_course_cache

  def invalidate_course_cache
    if self.workflow_state_changed?
      Rails.cache.delete(self.class.course_cache_key(self.course))
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
      course.master_course_templates.active.for_full_course.first_or_create
    end
  end

  def self.full_template_for(course)
    course.master_course_templates.active.for_full_course.first
  end

  # load all the tags into a nested index for fast searching in content_tag_for
  def load_tags!
    @content_tag_index = {}
    self.master_content_tags.to_a.group_by(&:content_type).each do |content_type, typed_tags|
      @content_tag_index[content_type] = typed_tags.index_by(&:content_id)
    end
    true
  end

  def content_tag_for(content)
    return unless MasterCourses::ALLOWED_CONTENT_TYPES.include?(content.class.base_class.name)
    if @content_tag_index
      tag = (@content_tag_index[content.class.base_class.name] || {})[content.id]
      unless tag
        tag = create_content_tag_for!(content)
        @content_tag_index[content.class.base_class.name] ||= {}
        @content_tag_index[content.class.base_class.name][content.id] = tag
      end
      tag
    else
      self.master_content_tags.polymorphic_where(:content => content).first || create_content_tag_for!(content)
    end
  end

  def create_content_tag_for!(content)
    self.class.unique_constraint_retry do |retry_count|
      tag = nil
      tag = self.master_content_tags.polymorphic_where(:content => content).first if retry_count > 0
      tag ||= self.master_content_tags.create!(:content => content)
      tag
    end
  end

  def migration_id_for(obj, prepend="")
    key = obj.is_a?(ActiveRecord::Base) ? obj.global_asset_string : obj.to_s
    "mc_#{self.shard.id}_#{self.id}_#{Digest::MD5.hexdigest(prepend + key)}"
  end

  def add_child_course!(child_course)
    MasterCourses::ChildSubscription.unique_constraint_retry do |retry_count|
      child_sub = nil
      child_sub = self.child_subscriptions.active.where(:child_course_id => child_course).first if retry_count > 0
      child_sub ||= self.child_subscriptions.create!(:child_course => child_course)
      child_sub
    end
  end

  def active_migration_running?
    self.active_migration && self.active_migration.still_running?
  end

  def last_export_at
    unless defined?(@last_export_at)
      @last_export_at = self.master_migrations.where(:workflow_state => "completed").order("id DESC").limit(1).pluck(:exports_started_at).first
    end
    @last_export_at
  end
end
