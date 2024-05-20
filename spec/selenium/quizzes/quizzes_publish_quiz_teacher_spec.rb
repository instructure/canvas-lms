# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../common"
require_relative "../helpers/quizzes_common"

describe "publishing a quiz" do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  context "as a teacher" do
    before do
      course_with_teacher_logged_in
      @quiz = create_quiz_with_due_date(course: @course)
      @quiz.workflow_state = "unavailable"
      @quiz.save!
    end

    context "when on the quiz show page" do
      it "publishes a quiz" do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
        expect_new_page_load { f("#quiz-publish-link").click }
        expect { @quiz.reload.workflow_state }.to become("available")
      end

      context "after the quiz is published" do
        before do
          @quiz.workflow_state = "available"
          @quiz.save!
          get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
          wait_for_quiz_publish_button_to_populate
        end

        it "changes the button's text to 'Published'", priority: "1" do
          driver.action.move_to(f("#header")).perform
          expect(f("#quiz-publish-link")).to include_text "Published"
        end

        it "changes the button text on hover to |Unpublish|", priority: "1" do
          driver.action.move_to(f("#quiz-publish-link")).perform
          expect(f("#quiz-publish-link")).to include_text "Unpublish"
        end

        it "removes the 'This quiz is unpublished' message", priority: "1" do
          expect(f("#content")).not_to contain_css(".alert .unpublished_warning")
        end

        it "adds links to the right sidebar", priority: "1" do
          links = ff("ul.page-action-list li")

          expect(links[0]).to include_text "Moderate This Quiz"
          expect(links[1]).to include_text "SpeedGrader"
        end

        it "displays both |Preview| buttons", priority: "1" do
          expect(ff("#preview_quiz_button")).to have_size 2
        end

        context "when clicking the cog menu tool" do
          it "shows updated options", priority: "1" do
            f(".header-group-right button.al-trigger").click
            items = ff("ul#toolbar-1 li.ui-menu-item")
            items_text = items.map { |i| i.text.split("\n")[0] }

            expect(items_text).to include "Show Rubric"
            expect(items_text).to include "Preview"
            expect(items_text).to include "Lock this Quiz Now"
            expect(items_text).to include "Show Student Quiz Results"
            expect(items_text).to include "Message Students Who..."
            expect(items_text).to include "Delete"
          end
        end
      end
    end
  end
end
