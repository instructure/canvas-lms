#
# Copyright (C) 2011 - present Instructure, Inc.
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

class LatePolicy < ActiveRecord::Base
  POINT_DEDUCTIBLE_GRADING_TYPES = %w(points percent letter_grade gpa_scale).freeze

  belongs_to :course, inverse_of: :late_policy

  validates :course_id,
    presence: true,
    uniqueness: true
  validates :late_submission_minimum_percent, :missing_submission_deduction, :late_submission_deduction,
    presence: true,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :late_submission_interval,
    presence: true,
    inclusion: { in: %w(day hour) }

  after_save :update_late_submissions, if: :late_policy_attributes_changed?

  def points_deducted(score: nil, possible: 0.0, late_for: 0.0, grading_type: nil)
    return 0.0 unless late_submission_deduction_enabled && score && possible&.positive? && late_for&.positive?
    return 0.0 unless POINT_DEDUCTIBLE_GRADING_TYPES.include?(grading_type)

    intervals_late = (late_for / interval_seconds).ceil
    minimum_percent = late_submission_minimum_percent_enabled ? late_submission_minimum_percent : 0.0
    raw_score_percent = score * 100.0 / possible
    maximum_deduct = [raw_score_percent - minimum_percent, 0.0].max
    late_percent_deduct = late_submission_deduction * intervals_late
    possible * [late_percent_deduct, maximum_deduct].min / 100
  end

  def missing_points_deducted(points_possible, grading_type)
    return points_possible.to_f if grading_type == 'pass_fail'
    points_possible.to_f * missing_submission_deduction.to_f / 100
  end

  def points_for_missing(points_possible, grading_type)
    points_possible.to_f - missing_points_deducted(points_possible, grading_type)
  end

  private

  def interval_seconds
    { 'hour' => 1.hour, 'day' => 1.day }[late_submission_interval].to_f
  end

  def update_late_submissions
    LatePolicyApplicator.for_course(course)
  end

  def late_policy_attributes_changed?
    (
      [
        'late_submission_deduction_enabled',
        'late_submission_deduction',
        'late_submission_interval',
        'late_submission_minimum_percent_enabled',
        'late_submission_minimum_percent',
        'missing_submission_deduction_enabled'
      ] & saved_changes.keys
    ).present?
  end
end
