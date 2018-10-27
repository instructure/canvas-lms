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
  def completed_link_options
    {
      title: I18n.t('tooltips.finished', 'finished')
    }
  end

  def in_progress_link_options
    {
      title: I18n.t('tooltips.incomplete', 'incomplete')
    }
  end

  def multiple_due_dates(assignment)
    # can use this method as the single source of rendering multiple due dates
    # for now, just text, but eventually, a bubble/dialog/link/etc, rendering
    # the information contained in the varied_due_date parameter
    I18n.t '#assignments.multiple_due_dates', 'Multiple Due Dates'
  end

  def student_peer_review_link_for(context, assignment, assessment)
    options = assessment.completed? ? completed_link_options : in_progress_link_options
    icon_class = assessment.completed? ? 'icon-check' : 'icon-warning'
    text = safe_join [
      "<i class='#{icon_class}' aria-hidden='true'></i>".html_safe,
      submission_author_name_for(assessment)
    ]
    href = context_url(context, :context_assignment_submission_url, assignment.id, assessment.asset.user_id)
    link_to text, href, options
  end

  def due_at(assignment, user)
    if assignment.multiple_due_dates_apply_to?(user)
      multiple_due_dates(assignment)
    else
      assignment = assignment.overridden_for(user)
      due_date = assignment.due_at || assignment.applied_overrides.map(&:due_at).compact.first
      due_date ? datetime_string(due_date) : I18n.t('No Due Date')
    end
  end

  def assignment_publishing_enabled?(assignment, user)
    assignment.grants_right?(user, :update)
  end

  def assignment_submission_button(assignment, user, user_submission)
    if assignment.expects_submission? && can_do(assignment, user, :submit)
      submit_text = user_submission.try(:has_submission?) ? I18n.t("Re-submit Assignment") : I18n.t("Submit Assignment")
      late = user_submission.try(:late?) ? "late" : ""
      link_to(submit_text, '#', :role => "button", :class => "Button Button--primary submit_assignment_link #{late}")
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
    number = Float(grade.sub(/%$/, '')) rescue nil
    if number.present?
      if grading_type.nil?
        grading_type = (/%$/ =~ grade) ? 'percent' : 'points'
      end
      if grading_type == 'points' || grading_type == 'percent'
        return I18n.n(round_if_whole(number), percentage: (grading_type == 'percent'))
      end
    end
    grade
  end
end
