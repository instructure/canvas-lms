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

require_relative "../../common"
require_relative "../../helpers/quizzes_common"
require_relative "../../helpers/assignment_overrides"

describe "viewing a quiz with variable due dates on the quiz show page" do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include AssignmentOverridesSeleniumHelper

  context "as an observer linked to two students in different sections" do
    before(:once) { prepare_vdd_scenario_for_first_observer }

    before do
      user_session(@observer1)
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    end

    it "indicates multiple due dates", priority: "2" do
      validate_quiz_show_page("Due Multiple Due Dates")
    end

    it "indicates various availability dates", priority: "2" do
      skip("Bug ticket created: CNVS-22549")
      validate_quiz_show_page("Available Various Availability Dates")
    end

    it "prevents taking the quiz", priority: "2" do
      expect(f("#content")).not_to contain_css(".take_quiz_button")
    end
  end

  context "as an observer linked to a single student" do
    before(:once) { prepare_vdd_scenario_for_second_observer }

    before do
      user_session(@observer2)
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    end

    it "shows the due dates for Section B", priority: "2" do
      validate_quiz_show_page("Due #{format_date_for_view(@due_at_b)}")
    end

    it "shows the availability dates for Section B", priority: "2" do
      validate_quiz_show_page("Available #{format_time_for_view(@unlock_at_b)} " \
                              "- #{format_time_for_view(@lock_at_b)}")
    end

    it "prevents taking the quiz", priority: "2" do
      expect(f("#content")).not_to contain_css(".take_quiz_button")
    end

    it "indicates quiz is locked", priority: "2" do
      validate_quiz_show_page("This quiz is locked until #{format_time_for_view(@unlock_at_b)}")
    end
  end
end
