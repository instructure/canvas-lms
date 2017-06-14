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

require_relative '../../helpers/gradezilla_common'
require_relative '../../helpers/assignment_overrides'
require_relative '../page_objects/gradezilla_page'

describe "Gradezilla view menu" do
  include_context "in-process server selenium tests"
  include AssignmentOverridesSeleniumHelper
  include GradezillaCommon

  before(:once) { gradebook_data_setup }
  before(:each) { user_session(@teacher) }

  context "sort by assignment group order" do
    before(:each) do
      Gradezilla.visit(@course)
    end

    it "defaults arrange by to assignment group in the grid", priority: "1", test_id: 220028 do
      first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
      expect(first_row_cells[0]).to include_text @assignment_1_points
      expect(first_row_cells[1]).to include_text @assignment_2_points
      expect(first_row_cells[2]).to include_text "-"
    end

    it "shows default arrange by in the menu" do
      Gradezilla.open_view_menu_and_arrange_by_menu

      expect(Gradezilla.popover_menu_item('Default Order').attribute('aria-checked')).to eq 'true'
    end

    it "validates arrange columns by assignment group option", priority: "1", test_id: 3253267 do
      Gradezilla.open_view_menu_and_arrange_by_menu
      Gradezilla.popover_menu_item('Default Order').click

      first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
      expect(first_row_cells[0]).to include_text @assignment_1_points
      expect(first_row_cells[1]).to include_text @assignment_2_points
      expect(first_row_cells[2]).to include_text "-"
    end
  end
end
