require File.expand_path(File.dirname(__FILE__) + '/helpers/assignments_common')

describe "quizzes assignments" do
  include_context "in-process server selenium tests"


  before (:each) do
    @domain_root_account = Account.default
    course_with_teacher_logged_in
  end

  context "created on the index page" do
    it "should redirect to the quiz", priority: "2", test_id: 220306 do
      ag = @course.assignment_groups.create!(:name => "Quiz group")
      get "/courses/#{@course.id}/assignments"
      build_assignment_with_type("Quiz", :assignment_group_id => ag.id, :name => "New Quiz", :submit => true)
      expect_new_page_load { f("#assignment_group_#{ag.id}_assignments .ig-title").click }
      expect(driver.current_url).to match %r{/courses/\d+/quizzes/\d+}
    end
  end

  context "created with 'more options'" do
    it "should redirect to the quiz new page and maintain parameters", priority: "2", test_id: 220307 do
      ag = @course.assignment_groups.create!(:name => "Quiz group")
      get "/courses/#{@course.id}/assignments"
      expect_new_page_load { build_assignment_with_type("Quiz", :assignment_group_id => ag.id, :name => "Testy!", :more_options => true) }
      expect(fj('input[name="quiz[title]"]').attribute(:value)).to eq "Testy!"
    end
  end

  context "edited from the index page" do
    it "should update quiz when updated", priority: "1", test_id: 220308 do
      assign = @course.assignments.create!(:name => "Testy!", :submission_types => "online_quiz")
      get "/courses/#{@course.id}/assignments"
      edit_assignment(assign.id, :name => "Retest!", :submit => true)
      expect(Quizzes::Quiz.where(assignment_id: assign).first.title).to eq "Retest!"
    end
  end

  context "edited with 'more options'" do
    it "should redirect to the quiz edit page and maintain parameters", priority: "2", test_id: 220309 do
      assign = @course.assignments.create!(:name => "Testy!", :submission_types => "online_quiz")
      get "/courses/#{@course.id}/assignments"
      expect_new_page_load { edit_assignment(assign.id, :name => "Retest!", :more_options => true)}
      expect(fj('input[name="quiz[title]"]').attribute(:value)).to eq "Retest!"
    end
  end
end
