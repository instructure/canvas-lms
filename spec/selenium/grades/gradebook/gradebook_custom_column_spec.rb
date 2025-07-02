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
# with this program. If not, see <http://www.gnu.org/licenses/>

require_relative "../../helpers/gradebook_common"
require_relative "../pages/gradebook_page"

# NOTE: We are aware that we're duplicating some unnecessary testcases, but this was the
# easiest way to review, and will be the easiest to remove after the feature flag is
# permanently removed. Testing both flag states is necessary during the transition phase.
shared_examples "Gradebook - custom columns" do |ff_enabled|
  include_context "in-process server selenium tests"
  include GradebookCommon

  before :once do
    # Set feature flag state for the test run - this affects how the gradebook data is fetched, not the data setup
    if ff_enabled
      Account.site_admin.enable_feature!(:performance_improvements_for_gradebook)
    else
      Account.site_admin.disable_feature!(:performance_improvements_for_gradebook)
    end
    gradebook_data_setup
  end

  before { user_session(@teacher) }

  def custom_column(opts = {})
    opts.reverse_merge! title: "<b>SIS ID</b>"
    @course.custom_gradebook_columns.create! opts
  end

  it "shows custom columns", priority: "2" do
    hidden = custom_column title: "hidden", hidden: true
    col = custom_column
    col.update_order([col.id, hidden.id])

    col.custom_gradebook_column_data.new.tap do |d|
      d.user_id = @student_1.id
      d.content = "123456"
    end.save!

    Gradebook.visit(@course)

    expect(Gradebook.header_selector_by_col_index(2)).to include_text col.title
    expect(Gradebook.slick_headers_selector.map(&:text).join).not_to include hidden.title
    expect(Gradebook.slick_custom_column_cell_selector.count { |c| c.text == "123456" }).to eq 1
  end

  it "lets you show and hide the teacher notes column", priority: "1" do
    Gradebook.visit(@course)
    # create the notes column
    Gradebook.select_view_dropdown
    Gradebook.select_notes_option
    expect(Gradebook.content_selector).to contain_css(".custom_column")

    # hide the notes column
    driver.action.send_keys(:escape).perform
    Gradebook.select_view_dropdown
    Gradebook.select_notes_option
    expect(Gradebook.content_selector).not_to contain_css(".custom_column")

    # show the notes column
    driver.action.send_keys(:escape).perform
    Gradebook.select_view_dropdown
    Gradebook.select_notes_option
    expect(Gradebook.content_selector).to contain_css(".custom_column")
  end
end

describe "Gradebook - custom columns" do
  it_behaves_like "Gradebook - custom columns", true
  it_behaves_like "Gradebook - custom columns", false
end
