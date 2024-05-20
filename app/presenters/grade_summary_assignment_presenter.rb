# frozen_string_literal: true

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
  include GradeDisplay
  attr_reader :assignment, :submission, :originality_reports

  def initialize(summary, current_user, assignment, submission)
    @summary = summary
    @current_user = current_user
    @assignment = assignment
    @submission = submission
    @originality_reports = @submission.originality_reports_for_display if @submission
  end

  def upload_status
    return unless submission

    # The sort here ensures that statuses received are in the failed,
    # pending and success order. With that security we can just pluck
    # first one.
    submission.attachments
              .map { |a| AttachmentUploadStatus.upload_status(a) }
              .min
  end

  def originality_report?
    @originality_reports.present?
  end

  def show_distribution_graph?
    @assignment.score_statistic = @summary.assignment_stats[assignment.id] # Avoid another query
    @assignment.can_view_score_statistics?(@current_user)
  end

  def is_unread?
    (submission.present? ? @summary.unread_submission_ids.include?(submission.id) : false)
  end

  def item_unread?(item)
    submission.present? && !!@summary.unread_submission_items[submission.id]&.include?(item)
  end

  def hide_grade_from_student?
    submission.blank? || submission.hide_grade_from_student?
  end

  def graded?
    return false if submission.blank?

    (submission.grade || submission.excused?) && !hide_grade_from_student?
  end

  def is_letter_graded?
    assignment.grading_type == "letter_grade"
  end

  def is_gpa_scaled?
    assignment.grading_type == "gpa_scale"
  end

  def points_graded?
    assignment.grading_type == "points"
  end

  def is_letter_graded_or_gpa_scaled?
    is_letter_graded? || is_gpa_scaled?
  end

  def is_assignment?
    assignment.instance_of?(Assignment)
  end

  def has_no_group_weight?
    !(assignment.group_weight rescue false)
  end

  def has_no_score_display?
    hide_grade_from_student? || submission.nil?
  end

  def quiz_pending_review?
    submission&.submission_type == "online_quiz" && submission&.workflow_state == "pending_review"
  end

  def custom_grade_status?
    return false unless Account.site_admin.feature_enabled?(:custom_gradebook_statuses)

    submission&.custom_grade_status_id?
  end

  def custom_grade_status_id
    submission&.custom_grade_status_id
  end

  def original_points
    has_no_score_display? ? "" : submission.published_score
  end

  def unchangeable?
    !@summary.editable? || assignment.special_class
  end

  def has_comments?
    submission&.visible_submission_comments && !submission.visible_submission_comments.empty?
  end

  def has_scoring_details?
    return false unless submission&.score.present? && assignment&.points_possible.present?

    assignment.points_possible > 0 && !hide_grade_from_student?
  end

  def has_grade_distribution?
    return false if assignment&.points_possible.blank?

    assignment.points_possible > 0 && !hide_grade_from_student?
  end

  def has_rubric_assessments?
    !rubric_assessments.empty?
  end

  def is_text_entry?
    submission.submission_type == "online_text_entry"
  end

  def is_online_upload?
    submission.submission_type == "online_upload"
  end

  def should_display_details?
    !assignment.special_class && (has_comments? || has_scoring_details?)
  end

  def special_class
    assignment.special_class ? ("hard_coded " + assignment.special_class) : "editable"
  end

  def show_submission_details?
    is_assignment? && !!submission&.can_view_details?(@current_user)
  end

  def classes
    classes = ["student_assignment"]
    classes << "assignment_graded" if graded?
    classes << special_class
    classes << "excused" if excused?
    classes << "extended" if extended?
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

  def extended?
    submission.try(:extended?)
  end

  def deduction_present?
    !!(submission&.points_deducted&.> 0)
  end

  def entered_grade
    if is_letter_graded_or_gpa_scaled? && submission.entered_grade.present?
      "(#{submission.entered_grade})"
    else
      ""
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
      "(#{replace_dash_with_minus(submission.published_grade)})"
    else
      ""
    end
  end

  def display_score
    if has_no_score_display?
      ""
    else
      "#{I18n.n round_if_whole(submission.published_score)} #{published_grade}"
    end
  end

  def turnitin
    plagiarism("turnitin")
  end

  def vericite
    plagiarism("vericite")
  end

  def plagiarism(type)
    plag_data = if type == "vericite"
                  submission.vericite_data(true)
                else
                  submission.originality_data
                end
    t = if is_text_entry?
          plag_data[OriginalityReport.submission_asset_key(submission)] ||
            plag_data[submission.asset_string]
        elsif is_online_upload? && file
          plag_data[file.asset_string]
        end
    t.try(:[], :state) ? t : nil
  end

  def grade_distribution
    @grade_distribution ||= if (stats = @summary.assignment_stats[assignment.id])
                              [stats.maximum, stats.minimum, stats.mean, stats.median, stats.lower_q, stats.upper_q].map { |stat| stat&.to_f&.round(2) }
                            end
  end

  def graph
    @graph ||= begin
      high, low, mean, median, lower_q, upper_q = grade_distribution
      score = submission&.score
      # Just render the old-style fake box-and whiskers plot (box edges are high and low with middle at mean)
      # if flag off or we don't have the new statistics
      GradeSummaryGraph.new(
        high:,
        low:,
        lower_q:,
        upper_q:,
        median:,
        mean:,
        points_possible: assignment.points_possible,
        score:,
        legacy: !show_advanced_statistics?(median)
      )
    end
  end

  def show_advanced_statistics?(median)
    Account.site_admin.feature_enabled?(:enhanced_grade_statistics) && !median.nil?
  end

  def file
    @file ||= submission.attachments.detect { |a| plagiarism_attachment?(a) }
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
    return [] unless submission

    submission.visible_rubric_assessments_for(@current_user)
  end

  def group
    @group ||= assignment&.assignment_group
  end

  def viewing_fake_student?
    @summary.student_enrollment.fake_student?
  end

  FULLWIDTH = 150.0
  GradeSummaryGraph = Struct.new(:high, :low, :lower_q, :upper_q, :median, :mean, :points_possible, :score, :legacy, keyword_init: true) do
    def low_pos
      pixels_for(legacy ? 0 : low)
    end

    def lq_pos
      pixels_for(legacy ? low : lower_q)
    end

    def uq_pos
      pixels_for(legacy ? high : upper_q)
    end

    def median_pos
      pixels_for(legacy ? mean : median)
    end

    def high_pos
      pixels_for(legacy ? points_possible : high)
    end

    def max_pos
      FULLWIDTH
    end

    def score_pos
      pixels_for(score)
    end

    def title
      if legacy
        I18n.t("#grade_summary.graph_title",
               "Mean %{mean}, High %{high}, Low %{low}",
               {
                 mean: I18n.n(mean), high: I18n.n(high), low: I18n.n(low)
               })
      else
        I18n.t("Median %{median}, High %{high}, Low %{low}",
               {
                 median: I18n.n(median), high: I18n.n(high), low: I18n.n(low)
               })
      end
    end

    private

    def pixels_for(value)
      (value.to_f / points_possible * FULLWIDTH)
    end
  end
end
