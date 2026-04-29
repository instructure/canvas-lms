# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../../helpers/context_modules_common"
require_relative "../page_objects/modules2_index_page"
require_relative "../../helpers/items_assign_to_tray"
require_relative "../../helpers/assignments_common"

describe "context modules pagination - student view", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include Modules2IndexPage
  include ItemsAssignToTray
  include AssignmentsCommon

  before :once do
    modules2_student_setup
  end

  before do
    user_session(@student)
  end

  before :once do
    @course = course_factory(active_all: true)
    @teacher = @course.teachers.first
    @student = student_in_course(course: @course, active_all: true).user
    @empty_module = create_module_with_many_files(course: @course)
  end

  it "shows pagination when expanded module has more than 100 items" do
    go_to_modules
    wait_for_ajaximations
    module_header_expand_toggles.last.click
    wait_for_ajaximations
    expect(pagination_info_text_includes?("Showing 1-10 of 150 items")).to be true

    pagination_page_buttons[1].click
    wait_for_ajaximations
    expect(pagination_info_text_includes?("Showing 11-20 of 150 items")).to be true
  end

  context "with many paged modules" do
    before :once do
      @second_module = create_module_with_many_files(course: @course, count: 11)
      @third_module = create_module_with_many_files(course: @course, count: 10)

      Setting.set("module_perf_threshold", -1)
    end

    it "keeps the paged module in the viewport upon paging" do
      go_to_modules
      wait_for_ajaximations
      expand_all_modules
      scroll_into_view(module_pagination_container(@second_module.id))
      module_pagination_buttons(@second_module.id)[-1].click
      wait_for_ajaximations

      expect_element_in_viewport(context_module_selector(@second_module.id))
    end
  end
end
