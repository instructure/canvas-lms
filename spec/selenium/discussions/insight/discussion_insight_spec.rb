# frozen_string_literal: true

# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../../common"

describe "Discussion Insight" do
  include_context "in-process server selenium tests"

  context "when Discussion Insight is enabled" do
    before :once do
      Account.site_admin.enable_feature!(:react_discussions_post)
      Account.default.enable_feature!(:discussion_insights)
    end

    before do
      course_with_teacher(active_course: true, active_all: true, name: "teacher")
      @topic_title = "Our Discussion Topic with Insight"
      @topic = @course.discussion_topics.create!(
        title: @topic_title,
        message: "This is a test topic",
        posted_at: "2025-04-07 11:00:00",
        user: @teacher
      )
    end

    it "should not display the insight button for a student" do
      @student = student_in_course(course: @course, name: "Jeff", active_all: true).user
      user_session(@student)
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      expect(f("body")).not_to contain_jqcss("#discussion-insights-button")
    end

    it "should display the insight button for a teacher" do
      user_session(@teacher)
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      expect(f("body")).to contain_jqcss("#discussion-insights-button")
    end

    it "should display the generate an insight if there are entries" do
      (1..5).each do |i|
        student = student_in_course(course: @course, name: "Student #{i}", active_all: true).user

        @topic.discussion_entries.create!(
          message: "This is a test entry #{i}",
          user: student
        )
      end

      user_session(@teacher)
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}/insights"
      expect(f("body")).to contain_jqcss("[data-testid='discussion-insights-generate-button']")
      expect(f("body")).to contain_jqcss("[data-testid='discussion-insights-search-bar']")
      expect(f("body")).to contain_jqcss("[data-testid='placeholder-action-button']")
    end

    it "should display the result if there is already generated insight" do
      insight = @topic.insights.create!(
        user: @teacher,
        workflow_state: "completed"
      )

      (1..5).each do |i|
        student = student_in_course(course: @course, name: "Student #{i}", active_all: true).user

        entry = @topic.discussion_entries.create!(
          message: "This is a test entry #{i}",
          user: student
        )

        insight.entries.create!(
          discussion_topic: @topic,
          discussion_entry: entry,
          discussion_entry_version: entry.discussion_entry_versions.first,
          locale: "en",
          dynamic_content_hash: "hash",
          ai_evaluation: {
            "relevance_classification" => "relevant",
            "confidence" => 3,
            "notes" => "notes"
          },
          ai_evaluation_human_feedback_liked: false,
          ai_evaluation_human_feedback_disliked: false,
          ai_evaluation_human_feedback_notes: ""
        )
      end

      user_session(@teacher)
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}/insights"
      expect(f("body")).to contain_jqcss("[data-testid='insight-result-counter']")
      expect(f("[data-testid='insight-result-counter']").text).to eq "5 Results"
    end
  end

  context "when Discussion Insight is disabled" do
    before :once do
      Account.site_admin.enable_feature!(:react_discussions_post)
      Account.default.disable_feature!(:discussion_insights)
    end

    before do
      course_with_teacher(active_course: true, active_all: true, name: "teacher")
      @topic_title = "Our Discussion Topic"
      @topic = @course.discussion_topics.create!(
        title: @topic_title,
        message: "This is a test topic",
        posted_at: "2025-04-07 11:00:00",
        user: @teacher
      )
    end

    it "should not display the insight button for teacher" do
      user_session(@teacher)
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      expect(f("body")).not_to contain_jqcss("#discussion-insights-button")
    end

    it "should not display the insight button for student" do
      @student = student_in_course(course: @course, name: "Jeff", active_all: true).user
      user_session(@student)
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      expect(f("body")).not_to contain_jqcss("#discussion-insights-button")
    end
  end
end
