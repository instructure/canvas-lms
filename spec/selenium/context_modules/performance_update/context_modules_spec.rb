# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
require_relative "../../helpers/public_courses_context"
require_relative "../page_objects/modules_index_page"
describe "context modules, performance update" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include ModulesIndexPage
  before(:once) do
    course_factory(active_course: true)
    @page1 = @course.wiki_pages.create! title: "title1"
    @page2 = @course.wiki_pages.create! title: "title2"
    @context_module = @course.context_modules.create! name: "Module X"
    @item1 = @context_module.add_item({ type: "wiki_page", id: @page1.id }, nil, position: 2)
    @item2 = @context_module.add_item({ type: "wiki_page", id: @page2.id }, nil, position: 1)
  end

  before do
    @course.account.enable_feature!(:modules_perf)
    course_with_teacher_logged_in(course: @course, active_enrollment: true)
  end

  it "lazy loads module items" do
    go_to_modules
    wait_for_dom_ready
    wait_for_children("#context_module_#{@context_module.id}")
    expect(f("#context_module_#{@context_module.id}")).to be_displayed
    expect(f("#context_module_item_#{@item1.id}")).to be_displayed
    expect(f("#context_module_item_#{@item2.id}")).to be_displayed
  end
end
