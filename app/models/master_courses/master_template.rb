class MasterCourses::MasterTemplate < ActiveRecord::Base
  # NOTE: at some point we can use this model if we decide to allow collections of objects within a course to be pushed out
  # instead of the entire course, but for now that's what we'll roll with

  belongs_to :course
  has_many :master_content_tags, :class_name => "MasterCourses::MasterContentTag", :inverse_of => :master_template
  has_many :child_subscriptions, :class_name => "MasterCourses::ChildSubscription", :inverse_of => :master_template

  strong_params

  include Canvas::SoftDeletable

  scope :for_full_course, -> { where(:full_course => true) }

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
    if @content_tag_index
      (@content_tag_index[content.class.base_class.name] || {})[content.id] || create_content_tag_for!(content)
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

  def add_child_course!(child_course)
    MasterCourses::ChildSubscription.unique_constraint_retry do |retry_count|
      child_sub = nil
      child_sub = self.child_subscriptions.active.where(:child_course_id => child_course).first if retry_count > 0
      child_sub ||= self.child_subscriptions.create!(:child_course => child_course)
      child_sub
    end
  end
end
