#
# Copyright (C) 2015 - 2016 Instructure, Inc.
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

  belongs_to :grading_period_group, inverse_of: :grading_periods
  has_many :scores, -> { active }

  validates :title, :start_date, :end_date, :close_date, :grading_period_group_id, presence: true
  validates :weight, numericality: true, allow_nil: true
  validate :start_date_is_before_end_date
  validate :close_date_is_on_or_after_end_date
  validate :not_overlapping, unless: :skip_not_overlapping_validator?

  before_validation :adjust_close_date_for_course_period
  before_validation :ensure_close_date

  after_save :recompute_scores, if: :dates_or_weight_changed?
  after_destroy :destroy_grading_period_set, if: :last_remaining_legacy_period?
  after_destroy :destroy_scores

  scope :current, -> do
    period_table = GradingPeriod.arel_table
    now = Time.zone.now
    where(period_table[:start_date].lt(now)).
      where(period_table[:end_date].gteq(now))
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

  def self.date_in_closed_grading_period?(course:, date:, periods: nil)
    period = self.for_date_in_course(date: date, course: course, periods: periods)
    period.present? && period.closed?
  end

  def self.for_date_in_course(date:, course:, periods: nil)
    periods ||= self.for(course)

    if date.nil?
      return periods.sort_by(&:end_date).last
    else
      periods.detect { |p| p.in_date_range?(date) }
    end
  end

  def self.for(context, inherit: true)
    grading_periods = context.grading_periods.active
    if context.is_a?(Course) && inherit && grading_periods.empty?
      context.enrollment_term.grading_periods.active
    else
      grading_periods
    end
  end

  def self.current_period_for(context)
    self.for(context).find(&:current?)
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
    start_date < date && date <= end_date
  end

  def last?
    # should never be nil, because self is part of the potential set
    @last_period ||= grading_period_group
      .grading_periods
      .active
      .order(end_date: :desc)
      .first
    @last_period == self
  end
  alias_method :is_last, :last?

  def closed?
    Time.zone.now > close_date
  end
  alias_method :is_closed, :closed?

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
      only: [:id, :title, :start_date, :end_date, :close_date, :weight],
      permissions: { user: user },
      methods: [:is_last, :is_closed],
    ).fetch(:grading_period)
  end

  private

  def destroy_scores
    scores.find_ids_in_ranges do |min_id, max_id|
      scores.where(id: min_id..max_id).update_all(workflow_state: :deleted)
    end
  end

  def destroy_grading_period_set
    grading_period_group.destroy
  end

  def last_remaining_legacy_period?
    course_group? && grading_period_group.active? && siblings.active.empty?
  end

  def skip_not_overlapping_validator?
    @_skip_not_overlapping_validator
  end

  scope :overlaps, ->(from, to) do
    # sourced: http://c2.com/cgi/wiki?TestIfDateRangesOverlap
    where('((end_date > ?) and (start_date < ?))', from, to)
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
      errors.add(:end_date, t('must be after start date'))
    end
  end

  def adjust_close_date_for_course_period
    self.close_date = end_date if grading_period_group.present? && course_group?
  end

  def ensure_close_date
    self.close_date ||= end_date
  end

  def close_date_is_on_or_after_end_date
    if close_date.present? && end_date.present? && close_date < end_date
      errors.add(:close_date, t('must be on or after end date'))
    end
  end

  def recompute_scores
    if course_group?
      courses = [grading_period_group.course]
    else
      term_ids = grading_period_group.enrollment_terms.pluck(:id)
      courses = Course.active.where(enrollment_term_id: term_ids)
    end

    courses.each do |course|
      course.recompute_student_scores(
        # different assignments could fall in this period if time
        # boundaries changed so we need to recalculate scores.
        # otherwise, weight must have changed, in which case we
        # do not need to recompute the grading period scores (we
        # only need to recompute the overall course score)
        grading_period_id: time_boundaries_changed? ? id : nil,
        update_all_grading_period_scores: false
      )
    end
  end

  def weight_actually_changed?
    grading_period_group.weighted && weight_changed?
  end

  def time_boundaries_changed?
    start_date_changed? || end_date_changed?
  end

  def dates_or_weight_changed?
    time_boundaries_changed? || weight_actually_changed?
  end
end
