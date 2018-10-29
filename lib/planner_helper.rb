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

  def self.planner_meta_cache_key(user)
    ['planner_items_meta', user].cache_key
  end

  def self.get_planner_cache_id(user)
    Rails.cache.fetch(planner_meta_cache_key(user), expires_in: 1.week) do
      SecureRandom.uuid
    end
  end

  def self.clear_planner_cache(user)
    Rails.cache.delete(planner_meta_cache_key(user))
  end

  # Handles real Submissions associated with graded things
  def self.complete_planner_override_for_submission(submission)
    planner_override = find_planner_override_for_submission(submission)
    complete_planner_override planner_override
  end

  # Ungraded surveys are submitted as a Quizzes::QuizSubmission that
  # had no submission attribute pointing to a real Submission
  def self.complete_planner_override_for_quiz_submission(quiz_submission)
    return if quiz_submission.submission # handled by Submission model
    planner_override = PlannerOverride.find_or_create_by(
      plannable_id: quiz_submission.quiz_id,
      plannable_type: PLANNABLE_TYPES['quiz'],
      user_id: quiz_submission.user_id
    )
    complete_planner_override planner_override
  end

  def self.complete_planner_override(planner_override)
    return unless planner_override.is_a? PlannerOverride
    planner_override.update_attributes(marked_complete: true)
    clear_planner_cache(planner_override&.user)
  end

  private

  # until the graded objects are handled more uniformly,
  # we have to look around for an associated override
  def self.find_planner_override_for_submission(submission)
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
