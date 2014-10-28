require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/assignment_overrides.rb')

describe "quizzes with draft state" do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  include AssignmentOverridesSeleniumHelper
  include_examples "quizzes selenium tests"

  before(:each) do
    course_with_student_logged_in
    @course.update_attributes(:name => 'teacher course')
    @course.save!
    @course.reload
  end



  context "with an unpublished quiz" do

    it "should show an error to students" do
      @context = @course
      q = quiz_model
      q.unpublish!
      get "/courses/#{@course.id}/quizzes/#{q.id}"
      wait_for_ajaximations
      expect(f("#unauthorized_holder")).to be_displayed
    end

    it "should not be able to take unpublished quiz" do
      @context = @course
      q = quiz_model
      q.unpublish!
      get "/courses/#{@course.id}/quizzes/#{q.id}/take"
      wait_for_ajaximations
      expect(f("#unauthorized_holder")).to be_displayed
    end
  end

  context "with an avaliable date in the future" do

    before(:each) do
      @context = @course
      @q = quiz_model
      @q.unlock_at = Time.now.utc + 200.seconds
      @q.publish!

    end
    it "should show an error if avaliable date in future" do
      get "/courses/#{@course.id}/quizzes/#{@q.id}/"
      wait_for_ajaximations
      expect(f(".lock_explanation")).to be_displayed
    end
  end
end

