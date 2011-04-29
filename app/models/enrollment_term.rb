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
  include EnrollmentDateRestrictions
  include Workflow

  attr_accessible :name, :start_at, :end_at, :ignore_term_date_restrictions
  belongs_to :root_account, :class_name => 'Account'
  has_many :enrollment_dates_overrides
  has_many :courses
  has_many :course_sections
  validates_length_of :sis_data, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  
  def set_overrides(context, params)
    return unless params && context
    params.map do |type, values|
      type = type.classify
      enrollment_type = Enrollment.typed_enrollment(type).to_s
      override = self.enrollment_dates_overrides.find_or_create_by_enrollment_type(enrollment_type)
      override.start_at = values[:start_at]
      override.end_at = values[:end_at]
      override.context = context
      override.save
      override
    end
  end
  
  def users_count
    Enrollment.active.count(
      :select => "enrollments.user_id", 
      :distinct => true,
      :joins => :course_section,
      :conditions => ['enrollments.course_section_id = course_sections.id AND course_sections.enrollment_term_id = ?', id]
    )
  end
  
  workflow do
    state :active
    state :deleted
  end
  
  def enrollment_dates_for(enrollment)
    return [nil, nil] if ignore_term_date_restrictions
    override = EnrollmentDatesOverride.find_by_enrollment_term_id_and_enrollment_type(self.id, enrollment.type.to_s)
    if override
      [override.start_at, override.end_at]
    else
      [start_at, end_at]
    end
  end
  
  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    save!
  end
  
  named_scope :active, lambda {
    { :conditions => ['enrollment_terms.workflow_state != ?', 'deleted'] }
  }
end
