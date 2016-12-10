class MasterCourses::MasterContentTag < ActiveRecord::Base
  # i want to get off content tag's wild ride

  belongs_to :master_template, :class_name => "MasterCourses::MasterTemplate"
  belongs_to :content, :polymorphic => true
  validates_inclusion_of :content_type, :allow_nil => false, :in => MasterCourses::ALLOWED_CONTENT_TYPES

  strong_params
end
