require File.expand_path(File.dirname(__FILE__) + '/common')

describe "Grading periods (more)" do
  include_examples "in-process server selenium tests"

  describe "Account Grading Periods" do
    before(:each) do
      course_with_admin_logged_in
      @account = @course.root_account
      get "/accounts/#{@account.id}/grading_standards"
    end

    context "with Multiple Grading Periods feature on," do
      TITLE = 'hi'
      START_DATE = 'Feb 1'
      END_DATE = 'Feb 28'

      before(:each) do
        @account.enable_feature!(:multiple_grading_periods)
      end

      it "add without saving doesn't create a grading period", priority: "1", test_id: 202308 do
        get "/accounts/#{@account.id}/grading_standards"
        f('#add-period-button').click
        refresh_page
        expect(ff('.grading-period').length).to eq(0)
      end

      it "creates a grading period", priority: "1", test_id: 244001 do
        get "/accounts/#{@account.id}/grading_standards"
        f('#add-period-button').click
        f('#period_title_new2').send_keys TITLE, :return
        f('#period_start_date_new2').send_keys START_DATE, :return
        f('#period_end_date_new2').send_keys END_DATE, :return
        f('#update-button').click
        refresh_page
        expect(ff('.grading-period').length).to eq(1)
        id = GradingPeriod.where(title: TITLE).first.id
        expect(f("#period_title_#{id}")).to have_value(TITLE)
        expect(f("#period_start_date_#{id}")).to have_value("#{START_DATE}, #{Time.zone.now.year} at 12:00am")
        expect(f("#period_end_date_#{id}")).to have_value("#{END_DATE}, #{Time.zone.now.year} at 12:00am")
      end

      it "flashes error if missing info", priority: "1", test_id: 202310 do
        get "/accounts/#{@account.id}/grading_standards"
        f('#add-period-button').click
        f('#period_title_new2').send_keys TITLE, :return
        f('#update-button').click
        assert_flash_error_message(/All dates fields must be present and formatted correctly/)

        # fill out the rest of the fields
        f('#period_start_date_new2').send_keys START_DATE, :return
        f('#period_end_date_new2').send_keys END_DATE, :return
        f('#update-button').click
        expect(ff('.grading-period').length).to eq(1)
      end

      it "reads only account level grading periods", priority: "1", test_id: 202311 do
        sub_account = Account.create(name: 'sub account from default account', parent_account: Account.default)
        account_grading_period = create_grading_periods_for(@account).first

        # these should NOT show up on account grading periods page
        create_grading_periods_for(sub_account).first.title = "Sub"
        create_grading_periods_for(@course).first.title = "Course"

        get "/accounts/#{@account.id}/grading_standards"
        expect(ff('.grading-period').length).to eq(1)
        expect(f("#period_title_#{account_grading_period.id}").attribute('value')).to eq(account_grading_period.title)
      end

      it "flashes a notice message when saved", priority: "1", test_id: 202312 do
        get "/accounts/#{@account.id}/grading_standards"
        f('#add-period-button').click
        f('#period_title_new2').send_keys TITLE, :return
        f('#period_start_date_new2').send_keys START_DATE, :return
        f('#period_end_date_new2').send_keys END_DATE, :return
        f('#update-button').click
        assert_flash_notice_message(/All changes were saved/)
      end

      it "verifies with alert modal before deletion", priority: "1", test_id: 202313 do
        create_grading_periods_for(@account)
        get "/accounts/#{@account.id}/grading_standards"
        ff('.icon-delete-grading-period').first.click
        expect(driver.switch_to.alert.text).to eq('Are you sure you want to delete this grading period?')
        driver.switch_to.alert.accept
        wait_for_ajaximations
        expect(ff('.grading-period').length).to eq(0)
      end

      it "deletes an unsaved grading period", priority: "1", test_id: 202314 do
        get "/courses/#{@course.id}/grading_standards"
        f('#add-period-button').click
        expect(ff('.grading-period').length).to be(1)
        ff('.icon-delete-grading-period').first.click
        wait_for_ajaximations
        expect(ff('.grading-period').length).to be(0)
      end
    end # mgp feature on
  end  # account grading periods
end
