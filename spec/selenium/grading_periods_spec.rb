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

      it "should create a blank grading period form when Add Grading Period is clicked" do
        get "/courses/#{@course.id}/grading_standards"
        expect(ff('.grading-period').length).to eq(0)
        f('#add-grading-period-button').click
        expect(ff('.grading-period').length).to eq(1)
      end

      it "should prevent saving a grading period until each input is filled out" do
        get "/courses/#{@course.id}/grading_standards"
        f('#add-grading-period-button').click

        expect(f('.update-button')['disabled']).to eq("true")
        f('#period_title_new2').send_keys 'grading period name'
        f('#period_start_date_new2').send_keys 'Feb 12, 2015'
        f('#period_end_date_new2').send_keys 'Feb 13, 2015'
        f('.grading-period').click
        expect(f('.update-button')['disabled']).to be_nil
      end

      it "should remove an unsaved grading period from the dom gracefully" do
        get "/courses/#{@course.id}/grading_standards"
        f('#add-grading-period-button').click
        expect(ff('.grading-period').length).to be(1)
        f('.icon-delete-grading-period').click
        expect(ff('.grading-period').length).to be(0)
      end

      it "should warn user start_date occurs after end_date" do
        get "/courses/#{@course.id}/grading_standards"
        f('#add-grading-period-button').click
        f('#period_title_new2').send_keys 'hi'
        f('#period_start_date_new2').send_keys 'Feb 2'
        f('#period_end_date_new2').send_keys 'Feb 1'
        f('.grading-period').click

        f('.update-button').click
        assert_error_box '#period_start_date_new2'
      end

      it "submit button should say 'save' when creating a new grading period" do
        get "/courses/#{@course.id}/grading_standards"
        f('#add-grading-period-button').click
        expect(f('.update-button').text).to eq('Save')
      end

      it "submit button should save 'update' when updating a grading period" do
        grading_period_group = @course.grading_period_groups.create!
        grading_period_group.grading_periods.create!(title: "Delete me, please!",
            start_date: Time.zone.now,
            end_date: 30.days.from_now,
            weight: 1)

        get "/courses/#{@course.id}/grading_standards"
        expect(f('.update-button').text).to eq('Update')
      end

      it "should allow user to add multiple grading periods simultaneously" do
        get "/courses/#{@course.id}/grading_standards"
        3.times { f('#add-grading-period-button').click }
        expect(ff('.grading-period').length).to eq(3)
      end

      it "should allow user to save grading period" do
        grading_period_title = 'grading period name'
        get "/courses/#{@course.id}/grading_standards"
        f('#add-grading-period-button').click

        f('#period_title_new2').send_keys grading_period_title
        f('#period_start_date_new2').send_keys 'Feb 12, 2015'
        f('#period_end_date_new2').send_keys 'Feb 22, 2015'
        f('.grading-period').click
        f('.update-button').click
        wait_for_ajax_requests
        expect(GradingPeriod.last.title).to eq(grading_period_title)
      end

      it "should allow users to update a grading period" do
        updated_grading_period_title = 'updated'
        grading_period_group = @course.grading_period_groups.create!
        grading_period = grading_period_group.grading_periods.create!(title: "Delete me, please!",
            start_date: Time.zone.now,
            end_date: 30.days.from_now)

        get "/courses/#{@course.id}/grading_standards"
        replace_content(f('#period_title_' + grading_period.id.to_s), updated_grading_period_title)
        f('.grading-period').click
        f('.update-button').click
        wait_for_ajax_requests

        expect(GradingPeriod.last.title).to eq(updated_grading_period_title)
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
