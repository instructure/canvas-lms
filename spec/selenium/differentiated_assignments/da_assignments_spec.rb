require File.expand_path(File.dirname(__FILE__) + '/../helpers/assignments_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/differentiated_assignments')
describe "interaction with differentiated assignments" do
  include_context "in-process server selenium tests"

  context "Student" do
    before :each do
      course_with_student_logged_in
      da_setup
      create_da_assignment
    end

    context "Assignment Index" do
      it "should hide assignments not visible" do
        create_section_override_for_assignment(@da_assignment, course_section: @section1)
        get "/courses/#{@course.id}/assignments"
        expect(f(".ig-empty-msg")).to include_text("No Assignment Groups found")
      end
      it "should show assignments with an override" do
        create_section_override_for_assignment(@da_assignment)
        get "/courses/#{@course.id}/assignments"
        expect(f("#assignment_group_upcoming")).to include_text(@da_assignment.title)
      end
      it "should show assignments with a graded submission" do
        @da_assignment.grade_student(@user, {:grade => 10})
        get "/courses/#{@course.id}/assignments"
        expect(f("#assignment_group_undated")).to include_text(@da_assignment.title)
      end
    end

    context "Assignment Show page and Submission page" do
      it "should redirect back to assignment index from inaccessible assignments" do
        create_section_override_for_assignment(@da_assignment, course_section: @section1)
        get "/courses/#{@course.id}/assignments/#{@da_assignment.id}"
        keep_trying_until { expect(f("#flash_message_holder")).to include_text("The assignment you requested is not available to your course section.") }
        expect(driver.current_url).to match %r{/courses/\d+/assignments}
      end
      it "should show the assignment page with an override" do
        create_section_override_for_assignment(@da_assignment)
        get "/courses/#{@course.id}/assignments/#{@da_assignment.id}"
        expect(driver.current_url).to match %r{/courses/\d+/assignments/#{@da_assignment.id}}
      end
      it "should show the assignment page with a graded submission" do
        @da_assignment.grade_student(@user, {:grade => 10})
        get "/courses/#{@course.id}/assignments/#{@da_assignment.id}"
        expect(driver.current_url).to match %r{/courses/\d+/assignments/#{@da_assignment.id}}
      end
      it "should allow previous submissions to be accessed on an inaccessible assignment" do
        create_section_override_for_assignment(@da_assignment)
        @da_assignment.find_or_create_submission(@student)
        # destroy the override providing visibility to the current student
        AssignmentOverride.find(@da_assignment.assignment_overrides.first!).destroy
        get "/courses/#{@course.id}/assignments/#{@da_assignment.id}/submissions/#{@student.id}"
        # check the preview frame for the success banner and for your submission text
        in_frame('preview_frame') do
          keep_trying_until { expect(f("#flash_message_holder")).to include_text("This assignment will no longer count towards your grade.") }
        end
      end
    end

      context "Student Grades Page" do
        it "should show assignments with an override" do
          create_section_override_for_assignment(@da_assignment)
          get "/courses/#{@course.id}/grades"
          expect(f("#assignments")).to include_text(@da_assignment.title)
        end
        it "should show assignments with a graded submission" do
          @da_assignment.grade_student(@student, {:grade => 10})
          get "/courses/#{@course.id}/grades"
          expect(f("#assignments")).to include_text(@da_assignment.title)
        end
        it "should not show inaccessible assignments" do
          create_section_override_for_assignment(@da_assignment, course_section: @section1)
          get "/courses/#{@course.id}/grades"
          expect(f("#assignments")).not_to include_text(@da_assignment.title)
        end
      end
    end

  context "Observer with student" do
    before :each do
      observer_setup
      da_setup
      create_da_assignment
    end

    context "Assignment Index" do
      it "should hide inaccessible assignments" do
        create_section_override_for_assignment(@da_assignment, course_section: @section1)
        get "/courses/#{@course.id}/assignments"
        expect(f(".ig-empty-msg")).to include_text("No Assignment Groups found")
      end
      it "should show assignments with an override" do
        create_section_override_for_assignment(@da_assignment)
        get "/courses/#{@course.id}/assignments"
        expect(f("#assignment_group_upcoming")).to include_text(@da_assignment.title)
      end
      it "should show assignments with a graded submission" do
        @da_assignment.grade_student(@user, {:grade => 10})
        get "/courses/#{@course.id}/assignments"
        expect(f("#assignment_group_undated")).to include_text(@da_assignment.title)
      end
    end

    context "Assignment Show page and Submission page" do
      it "should redirect back to assignment index from inaccessible assignments" do
        create_section_override_for_assignment(@da_assignment, course_section: @section1)
        get "/courses/#{@course.id}/assignments/#{@da_assignment.id}"
        keep_trying_until { expect(f("#flash_message_holder")).to include_text("The assignment you requested is not available to your course section.") }
        expect(driver.current_url).to match %r{/courses/\d+/assignments}
      end
      it "should show the assignment page with an override" do
        create_section_override_for_assignment(@da_assignment)
        get "/courses/#{@course.id}/assignments/#{@da_assignment.id}"
        expect(driver.current_url).to match %r{/courses/\d+/assignments/#{@da_assignment.id}}
      end
      it "should show the assignment page with a graded submission" do
        @da_assignment.grade_student(@student, {:grade => 10})
        get "/courses/#{@course.id}/assignments/#{@da_assignment.id}"
        expect(driver.current_url).to match %r{/courses/\d+/assignments/#{@da_assignment.id}}
      end
      it "should allow previous submissions to be accessed on an inaccessible assignment" do
        create_section_override_for_assignment(@da_assignment)
        @da_assignment.find_or_create_submission(@student)
        # destroy the override providing visibility to the current student
        AssignmentOverride.find(@da_assignment.assignment_overrides.first!).destroy
        get "/courses/#{@course.id}/assignments/#{@da_assignment.id}/submissions/#{@student.id}"
        # check the preview frame for the success banner and for your submission text
        in_frame('preview_frame') do
          keep_trying_until { expect(f("#flash_message_holder")).to include_text("This assignment will no longer count towards your grade.") }
        end
      end
    end

    context "Student Grades Page" do
      it "should show assignments with an override" do
        create_section_override_for_assignment(@da_assignment)
        get "/courses/#{@course.id}/grades"
        expect(f("#assignments")).to include_text(@da_assignment.title)
      end
      it "should show assignments with a graded submission" do
        @da_assignment.grade_student(@student, {:grade => 10})
        get "/courses/#{@course.id}/grades"
        expect(f("#assignments")).to include_text(@da_assignment.title)
      end
      it "should not show inaccessible assignments" do
        create_section_override_for_assignment(@da_assignment, course_section: @section1)
        get "/courses/#{@course.id}/grades"
        expect(f("#assignments")).not_to include_text(@da_assignment.title)
      end
    end
  end

  context "Teacher" do
    before :each do
      course_with_teacher_logged_in
      da_setup
      create_da_assignment
    end
    it "should hide students from speedgrader if they don't have Differentiated assignment visibility or a graded submission" do
      # this is all setup
      @s1, @s2, @s3, @s4, @s5 = ["Not Displayed", "bob", "steve", "mary", "jeanie"].map do |name|
        course_with_student(:course => @course)
        @student.name = name
        @student.tap(&:save)
      end
      [@s1, @s2, @s3].each do |student|
        @course.enroll_user(student, 'StudentEnrollment', :enrollment_state => 'active', :section => @default_section)
      end
      [@s4, @s5].each do |student|
        @course.enroll_user(student, 'StudentEnrollment', :enrollment_state => 'active', :section => @section1)
      end
      create_section_override_for_assignment(@da_assignment, course_section: @section1)
      @da_assignment.grade_student(@s3, {:grade => 10})

      # evaluate for our data
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@da_assignment.id}"
      f(".ui-selectmenu-icon").click
      [@s1, @s2].each do |student|
        expect(f("#students_selectmenu-menu")).not_to include_text("#{student.name}")
      end
      [@s3, @s4, @s5].each do |student|
        expect(f("#students_selectmenu-menu")).to include_text("#{student.name}")
      end
    end
  end
end
