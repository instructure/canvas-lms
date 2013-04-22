require File.expand_path(File.dirname(__FILE__) + '/helpers/assignments_common')

describe "quizzes assignments" do
  it_should_behave_like "in-process server selenium tests"


  before (:each) do
    course_with_teacher_logged_in
  end

  context "created on the index page" do
    it "should redirect to the quiz" do
      get "/courses/#{@course.id}/assignments"
      build_assignment_with_type("Quiz", :submit => true)
      expect_new_page_load { f(".assignment_list .group_assignment .assignment_title a").click }
      driver.current_url.should match %r{/courses/\d+/quizzes/\d+}
    end
  end

  context "created with 'more options'" do
    it "should redirect to the quiz new page and maintain parameters" do
      get "/courses/#{@course.id}/assignments"
      build_assignment_with_type("Quiz", :name => "Testy!")
      expect_new_page_load { f('.more_options_link').click }
      wait_for_ajaximations
      fj('input[name="quiz[title]"]').attribute(:value).should == "Testy!"
    end
  end

  context "edited from the index page" do
    it "should update quiz when updated" do
      assign = @course.assignments.create!(:name => "Testy!", :submission_types => "online_quiz")
      get "/courses/#{@course.id}/assignments"
      driver.execute_script %{$('#assignment_#{assign.id} .edit_assignment_link:first').addClass('focus');}
      f("#assignment_#{assign.id} .edit_assignment_link").click
      edit_assignment(:name => "Retest!", :submit => true)
      Quiz.find_by_assignment_id(assign.id).title.should == "Retest!"
    end
  end

  context "edited with 'more options'" do
    it "should redirect to the quiz edit page and maintain parameters" do
      assign = @course.assignments.create!(:name => "Testy!", :submission_types => "online_quiz")
      get "/courses/#{@course.id}/assignments"
      driver.execute_script %{$('#assignment_#{assign.id} .edit_assignment_link:first').addClass('focus');}
      f("#assignment_#{assign.id} .edit_assignment_link").click
      edit_assignment(:name => "Retest!")
      expect_new_page_load { f('.more_options_link').click }
      wait_for_ajaximations
      fj('input[name="quiz[title]"]').attribute(:value).should == "Retest!"
    end
  end
end
