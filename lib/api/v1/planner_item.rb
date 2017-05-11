#
# Copyright (C) 2011 Instructure, Inc.
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
      case item
      when Assignment, DiscussionTopic
        assignment = item
        hash[:assignment] = assignment_json(assignment, user, session, include_discussion_topic: true)
        hash[:html_url] = todo_type == 'grading' ?
          speed_grader_course_gradebook_url(assignment.context_id, :assignment_id => assignment.id) :
          "#{course_assignment_url(assignment.context_id, assignment.id)}#submit"

        if todo_type == 'grading'
          hash['needs_grading_count'] = Assignments::NeedsGradingCountQuery.new(assignment, user).count
        end
      when Quizzes::Quiz
        quiz = item
        hash[:quiz] = quiz_json(quiz, quiz.context, user, session)
        hash[:html_url] = course_quiz_url(quiz.context_id, quiz.id)
      when WikiPage
        wiki_page = item
        hash[:wiki_page] = wiki_page_json(wiki_page, user, session)
        hash[:html_url] = wiki_page.url
      when Announcement
        announcement = item
        hash[:announcement] = discussion_topic_api_json(announcement, announcement.context, user, session)
        hash[:html_url] = announcement.topic_pagination_url
      end
    end
  end
end
