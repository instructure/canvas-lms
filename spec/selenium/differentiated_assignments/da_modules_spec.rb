require File.expand_path(File.dirname(__FILE__) + '/../helpers/assignments_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/differentiated_assignments')

describe "interaction with differentiated assignments/quizzes/discusssions in modules" do
  include_examples "in-process server selenium tests"

  def expect_module_to_have_items(module_item)
    expect(f("#context_module_#{module_item.id}")).to include_text(@da_assignment.title)
    expect(f("#context_module_#{module_item.id}")).to include_text(@da_discussion.title)
    expect(f("#context_module_#{module_item.id}")).to include_text(@da_quiz.title)
  end

  def expect_module_to_not_have_items(module_item)
    expect(f("#context_module_#{module_item.id}")).not_to include_text(@da_assignment.title)
    expect(f("#context_module_#{module_item.id}")).not_to include_text(@da_discussion.title)
    expect(f("#context_module_#{module_item.id}")).not_to include_text(@da_quiz.title)
  end

  context "Student" do
    before :each do
      course_with_student_logged_in
      da_setup
      da_module_setup
    end

    it "should not show inaccessible module items" do
      create_section_overrides(@section1)
      get "/courses/#{@course.id}/modules"
      expect_module_to_not_have_items(@module)
    end
    it "should display module items with overrides" do
      create_section_overrides(@default_section)
      get "/courses/#{@course.id}/modules"
      expect_module_to_have_items(@module)
    end
    it "should show module items with graded submissions" do
      grade_da_assignments
      get "/courses/#{@course.id}/modules"
      expect_module_to_have_items(@module)
    end
    it "should ignore completion requirements of inaccessible module items" do
      create_section_override_for_assignment(@da_discussion.assignment)
      create_section_override_for_assignment(@da_quiz)
      create_section_override_for_assignment(@da_assignment, course_section: @section1)
      @module.completion_requirements = {@tag_assignment.id => {:type => 'must_view'},
                                         @tag_discussion.id => {:type => 'must_view'},
                                         @tag_quiz.id => {:type => 'must_view'}
                                         }
      @module.save
      expect(@module.evaluate_for(@student).workflow_state).to include_text("unlocked")
      get "/courses/#{@course.id}/modules/items/#{@tag_discussion.id}"
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
        expect_module_to_not_have_items(@module)
      end
      it "should display module items with overrides" do
        create_section_overrides(@default_section)
        get "/courses/#{@course.id}/modules"
        expect_module_to_have_items(@module)
      end
      it "should show module items with graded submissions" do
        grade_da_assignments
        get "/courses/#{@course.id}/modules"
        expect_module_to_have_items(@module)
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
        expect_module_to_have_items(@module)
      end
    end
  end
end