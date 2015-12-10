require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook2_common')

describe "interaction with multiple grading periods" do
  include_context "in-process server selenium tests"
  include Gradebook2Common

  context "gradebook" do
    before :each do
      gradebook_data_setup(grading_periods: [:future, :current])
    end

    it "should display the correct grading period based on the GET param" do
      future_grading_period = @course.grading_periods.detect{|gp| gp.start_date > Time.now}
      get "/courses/#{@course.id}/gradebook?grading_period_id=#{future_grading_period.id}"
      expect(f('.grading-period-select-button')).to include_text(future_grading_period.title)
    end

    it "should display All Grading Periods when grading period id is set to 0" do
      get "/courses/#{@course.id}/gradebook?grading_period_id=0"
      expect(f('.grading-period-select-button')).to include_text("All Grading Periods")
    end

    it "should display the current grading period without a GET param" do
      current_grading_period = @course.grading_periods.detect{|gp| gp.start_date < Time.now}
      get "/courses/#{@course.id}/gradebook"
      expect(f('.grading-period-select-button')).to include_text(current_grading_period.title)
    end
  end

  context 'grading schemes' do
    let(:account) { Account.default }
    let(:admin) { account_admin_user(:account => account) }
    let!(:enable_mgp_flag) { account.enable_feature!(:multiple_grading_periods) }

    it 'should still be functional with mgp flag turned on and disable adding during edit mode', priority: "1", test_id: 545585 do
      user_session(admin)
      get "/accounts/#{account.id}/grading_standards"
      fj('#react_grading_tabs a[href="#grading-standards-tab"]').click
      fj('a.btn.pull-right.add_standard_link').click
      expect(fj('input.scheme_name')).not_to be_nil
      expect(fj('a.btn.pull-right.add_standard_link')).to have_class('disabled')
    end
  end
end
