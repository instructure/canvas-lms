# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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
  has_many :submissions, -> { active }
  has_many :auditor_grade_change_records,
    class_name: "Auditors::ActiveRecord::GradeChangeRecord",
    inverse_of: :grading_period

  validates :title, :start_date, :end_date, :close_date, :grading_period_group_id, presence: true
  validates :weight, numericality: true, allow_nil: true
  validate :start_date_is_before_end_date
  validate :close_date_is_on_or_after_end_date
  validate :not_overlapping, unless: :skip_not_overlapping_validator?

  before_validation :adjust_close_date_for_course_period
  before_validation :ensure_close_date

  before_save :set_root_account_id
  after_save :recompute_scores, if: :dates_or_weight_or_workflow_state_changed?
  after_destroy :destroy_grading_period_set, if: :last_remaining_legacy_period?
  after_destroy :destroy_scores
  scope :current, -> do
    now = Time.zone.now.change(sec: 0)
    where(
      "date_trunc('minute', grading_periods.end_date) >= ? AND date_trunc('minute', grading_periods.start_date) < ?",
      now,
      now
    )
  end

  scope :closed, -> { where("grading_periods.close_date < ?", Time.zone.now) }
  scope :open, -> { where("grading_periods.close_date IS NULL OR grading_periods.close_date >= ?", Time.zone.now) }

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

  def assignments_for_student(course, assignments, student)
    assignment_ids = GradebookGradingPeriodAssignments.new(course, student: student).to_h.fetch(id, [])
    if assignment_ids.empty?
      []
    else
      assignments.select { |assignment| assignment_ids.include?(assignment.id.to_s) }
    end
  end

  def assignments(course, assignments)
    assignment_ids = GradebookGradingPeriodAssignments.new(course).to_h.fetch(id, [])
    if assignment_ids.empty?
      []
    else
      assignments.select { |assignment| assignment_ids.include?(assignment.id.to_s) }
    end
  end

  def current?
    in_date_range?(Time.zone.now)
  end

  def in_date_range?(date)
    comparison_date = date_for_comparison(date)
    date_for_comparison(start_date) < comparison_date && comparison_date <= date_for_comparison(end_date)
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

  def disable_post_to_sis
    raise(RangeError, "The grading period is not yet closed.") if Time.zone.now < close_date
    # This method is called from a job, to know if it is already processed we
    # cache that the job has processed.
    # If the look_back in the job is changed, the amount of time we cache needs
    # to also follow, so using the same setting.
    look_back = Setting.get('disable_post_to_sis_on_grading_period', '60').to_i + 10
    due_at_range = start_date..end_date
    Rails.cache.fetch(['disable_post_to_sis_in_completed', self].cache_key, expires_in: look_back.minutes) do
      possible_assignments_scope = Assignment.active.
        where(root_account_id: root_account_id, post_to_sis: true)
      scope = possible_assignments_scope.
        where(due_at: due_at_range).
        union(possible_assignments_scope.where("EXISTS (?)",
          AssignmentOverride.active.
            where("assignment_id = assignments.id").
            where(set_type: "CourseSection", due_at_overridden: true, due_at: due_at_range)))
      # until all post_to_sis in scope are false, repeat.
      while scope.limit(1_000).update_all(post_to_sis: false, updated_at: Time.zone.now) == 1_000 do; end
      # caching that it has completed, so if this gets called again, it can skip.
      true
    end
  end

  private

  def set_root_account_id
    self.root_account_id ||= grading_period_group&.root_account_id
  end

  def date_for_comparison(date)
    comparison_date = date.is_a?(String) ? Time.zone.parse(date) : date
    comparison_date&.change(sec: 0)
  end

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
    where(
      "((date_trunc('minute', end_date) > ?) and (date_trunc('minute', start_date) < ?))",
      from&.change(sec: 0),
      to&.change(sec: 0)
    )
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
    dates_or_workflow_state_changed = time_boundaries_changed? || saved_change_to_workflow_state?

    if course_group?
      course = grading_period_group.course
      course.recompute_student_scores(update_all_grading_period_scores: dates_or_workflow_state_changed)
      DueDateCacher.recompute_course(course) if dates_or_workflow_state_changed
    else
      grading_period_group.recompute_scores_for_each_term(dates_or_workflow_state_changed)
    end
  end

  def weight_actually_changed?
    grading_period_group.weighted && saved_change_to_weight?
  end

  def time_boundaries_changed?
    saved_change_to_start_date? || saved_change_to_end_date?
  end

  def dates_or_weight_or_workflow_state_changed?
    time_boundaries_changed? || weight_actually_changed? || saved_change_to_workflow_state?
  end
end
