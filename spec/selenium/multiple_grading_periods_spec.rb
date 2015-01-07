require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook2_common')

describe "interaction with multiple grading periods" do
  include_examples "in-process server selenium tests"

  def set_up_multiple_grading_periods
    @course.account.enable_feature!(:multiple_grading_periods)
    @group1 = @course.assignment_groups.create!(name: 'group1', postion: 10, group_weight: 40)
    @group2 = @course.assignment_groups.create!(name: 'group2', postion: 7, group_weight: 60)
    @course.assignments.create!(assignment_group: @group1, due_at: Time.now)
    @course.assignments.create!(assignment_group: @group1, due_at: 3.months.from_now)
    @course.assignments.create!(assignment_group: @group2, due_at: Time.now)
    gpg = @course.grading_period_groups.create!
    @gp1 = gpg.grading_periods.create!(title: "Today", workflow_state: "active", weight: 50, start_date: 1.month.ago, end_date: 1.month.from_now)
    @gp2 = gpg.grading_periods.create!(title: "Future", workflow_state: "active", weight: 50, start_date: 2.months.from_now, end_date: 4.months.from_now)
  end


  context "gradebook" do

    before :each do
      gradebook_data_setup
      set_up_multiple_grading_periods
    end

    it "should display the correct grading period based on the GET param" do
      get "/courses/#{@course.id}/gradebook?grading_period_id=#{@gp2.id}"
      expect(f('.grading-period-select-button')).to include_text(@gp2.title)
    end

    it "should display All Grading Periods with a 0 GET param" do
      get "/courses/#{@course.id}/gradebook?grading_period_id=0"
      expect(f('.grading-period-select-button')).to include_text("All Grading Periods")
    end

    it "should display the current grading period without a GET param" do
      get "/courses/#{@course.id}/gradebook"
      expect(f('.grading-period-select-button')).to include_text(@gp1.title)
    end
  end


end