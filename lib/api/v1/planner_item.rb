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

module Api::V1::PlannerItem
  include Api::V1::Json
  include Api::V1::Assignment
  include Api::V1::Quiz
  include Api::V1::Context
  include Api::V1::DiscussionTopics
  include Api::V1::WikiPage
  include Api::V1::PlannerOverride
  include Api::V1::CalendarEvent
  include Api::V1::PlannerNote
  include PlannerHelper

  def planner_item_json(item, user, session, opts = {})
    context_data(item, use_effective_code: true).merge({
      :plannable_id => item.id,
      :planner_override => planner_override_json(item.planner_override_for(user), user, session),
      :new_activity => new_activity(item, user, opts)
    }).merge(submission_statuses_for(user, item, opts)).tap do |hash|
      assignment_opts = {exclude_response_fields: ['rubric']}
      if item.is_a?(::CalendarEvent)
        hash[:plannable_date] = item.start_at || item.created_at
        hash[:plannable_type] = 'calendar_event'
        hash[:plannable] = event_json(item, user, session)
      elsif item.is_a?(::PlannerNote)
        hash[:plannable_date] = item.todo_date || item.created_at
        hash[:plannable_type] = 'planner_note'
        hash[:plannable] = planner_note_json(item, user, session)
        # TODO: We don't currently have an html_url for individual planner items.
        # hash[:html_url] = ???
      elsif item.is_a?(Quizzes::Quiz) || (item.respond_to?(:quiz?) && item.quiz?)
        hash[:plannable_date] = item[:user_due_date] || item.due_at
        quiz = item.is_a?(Quizzes::Quiz) ? item : item.quiz
        hash[:plannable_id] = quiz.id
        hash[:plannable_type] = 'quiz'
        hash[:plannable] = quiz_json(quiz, quiz.context, user, session, skip_permissions: true)
        hash[:html_url] = named_context_url(quiz.context, :context_quiz_url, quiz.id)
        hash[:planner_override] ||= planner_override_json(quiz.planner_override_for(user), user, session)
      elsif item.is_a?(WikiPage) || (item.respond_to?(:wiki_page?) && item.wiki_page?)
        item = item.wiki_page if item.respond_to?(:wiki_page?) && item.wiki_page?
        hash[:plannable_date] = item.todo_date || item.created_at
        hash[:plannable_type] = 'wiki_page'
        hash[:plannable] = wiki_page_json(item, user, session, false, assignment_opts: assignment_opts)
        hash[:html_url] = named_context_url(item.context, :context_wiki_page_url, item.url)
        hash[:planner_override] ||= planner_override_json(item.planner_override_for(user), user, session)
      elsif item.is_a?(Announcement)
        hash[:plannable_date] = item.posted_at || item.created_at
        hash[:plannable_type] = 'announcement'
        hash[:plannable] = discussion_topic_api_json(item, item.context, user, session, use_preload: true, user_can_moderate: false, skip_permissions: true)
        hash[:html_url] = named_context_url(item.context, :context_discussion_topic_url, item.id)
      elsif item.is_a?(DiscussionTopic) || (item.respond_to?(:discussion_topic?) && item.discussion_topic?)
        topic = item.is_a?(DiscussionTopic) ? item : item.discussion_topic
        hash[:plannable_id] = topic.id
        hash[:plannable_date] = item[:user_due_date] || topic.todo_date || topic.posted_at || topic.created_at
        hash[:plannable_type] = 'discussion_topic'
        hash[:plannable] = discussion_topic_api_json(topic, topic.context, user, session, assignment_opts: assignment_opts, use_preload: true, user_can_moderate: false, skip_permissions: true)
        hash[:html_url] = discussion_topic_html_url(topic, user, hash[:submissions])
        hash[:planner_override] ||= planner_override_json(topic.planner_override_for(user), user, session)
      else
        hash[:plannable_type] = 'assignment'
        hash[:plannable_date] = item[:user_due_date] || item.due_at
        hash[:plannable] = assignment_json(item, user, session, {include_discussion_topic: true}.merge(assignment_opts))
        hash[:html_url] = assignment_html_url(item, user, hash[:submissions])
      end
    end
  end

  def planner_items_json(items, user, session, opts = {})
    preload_items = items.map do |i|
      if i.try(:wiki_page?)
        i.wiki_page
      elsif i.try(:discussion_topic?)
        i.discussion_topic
      elsif i.try(:quiz?)
        i.quiz
      else
        i
      end
    end
    ActiveRecord::Associations::Preloader.new.preload(preload_items, :planner_overrides, ::PlannerOverride.where(user: user))
    events, other_items = preload_items.partition{|i| i.is_a?(::CalendarEvent)}
    ActiveRecord::Associations::Preloader.new.preload(events, :context) if events.any?
    notes, context_items = other_items.partition{|i| i.is_a?(::PlannerNote)}
    ActiveRecord::Associations::Preloader.new.preload(notes, user: {pseudonym: :account}) if notes.any?
    wiki_pages, other_context_items = context_items.partition{|i| i.is_a?(::WikiPage)}
    ActiveRecord::Associations::Preloader.new.preload(wiki_pages, {context: :root_account}) if wiki_pages.any?
    ActiveRecord::Associations::Preloader.new.preload(other_context_items, {context: :root_account}) if other_context_items.any?
    ss = user.submission_statuses(opts)
    discussions, _assign_quiz_items = other_context_items.partition{|i| i.is_a?(::DiscussionTopic)}
    ActiveRecord::Associations::Preloader.new.preload(discussions, :discussion_topic_participants, DiscussionTopicParticipant.where(user: user))
    items.map do |item|
      planner_item_json(item, user, session, opts.merge(submission_statuses: ss))
    end
  end

  def submission_statuses_for(user, item, opts = {})
    submission_status = {submissions: false}
    return submission_status unless item.is_a?(Assignment)
    ss = opts[:submission_statuses] || user.submission_statuses(opts)
    submission_status[:submissions] = {
      submitted: ss[:submitted].include?(item.id),
      excused: ss[:excused].include?(item.id),
      graded: ss[:graded].include?(item.id),
      late: ss[:late].include?(item.id),
      missing: ss[:missing].include?(item.id),
      needs_grading: ss[:needs_grading].include?(item.id),
      has_feedback: ss[:has_feedback].include?(item.id)
    }

    # planner will display the most recent comment not made by the user herself
    if submission_status[:submissions][:has_feedback]
      relevant_submissions = user.recent_feedback.select {|s| s.assignment_id == item.id}
      ActiveRecord::Associations::Preloader.new.preload(relevant_submissions, [visible_submission_comments: :author])
      feedback_data = relevant_submissions.
        flat_map(&:visible_submission_comments).
        reject{|comment| comment.author_id == user.id}. # omit comments by the user's own self
        sort_by(&:updated_at).
        last

      if feedback_data.present?
        submission_status[:submissions][:feedback] = {
          comment: feedback_data.comment,
          author_name: feedback_data.author_name,
          author_avatar_url: feedback_data.author.avatar_url,
          is_media: feedback_data.media_comment_id?
        }
      end
    end

    submission_status
  end

  def new_activity(item, user, opts = {})
    if item.is_a?(Assignment) || item.try(:assignment)
      ss = opts[:submission_statuses] || user.submission_statuses(opts)
      assign = item.try(:assignment) || item
      return true if ss.dig(:new_activity).include?(assign.id)
    end
    if item.is_a?(DiscussionTopic) || item.try(:discussion_topic)
      topic = item.try(:discussion_topic) || item
      return true if topic && (topic.unread?(user) || topic.unread_count(user) > 0)
    end
    false
  end

  private

  def assignment_feedback_url(assignment, user, submission_info)
    return nil unless assignment
    return nil unless submission_info
    return nil unless submission_info[:submitted] || submission_info[:graded] || submission_info[:has_feedback]
    context_url(assignment.context, :context_assignment_submission_url, assignment.id, user.id)
  end

  def assignment_html_url(assignment, user, submission_info)
    assignment_feedback_url(assignment, user, submission_info) || named_context_url(assignment.context, :context_assignment_url, assignment.id)
  end

  def discussion_topic_html_url(topic, user, submission_info)
    assignment_feedback_url(topic.assignment, user, submission_info) || named_context_url(topic.context, :context_discussion_topic_url, topic.id)
  end
end
