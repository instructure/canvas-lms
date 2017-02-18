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

  after_create :invalidate_course_cache

  include Canvas::SoftDeletable

  include MasterCourses::TagHelper
  self.content_tag_association = :child_content_tags

  def invalidate_course_cache
    if self.workflow_state_changed?
      Rails.cache.delete(self.class.course_cache_key(self.child_course))
    end
  end

  def self.course_cache_key(course_id)
    ["has_master_course_subscriptions", Shard.global_id_for(course_id)].cache_key
  end

  def self.is_child_course?(course_id)
    Rails.cache.fetch(course_cache_key(course_id)) do
      course_id = course_id.id if course_id.is_a?(Course)
      self.where(:child_course_id => course_id).exists? # restrictions should still apply even if subscription is deleted
    end
  end
end
