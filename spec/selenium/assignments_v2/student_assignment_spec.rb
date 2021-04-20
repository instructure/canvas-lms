# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require_relative './page_objects/student_assignment_page_v2'
require_relative '../common'

describe 'as a student' do
  include_context "in-process server selenium tests"

  context 'on assignments 2 page' do
    before(:once) do
      Account.default.enable_feature!(:assignments_2_student)
      course_with_student(course: @course, active_all: true)
    end

    context 'assignment details' do
      before(:once) do
        @assignment = @course.assignments.create!(
          name: 'assignment',
          due_at: 5.days.ago,
          points_possible: 10,
          submission_types: 'online_upload'
        )
      end

      before(:each) do
        user_session(@student)
        StudentAssignmentPageV2.visit(@course, @assignment)
      end

      it 'should show submission workflow tracker' do
        expect(StudentAssignmentPageV2.submission_workflow_tracker).to be_displayed
      end

      it 'should show assignment title' do
        expect(StudentAssignmentPageV2.assignment_title(@assignment.title)).to_not be_nil
      end

      it 'available assignment should show details toggle' do
        expect(StudentAssignmentPageV2.details_toggle).to be_displayed
      end

      it 'should show assignment group link' do
        expect(StudentAssignmentPageV2.assignment_group_link).to be_displayed
      end

      it 'should show assignment due date' do
        expect(StudentAssignmentPageV2.due_date_css(@assignment.due_at)).to_not be_nil
      end

      it 'should show how many points possible the assignment is worth' do
        expect(StudentAssignmentPageV2.points_possible_css(@assignment.points_possible)).to_not be_nil
      end

      it 'available assignment should show content tablist' do
        expect(StudentAssignmentPageV2.content_tablist).to be_displayed
      end
    end

    context 'text assignments' do
      before(:once) do
        @assignment = @course.assignments.create!(
          name: 'text assignment',
          due_at: 5.days.ago,
          points_possible: 10,
          submission_types: 'online_text_entry'
        )
      end

      before(:each) do
        user_session(@student)
        StudentAssignmentPageV2.visit(@course, @assignment)
        wait_for_ajaximations
      end

      it 'should be able to be submitted', custom_timeout: 30 do
        skip("Skip for now and fix with LS-2164")
        StudentAssignmentPageV2.create_text_entry_draft("Hello")
        wait_for_ajaximations
        StudentAssignmentPageV2.submit_assignment
        wait_for_ajaximations
        expect(StudentAssignmentPageV2.text_display_area).to include_text("Hello")
      end

      it 'should be able to be saved as a draft' do
        skip("Skip for now and fix with LS-2164")
        StudentAssignmentPageV2.create_text_entry_draft("Hello")
        wait_for_ajaximations
        StudentAssignmentPageV2.edit_text_entry_button.click
        expect(StudentAssignmentPageV2.text_draft_contents).to include("Hello")
      end
    end

    context 'url assignments' do
      before(:once) do
        @assignment = @course.assignments.create!(
          name: 'text assignment',
          due_at: 5.days.ago,
          points_possible: 10,
          submission_types: 'online_url'
        )
      end

      before(:each) do
        user_session(@student)
        StudentAssignmentPageV2.visit(@course, @assignment)
      end

      it 'should be able to be submitted' do
        url_text = "www.google.com"
        StudentAssignmentPageV2.create_url_draft(url_text)
        StudentAssignmentPageV2.submit_assignment
        expect(StudentAssignmentPageV2.url_submission_link).to include_text url_text
      end

      it 'should be able to be saved as a draft' do
        url_text = "www.google.com"
        StudentAssignmentPageV2.create_url_draft(url_text)

        # This is to wait for the submit button to appear so that we know the draft
        # has been saved. We are not clicking the button here.
        StudentAssignmentPageV2.submit_button

        refresh_page
        expect(StudentAssignmentPageV2.url_text_box.attribute('value')).to include url_text
      end
    end

    context "moduleSequenceFooter" do
      before do
        @assignment = @course.assignments.create!(submission_types: 'online_upload')

        # add items to module
        @module = @course.context_modules.create!(:name => "My Module")
        @item_before = @module.add_item :type => 'assignment', :id => @course.assignments.create!(:title => 'assignment BEFORE this one').id
        @module.add_item :type => 'assignment', :id => @assignment.id
        @item_after = @module.add_item :type => 'assignment', :id => @course.assignments.create!(:title => 'assignment AFTER this one').id

        user_session(@student)
        StudentAssignmentPageV2.visit(@course, @assignment)
      end

      it "shows the module sequence footer" do
        expect(f('.module-sequence-footer-button--previous a')).to have_attribute("href", "/courses/#{@course.id}/modules/items/#{@item_before.id}")
        expect(f('.module-sequence-footer-button--next a')).to have_attribute("href", "/courses/#{@course.id}/modules/items/#{@item_after.id}")
      end
    end

    context 'media assignments' do
      before(:once) do
        @assignment = @course.assignments.create!(
          name: 'media assignment',
          due_at: 5.days.ago,
          points_possible: 10,
          submission_types: 'media_recording'
        )
      end

      before(:each) do
        stub_kaltura
        user_session(@student)
        StudentAssignmentPageV2.visit(@course, @assignment)
      end

      it "should be able to open the media modal" do
        skip 'LS-1514 10/5/2020'
        StudentAssignmentPageV2.record_upload_button.click
        expect(StudentAssignmentPageV2.media_modal).to be_displayed
      end
    end
  end
end
