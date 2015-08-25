# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/common')

describe "sections" do
  include_context "in-process server selenium tests"

  context "as a teacher" do

    it "should only show users enrolled in the section on the section page" do
      course_with_teacher_logged_in(:active_course => true, :active_user => true)
      @section = @course.course_sections.create!
      e2 = student_in_course(:active_all => true, :name => "Señor Chang")
      e2.course_section = @section
      e2.save!

      get "/courses/#{@course.id}/sections/#{@section.id}"
      wait_for_ajaximations

      expect(ff("#current-enrollment-list .user").count).to eq 1
      expect(f("#enrollment_#{e2.id}")).to include_text e2.user.name

      get "/courses/#{@course.id}/sections/#{@course.default_section.id}"
      wait_for_ajaximations

      expect(ff("#current-enrollment-list .user").count).to eq 1
      expect(f("#enrollment_#{@teacher.enrollments.first.id}")).to include_text @teacher.name
    end
  end
end
