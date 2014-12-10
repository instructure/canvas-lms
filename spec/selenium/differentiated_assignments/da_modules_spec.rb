require File.expand_path(File.dirname(__FILE__) + '/../helpers/assignments_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/differentiated_assignments')

describe "interaction with differentiated assignments/quizzes/discusssions in modules" do
  include_examples "in-process server selenium tests"

  context "Student" do
    before :each do
      course_with_student_logged_in
      da_setup
      da_module_setup
    end

    it "should not show inaccessible module items" do
      create_section_overrides(@section1)
      get "/courses/#{@course.id}/modules"
      expect(f("#context_module_#{@module.id}")).not_to include_text(@da_assignment.title)
      expect(f("#context_module_#{@module.id}")).not_to include_text(@da_discussion.title)
      expect(f("#context_module_#{@module.id}")).not_to include_text(@da_quiz.title)
    end
    it "should display module items with overrides" do
      create_section_overrides(@other_section)
      get "/courses/#{@course.id}/modules"
      expect(f("#context_module_#{@module.id}")).to include_text(@da_assignment.title)
      expect(f("#context_module_#{@module.id}")).to include_text(@da_discussion.title)
      expect(f("#context_module_#{@module.id}")).to include_text(@da_quiz.title)
    end
    it "should show module items with graded submissions" do
      grade_da_assignments
      get "/courses/#{@course.id}/modules"
      expect(f("#context_module_#{@module.id}")).to include_text(@da_assignment.title)
      expect(f("#context_module_#{@module.id}")).to include_text(@da_discussion.title)
      expect(f("#context_module_#{@module.id}")).to include_text(@da_quiz.title)
    end
    it "should ignore completion requirements of inaccessible module items" do
      create_section_override_for_assignment(@da_discussion.assignment, course_section: @other_section)
      create_section_override_for_assignment(@da_quiz, course_section: @other_section)
      create_section_override_for_assignment(@da_assignment, course_section: @section1)
      @module.completion_requirements = {@tag_assignment.id => {:type => 'must_view'},
                                         @tag_discussion.id => {:type => 'must_view'},
                                         @tag_quiz.id => {:type => 'must_view'}
                                         }
      @module.save
      expect(@module.evaluate_for(@student).workflow_state).to include_text("unlocked")
      get "/courses/#{@course.id}/modules/items/#{@tag_discussion.id}"
      wait_for_ajaximations
      get "/courses/#{@course.id}/modules/items/#{@tag_quiz.id}"
      #confirm canvas believes this module is now completed despite the invisible assignment not having been viewed
      expect(@module.evaluate_for(@student).workflow_state).to include_text("completed")
    end
  end

  context "Observer" do
    context "with a student attached" do
      before :each do
        observer_setup
        da_setup
        da_module_setup
      end

      it "should not show inaccessible module items" do
        create_section_overrides(@section1)
        get "/courses/#{@course.id}/modules"
        expect(f("#context_module_#{@module.id}")).not_to include_text(@da_assignment.title)
        expect(f("#context_module_#{@module.id}")).not_to include_text(@da_discussion.title)
        expect(f("#context_module_#{@module.id}")).not_to include_text(@da_quiz.title)
      end
      it "should display module items with overrides" do
        create_section_overrides(@other_section)
        get "/courses/#{@course.id}/modules"
        expect(f("#context_module_#{@module.id}")).to include_text(@da_assignment.title)
        expect(f("#context_module_#{@module.id}")).to include_text(@da_discussion.title)
        expect(f("#context_module_#{@module.id}")).to include_text(@da_quiz.title)
      end
      it "should show module items with graded submissions" do
        grade_da_assignments
        get "/courses/#{@course.id}/modules"
        expect(f("#context_module_#{@module.id}")).to include_text(@da_assignment.title)
        expect(f("#context_module_#{@module.id}")).to include_text(@da_discussion.title)
        expect(f("#context_module_#{@module.id}")).to include_text(@da_quiz.title)
      end
    end

    context "without a student attached" do
      before :each do
        course_with_observer_logged_in
        da_setup
        da_module_setup
      end

      it "should display all module items" do
        get "/courses/#{@course.id}/modules"
        expect(f("#context_module_#{@module.id}")).to include_text(@da_assignment.title)
        expect(f("#context_module_#{@module.id}")).to include_text(@da_discussion.title)
        expect(f("#context_module_#{@module.id}")).to include_text(@da_quiz.title)
      end
    end
  end
end