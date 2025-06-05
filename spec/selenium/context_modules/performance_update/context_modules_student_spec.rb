# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
require_relative "../page_objects/modules_settings_tray"
require_relative "../../helpers/items_assign_to_tray"
require_relative "../../dashboard/pages/k5_dashboard_page"
require_relative "../../dashboard/pages/k5_dashboard_common_page"
require_relative "../../../helpers/k5_common"
require_relative "../shared_examples/modules_performance_shared_examples"
require_relative "../shared_examples/context_modules_student_shared_examples"

describe "context modules" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include ModulesIndexPage
  include ModulesSettingsTray
  include ItemsAssignToTray
  include K5Common
  include K5DashboardPageObject
  include K5DashboardCommonPageObject

  context "as a student" do
    before(:once) do
      course_with_student(active_all: true)

      @course.account.enable_feature!(:modules_perf)
    end

    before do
      user_session(@student)
    end

    it_behaves_like "context modules for students"

    context "with low performance threshold" do
      before(:once) do
        Setting.set("module_perf_threshold", -1)
      end

      context "with many module items on the modules page" do
        before(:once) do
          @module_list = big_course_setup
          @course.reload
        end

        it_behaves_like "module performance with module items", :context_modules
        it_behaves_like "module performance with module items", :course_homepage
      end

      context "show all or less" do
        before(:once) do
          course_with_student(active_all: true)
          @course.account.enable_feature!(:modules_perf)
          Setting.set("module_perf_threshold", -1)
          @module = @course.context_modules.create!(name: "module 1")
          11.times do |i|
            @module.add_item(type: "assignment", id: @course.assignments.create!(title: "assignment #{i}").id)
          end
        end

        before do
          user_session(@student)
        end

        it_behaves_like "module show all or less", :context_modules
        it_behaves_like "module show all or less", :course_homepage
      end
    end
  end

  context "as a canvas for elementary student with many module items", :ignore_js_errors do
    before(:once) do
      student_setup
      @subject_course.account.enable_feature!(:modules_perf)
      Setting.set("module_perf_threshold", -1)
      @course = @subject_course
      @module_list = big_course_setup
      @subject_course.reload
    end

    before do
      user_session(@student)
    end

    it_behaves_like "module performance with module items", :canvas_for_elementary
  end

  context "as a canvas for elementary student with module items to show", :ignore_js_errors do
    before(:once) do
      student_setup
      @subject_course.account.enable_feature!(:modules_perf)
      Setting.set("module_perf_threshold", -1)
      @course = @subject_course
      @module = @course.context_modules.create!(name: "module 1")
      11.times do |i|
        @module.add_item(type: "assignment", id: @course.assignments.create!(title: "assignment #{i}").id)
      end
      @subject_course.reload
    end

    before do
      user_session(@student)
    end

    it_behaves_like "module show all or less", :canvas_for_elementary
  end
end
