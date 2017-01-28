require File.expand_path(File.dirname(__FILE__) + '/helpers/context_modules_common')

describe "context modules" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon

  context "as an observer" do
    before(:each) do
      @course = course_factory(active_all: true)
      @student = user_factory(active_all: true, :active_state => 'active')
      @observer = user_factory(active_all: true, :active_state => 'active')

      @student_enrollment = @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active')

      @assignment = @course.assignments.create!(:title => 'assignment 1', :name => 'assignment 1')
      @due_at = 1.year.from_now
      override_for_student(@student, @due_at)

      course_module
      @module.add_item({:id => @assignment.id, :type => 'assignment'})

      user_session(@observer)
    end

    def override_for_student(student, due_at)
      override = assignment_override_model(:assignment => @assignment)
      override.override_due_at(due_at)
      override.save!
      override_student = override.assignment_override_students.build
      override_student.user = student
      override_student.save!
    end

    def section_due_date_override(due_at)
      section2 = @course.course_sections.create!
      override = assignment_override_model(:assignment => @assignment)
      override.set = section2
      override.override_due_at(due_at)
      override.save!
      return section2
    end

    it "when not associated, and in one section, it should show the section's due date" do
      section2 = section_due_date_override(@due_at)
      @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :enrollment_state => 'active', :section => section2)
      get "/courses/#{@course.id}/modules"
      expect(f(".due_date_display").text).not_to be_blank
      expect(f(".due_date_display").text).to eq format_date_for_view(@due_at)
    end

    it "when not associated, and in multiple sections, it should show the latest due date" do
      override = assignment_override_model(:assignment => @assignment)
      override.set = @course.default_section
      override.override_due_at(@due_at)
      override.save!
      section2 = section_due_date_override(@due_at - 1.day)

      @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :enrollment_state => 'active')
      @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :enrollment_state => 'active', :allow_multiple_enrollments => true, :section => section2)
      get "/courses/#{@course.id}/modules"
      expect(f(".due_date_display").text).not_to be_blank
      expect(f(".due_date_display").text).to eq format_date_for_view(@due_at)
    end

    it "when associated with a student, it should show the student's overridden due date" do
      @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :enrollment_state => 'active', :associated_user_id => @student.id)
      get "/courses/#{@course.id}/modules"
      expect(f(".due_date_display").text).to eq format_date_for_view(@due_at)
      expect(f(".due_date_display").text).not_to be_blank
      expect(f(".due_date_display").text).not_to eq "Multiple Due Dates"
    end

    it "should indicate multiple due dates for multiple observed students" do
      section2 = section_due_date_override(@due_at + 1.day)

      student2 = user_factory(active_all: true, :active_state => 'active', :section => section2)
      @course.enroll_user(student2, 'StudentEnrollment', :enrollment_state => 'active')
      @course.enroll_user(@observer, 'ObserverEnrollment', :enrollment_state => 'active', :associated_user_id => @student.id)
      @course.enroll_user(@observer, 'ObserverEnrollment', :enrollment_state => 'active', :allow_multiple_enrollments => true, :associated_user_id => student2.id)

      get "/courses/#{@course.id}/modules"
      expect(f(".due_date_display").text).to eq "Multiple Due Dates"
    end
  end
end
