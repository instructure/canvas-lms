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
#

require_relative "../views_helper"

describe "sections/show" do
  describe "sis_source_id edit box" do
    before do
      course_with_teacher(active_all: true)
      @section = @course.course_sections.first
      @section.sis_source_id = "section_sissy_id"
      assign(:context, @course)
      assign(:section, @section)
      assign(:enrollments_count, 1)
      assign(:student_enrollments_count, 1)
      assign(:pending_enrollments_count, 1)
      assign(:completed_enrollments_count, 1)
      assign(:permission_classes, "manage-permissions")
    end

    it "does not show to teacher" do
      view_context(@course, @user)
      assign(:current_user, @user)
      render
      expect(response).to have_tag("span.sis_source_id", @section.sis_source_id)
      expect(response).not_to have_tag("input#course_section_sis_source_id")
    end

    it "shows to sis admin" do
      admin = account_admin_user(account: @course.root_account)
      view_context(@course, admin)
      assign(:current_user, admin)
      render
      expect(response).to have_tag("input#course_section_sis_source_id")
    end

    it "does not show to non-sis admin" do
      admin = account_admin_user_with_role_changes(account: @course.root_account, role_changes: { "manage_sis" => false })
      view_context(@course, admin)
      assign(:current_user, admin)
      render
      expect(response).not_to have_tag("input#course_section_sis_source_id")
      expect(response).to have_tag("span.sis_source_id", @section.sis_source_id)
    end
  end
end
