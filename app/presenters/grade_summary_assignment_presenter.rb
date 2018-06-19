#
# Copyright (C) 2013 - present Instructure, Inc.
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

class GradeSummaryAssignmentPresenter
  include TextHelper
  attr_reader :assignment, :submission, :originality_reports

  def initialize(summary, current_user, assignment, submission)
    @summary = summary
    @current_user = current_user
    @assignment = assignment
    @submission = submission
    @originality_reports = @submission.originality_reports_for_display if @submission
  end

  def originality_report?
    @originality_reports.present?
  end

  def hide_distribution_graphs?
    submission_count = @summary.assignment_stats[assignment.id]&.count || 0
    submission_count < 5 || assignment.context.hide_distribution_graphs?
  end

  def is_unread?
    (submission.present? ? @summary.unread_submission_ids.include?(submission.id) : false)
  end

  def graded?
    submission &&
      (submission.grade || submission.excused?) &&
      !assignment.muted?
  end

  def is_letter_graded?
    assignment.grading_type == 'letter_grade'
  end

  def is_gpa_scaled?
    assignment.grading_type == 'gpa_scale'
  end

  def is_letter_graded_or_gpa_scaled?
    is_letter_graded? || is_gpa_scaled?
  end

  def is_assignment?
    assignment.class.to_s == "Assignment"
  end

  def has_no_group_weight?
    !(assignment.group_weight rescue false)
  end

  def has_no_score_display?
    assignment.muted? || submission.nil?
  end

  def original_points
    has_no_score_display? ? '' : submission.published_score
  end

  def unchangeable?
    (!@summary.editable? || assignment.special_class)
  end

  def has_comments?
    submission && submission.visible_submission_comments && !submission.visible_submission_comments.empty?
  end

  def has_scoring_details?
    submission && submission.score && assignment.points_possible && assignment.points_possible > 0 && !assignment.muted?
  end

  def has_grade_distribution?
    assignment && assignment.points_possible && assignment.points_possible > 0 && !assignment.muted?
  end

  def has_rubric_assessments?
    !rubric_assessments.empty?
  end

  def is_text_entry?
    submission.submission_type == 'online_text_entry'
  end

  def is_online_upload?
    submission.submission_type == 'online_upload'
  end

  def should_display_details?
    !assignment.special_class && (has_comments? || has_scoring_details?)
  end

  def special_class
    assignment.special_class ? ("hard_coded " + assignment.special_class) : "editable"
  end

  def classes
    classes = ["student_assignment"]
    classes << "assignment_graded" if graded?
    classes << special_class
    classes << "excused" if excused?
    classes.join(" ")
  end

  def missing?
    submission.try(:missing?)
  end

  def late?
    submission.try(:late?)
  end

  def excused?
    submission.try(:excused?)
  end

  def deduction_present?
    !!(submission&.points_deducted&.> 0)
  end

  def entered_grade
    if is_letter_graded_or_gpa_scaled? && submission.entered_grade.present?
      "(#{submission.entered_grade})"
    else
      ''
    end
  end

  def display_entered_score
    "#{I18n.n round_if_whole(submission.entered_score)} #{entered_grade}"
  end

  def display_points_deducted
    I18n.n round_if_whole(-submission.points_deducted)
  end

  def published_grade
    if is_letter_graded_or_gpa_scaled? && !submission.published_grade.nil?
      "(#{submission.published_grade})"
    else
      ''
    end
  end

  def display_score
    if has_no_score_display?
      ''
    else
      "#{I18n.n round_if_whole(submission.published_score)} #{published_grade}"
    end
  end

  def turnitin
    plagiarism('turnitin')
  end

  def vericite
    plagiarism('vericite')
  end

  def plagiarism(type)
    if type == 'vericite'
      plag_data = submission.vericite_data(true)
    else
      plag_data = submission.originality_data
    end
    t = if is_text_entry?
          plag_data[submission.asset_string]
        elsif is_online_upload? && file
          plag_data[file.asset_string]
        end
    t.try(:[], :state) ? t : nil
  end

  def grade_distribution
    @grade_distribution ||= begin
      if stats = @summary.assignment_stats[assignment.id]
        [stats.maximum, stats.minimum, stats.mean].map { |stat| stat.to_f.round(1) }
      end
    end
  end

  def graph
    @graph ||= begin
      high, low, mean = grade_distribution
      score = submission && submission.score
      GradeSummaryGraph.new(high, low, mean, assignment.points_possible, score)
    end
  end

  def file
    @file ||= submission.attachments.detect{|a| plagiarism_attachment?(a) }
  end

  def plagiarism_attachment?(a)
    @originality_reports.any? { |o| o.attachment == a } ||
    (submission.turnitin_data && submission.turnitin_data[a.asset_string]).present? ||
    (submission.vericite_data(true) && submission.vericite_data(true)[a.asset_string]).present?
  end

  def comments
    submission.visible_submission_comments
  end

  def rubric_assessments
    @visible_rubric_assessments ||= begin
      if submission && !assignment.muted?
        assessments = submission.rubric_assessments.select { |a| a.grants_right?(@current_user, :read) }
        assessments.sort_by { |a| [a.assessment_type == 'grading' ? CanvasSort::First : CanvasSort::Last, a.assessor_name] }
      else
        []
      end
    end
  end

  def group
    @group ||= assignment && assignment.assignment_group
  end

  def viewing_fake_student?
    @summary.student_enrollment.fake_student?
  end
end


class GradeSummaryGraph
  FULLWIDTH = 150.0

  def initialize(high, low, mean, points_possible, score)
    @high = high.to_f
    @mean = mean.to_f
    @low = low.to_f
    @points_possible = points_possible.to_f
    @score = score
  end

  def low_width
    pixels_for(@low)
  end

  def high_left
    pixels_for(@high)
  end

  def high_width
    pixels_for(@points_possible - @high)
  end

  def mean_left
    pixels_for(@mean)
  end

  def mean_low_width
    pixels_for(@mean - @low)
  end

  def mean_high_width
    pixels_for(@high - @mean)
  end

  def max_left
    [FULLWIDTH.round, (pixels_for(@high) + 3)].max
  end

  def score_left
    pixels_for(@score) - 5
  end

  def title
    I18n.t('#grade_summary.graph_title', "Mean %{mean}, High %{high}, Low %{low}", {
      mean: I18n.n(@mean), high: I18n.n(@high), low: I18n.n(@low)
    })
  end

  private
  def pixels_for(value)
    (value.to_f / @points_possible * FULLWIDTH).round
  end
end
