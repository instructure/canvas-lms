# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative "../../common"
require_relative "../pages/k5_dashboard_page"
require_relative "../pages/k5_dashboard_common_page"
require_relative "../../../helpers/k5_common"
require_relative "../pages/k5_important_dates_section_page"
require_relative "../shared_examples/k5_important_dates_shared_examples"

describe "student k5 dashboard important dates" do
  include_context "in-process server selenium tests"
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common
  include K5ImportantDatesSectionPageObject

  before :once do
    student_setup
  end

  before do
    user_session @student
  end

  context "important dates panel" do
    it "shows the important date for student with override", custom_timeout: 20 do
      assignment_title = "Elec HW"
      due_at = 2.days.ago(Time.zone.now)
      assignment = create_dated_assignment(@subject_course, assignment_title, due_at)
      assignment.update!(important_dates: true)
      override = assignment_override_model(assignment:)
      student_due_at = 2.days.from_now(Time.zone.now)
      override.override_due_at(student_due_at)
      override.save!
      override_student = override.assignment_override_students.build
      override_student.user = @student
      override_student.save!

      get "/"

      expect(important_date_link).to include_text(assignment_title)
    end
  end

  it_behaves_like "k5 important dates"

  it_behaves_like "k5 important dates calendar picker", :student
end
