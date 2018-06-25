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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'nokogiri'

describe "assignments" do
  def multiple_section_submissions
    course_with_student(:active_all => true); @student1 = @student
    @s2enrollment = student_in_course(:active_all => true); @student2 = @user

    @section = @course.course_sections.create!
    @s2enrollment.course_section = @section; @s2enrollment.save!

    @assignment = @course.assignments.create!(:title => "Test 1", :submission_types => "online_upload")

    @submission1 = @assignment.submit_homework(@student1, :submission_type => "online_text_entry", :body => "hi")
    @submission2 = @assignment.submit_homework(@student2, :submission_type => "online_text_entry", :body => "there")
  end

  def create_assignment_section_override(section, due_at)
    override = assignment_override_model(:assignment => @assignment)
    override.set = section
    override.override_due_at(due_at)
    override.save!
  end

  it "should correctly list ungraded and total submissions for teacher" do
    multiple_section_submissions

    course_with_teacher_logged_in(:course => @course, :active_all => true)
    get "/courses/#{@course.id}/assignments/#{@assignment.id}"

    expect(response).to be_success
    expect(Nokogiri::HTML(response.body).at_css('.graded_count').text).to match(/0 out of 2/)
  end

  it "should correctly list ungraded and total submissions for ta" do
    multiple_section_submissions

    @taenrollment = course_with_ta(:course => @course, :active_all => true)
    @taenrollment.limit_privileges_to_course_section = true
    @taenrollment.save!
    user_session(@ta)

    get "/courses/#{@course.id}/assignments/#{@assignment.id}"

    expect(response).to be_success
    expect(Nokogiri::HTML(response.body).at_css('.graded_count').text).to match(/0 out of 1/)
  end

  it "should show student view student submission as needing grading" do
    course_with_teacher_logged_in(:active_all => true)
    @fake_student = @course.student_view_student
    assignment_model(:course => @course, :submission_types => 'online_text_entry', :title => 'Assignment 1')
    @assignment.submit_homework(@fake_student, :submission_type => 'online_text_entry', :body => "my submission")

    get "/courses/#{@course.id}/assignments/#{@assignment.id}"

    expect(response).to be_success
    expect(Nokogiri::HTML(response.body).at_css('.graded_count').text).to match(/0 out of 1/)
  end

  describe "due date overrides" do
    include TextHelper

    before do
      course_with_teacher_logged_in(:active_all => true)
      assignment_model(:course => @course, :due_at => 3.days.from_now)
      @assignment.update_attribute :due_at, 2.days.from_now
      @cs1 = @course.default_section
      @cs2 = @course.course_sections.create!
    end

    it "should show 'Everyone' when there are no overrides" do
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      doc = Nokogiri::HTML(response.body)
      expect(doc.css(".assignment_dates").text).to include "Everyone"
      expect(doc.css(".assignment_dates").text).not_to include "Everyone else"
    end

    it "should show 'Everyone else' when some sections have due date overrides" do
      due_at1 = 3.days.from_now
      create_assignment_section_override(@cs1, due_at1)

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      doc = Nokogiri::HTML(response.body)
      expect(doc.css(".assignment_dates").text).to include "Everyone else"
    end

    it "should not show 'Everyone else' when all sections have due date overrides" do
      due_at1, due_at2 = 3.days.from_now, 4.days.from_now
      create_assignment_section_override(@cs1, due_at1)
      create_assignment_section_override(@cs2, due_at2)

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      doc = Nokogiri::HTML(response.body)
      expect(doc.css(".assignment_dates").text).not_to include "Everyone"
    end
  end
end

describe "download submissions link" do

  before do
    course_with_teacher_logged_in(:active_all => true)
    assignment_model(:course => @course, :submission_types => 'online_url', :title => 'Assignment 1')
    @student = User.create!(:name => 'student1')
    @student.register!
    @student.workflow_state = 'active'
    @student2 = User.create!(:name => 'student2')
    @student2.register
    @student2.workflow_state = 'active'
    @student2.save
    @course.enroll_user(@student, 'StudentEnrollment')
    @course.enroll_user(@student2, 'StudentEnrollment')
    @course.save!
    @student.save!
    @student2.save!
  end

  it "should not show download submissions button with no submissions" do
    get "/courses/#{@course.id}/assignments/#{@assignment.id}"
    expect(response).to be_success
    doc = Nokogiri::XML(response.body)
    expect(doc.at_css('#download_submission_button')).to be_nil
  end

  it "should not show download submissions button with no submissions from active students" do
    @submission = @assignment.submissions.find_by!(user: @student)
    @submission.update(submission_type: 'online_url')
    @student.enrollments.each(&:conclude)

    get "/courses/#{@course.id}/assignments/#{@assignment.id}"
    expect(response).to be_success
    doc = Nokogiri::XML(response.body)
    expect(doc.at_css('#download_submission_button')).to be_nil
  end

  it "should show download submissions button with submission not graded" do
    @submission = @assignment.submissions.find_by!(user: @student)
    @submission.update(submission_type: 'online_url')
    expect(@submission.state).to eql(:submitted)

    get "/courses/#{@course.id}/assignments/#{@assignment.id}"
    expect(response).to be_success
    doc = Nokogiri::XML(response.body)
    expect(doc.at_css('#download_submission_button')).not_to be_nil
  end

  it "should show download submissions button with a submission graded" do
    @submission = @assignment.submissions.find_by!(user: @student)
    @submission.update!(submission_type: 'online_url')
    @submission.grade_it
    @submission.score = 5
    @submission.save!
    expect(@submission.state).to eql(:graded)
    @submission2 = @assignment.submissions.find_by!(user: @student2)
    @submission2.update!(submission_type: 'online_url')

    get "/courses/#{@course.id}/assignments/#{@assignment.id}"
    expect(response).to be_success
    doc = Nokogiri::XML(response.body)
    expect(doc.at_css('#download_submission_button')).not_to be_nil
  end

  it "should show download submissions button with all submissions graded" do
    @submission = @assignment.submissions.find_by!(user: @student)
    @submission.update!(submission_type: 'online_url')
    @submission.grade_it
    @submission.score = 5
    @submission.save!
    expect(@submission.state).to eql(:graded)
    @submission2 = @assignment.submissions.find_by!(user: @student2)
    @submission2.update!(submission_type: 'online_url')
    @submission2.grade_it
    @submission2.score = 5
    @submission2.save!
    expect(@submission2.state).to eql(:graded)

    get "/courses/#{@course.id}/assignments/#{@assignment.id}"
    expect(response).to be_success
    doc = Nokogiri::XML(response.body)
    expect(doc.at_css('#download_submission_button')).not_to be_nil
  end

  it "should not show download submissions button to students" do
    @submission = @assignment.submissions.find_by!(user: @student)
    @submission.update!(submission_type: 'online_url')
    expect(@submission.state).to eql(:submitted)
    user_session(@student)
    get "/courses/#{@course.id}/assignments/#{@assignment.id}"
    expect(response).to be_success
    doc = Nokogiri::XML(response.body)
    expect(doc.at_css('#download_submission_button')).to be_nil
  end

