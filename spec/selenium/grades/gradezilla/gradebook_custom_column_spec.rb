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

require_relative '../../helpers/gradezilla_common'
require_relative '../pages/gradezilla_page'

describe "Gradezilla - custom columns" do
  include_context "in-process server selenium tests"
  include GradezillaCommon

  before(:once) { gradebook_data_setup }
  before(:each) { user_session(@teacher) }

  def custom_column(opts = {})
    opts.reverse_merge! title: "<b>SIS ID</b>"
    @course.custom_gradebook_columns.create! opts
  end

  it "shows custom columns", priority: "2", test_id: 164225 do
    hidden = custom_column title: "hidden", hidden: true
    col = custom_column
    col.update_order([col.id, hidden.id])

    col.custom_gradebook_column_data.new.tap do |d|
      d.user_id = @student_1.id
      d.content = "123456"
    end.save!

    Gradezilla.visit(@course)

    expect(Gradezilla.header_selector_by_col_index(2)).to include_text col.title
    expect(Gradezilla.slick_headers_selector.map(&:text).join).not_to include hidden.title
    expect((Gradezilla.slick_custom_column_cell_selector).count { |c| c.text == "123456" }).to eq 1
  end

  it "lets you show and hide the teacher notes column", priority: "1", test_id: 3253279 do
    Gradezilla.visit(@course)
    # create the notes column
    Gradezilla.select_view_dropdown
    Gradezilla.select_notes_option
    expect(Gradezilla.content_selector).to contain_css('.custom_column')

    # hide the notes column
    Gradezilla.select_view_dropdown
    Gradezilla.select_notes_option
    expect(Gradezilla.content_selector).not_to contain_css('.custom_column')

    # show the notes column
    Gradezilla.select_view_dropdown
    Gradezilla.select_notes_option
    expect(Gradezilla.content_selector).to contain_css('.custom_column')
  end
end
