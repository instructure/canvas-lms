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
  include PlannerHelper

  def planner_item_json(item, user, session, opts = {})
    context_data(item, use_effective_code: true).merge({
      :plannable_id => item.id,
      :planner_override => planner_override_json(item.planner_override_for(user), user, session),
      :new_activity => new_activity(item, user, opts)
    }).merge(submission_statuses_for(user, item, opts)).tap do |hash|
      if item.is_a?(::CalendarEvent)
        hash[:plannable_date] = item.start_at || item.created_at
        hash[:plannable_type] = 'calendar_event'
        hash[:plannable] = event_json(item, user, session)
      elsif item.is_a?(::PlannerNote)
        hash[:plannable_date] = item.todo_date || item.created_at
        hash[:plannable_type] = 'planner_note'
        hash[:plannable] = api_json(item, user, session)
        # TODO: We don't currently have an html_url for individual planner items.
        # hash[:html_url] = ???
      elsif item.is_a?(Quizzes::Quiz) || (item.respond_to?(:quiz?) && item.quiz?)
        hash[:plannable_date] = item[:user_due_date] || item.due_at
        quiz = item.is_a?(Quizzes::Quiz) ? item : item.quiz
        hash[:plannable_id] = quiz.id
        hash[:plannable_type] = 'quiz'
        hash[:plannable] = quiz_json(quiz, quiz.context, user, session)
        hash[:html_url] = named_context_url(quiz.context, :context_quiz_url, quiz.id)
        hash[:planner_override] ||= planner_override_json(quiz.planner_override_for(user), user, session)
      elsif item.is_a?(WikiPage) || (item.respond_to?(:wiki_page?) && item.wiki_page?)
        item = item.wiki_page if item.respond_to?(:wiki_page?) && item.wiki_page?
        hash[:plannable_date] = item.todo_date || item.created_at
        hash[:plannable_type] = 'wiki_page'
        hash[:plannable] = wiki_page_json(item, user, session)
        hash[:html_url] = named_context_url(item.context, :context_wiki_page_url, item.id)
        hash[:planner_override] ||= planner_override_json(item.planner_override_for(user), user, session)
      elsif item.is_a?(Announcement)
        hash[:plannable_date] = item.todo_date || item.posted_at || item.created_at
        hash[:plannable_type] = 'announcement'
        hash[:plannable] = discussion_topic_api_json(item.discussion_topic, item.discussion_topic.context, user, session)
        hash[:html_url] = named_context_url(item.discussion_topic.context, :context_discussion_topic_url, item.discussion_topic.id)
      elsif item.is_a?(DiscussionTopic) || (item.respond_to?(:discussion_topic?) && item.discussion_topic?)
        topic = item.is_a?(DiscussionTopic) ? item : item.discussion_topic
        hash[:plannable_id] = topic.id
        hash[:plannable_date] = item[:user_due_date] || topic.todo_date || topic.posted_at || topic.created_at
        hash[:plannable_type] = 'discussion_topic'
        hash[:plannable] = discussion_topic_api_json(topic, topic.context, user, session)
        hash[:html_url] = named_context_url(topic.context, :context_discussion_topic_url, topic.id)
        hash[:planner_override] ||= planner_override_json(topic.planner_override_for(user), user, session)
      else
        hash[:plannable_type] = 'assignment'
        hash[:plannable_date] = item[:user_due_date] || item.due_at
        hash[:plannable] = assignment_json(item, user, session, include_discussion_topic: true)
        hash[:html_url] = named_context_url(item.context, :context_assignment_url, item.id)
      end
    end
  end

  def planner_items_json(items, user, session, opts = {})
    _events, other_items = items.partition{|i| i.is_a?(::CalendarEvent)}
    notes, context_items = other_items.partition{|i| i.is_a?(::PlannerNote)}
    ActiveRecord::Associations::Preloader.new.preload(notes, :user => {:pseudonym => :account}) if notes.any?
    wiki_pages, other_context_items = context_items.partition{|i| i.is_a?(::WikiPage)}
    ActiveRecord::Associations::Preloader.new.preload(wiki_pages, :wiki => [{:course => :root_account}, {:group => :root_account}]) if wiki_pages.any?
    ActiveRecord::Associations::Preloader.new.preload(other_context_items, :context => :root_account) if other_context_items.any?
    items.map do |item|
      planner_item_json(item, user, session, opts)
    end
  end

  def submission_statuses_for(user, item, opts = {})
    submission_status = {submissions: false}
    return submission_status unless item.is_a?(Assignment)
    ss = user.submission_statuses(opts)
    submission_status[:submissions] = {
      submitted: ss[:submitted].include?(item.id),
      excused: ss[:excused].include?(item.id),
      graded: ss[:graded].include?(item.id),
      late: ss[:late].include?(item.id),
      missing: ss[:missing].include?(item.id),
      needs_grading: ss[:needs_grading].include?(item.id),
      has_feedback: ss[:has_feedback].include?(item.id)
    }

    if submission_status[:submissions][:has_feedback]
      relevant_submissions = user.recent_feedback.select {|s| s.assignment_id == item.id}
      ActiveRecord::Associations::Preloader.new.preload(relevant_submissions, [visible_submission_comments: :author])
      feedback_data = relevant_submissions
                      .flat_map(&:visible_submission_comments)
                      .flat_map {|comment| {
                        comment: comment.comment,
                        author_name: comment.author_name,
                        author_avatar_url: comment.author.avatar_url
                      }}
      submission_status[:submissions][:feedback] = feedback_data if feedback_data.present?
    end

    submission_status
  end

  def new_activity(item, user, opts = {})
    if item.is_a?(Assignment) || item.try(:assignment)
      assign = item.try(:assignment) || item
      return true if user.submission_statuses(opts).dig(:new_activity).include?(assign.id)
    end
    if item.is_a?(DiscussionTopic) || item.try(:discussion_topic)
      topic = item.try(:discussion_topic) || item
      return true if topic && (topic.unread?(user) || topic.unread_count(user) > 0)
    end
    false
  end
end
