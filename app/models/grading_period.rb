#
# Copyright (C) 2015-2016 Instructure, Inc.
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

class GradingPeriod < ActiveRecord::Base
  include Canvas::SoftDeletable

  attr_accessible :weight, :start_date, :end_date, :title

  belongs_to :grading_period_group, inverse_of: :grading_periods
  has_many :grading_period_grades, dependent: :destroy

  validates :title, :start_date, :end_date, :grading_period_group_id, presence: true
  validate :start_date_is_before_end_date
  validate :not_overlapping, unless: :skip_not_overlapping_validator?

  scope :current, -> do
    where("start_date <= :now AND end_date >= :now", now: Time.zone.now)
  end

  scope :grading_periods_by, ->(context_with_ids) do
    joins(:grading_period_group).where(grading_period_groups: context_with_ids).readonly(false)
  end

  set_policy do
    %i[read create update delete].each do |permission|
      given do |user|
        grading_period_group.present? &&
          grading_period_group.grants_right?(user, permission)
      end
      can permission
    end
  end

  def self.for(course)
    periods = active.grading_periods_by(course_id: course.id)
    if periods.exists?
      periods
    else
      grading_period_group_ids = EnrollmentTerm.select(:grading_period_group_id).where(id: course.enrollment_term)
      active.where(grading_period_group_id: grading_period_group_ids)
    end
  end

  def self.current_period_for(context)
    self.for(context).find(&:current?)
  end

  # Takes a context and a grading_period_id and returns a grading period
  # if it is in the for collection. Uses Enumberable#find to query
  # collection.
  def self.context_find(context, grading_period_id)
    self.for(context).find do |grading_period|
      grading_period.id == grading_period_id.to_i
    end
  end

  def account_group?
    grading_period_group.course_id.nil?
  end

  def course_group?
    grading_period_group.course_id.present?
  end

  def assignments_for_student(assignments, student)
    Assignment::FilterWithOverridesByDueAtForStudent.new(
      assignments: assignments,
      grading_period: self,
      student: student
    ).filter_assignments
  end

  def assignments(assignments)
    Assignment::FilterWithOverridesByDueAtForClass.new(
      assignments: assignments,
      grading_period: self
    ).filter_assignments
  end

  def current?
    in_date_range?(Time.zone.now)
  end

  def in_date_range?(date)
    start_date <= date && end_date >= date
  end

  def last?
    grading_period_group
      .grading_periods
      .active
      .sort_by(&:end_date)
      .last == self
  end
  alias_method :is_last, :last?

  def overlapping?
    overlaps.active.exists?
  end

  def skip_not_overlapping_validator
    @_skip_not_overlapping_validator = true
  end

  def self.json_for(context, user)
    periods = self.for(context).sort_by(&:start_date)
    self.periods_json(periods, user)
  end

  def self.periods_json(periods, user)
    periods.map do |period|
      period.as_json_with_user_permissions(user)
    end
  end

  def as_json_with_user_permissions(user)
    as_json(
      only: [:id, :title, :start_date, :end_date],
      permissions: { user: user },
      methods: :is_last
    ).fetch(:grading_period)
  end

  private

  def skip_not_overlapping_validator?
    @_skip_not_overlapping_validator
  end

  scope :overlaps, ->(from, to) do
    # sourced: http://c2.com/cgi/wiki?TestIfDateRangesOverlap
    where('((start_date < ?) and (end_date > ?))', to, from)
  end

  def not_overlapping
    if overlapping?
      errors.add(:base, t('errors.overlap_message',
        "Grading period cannot overlap with existing grading periods in group"))
    end
  end

  def overlaps
    siblings.overlaps(start_date, end_date)
  end

  def siblings
    grading_periods = self.class.where(
      grading_period_group_id: grading_period_group_id
    )
    if new_record?
      grading_periods
    else
      grading_periods.where("id <> ?", id)
    end
  end

  def start_date_is_before_end_date
    if start_date && end_date && end_date < start_date
      errors.add(:end_date, t('errors.invalid_grading_period_end_date',
                              'Grading period end date precedes start date'))
    end
  end
end
