# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative "../common"
require_relative "../helpers/context_modules_common"
require_relative "shared_examples/context_modules_student_shared_examples"

describe "context modules" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon

  before :once do
    @course = course_model.tap(&:offer!)
    @teacher = teacher_in_course(course: @course, name: "teacher", active_all: true).user
    @student = student_in_course(course: @course, name: "student", active_all: true).user
  end

  it_behaves_like "context modules for students"
end
