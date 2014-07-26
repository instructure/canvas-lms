#
# Copyright (C) 2011 Instructure, Inc.
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

class EnrollmentTerm < ActiveRecord::Base
  DEFAULT_TERM_NAME = "Default Term"
  
  include Workflow

  attr_accessible :name, :start_at, :end_at, :ignore_term_date_restrictions
  belongs_to :root_account, :class_name => 'Account'
  has_many :enrollment_dates_overrides
  has_many :courses
  has_many :enrollments, :through => :courses
  has_many :course_sections

  EXPORTABLE_ATTRIBUTES = [
    :id, :root_account_id, :name, :term_code, :sis_source_id, :sis_batch_id, :start_at, :end_at, :accepting_enrollments, :can_manually_enroll, :created_at,
    :updated_at, :workflow_state, :ignore_term_date_restrictions
  ]
  EXPORTABLE_ASSOCIATIONS = [:root_account, :enrollment_dates_overrides, :courses, :course_sections]

  validates_presence_of :root_account_id, :workflow_state
  before_validation :verify_unique_sis_source_id
  before_save :update_courses_later_if_necessary

  include StickySisFields
  are_sis_sticky :name, :start_at, :end_at

  def update_courses_later_if_necessary
    self.update_courses_later if !self.new_record? && (self.start_at_changed? || self.end_at_changed?)
  end

  # specifically for use in specs
  def reset_touched_courses_flag
    @touched_courses = false
  end

  def touch_all_courses
    return if new_record?
    self.courses.update_all(:updated_at => Time.now.utc)
  end

  def update_courses_later
    self.send_later_if_production(:touch_all_courses) unless @touched_courses
    @touched_courses = true
  end

  def self.i18n_default_term_name
    t '#account.default_term_name', "Default Term"
  end
  
  def default_term?
    read_attribute(:name) == EnrollmentTerm::DEFAULT_TERM_NAME
  end
  
  def name
    if default_term?
      EnrollmentTerm.i18n_default_term_name
    else
      read_attribute(:name)
    end
  end
  
  def name=(new_name)
    if new_name == EnrollmentTerm.i18n_default_term_name
      write_attribute(:name, DEFAULT_TERM_NAME)
    else
      write_attribute(:name, new_name)
    end
  end
  
  def set_overrides(context, params)
    return unless params && context
    params.map do |type, values|
      type = type.classify
      enrollment_type = Enrollment.typed_enrollment(type).to_s
      override = self.enrollment_dates_overrides.find_by_enrollment_type(enrollment_type)
      override ||= self.enrollment_dates_overrides.build(:enrollment_type => enrollment_type)
      # preload the reverse association - VERY IMPORTANT so that @touched_enrollments is shared
      override.enrollment_term = self
      override.start_at = values[:start_at]
      override.end_at = values[:end_at]
      override.context = context
      override.save
      override
    end
  end
  
  def verify_unique_sis_source_id
    return true unless self.sis_source_id
    existing_term = self.root_account.enrollment_terms.find_by_sis_source_id(self.sis_source_id)
    return true if !existing_term || existing_term.id == self.id 
    
    self.errors.add(:sis_source_id, t('errors.not_unique', "SIS ID \"%{sis_source_id}\" is already in use", :sis_source_id => self.sis_source_id))
    false
  end
  
  def users_count
    scope = Enrollment.active.joins(:course).
      where(root_account_id: root_account_id, courses: {enrollment_term_id: self})
    if CANVAS_RAILS2
      scope.count(:distinct => true, :select => "enrollments.user_id")
    else
      scope.select(:user_id).uniq.count
    end
  end
  
  workflow do
    state :active
    state :deleted
  end
  
  def enrollment_dates_for(enrollment)
    return [nil, nil] if ignore_term_date_restrictions
    # detect will cause the whole collection to load; that's fine, it's a small collection, and
    # we'll probably call enrollment_dates_for multiple times in a single request, so we want
    # it cached, rather than using .scoped which would force a re-query every time
    override = enrollment_dates_overrides.detect { |override| override.enrollment_type == enrollment.type.to_s}
    [ override.try(:start_at) || start_at, override.try(:end_at) || end_at ]
  end
  
  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    save!
  end
  
  scope :active, -> { where("enrollment_terms.workflow_state<>'deleted'") }
end
