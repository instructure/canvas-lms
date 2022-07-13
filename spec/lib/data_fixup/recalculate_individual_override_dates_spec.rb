# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe DataFixup::RecalculateIndividualOverrideDates do
  before do
    course_with_student(active_all: true)
    Account.site_admin.disable_feature!(:prioritize_individual_overrides)
    @assignment = @course.assignments.create!(only_visible_to_overrides: true)
    @adhoc_due_at = 10.days.from_now.iso8601.to_datetime
    create_adhoc_override_for_assignment(@assignment, @student, due_at: @adhoc_due_at)
    @section_due_at = 10.days.from_now(@adhoc_due_at)
    create_section_override_for_assignment(@assignment, due_at: @section_due_at)
  end

  it "recomputes the cached_due_date on assignments with multiple overrides with at least one adhoc" do
    Account.site_admin.enable_feature!(:prioritize_individual_overrides)
    expect { DataFixup::RecalculateIndividualOverrideDates.run }.to change {
      @assignment.submissions.find_by(user: @student).cached_due_date
    }.from(@section_due_at).to(@adhoc_due_at)
  end

  it "after running, returns the correct due date for overridden assignment objects" do
    Account.site_admin.enable_feature!(:prioritize_individual_overrides)
    DataFixup::RecalculateIndividualOverrideDates.run
    expect(@assignment.overridden_for(@student).due_at).to eq @adhoc_due_at
  end
end
