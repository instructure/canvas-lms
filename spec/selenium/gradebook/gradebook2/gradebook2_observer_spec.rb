require_relative '../../helpers/gradebook2_common'

describe "gradebook2" do
  include_context "in-process server selenium tests"
  include Gradebook2Common

  context "as an observer" do
    before(:each) do
      data_setup_as_observer
    end

    it "should allow observer to see grade totals" do
      get "/courses/#{@course.id}/grades/#{@student_2.id}"
      expect(f(".final_grade .grade")).to include_text("66.67")
      f("#only_consider_graded_assignments_wrapper").click
      wait_for_ajax_requests
      expect(f(".final_grade .grade")).to include_text("12.5")
    end
  end
end
