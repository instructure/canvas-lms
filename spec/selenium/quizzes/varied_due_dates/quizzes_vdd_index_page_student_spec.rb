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

describe "viewing a quiz with variable due dates on the quizzes index page" do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include AssignmentOverridesSeleniumHelper

  context "as a student in Section A" do
    before(:once) { prepare_vdd_scenario_for_first_student }

    before do
      user_session(@student1)
      get "/courses/#{@course.id}/quizzes"
    end

    it "shows the due dates for Section A", priority: "1" do
      expect(f(".date-due")).to include_text("Due #{format_time_for_view(@due_at_a)}")
    end

    it "shows the availability dates for Section A", priority: "1" do
      expect(f(".date-available")).to include_text("Available until " \
                                                   "#{format_date_for_view(@lock_at_a, :short)}")
    end
  end

  context "as a student in Section B" do
    before(:once) { prepare_vdd_scenario_for_second_student }

    before do
      user_session(@student2)
      get "/courses/#{@course.id}/quizzes"
    end

    it "shows the due dates for Section B", priority: "1" do
      expect(f(".date-due")).to include_text("Due #{format_time_for_view(@due_at_b)}")
    end

    it "shows the availability dates for Section B", priority: "1" do
      expect(f(".date-available")).to include_text("Not available until " \
                                                   "#{format_date_for_view(@unlock_at_b, :short)}")
    end
  end
end