end

describe "ratio of submissions graded" do

  before do
    course_with_teacher_logged_in(:active_all => true)
    assignment_model(:course => @course, :submission_types => 'online_url', :title => 'Assignment 1')
    @student = User.create!(:name => 'student1')
    @student.register!
    @student.workflow_state = 'active'
    @student2 = User.create!(:name => 'student2')
    @student2.register
    @student2.workflow_state = 'active'
    @student2.save
    @course.enroll_user(@student, 'StudentEnrollment')
    @course.enroll_user(@student2, 'StudentEnrollment')
    @course.save!
    @student.save!
    @student2.save!
  end

  it "should not show ratio of submissions graded with no submissions" do

    get "/courses/#{@course.id}/assignments/#{@assignment.id}"
    expect(response).to be_success
    doc = Nokogiri::XML(response.body)
    expect(doc.at_css('#ratio_of_submissions_graded')).to be_nil
  end

  it "should show ratio of submissions graded with submission not graded" do
    @submission = @assignment.submissions.find_by!(user: @student)
    @submission.update!(submission_type: 'online_url')
    expect(@submission.state).to eql(:submitted)
    @submission2 = @assignment.submissions.find_by!(user: @student2)
    @submission2.update!(submission_type: 'online_url')
    expect(@submission2.state).to eql(:submitted)

    get "/courses/#{@course.id}/assignments/#{@assignment.id}"
    expect(response).to be_success
    doc = Nokogiri::XML(response.body)
    expect(doc.at_css('#ratio_of_submissions_graded').text.strip).to eq "0 out of 2 Submissions Graded"
  end

  it "should show ratio of submissions graded with a submission graded" do
    @submission = @assignment.submissions.find_by!(user: @student)
    @submission.update!(submission_type: 'online_url')
    @submission.grade_it
    @submission.score = 5
    @submission.save!
    expect(@submission.state).to eql(:graded)
    @submission2 = @assignment.submissions.find_by!(user: @student2)
    @submission2.update!(submission_type: 'online_url')

    get "/courses/#{@course.id}/assignments/#{@assignment.id}"
    expect(response).to be_success
    doc = Nokogiri::XML(response.body)
    expect(doc.at_css('#ratio_of_submissions_graded').text.strip).to eq "1 out of 2 Submissions Graded"
  end

  it "should show ratio of submissions graded with all submissions graded" do
    @submission = @assignment.submissions.find_by!(user: @student)
    @submission.update!(submission_type: 'online_url')
    @submission.grade_it
    @submission.score = 5
    @submission.save!
    expect(@submission.state).to eql(:graded)
    @submission2 = @assignment.submissions.find_by!(user: @student2)
    @submission2.update!(submission_type: 'online_url')
    @submission2.grade_it
    @submission2.score = 5
    @submission2.save!
    expect(@submission2.state).to eql(:graded)

    get "/courses/#{@course.id}/assignments/#{@assignment.id}"
    expect(response).to be_success
    doc = Nokogiri::XML(response.body)
    expect(doc.at_css('#ratio_of_submissions_graded').text.strip).to eq "2 out of 2 Submissions Graded"
  end

  it "should not show ratio of submissions graded to students" do
    @submission = @assignment.submissions.find_by!(user: @student)
    @submission.update!(submission_type: 'online_url')
    expect(@submission.state).to eql(:submitted)

    user_session(@student)
    get "/courses/#{@course.id}/assignments/#{@assignment.id}"
    expect(response).to be_success
    doc = Nokogiri::XML(response.body)
    expect(doc.at_css('#ratio_of_submissions_graded')).to be_nil
  end

  describe 'assignment moderation' do
    let(:moderate_button) { Nokogiri::HTML(response.body).at_css('#moderated_grading_button') }

    it 'shows the moderation link for moderated assignments' do
      @assignment.update!(moderated_grading: true, grader_count: 1, final_grader: @teacher)

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(moderate_button).not_to be_nil
    end

    it 'does not show the moderation link for non-moderated assignments' do
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(moderate_button).to be_nil
    end
  end
end
