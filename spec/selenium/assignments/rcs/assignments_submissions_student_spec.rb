#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../../common'
require_relative '../../helpers/files_common'
require_relative '../../helpers/submissions_common'
require_relative '../../helpers/gradebook_common'

describe "submissions" do
  include_context "in-process server selenium tests"
  include FilesCommon
  include GradebookCommon
  include SubmissionsCommon

  context 'as a student' do

    before(:once) do
      @due_date = Time.now.utc + 2.days
      course_with_student(active_all: true)
      enable_all_rcs @course.account
      @assignment = @course.assignments.create!(:title => 'assignment 1', :name => 'assignment 1', :due_at => @due_date)
      @second_assignment = @course.assignments.create!(:title => 'assignment 2', :name => 'assignment 2', :due_at => nil)
      @third_assignment = @course.assignments.create!(:title => 'assignment 3', :name => 'assignment 3', :due_at => nil)
      @fourth_assignment = @course.assignments.create!(:title => 'assignment 4', :name => 'assignment 4', :due_at => @due_date - 1.day)
    end

    before(:each) do
      user_session(@student)
      stub_rcs_config
    end

    it "should let a student submit a text entry", priority: "1", test_id: 56015 do
      @assignment.update_attributes(submission_types: "online_text_entry")
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      f(".submit_assignment_link").click
      type_in_tiny("#submission_body", 'text')
      f('button[type="submit"]').click

      expect(f("#sidebar_content")).to include_text("Submitted!")
      expect(f("#content")).not_to contain_css(".error_text")
    end

    it "should not let a student submit a text entry with no text entered", priority: "2", test_id: 238143 do
      @assignment.update_attributes(submission_types: "online_text_entry")
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      f(".submit_assignment_link").click
      f('button[type="submit"]').click

      expect(fj(".error_text")).to be
    end

    it "should show as not turned in when submission was auto created in speedgrader", priority: "1", test_id: 237025 do
      # given
      @teacher = User.create!
      @course.enroll_teacher(@teacher)
      @assignment.update_attributes(:submission_types => "online_text_entry")
      @assignment.grade_student(@student, grade: "0", grader: @teacher)
      # when
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      # expect
      expect(f('#sidebar_content .details')).to include_text "Not Submitted!"
      expect(f('.submit_assignment_link')).to include_text "Submit Assignment"
    end

    it "should not allow blank submissions for text entry", priority: "1", test_id: 237026 do
      @assignment.update_attributes(:submission_types => "online_text_entry")
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      f('.submit_assignment_link').click
      assignment_form = f('#submit_online_text_entry_form')
      wait_for_tiny(assignment_form)
      submission = @assignment.submissions.find_by!(user_id: @student)

      # it should not actually submit and pop up an error message
      expect { submit_form(assignment_form) }.not_to change { submission.reload.updated_at }
      expect(submission.reload.body).to be nil
      expect(ff('.error_box')[1]).to include_text('Required')

      # now make sure it works
      body_text = 'now it is not blank'
      type_in_tiny('#submission_body', body_text)
      expect { submit_form(assignment_form) }.to change { submission.reload.updated_at }
      expect(submission.reload.body).to eq "<p>#{body_text}</p>"
    end

    it "should submit an assignment and validate confirmation information", priority: "1", test_id: 237029
  end
end
