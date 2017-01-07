#
# Copyright (C) 2011-2016 Instructure, Inc.
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

  attr_accessible :name, :start_at, :end_at
  belongs_to :root_account, :class_name => 'Account'
  belongs_to :grading_period_group, inverse_of: :enrollment_terms
  has_many :grading_periods, through: :grading_period_group
  has_many :enrollment_dates_overrides
  has_many :courses
  has_many :enrollments, :through => :courses
  has_many :course_sections

  validates_presence_of :root_account_id, :workflow_state
  validate :check_if_deletable
  validate :consistent_account_associations

  before_validation :verify_unique_sis_source_id
  after_save :update_courses_later_if_necessary

  include StickySisFields
  are_sis_sticky :name, :start_at, :end_at

  def check_if_deletable
    if self.workflow_state_changed? && self.workflow_state == "deleted"
      if self.default_term?
        self.errors.add(:workflow_state, t('errors.delete_default_term', "Cannot delete the default term"))
      elsif self.courses.active.exists?
        self.errors.add(:workflow_state, t('errors.delete_term_with_courses', "Cannot delete a term with active courses"))
      end
    end
  end

  def update_courses_later_if_necessary
    if !self.new_record? && (self.start_at_changed? || self.end_at_changed?)
      self.update_courses_and_states_later
    end
  end

  # specifically for use in specs
  def reset_touched_courses_flag
    @touched_courses = false
  end

  def touch_all_courses
    self.courses.touch_all
  end

  def update_courses_and_states_later(enrollment_type=nil)
    return if new_record?

    self.send_later_if_production(:touch_all_courses) unless @touched_courses
    @touched_courses = true

    EnrollmentState.send_later_if_production(:invalidate_states_for_term, self, enrollment_type)
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
      override = self.enrollment_dates_overrides.where(enrollment_type: enrollment_type).first_or_initialize
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
    return true if !root_account_id_changed? && !sis_source_id_changed?

    scope = root_account.enrollment_terms.where(sis_source_id: self.sis_source_id)
    scope = scope.where("id<>?", self) unless self.new_record?

    return true unless scope.exists?

    self.errors.add(:sis_source_id, t('errors.not_unique', "SIS ID \"%{sis_source_id}\" is already in use", :sis_source_id => self.sis_source_id))
    false
  end

  def self.user_counts(root_account, terms)
    # Warning: returns keys as strings, I think because of the join
    Enrollment.active.joins(:course).
      where(root_account_id: root_account, courses: {enrollment_term_id: terms}).
      group(:enrollment_term_id).
      uniq.
      count(:user_id)
  end

  def self.course_counts(terms)
    Course.active.
      where(enrollment_term_id: terms).
      group(:enrollment_term_id).
      count
  end

  workflow do
    state :active
    state :deleted
  end

  def enrollment_dates_for(enrollment)
    # detect will cause the whole collection to load; that's fine, it's a small collection, and
    # we'll probably call enrollment_dates_for multiple times in a single request, so we want
    # it cached, rather than using .scoped which would force a re-query every time
    override = enrollment_dates_overrides.detect { |override| override.enrollment_type == enrollment.type.to_s}

    # ignore the start dates as admin
    [ override.try(:start_at) || (enrollment.admin? ? nil : start_at), override.try(:end_at) || end_at ]
  end

  # return the term dates applicable to the given enrollment(s)
  def overridden_term_dates(enrollments)
    dates = enrollments.uniq { |enrollment| enrollment.type }.map { |enrollment| enrollment_dates_for(enrollment) }
    start_dates = dates.map(&:first)
    end_dates = dates.map(&:last)
    [start_dates.include?(nil) ? nil : start_dates.min, end_dates.include?(nil) ? nil : end_dates.max]
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    save!
  end

  def consistent_account_associations
    if read_attribute(:grading_period_group_id).present?
      if root_account_id != grading_period_group.account_id
        errors.add(:grading_period_group, t("cannot be associated with a different account"))
      end
    end
  end

  scope :active, -> { where("enrollment_terms.workflow_state<>'deleted'") }
  scope :ended, -> { where('enrollment_terms.end_at < ?', Time.now.utc) }
  scope :started, -> { where('enrollment_terms.start_at < ?', Time.now.utc) }
  scope :not_ended, -> { where('enrollment_terms.end_at IS NULL OR enrollment_terms.end_at >= ?', Time.now.utc) }
  scope :not_started, -> { where('enrollment_terms.start_at IS NULL OR enrollment_terms.start_at > ?', Time.now.utc) }
  scope :by_name, -> { order(best_unicode_collation_key('name')) }
end
