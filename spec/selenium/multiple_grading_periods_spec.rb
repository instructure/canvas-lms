require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook2_common')

describe "interaction with multiple grading periods" do
  include_examples "in-process server selenium tests"

  context "gradebook" do
    before :each do
      gradebook_data_setup(grading_periods: [:future, :current])
    end

    it "should display the correct grading period based on the GET param" do
      future_grading_period = @course.grading_periods.first
      get "/courses/#{@course.id}/gradebook?grading_period_id=#{future_grading_period.id}"
      expect(f('.grading-period-select-button')).to include_text(future_grading_period.title)
    end

    it "should not display All Grading Periods when a grading period id is provided" do
      get "/courses/#{@course.id}/gradebook?grading_period_id=2"
      expect(f('.grading-period-select-button')).to_not be_present
    end

    it "should display All Grading Periods when grading period id is set to 0" do
      get "/courses/#{@course.id}/gradebook?grading_period_id=0"
      expect(f('.grading-period-select-button')).to include_text("All Grading Periods")
    end

    it "should display the current grading period without a GET param" do
      current_grading_period = @course.grading_periods.second
      get "/courses/#{@course.id}/gradebook"
      expect(f('.grading-period-select-button')).to include_text(current_grading_period.title)
    end
  end
end
