#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative '../common'
require_relative 'page_objects/conditional_release_objects'

describe "native canvas conditional release" do
  include_context "in-process server selenium tests"
  before(:once) do
    Account.default.enable_feature! :conditional_release
  end

  before(:each) do
    course_with_teacher_logged_in
  end

  context 'Pages as part of Mastery Paths' do
    it 'shows Allow in Mastery Paths for a Page when feature enabled' do
      get "/courses/#{@course.id}/pages/new/edit"
      expect(ConditionalReleaseObjects.conditional_content_exists?).to eq(true)
    end

    it 'does not show Allow in Mastery Paths when feature disabled' do
      Account.default.disable_feature! :conditional_release
      get "/courses/#{@course.id}/pages/new/edit"
      expect(ConditionalReleaseObjects.conditional_content_exists?).to eq(false)
    end

    it 'hides scores fields for page assignments' do
      page_title = "MP Page to Verify"
      @new_page = @course.wiki_pages.create!(:title => page_title)
      @new_page.course.assignments.create!(
        :wiki_page => @new_page,
        :submission_types => 'wiki_page',
        :title => @new_page.title
      )

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations
      ConditionalReleaseObjects.assignment_kebob(page_title).click
      ConditionalReleaseObjects.edit_assignment(page_title).click
      expect(ConditionalReleaseObjects.due_at_exists?).to eq(false)
      expect(ConditionalReleaseObjects.points_possible_exists?).to eq(false)
    end
  end

  context "Quizzes Classic as part of Mastery Paths" do
    it "should display Mastery Paths tab in quizzes edit page" do
      course_quiz
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"

      expect(ConditionalReleaseObjects.quiz_conditional_release_link.text).to eq("Mastery Paths")

      ConditionalReleaseObjects.quiz_conditional_release_link.click
      expect(ConditionalReleaseObjects.cr_editor_exists?).to eq(true)
    end

    it "should disable Mastery Paths tab in quizzes for quiz types other than graded" do
      course_quiz

      quiz_types_without_mastery_paths = [
        :practice_quiz,
        :graded_survey,
        :survey
      ].freeze

      quiz_types_without_mastery_paths.each do |type|
        @quiz.quiz_type = type
        @quiz.save!
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        expect(ConditionalReleaseObjects.disabled_cr_editor_exists?).to eq(true)
      end
    end
  end

  context "Discussions as part of Mastery Paths" do
    it "should display Mastery paths tab from (graded) Discussions edit page" do
      discussion_topic_model(:context => @course)

      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}/edit"

      expect(ConditionalReleaseObjects.conditional_release_link.text).to eq("Mastery Paths")

      ConditionalReleaseObjects.conditional_release_link.click
      expect(ConditionalReleaseObjects.conditional_release_editor_exists?).to eq(true)
    end
  end

  context "Assignment Mastery Paths" do
    it "should display Mastery Paths tab in assignments edit page" do
      assignment = assignment_model(course: @course)
      get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"

      expect(ConditionalReleaseObjects.conditional_release_link.text).to eq("Mastery Paths")

      ConditionalReleaseObjects.conditional_release_link.click
      expect(ConditionalReleaseObjects.conditional_release_editor_exists?).to eq(true)
    end

    it "should be able to see default conditional release editor" do
      assignment = assignment_model(course: @course, points_possible: 100)
      get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"
      ConditionalReleaseObjects.conditional_release_link.click
      expect(ConditionalReleaseObjects.scoring_ranges.count).to eq(3)
      expect(ConditionalReleaseObjects.top_scoring_boundary.text).to eq("100 pts")
    end

    it "should have Mastery Paths Breakdown on Assignment Summary" do
      skip "need to do"
      assignment = assignment_model(course: @course)
      # TODO: set up mastery path data
      get "/courses/#{@course.id}/assignments/#{assignment.id}"
    end

    it "should be able to set scoring range" do
      assignment = assignment_model(course: @course, points_possible: 100)
      get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"
      ConditionalReleaseObjects.conditional_release_link.click
      replace_content(ConditionalReleaseObjects.division_cutoff1, "72")
      replace_content(ConditionalReleaseObjects.division_cutoff2, "47")
      ConditionalReleaseObjects.division_cutoff2.send_keys :tab

      expect(ConditionalReleaseObjects.division_cutoff1.attribute("value")).to eq("72 pts")
      expect(ConditionalReleaseObjects.division_cutoff2.attribute("value")).to eq("47 pts")
    end
  end
end

