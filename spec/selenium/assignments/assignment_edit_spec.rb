#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative '../common'
require_relative 'page_objects/assignment_create_edit_page'
require_relative 'page_objects/assignment_page'

describe "assignment" do
  include_context "in-process server selenium tests"

  context "for submission limited attempts" do
    before(:each) do
      @course1 = Course.create!(:name => "First Course1")
      @teacher1 = User.create!
      @teacher1 = User.create!(:name => "First Teacher")
      @teacher1.accept_terms
      @teacher1.register!
      @course1.enroll_teacher(@teacher1, :enrollment_state => 'active')
      @assignment1 = @course1.assignments.create!(
        :title => 'Existing Assignment',
        :points_possible => 10,
        :submission_types => "online_url,online_upload,online_text_entry"
      )
      @assignment2_paper = @course1.assignments.create!(
        :title => 'Existing Assignment',
        :points_possible => 10,
        :submission_types => "on_paper"
      )
    end

    context "with feature on" do
      before(:each) do
        Account.site_admin.allow_feature! :assignment_attempts
        @course1.enable_feature! :assignment_attempts
        user_session(@teacher1)
      end

      it "with feature on, displays the attempts field on edit view" do
        AssignmentCreateEditPage.visit_assignment_edit_page(@course1.id, @assignment1.id)

        expect(AssignmentCreateEditPage.limited_attempts_fieldset.displayed?).to be true
      end

      it "with feature on, hides attempts field for paper assignment" do
        AssignmentCreateEditPage.visit_assignment_edit_page(@course1.id, @assignment2_paper.id)

        expect(AssignmentCreateEditPage.limited_attempts_fieldset.displayed?).to be false
      end

      it "with feature on, displays the attempts field on create view" do
        AssignmentCreateEditPage.visit_new_assignment_create_page(@course1.id)
        click_option(AssignmentCreateEditPage.submission_type_selector, "External Tool")

        expect(AssignmentCreateEditPage.limited_attempts_fieldset.displayed?).to be true
      end

      it "with feature on, hides the attempts field on create view when no submissions is needed" do
        AssignmentCreateEditPage.visit_new_assignment_create_page(@course1.id)
        click_option(AssignmentCreateEditPage.submission_type_selector, "No Submission")

        expect(AssignmentCreateEditPage.limited_attempts_fieldset.displayed?).to be false
      end

      it "allows user to set submission limit", custom_timeout: 25 do
        AssignmentCreateEditPage.visit_assignment_edit_page(@course1.id, @assignment1.id)
        click_option(AssignmentCreateEditPage.limited_attempts_dropdown, "Limited")

        # default attempt count is 1
        expect(AssignmentCreateEditPage.limited_attempts_input.attribute('value')).to eq "1"

        # increase attempts count
        AssignmentCreateEditPage.increase_attempts_btn.click()
        AssignmentCreateEditPage.assignment_save_button.click()
        wait_for_ajaximations

        expect(AssignmentPage.allowed_attempts_count.text).to include "2"
      end
    end
  end
end
