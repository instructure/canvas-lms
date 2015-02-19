require File.expand_path(File.dirname(__FILE__) + '/common')

describe "grading periods" do
  include_examples "in-process server selenium tests"

  describe "Course Grading Periods" do
    before(:each) do
      course_with_teacher_logged_in
    end

    context "with Multiple Grading Periods feature on" do
      before(:each) do
        @course.root_account.enable_feature!(:multiple_grading_periods)
      end

      it "should contain a tab for grading periods" do
        get "/courses/#{@course.id}/grading_standards"
        expect(f(".grading_periods_tab")).to be_displayed
      end

      it "should show grading periods created at the course-level" do
        course_grading_period = create_grading_periods_for(@course).first
        get "/courses/#{@course.id}/grading_standards"
        expect(f("#period_title_#{course_grading_period.id}").attribute("value")).to eq(course_grading_period.title)
      end

      it "should show grading periods created by an associated account" do
        pending("this test marked as pending until the grading periods API
                  is changed to return grading periods created at the account
                  level for a given course (in addition to returning grading periods
                  created at the course level")
        account_grading_period = create_grading_periods_for(@course.root_account).first
        get "/courses/#{@course.id}/grading_standards"
        expect(f("#period_title_#{account_grading_period.id}").attribute("value")).to eq(account_grading_period.title)
      end

      it "should allow grading periods to be deleted" do
        grading_period_selector = '.grading-period'
        create_grading_periods_for(@course)
        get "/courses/#{@course.id}/grading_standards"
        expect(ff(grading_period_selector).length).to be 1

        f('.icon-delete-grading-period').click
        driver.switch_to.alert.accept
        wait_for_ajaximations
        expect(ff(grading_period_selector).length).to be 0
      end
    end

    context "with Multiple Grading Periods feature off" do
      it "should not contain a tab for grading periods" do
        get "/courses/#{@course.id}/grading_standards"
        expect(f(".grading_periods_tab")).to be_nil
      end
    end
  end

  describe "Account Grading Periods" do
    before(:each) do
      course_with_admin_logged_in
      @account = @course.root_account
    end

    context "with Multiple Grading Periods feature on" do
      before(:each) do
        @account.enable_feature!(:multiple_grading_periods)
      end

      it "should contain a tab for grading periods" do
        get "/accounts/#{@account.id}/grading_standards"
        expect(f(".grading_periods_tab")).to be_displayed
      end

      it "should show grading periods created at the account-level" do
        account_grading_period = create_grading_periods_for(@account).first
        get "/accounts/#{@account.id}/grading_standards"
        expect(f("#period_title_#{account_grading_period.id}").attribute("value")).to eq(account_grading_period.title)
      end

      it "should NOT show grading periods created by courses under this account" do
        course_grading_period = create_grading_periods_for(@course).first
        get "/accounts/#{@account.id}/grading_standards"
        expect(f("#period_title_#{course_grading_period.id}")).to be_nil
      end
    end

    context "with Multiple Grading Periods feature off" do
      it "should not contain a tab for grading periods" do
        get "/courses/#{@course.id}/grading_standards"
        expect(f(".grading_periods_tab")).to be_nil
      end
    end
  end
end
