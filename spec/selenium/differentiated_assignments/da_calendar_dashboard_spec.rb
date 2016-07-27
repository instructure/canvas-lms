require File.expand_path(File.dirname(__FILE__) + '/../helpers/assignments_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/differentiated_assignments')

describe "interaction with differentiated assignments on the dashboard and calendar" do
  include_context "in-process server selenium tests"
  include DifferentiatedAssignments
  include AssignmentsCommon

  context "Student" do
    before :each do
      course_with_student_logged_in
      da_setup
      create_da_assignment
    end

    context "Main Dashboard" do
      it "should not show inaccessible assignments in the To Do section" do
        create_section_override_for_assignment(@da_assignment, course_section: @section1)
        get "/"
        expect(f("#right-side")).not_to include_text("Turn in DA assignment")
      end
      it "should show assignments with an override in the To Do section" do
        create_section_override_for_assignment(@da_assignment, due_at: 4.days.from_now)
        get "/"
        expect(f("#right-side")).to include_text("Turn in DA assignment")
      end
      it "should not show inaccessible assignments in Recent activity" do
        create_section_override_for_assignment(@da_assignment, course_section: @section1)
        get "/"
        f('#dashboardToggleButton').click if ENV['CANVAS_FORCE_USE_NEW_STYLES']
        expect(f("#not_right_side .no_recent_messages")).to include_text("No Recent Messages")
      end
    end

    context "Course Dashboard" do
      it "should not show inaccessible assignments in the To Do section" do
        create_section_override_for_assignment(@da_assignment, course_section: @section1)
        get "/courses/#{@course.id}"
        #make sure this element isn't visible as there should be nothing to do.
        expect(f("#content")).not_to contain_css(".to-do-list")
      end
      it "should show assignments with an override in the To Do section" do
        create_section_override_for_assignment(@da_assignment)
        get "/courses/#{@course.id}"
        expect(f(".to-do-list")).to include_text("Turn in DA assignment")
      end
    end

    context "Calendar" do
      it "should not show inaccessible assignments" do
        create_section_override_for_assignment(@da_assignment, course_section: @section1, :due_at => Time.now)
        get "/calendar"
        # there should be no events for this user to see, thus .fc-event-title should be nil
        expect(f(".fc-month-view")).not_to include_text(@da_assignment.title)
      end
      it "should show assignments with an override" do
        create_section_override_for_assignment(@da_assignment, :due_at => Time.now)
        get "/calendar"
        expect(f(".fc-month-view")).to include_text(@da_assignment.title)
      end
      it "should show assignments with a graded submission" do
        @da_assignment.grade_student(@student, {:grade => 10})
        get "/calendar"
        f("#undated-events-button").click
        wait_for_ajaximations
        expect(f("#undated_events_list")).to include_text(@da_assignment.title)
      end
    end
  end

  context "Observer with student" do
    before :each do
      observer_setup
      da_setup
      create_da_assignment
    end

    context "Main Dashboard" do
      it "should not show inaccessible assignments in the To Do section" do
        create_section_override_for_assignment(@da_assignment, course_section: @section1)
        get "/"
        expect(f("#right-side")).not_to include_text("DA assignment")
      end
      it "should show assignments with an override in the To Do section" do
        create_section_override_for_assignment(@da_assignment)
        get "/"
        expect(f("#right-side")).to include_text("DA assignment")
      end
      it "should not show inaccessible assignments in Recent activity" do
        create_section_override_for_assignment(@da_assignment, course_section: @section1)
        get "/"
        f('#dashboardToggleButton').click if ENV['CANVAS_FORCE_USE_NEW_STYLES']
        expect(f("#not_right_side .no_recent_messages")).to include_text("No Recent Messages")
      end
    end

    context "Course Dashboard" do
      it "should not show inaccessible assignments in the To Do section" do
        create_section_override_for_assignment(@da_assignment, course_section: @section1)
        get "/courses/#{@course.id}"
        #make sure this element isn't visible as there should be nothing to do.
        expect(f("#content")).not_to contain_css(".to-do-list")
      end
      it "should show assignments with an override in the To Do section" do
        create_section_override_for_assignment(@da_assignment)
        get "/courses/#{@course.id}"
        expect(f(".coming_up")).to include_text("DA assignment")
      end
    end

    context "Calendar" do
      it "should not show inaccessible assignments" do
        create_section_override_for_assignment(@da_assignment, course_section: @section1, :due_at => Time.now)
        get "/calendar"
        # there should be no events for this user to see, thus .fc-event-month should be nil
        expect(f(".fc-month-view")).not_to include_text(@da_assignment.title)
      end
      it "should show assignments with an override" do
        create_section_override_for_assignment(@da_assignment, :due_at => Time.now)
        get "/calendar"
        expect(f(".fc-month-view")).to include_text(@da_assignment.title)
      end
      it "should show assignments with a graded submission" do
        @da_assignment.grade_student(@student, {:grade => 10})
        get "/calendar"
        f("#undated-events-button").click
        wait_for_ajaximations
        expect(f("#undated_events_list")).to include_text(@da_assignment.title)
      end
    end
  end
end
