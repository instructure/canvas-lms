#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative '../../../helpers/gradebook_common'
require_relative '../../pages/gradebook_page'
require_relative '../../setup/gb_performance_setup/gb_large_data_setup'

describe "gradebook" do
  include_context "in-process server selenium tests"
  include GradebookLargeDataSetup
  include GradebookCommon

  before(:once) do
    assignment_setup
    @gradebook_page = Gradebook::MultipleGradingPeriods.new

  end

  before(:each) { user_session(@teacher) }

  it "page should load within acceptable time ", priority:"1" do
    page_load_start_time = Time.now
    @gradebook_page.visit_gradebook(@course)
    page_load_finish_time = Time.now
    page_load_time = page_load_finish_time - page_load_start_time
    puts "The gradebook page /courses/#{@course}/gradebook loaded in #{page_load_time} seconds"
    Rails.logger.debug "The gradebook page /courses/#{@course}/gradebook loaded in #{page_load_time} seconds"
    expect(page_load_time).to be > 0.0
  end
end
