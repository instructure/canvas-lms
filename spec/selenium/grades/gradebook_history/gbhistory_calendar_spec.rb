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

require_relative '../pages/gradebook_history_page'
require_relative '../setup/gradebook_setup'

describe "Gradebook History Page" do
  include_context "in-process server selenium tests"
  include GradebookSetup
  include CustomScreenActions
  include CustomSeleniumActions

  before(:once) do
    # create course with teacher
    course_factory(active_all: true)
  end

  before(:each) do
    user_session(@teacher)
    GradeBookHistory.visit(@course)
  end

  context "has filter button disabled" do

    it "and shows error message on entering backward dates", test_id: 3308866, priority: "1" do
      GradeBookHistory.enter_start_date('October 7, 2017')
      GradeBookHistory.enter_end_date(['October 4, 2017', :enter])
      expect(GradeBookHistory.error_text_invalid_dates).to be_displayed
    end

    it "on entering invalid dates", test_id: 3308867, priority: "1" do
      GradeBookHistory.enter_start_date('bad date')
      GradeBookHistory.enter_end_date('invalid date')
      GradeBookHistory.enter_end_date(:tab)
      filter_button_updated=GradeBookHistory.filter_button
      expect(element_value_for_attr(filter_button_updated,'aria-disabled')).to eq('true')
    end
  end
end
