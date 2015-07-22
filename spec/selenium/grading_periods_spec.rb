require File.expand_path(File.dirname(__FILE__) + '/common')

describe "grading periods" do
  include_examples "in-process server selenium tests"

  describe "Course Grading Periods" do
    before(:each) do
      course_with_teacher_logged_in
    end

    context "with Multiple Grading Periods feature on," do
      before(:each) do
        @course.root_account.enable_feature!(:multiple_grading_periods)
      end

      it "shows grading periods created at the course-level", priority: "1", test_id: 239998 do
        course_grading_period = create_grading_periods_for(@course).first
        get "/courses/#{@course.id}/grading_standards"
        expect(f("#period_title_#{course_grading_period.id}").attribute("value")).to eq(course_grading_period.title)
      end

      it "shows grading periods created by an associated account", priority: "1", test_id: 239997 do
        account_grading_period = create_grading_periods_for(@course.root_account).first
        get "/courses/#{@course.id}/grading_standards"
        period_title = f("#period_title_#{account_grading_period.id}").attribute("value")
        expect(period_title).to eq(account_grading_period.title)
      end

      it "allows grading periods to be deleted if there are more than 1", priority: "1", test_id: 202320 do
        grading_period_selector = '.grading-period'
        create_grading_periods_for(@course, grading_periods: [:old, :current])
        get "/courses/#{@course.id}/grading_standards"
        expect(ff(grading_period_selector).length).to be 2
        f('.icon-delete-grading-period').click
        driver.switch_to.alert.accept
        wait_for_ajaximations
        expect(ff(grading_period_selector).length).to be 1
      end

      it "creates a blank grading period form when Add Grading Period is clicked", priority: "1", test_id: 239999 do
        get "/courses/#{@course.id}/grading_standards"
        expect(ff('.grading-period').length).to eq(0)
        f('#add-period-button').click
        expect(ff('.grading-period').length).to eq(1)
      end

      it "removes an unsaved grading period from the dom gracefully", priority: "1", test_id: 240000 do
        create_grading_periods_for(@course)
        get "/courses/#{@course.id}/grading_standards"
        f('#add-period-button').click
        expect(ff('.grading-period').length).to be(2)
        ff('.icon-delete-grading-period').second.click
        expect(ff('.grading-period').length).to be(1)
      end

      it "flashes an error to the user if start_date occurs after end_date", priority: "1", test_id: 202309 do
        get "/courses/#{@course.id}/grading_standards"
        f('#add-period-button').click
        f('#period_title_new2').send_keys 'hi'
        f('#period_start_date_new2').send_keys 'Feb 2'
        f('#period_end_date_new2').send_keys 'Feb 1'
        f('.grading-period').click   # clicks away from the edit box to complete entry (method 1)

        # verify that fixing the dates solves the problem
        f('#update-button').click
        assert_flash_error_message(/All start dates must be before the end date/)
        replace_content f('#period_end_date_new2'), 'Feb 3'
        f('#period_end_date_new2').send_keys :return # types return to complete entry (method 2)
        f('#update-button').click
        expect(ff('.grading-period').length).to be 1
      end

      it "flashes an error if the user removes start_date", priority: "1", test_id: 240230 do
        create_grading_periods_for(@course)
        get "/courses/#{@course.id}/grading_standards"

        f("\#period_start_date_#{GradingPeriod.last.id}").clear

        f('#update-button').click
        assert_flash_error_message(/All dates fields must be present and formatted correctly/)
      end

      it "flashes an error if the user removes end_date", priority: "1", test_id: 240231 do
        create_grading_periods_for(@course)
        get "/courses/#{@course.id}/grading_standards"

        f("\#period_end_date_#{GradingPeriod.last.id}").clear

        f('#update-button').click
        assert_flash_error_message(/All dates fields must be present and formatted correctly/)
      end

      it "allows a user to add multiple grading periods simultaneously", priority: "1", test_id: 240002 do
        get "/courses/#{@course.id}/grading_standards"
        3.times { f('#add-period-button').click }
        expect(ff('.grading-period').length).to eq(3)
      end

      it "allows a user to save a grading period", priority: "1", test_id: 202317 do
        grading_period_title = 'grading period name'
        get "/courses/#{@course.id}/grading_standards"
        f('#add-period-button').click

        replace_content f('#period_title_new2'), grading_period_title
        replace_content f('#period_start_date_new2'), 'Feb 12, 2015 at 12:00am'
        replace_content f('#period_end_date_new2'), 'Feb 22, 2015 at 12:00am'
        f('.grading-period').click
        f('#update-button').click
        wait_for_ajax_requests
        expect(GradingPeriod.last.title).to eq(grading_period_title)
      end

      it "allows users to update a grading period", priority: "1", test_id: 202319 do
        updated_grading_period_title = 'updated'
        grading_period_group = @course.grading_period_groups.create!
        grading_period = grading_period_group.grading_periods.create!(title: "Delete me, please!",
            start_date: Time.zone.now,
            end_date: 30.days.from_now)

        get "/courses/#{@course.id}/grading_standards"
        replace_content(f('#period_title_' + grading_period.id.to_s), updated_grading_period_title)
        f('.grading-period').click
        f('#update-button').click
        wait_for_ajax_requests

        expect(GradingPeriod.last.title).to eq(updated_grading_period_title)
      end
    end

    context "with Multiple Grading Periods feature off", priority: "1", test_id: 240005 do
      it "does not contain a tab for grading periods" do
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

    context "with Multiple Grading Periods feature on," do
      before(:each) do
        @account.enable_feature!(:multiple_grading_periods)
      end

      it "shows grading periods created at the account-level", priority: "1", test_id: 240003 do
        account_grading_period = create_grading_periods_for(@account).first
        get "/accounts/#{@account.id}/grading_standards"
        expect(f("#period_title_#{account_grading_period.id}").attribute("value")).to eq(account_grading_period.title)
      end

      it "does NOT show grading periods created by courses under this account", priority: "1", test_id: 240004 do
        course_grading_period = create_grading_periods_for(@course).first
        get "/accounts/#{@account.id}/grading_standards"
        expect(f("#period_title_#{course_grading_period.id}")).to be_nil
      end
    end

    context "with Multiple Grading Periods feature off", priority: "1", test_id: 202305 do
      it "does not contain a tab for grading periods" do
        get "/courses/#{@course.id}/grading_standards"
        expect(f(".grading_periods_tab")).to be_nil
      end
    end
  end
end
