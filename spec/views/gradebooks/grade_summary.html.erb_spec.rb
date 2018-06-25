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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/gradebooks/grade_summary" do
  it "should render" do
    course_with_student
    view_context
    a = @course.assignments.create!(:title => "some assignment")
    assign(:presenter, GradeSummaryPresenter.new(@course, @user, nil))
    render "gradebooks/grade_summary"
    expect(response).not_to be_nil
  end

  it "should not show totals if configured so" do
    course_with_student
    @course.hide_final_grades = true
    view_context
    a = @course.assignments.create!(:title => "some assignment")
    assign(:presenter, GradeSummaryPresenter.new(@course, @user, nil))
    render "gradebooks/grade_summary"
    expect(response).not_to be_nil
    page = Nokogiri('<document>' + response.body + '</document>')
    expect(page.css(".final_grade").length).to eq 0
  end

  it "should not show 'what if' if not the student" do
    course_with_teacher
    student_in_course
    @student = @user
    @user = @teacher
    view_context
    a = @course.assignments.create!(:title => "some assignment")
    presenter = assign(:presenter, GradeSummaryPresenter.new(@course, @teacher, @student.id))
    expect(presenter.student_enrollment).not_to be_nil
    render "gradebooks/grade_summary"
    expect(response).not_to be_nil
    expect(response.body).not_to match(/Click any score/)
  end

  it "should know the types of media comments" do
    stub_kaltura
    course_with_teacher
    student_in_course
    view_context
    a = @course.assignments.create!(:title => 'some assignment', :submission_types => ['online_text_entry'])
    sub = a.submit_homework @student, :submission_type => "online_text_entry", :body => "o hai"
    sub.add_comment :author => @teacher, :media_comment_id => '0_abcdefgh', :media_comment_type => 'audio'
    sub.add_comment :author => @teacher, :media_comment_id => '0_ijklmnop', :media_comment_type => 'video'
    assign(:presenter, GradeSummaryPresenter.new(@course, @teacher, @student.id))
    render "gradebooks/grade_summary"
    doc = Nokogiri::HTML::DocumentFragment.parse response.body
    expect(doc.at_css('.audio_comment ~ span.media_comment_id').text).to eql '0_abcdefgh'
    expect(doc.at_css('.video_comment ~ span.media_comment_id').text).to eql '0_ijklmnop'
  end

  it "should show a disabled message for grade stats for the test student" do
    course_with_teacher(:active_all => true)
    @student = @course.student_view_student
    @user = @teacher
    view_context
    a = @course.assignments.create!(:title => "some assignment", :points_possible => 10)
    a.grade_student(@student, grade: "10", grader: @teacher)
    assign(:presenter, GradeSummaryPresenter.new(@course, @teacher, @student.id))
    render "gradebooks/grade_summary"
    expect(response).not_to be_nil
    expect(response.body).to match(/Test Student scores are not included in grade statistics./)
  end

  describe "submission details link" do
    before(:each) do
      course_with_teacher
      student_in_course
      @assignment = @course.assignments.create!(title: 'Moderated Assignment', anonymous_grading: true, muted: true)
      @assignment.submit_homework @student, :submission_type => "online_text_entry", :body => "o hai"
      @submission_details_url = context_url(@course, :context_assignment_submission_url, @assignment, @student.id)
    end

    it "should be shown for submitting student if assignment is anonymous grading and muted" do
      @user = @student
      assign(:presenter, GradeSummaryPresenter.new(@course, @student, @student.id))
      view_context
      render "gradebooks/grade_summary"
      expect(response).to have_tag("a[href='#{@submission_details_url}']")
    end

    it "should be hidden for non-submitting student if assignment is anonymous grading and muted" do
      view_context
      new_student = User.create!
      @course.enroll_student(new_student, enrollment_state: 'active')
      assign(:presenter, GradeSummaryPresenter.new(@course, new_student, @student.id))
      user_session(new_student)
      render "gradebooks/grade_summary"
      expect(response).not_to have_tag("a[href='#{@submission_details_url}']")
    end

    it "should be hidden for teacher if assignment is anonymous grading and muted" do
      @user = @teacher
      assign(:presenter, GradeSummaryPresenter.new(@course, @teacher, @student.id))
      view_context
      render "gradebooks/grade_summary"
      expect(response).not_to have_tag("a[href='#{@submission_details_url}']")
    end

    it "should be hidden for admin if assignment is anonymous grading and muted" do
      @user = account_admin_user
      assign(:presenter, GradeSummaryPresenter.new(@course, @user, @student.id))
      view_context
      render "gradebooks/grade_summary"
      expect(response).not_to have_tag("a[href='#{@submission_details_url}']")
    end

    it "should be shown for site admin if assignment is anonymous grading and muted" do
      @user = site_admin_user
      assign(:presenter, GradeSummaryPresenter.new(@course, @user, @student.id))
      view_context
      render "gradebooks/grade_summary"
      expect(response).to have_tag("a[href='#{@submission_details_url}']")
    end
  end
end
