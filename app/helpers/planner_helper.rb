#
# Copyright (C) 2017 - present Instructure, Inc.
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


module PlannerHelper
  PLANNABLE_TYPES = {
    'discussion_topic' => 'DiscussionTopic',
    'announcement' => 'Announcement',
    'quiz' => 'Quizzes::Quiz',
    'assignment' => 'Assignment',
    'wiki_page' => 'WikiPage',
    'planner_note' => 'PlannerNote',
    'calendar_event' => 'CalendarEvent',
    'assessment_request' => 'AssessmentRequest'
  }.freeze

  class InvalidDates < StandardError; end

  def planner_meta_cache_key
    ['planner_items_meta', @current_user].cache_key
  end

  def formatted_planner_date(input, val, default = nil, end_of_day: false)
    @errors ||= {}
    if val.present? && val.is_a?(String)
      if val =~ Api::DATE_REGEX
        if end_of_day
          Time.zone.parse(val).end_of_day
        else
          Time.zone.parse(val).beginning_of_day
        end
      elsif val =~ Api::ISO8601_REGEX
        Time.zone.parse(val)
      else
        raise(InvalidDates, I18n.t("Invalid date or datetime for %{field}", field: input))
      end
    else
      default
    end
  end

  def require_planner_enabled
    render json: { message: "Feature disabled" }, status: :forbidden unless @domain_root_account.feature_enabled?(:student_planner)
  end

  def sync_module_requirement_done(item, user, complete)
    return unless item.is_a?(ContextModuleItem)
    doneable = mark_doneable_tag(item)
    return unless doneable
    if complete
      doneable.context_module_action(user, :done)
    else
      progression = doneable.progression_for_user(user)
      if progression&.requirements_met&.find {|req| req[:id] == doneable.id && req[:type] == "must_mark_done" }
        progression.uncomplete_requirement(doneable.id)
        progression.evaluate
      end
    end
  end

  def sync_planner_completion(item, user, complete)
    return unless item.is_a?(ContextModuleItem) && item.is_a?(Plannable)
    return unless mark_doneable_tag(item)
    planner_override = PlannerOverride.where(user: user, plannable_id: item.id,
                                             plannable_type: item.class.to_s).first_or_create
    planner_override.marked_complete = complete
    planner_override.dismissed = complete
    planner_override.save
    Rails.cache.delete(planner_meta_cache_key)
    planner_override
  end

  # Handles real Submissions associated with graded things
  def complete_planner_override_for_submission(submission)
    planner_override = find_planner_override_for_submission(submission)
    complete_planner_override planner_override
  end

  # Ungraded surveys are submitted as a Quizzes::QuizSubmission that
  # had no submission attribute pointing to a real Submission
  def complete_planner_override_for_quiz_submission(quiz_submission)
    return if quiz_submission.submission # handled by Submission model
    planner_override = PlannerOverride.find_by(
      plannable_id: quiz_submission.quiz_id,
      plannable_type: PLANNABLE_TYPES['quiz'],
      user_id: quiz_submission.user_id
    )
    if planner_override
      complete_planner_override planner_override
    else
      planner_override = PlannerOverride.new(
        plannable_type: PLANNABLE_TYPES['quiz'],
        plannable_id: quiz_submission.quiz_id, 
        marked_complete: true,
        dismissed: false,
        user_id: quiz_submission.user_id)
      planner_override.save
    end
  end

  def complete_planner_override(planner_override)
    if planner_override&.is_a? PlannerOverride
      planner_override.marked_complete = true
      if planner_override.save
        Rails.cache.delete(planner_meta_cache_key)
      end
    end
  end

  private
  def mark_doneable_tag(item)
    doneable_tags = item.context_module_tags.select do |tag|
      tag.context_module.completion_requirements.find do |req|
        req[:id] == tag.id && req[:type] == "must_mark_done"
      end
    end
    doneable_tags.length == 1 ? doneable_tags.first : nil
  end

  # until the graded objects are handled more uniformly,
  # we have to look around for an associated override
  def find_planner_override_for_submission(submission)
    return unless submission&.respond_to?(:submission_type) && submission&.respond_to?(:assignment_id)

    planner_override = case submission.submission_type
      when "discussion_topic"
        discussion_topic_id = DiscussionTopic.find_by(assignment_id: submission.assignment_id)&.id
        PlannerOverride.find_by(
          plannable_id: discussion_topic_id,
          plannable_type: PLANNABLE_TYPES['discussion_topic'],
          user_id: submission.user_id
        )
      when "online_quiz"
        quiz_id = Quizzes::Quiz.find_by(assignment_id: submission.assignment_id)&.id
        PlannerOverride.find_by(
          plannable_id: quiz_id,
          plannable_type: PLANNABLE_TYPES['quiz'],
          user_id: submission.user_id
        )
    end
    planner_override ||= PlannerOverride.find_by(
      plannable_id: submission.assignment_id,
      plannable_type: PLANNABLE_TYPES['assignment'],
      user_id: submission.user_id
    )
    planner_override
  end
end
