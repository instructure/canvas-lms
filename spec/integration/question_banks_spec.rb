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

describe QuestionBanksController do
  describe "#show" do
    context "granular permissions" do
      before do
        course_with_teacher_logged_in
        @bank = @course.assessment_question_banks.create!
        @course.root_account.enable_feature!(:granular_permissions_manage_assignments)
      end

      it "renders all links" do
        get "/courses/#{@course.id}/question_banks/#{@bank.id}"

        expect(response.body).to include("Add a Question")
        expect(response.body).to include("Edit Bank Details")
        expect(response.body).to include("Delete Bank")
      end

      it "only renders add-appropriate links" do
        @course.root_account.role_overrides.create!(
          role: Role.find_by(name: "TeacherEnrollment"),
          permission: "manage_assignments_edit",
          enabled: false
        )
        @course.root_account.role_overrides.create!(
          role: Role.find_by(name: "TeacherEnrollment"),
          permission: "manage_assignments_delete",
          enabled: false
        )

        get "/courses/#{@course.id}/question_banks/#{@bank.id}"

        expect(response.body).to include("Add a Question")
        expect(response.body).not_to include("Edit Bank Details")
        expect(response.body).not_to include("Delete Bank")
      end

      it "only renders edit-appropriate links" do
        @course.root_account.role_overrides.create!(
          role: Role.find_by(name: "TeacherEnrollment"),
          permission: "manage_assignments_add",
          enabled: false
        )
        @course.root_account.role_overrides.create!(
          role: Role.find_by(name: "TeacherEnrollment"),
          permission: "manage_assignments_delete",
          enabled: false
        )

        get "/courses/#{@course.id}/question_banks/#{@bank.id}"

        expect(response.body).to include("Add a Question")
        expect(response.body).to include("Edit Bank Details")
        expect(response.body).not_to include("Delete Bank")
      end

      it "only renders delete-appropriate links" do
        @course.root_account.role_overrides.create!(
          role: Role.find_by(name: "TeacherEnrollment"),
          permission: "manage_assignments_add",
          enabled: false
        )
        @course.root_account.role_overrides.create!(
          role: Role.find_by(name: "TeacherEnrollment"),
          permission: "manage_assignments_edit",
          enabled: false
        )

        get "/courses/#{@course.id}/question_banks/#{@bank.id}"

        expect(response.body).not_to include("Add a Question")
        expect(response.body).not_to include("Edit Bank Details")
        expect(response.body).to include("Delete Bank")
      end
    end
  end
end
