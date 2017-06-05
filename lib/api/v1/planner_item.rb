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

  def planner_item_json(item, user, session, todo_type)
    context_data(item).merge({
      :type => todo_type,
      :ignore => api_v1_users_todo_ignore_url(item.asset_string, todo_type, :permanent => '0'),
      :ignore_permanently => api_v1_users_todo_ignore_url(item.asset_string, todo_type, :permanent => '1'),
      :visible_in_planner => item.visible_in_planner_for?(user),
      :planner_override => item.planner_override_for(user)
    }).tap do |hash|
      if item.is_a?(PlannerNote)
        hash[:plannable_type] = 'planner_note'
        hash[:plannable] = api_json(item, user, session)
        hash[:html_url] = api_v1_planner_notes_url(item.id)
      elsif item.is_a?(Quizzes::Quiz) || (item.respond_to?(:quiz?) && item.quiz?)
        quiz = item.is_a?(Quizzes::Quiz) ? item : item.quiz
        hash[:plannable_type] = 'quiz'
        hash[:plannable] = quiz_json(quiz, quiz.context, user, session)
        hash[:html_url] = course_quiz_url(quiz.context_id, quiz.id)
      elsif item.is_a?(WikiPage) || (item.respond_to?(:wiki_page?) && item.wiki_page?)
        item = item.wiki_page if item.respond_to?(:wiki_page?) && item.wiki_page?
        hash[:plannable_type] = 'wiki_page'
        hash[:plannable] = wiki_page_json(item, user, session)
        hash[:html_url] = item.url
      elsif item.is_a?(Announcement)
        hash[:plannable_type] = 'announcement'
        hash[:plannable] = discussion_topic_api_json(item.discussion_topic, item.discussion_topic.context, user, session)
        hash[:html_url] = named_context_url(item.discussion_topic.context, :context_discussion_topic_url, item.discussion_topic.id)
      elsif item.is_a?(DiscussionTopic) || (item.respond_to?(:discussion_topic?) && item.discussion_topic?)
        topic = item.is_a?(DiscussionTopic) ? item : item.discussion_topic
        hash[:plannable_type] = 'discussion_topic'
        hash[:plannable] = discussion_topic_api_json(topic, topic.context, user, session)
        hash[:html_url] = named_context_url(topic.context, :context_discussion_topic_url, topic.id)
      else
        hash[:plannable_type] = 'assignment'
        hash[:plannable] = assignment_json(item, user, session, include_discussion_topic: true)
        hash[:html_url] = if todo_type == 'grading'
                            speed_grader_course_gradebook_url(item.context_id, :assignment_id => item.id)
                          else
                            "#{course_assignment_url(item.context_id, item.id)}#submit"
                          end
        hash[:needs_grading_count] = Assignments::NeedsGradingCountQuery.new(item, user).count if todo_type == 'grading'
      end
    end
  end
end
