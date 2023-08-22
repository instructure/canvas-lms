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

module AssignmentsHelper
  include GradeDisplay

  def completed_link_options
    {
      title: I18n.t("tooltips.finished", "finished")
    }
  end

  def in_progress_link_options
    {
      title: I18n.t("tooltips.incomplete", "incomplete")
    }
  end

  def multiple_due_dates
    # can use this method as the single source of rendering multiple due dates
    # for now, just text, but eventually, a bubble/dialog/link/etc, rendering
    # the information contained in the varied_due_date parameter
    I18n.t "#assignments.multiple_due_dates", "Multiple Due Dates"
  end

  def student_peer_review_link_for(context, assignment, assessment)
    options = assessment.completed? ? completed_link_options : in_progress_link_options
    icon_class = assessment.completed? ? "icon-check" : "icon-warning"
    text = safe_join [
      "<i class='#{icon_class}' aria-hidden='true'></i>".html_safe,
      submission_author_name_for(assessment)
    ]
    href = if assignment.anonymous_peer_reviews?
             context_url(context, :context_assignment_anonymous_submission_url, assignment.id, assessment.asset.anonymous_id)
           else
             context_url(context, :context_assignment_submission_url, assignment.id, assessment.asset.user_id)
           end
    link_to text, href, options
  end

  def student_peer_review_url_in_a2_for(context, assignment, assessment)
    query_params = if assignment.anonymous_peer_reviews?
                     { anonymous_asset_id: assessment.asset.anonymous_id }
                   else
                     { reviewee_id: assessment.asset.user_id }
                   end
    context_url(context, :context_assignment_url, { id: assignment.id }.merge(query_params))
  end

  def due_at(assignment, user)
    if assignment.multiple_due_dates_apply_to?(user)
      multiple_due_dates
    else
      assignment = assignment.overridden_for(user)
      due_date = assignment.due_at || assignment.applied_overrides.filter_map(&:due_at).first
      due_date ? datetime_string(due_date) : I18n.t("No Due Date")
    end
  end

  def assignment_publishing_enabled?(assignment, user)
    assignment.grants_right?(user, :update)
  end

  def assignment_submission_button(assignment, user, user_submission, hidden)
    if assignment.expects_submission? && can_do(assignment, user, :submit)
      submit_text = user_submission.try(:has_submission?) ? I18n.t("New Attempt") : I18n.t("Start Assignment")
      late = user_submission.try(:late?) ? "late" : ""
      options = {
        type: "button",
        class: "Button Button--primary submit_assignment_link #{late}",
        disabled: user_submission && user_submission.attempts_left == 0
      }
      options[:style] = "display: none;" if hidden

      content_tag("button", submit_text, options)
    end
  end

  def user_crumb_name
    if @assessment_request
      submission_author_name_for(@assessment_request)
    else
      @user.try_rescue(:short_name)
    end
  end

  def turnitin_active?
    @assignment.turnitin_enabled? && @context.turnitin_enabled? &&
      !@assignment.submission_types.include?("none")
  end

  def vericite_active?
    @assignment.vericite_enabled? && @context.vericite_enabled? &&
      !@assignment.submission_types.include?("none")
  end

  def i18n_grade(grade, grading_type = nil)
    if grading_type == "pass_fail" && %w[complete incomplete].include?(grade)
      return (grade == "complete") ? I18n.t("Complete") : I18n.t("Incomplete")
    end

    number = Float(grade.sub(/%$/, "")) rescue nil
    if number.present?
      if grading_type.nil?
        grading_type = (/%$/ =~ grade) ? "percent" : "points"
      end
      if grading_type == "points" || grading_type == "percent"
        return I18n.n(round_if_whole(number), percentage: (grading_type == "percent"))
      end
    end

    return replace_dash_with_minus(grade) if grading_type == "letter_grade"

    grade
  end
end
