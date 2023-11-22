# frozen_string_literal: true

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

module GradebooksHelper
  def anonymous_survey?(assignment)
    !!assignment.quiz&.anonymous_survey?
  end

  def force_anonymous_grading?(assignment)
    anonymous_survey?(assignment) || assignment.anonymize_students?
  end

  def force_anonymous_grading_reason(assignment)
    if anonymous_survey?(assignment)
      I18n.t("Student names must be hidden because this is an anonymous survey.")
    elsif assignment.anonymize_students?
      I18n.t("Student names must be hidden because anonymous grading is required.")
    else
      ""
    end
  end

  def ungraded_submission_icon_attributes_for(submission_type, is_new_quizzes: false)
    if is_new_quizzes
      return {
        icon_class: "icon-quiz icon-Solid",
        screenreader_text: I18n.t("New Quizzes Submission")
      }
    end

    case submission_type
    when "online_url"
      {
        icon_class: "icon-link",
        screenreader_text: I18n.t("icons.online_url_submission", "Online Url Submission")
      }
    when "online_text_entry"
      {
        icon_class: "icon-text",
        screenreader_text: I18n.t("icons.text_entry_submission", "Text Entry Submission")
      }
    when "online_upload"
      {
        icon_class: "icon-document",
        screenreader_text: I18n.t("icons.file_upload_submission", "File Upload Submission")
      }
    when "discussion_topic"
      {
        icon_class: "icon-discussion",
        screenreader_text: I18n.t("icons.discussion_submission", "Discussion Submission")
      }
    when "online_quiz"
      {
        icon_class: "icon-quiz",
        screenreader_text: I18n.t("icons.quiz_submission", "Quiz Submission")
      }
    when "media_recording"
      {
        icon_class: "icon-filmstrip",
        screenreader_text: I18n.t("icons.media_submission", "Media Submission")
      }
    when "student_annotation"
      {
        icon_class: "icon-annotate",
        screenreader_text: I18n.t("Student Annotation")
      }
    end
  end

  def pass_icon_attributes
    {
      icon_class: "icon-check",
      screenreader_text: I18n.t("#gradebooks.grades.complete", "Complete"),
    }
  end

  def fail_icon_attributes
    {
      icon_class: "icon-x",
      screenreader_text: I18n.t("#gradebooks.grades.incomplete", "Incomplete"),
    }
  end

  def display_grade(grade)
    grade.presence || "-"
  end

  def graded_by_title(graded_at, grader_name)
    I18n.t(
      "%{graded_date} by %{grader}",
      graded_date: date_string(graded_at),
      grader: grader_name
    )
  end

  def history_submission_class(submission)
    "assignment_#{submission.assignment_id}_user_#{submission.user_id}_current_grade"
  end

  def student_score_display_for(submission, show_student_view = false)
    return "-" if submission.blank?

    score, grade = if show_student_view
                     [submission.published_score, submission.published_grade]
                   else
                     [submission.score, submission.grade]
                   end

    if submission.try(:excused?)
      "EX"
    elsif submission && grade && submission.workflow_state != "pending_review"
      graded_submission_display(grade, score, submission.assignment.grading_type)
    elsif submission.submission_type
      ungraded_submission_display(
        submission.submission_type,
        is_new_quizzes: submission.cached_quiz_lti
      )
    else
      "-"
    end
  end

  def graded_submission_display(grade, score, grading_type)
    case grading_type
    when "pass_fail"
      pass_fail_icon(score, grade)
    when "percent"
      if grade.nil?
        "-"
      else
        I18n.n grade.to_f, percentage: true
      end
    when "points"
      I18n.n round_if_whole(score.to_f.round(2))
    when "gpa_scale", "letter_grade"
      nil
    end
  end

  def ungraded_submission_display(submission_type, is_new_quizzes: false)
    sub_score = ungraded_submission_icon_attributes_for(submission_type, is_new_quizzes:)
    if sub_score
      screenreadable_icon(sub_score, %w[submission_icon])
    else
      "-"
    end
  end

  def pass_fail_icon(score, grade)
    icon_attrs = if (score && score > 0) || grade == "complete"
                   pass_icon_attributes
                 else
                   fail_icon_attributes
                 end
    screenreadable_icon(icon_attrs, %w[graded_icon])
  end

  def screenreadable_icon(icon_attrs, html_classes = [])
    html_classes << icon_attrs[:icon_class]
    content_tag("i", "", "class" => html_classes.join(" "), "aria-hidden" => true) +
      content_tag("span", icon_attrs[:screenreader_text], "class" => "screenreader-only")
  end

  def translated_due_date_for_speedgrader(assignment)
    return I18n.t("Due: Multiple Due Dates") if assignment.multiple_due_dates_apply_to?(@current_user)

    assignment = assignment.overridden_for(@current_user)

    if assignment.due_at
      return I18n.t("Due: %{assignment_due_date_time}", assignment_due_date_time: datetime_string(force_zone(assignment.due_at)))
    end

    override_dates = if assignment.only_visible_to_overrides?
                       assignment.active_assignment_overrides.where(due_at_overridden: true).pluck(:due_at).uniq
                     else
                       []
                     end

    if override_dates.count == 1
      I18n.t("Due: %{assignment_due_date_time}", assignment_due_date_time: datetime_string(force_zone(override_dates.first)))
    else
      I18n.t("Due: No Due Date")
    end
  end

  def show_message_students_with_observers_dialog?
    Account.site_admin.feature_enabled?(:message_observers_of_students_who)
  end

  # EVAL-3711 Remove ICE Evaluate feature flag
  def instui_nav?
    @context.root_account.feature_enabled?(:instui_nav)
  end
end
