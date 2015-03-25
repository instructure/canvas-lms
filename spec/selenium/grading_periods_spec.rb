require File.expand_path(File.dirname(__FILE__) + '/common')

describe "grading periods" do
  include_examples "in-process server selenium tests"

  describe "Course Grading Periods" do
    before(:each) do
      course_with_teacher_logged_in
    end

    context "with Multiple Grading Periods feature on" do
      before(:each) do
        @course.root_account.allow_feature!(:multiple_grading_periods)
        @course.account.enable_feature!(:multiple_grading_periods)
      end

      it "should contain a tab for grading periods" do
        get "/courses/#{@course.id}/grading_standards"
        expect(f(".grading_periods_tab")).to be_displayed
      end

      it "should show grading periods created at the Course-level" do
        grading_period_group = @course.grading_period_groups.create!
        grading_period = grading_period_group.grading_periods.create!(title: "Course-level grading period",
                                                                      start_date: Time.zone.now,
                                                                      end_date: 30.days.from_now)
        get "/courses/#{@course.id}/grading_standards"
        expect(f("#period_title_#{grading_period.id}").attribute("value")).to eq("Course-level grading period")
      end

      it "should show grading periods created by an associated Account" do
        pending("this test marked as pending until the grading periods API
                  is changed to return grading periods created at the Account
                  level for a given course (in addition to returning grading periods
                  created at the Course level")
        grading_period_group = @course.root_account.grading_period_groups.create!
        grading_period = grading_period_group.grading_periods.create!(title: "Account-level grading period",
                                                                      start_date: Time.zone.now,
                                                                      end_date: 30.days.from_now)
        get "/courses/#{@course.id}/grading_standards"
        expect(f("#period_title_#{grading_period.id}").attribute("value")).to eq("Account-level grading period")
      end

      it "should allow grading periods to be deleted" do
        grading_period_selector = '.grading-period'
        grading_period_group = @course.grading_period_groups.create!
        grading_period = grading_period_group.grading_periods.create!(title: "Delete me, please!",
                                                                      start_date: Time.zone.now,
                                                                      end_date: 30.days.from_now,
                                                                      weight: 1)
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
        @account.allow_feature!(:multiple_grading_periods)
        @course.account.enable_feature!(:multiple_grading_periods)
      end

      it "should contain a tab for grading periods" do
        get "/accounts/#{@account.id}/grading_standards"
        expect(f(".grading_periods_tab")).to be_displayed
      end

      it "should show grading periods created at the Account-level" do
        grading_period_group = @account.grading_period_groups.create!
        grading_period = grading_period_group.grading_periods.create!(title: "Account-level grading period",
                                                                      start_date: Time.zone.now,
                                                                      end_date: 30.days.from_now)
        get "/accounts/#{@account.id}/grading_standards"
        expect(f("#period_title_#{grading_period.id}").attribute("value")).to eq("Account-level grading period")
      end

      it "should NOT show grading periods created by Courses under this account" do
        grading_period_group = @course.grading_period_groups.create!
        grading_period = grading_period_group.grading_periods.create!(title: "Course-level grading period",
                                                                      start_date: Time.zone.now,
                                                                      end_date: 30.days.from_now)
        get "/accounts/#{@account.id}/grading_standards"
        expect(f("#period_title_#{grading_period.id}")).to be_nil
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
