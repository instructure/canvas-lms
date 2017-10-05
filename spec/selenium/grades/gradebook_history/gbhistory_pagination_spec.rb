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
require_relative '../setup/gb_history_search_setup'

describe "Gradebook History Page" do
  include_context "in-process server selenium tests"
  include GradebookHistorySetup
  include CustomScreenActions

  before(:once) do
    gb_history_setup(50)
  end

  before(:each) do
    user_session(@teacher)
    GradeBookHistory.visit(@course)
  end

  it "should show additional new rows on a new page scroll", test_id: 3308073, priority: "1" do
    GradeBookHistory.click_filter_button
    initial_row_count=GradeBookHistory.fetch_results_table_row_count
    scroll_page_to_bottom
    # different waits failed adding sleep temporarily, will refactor in future
    sleep 1 # sorry :'(
    final_row_count=GradeBookHistory.fetch_results_table_row_count
    paginated_rows_displayed=final_row_count-initial_row_count
    expect(paginated_rows_displayed).to be > 0
  end
end
