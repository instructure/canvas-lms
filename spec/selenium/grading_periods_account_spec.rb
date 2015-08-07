require File.expand_path(File.dirname(__FILE__) + '/common')

describe 'Account Grading Periods' do
  include_examples "in-process server selenium tests"

  let(:title) {'hi'}
  let(:start_date) {'Feb 1'}
  let(:end_date)  {'Feb 28'}
  let(:date_time_format)  {'%b %-d, %Y at %-l:%M%P'}   # e.g. May 28, 2015 at 8:58pm

  before(:each) do
    course_with_admin_logged_in
    @account = @course.root_account
  end

  context 'with Multiple Grading Periods feature on,' do
    before(:each) do
      @account.enable_feature!(:multiple_grading_periods)
    end

    it 'shows grading periods created at the account-level', priority: "1", test_id: 240003 do
      account_grading_period = create_grading_periods_for(@account).first
      get "/accounts/#{@account.id}/grading_standards"
      expect(f("#period_title_#{account_grading_period.id}").attribute("value")).to eq(account_grading_period.title)
    end

    it 'does NOT show grading periods created by courses under this account', priority: "1", test_id: 240004 do
      course_grading_period = create_grading_periods_for(@course).first
      get "/accounts/#{@account.id}/grading_standards"
      expect(f("#period_title_#{course_grading_period.id}")).to be_nil
    end

    it 'add without saving does not create a grading period', priority: "1", test_id: 202308 do
      get "/accounts/#{@account.id}/grading_standards"
      f('#add-period-button').click
      refresh_page
      expect(ff('.grading-period').length).to eq(0)
    end

    it 'creates a grading period', priority: "1", test_id: 244001 do
      get "/accounts/#{@account.id}/grading_standards"
      f('#add-period-button').click
      f('#period_title_new2').send_keys title, :return
      f('#period_start_date_new2').send_keys start_date, :return
      f('#period_end_date_new2').send_keys end_date, :return
      f('#update-button').click
      refresh_page
      expect(ff('.grading-period').length).to eq(1)
      id = GradingPeriod.where(title: title).first.id
      expect(f("#period_title_#{id}")).to have_value(title)
      expect(f("#period_start_date_#{id}")).to have_value("#{start_date}, #{Time.zone.now.year} at 12:00am")
      expect(f("#period_end_date_#{id}")).to have_value("#{end_date}, #{Time.zone.now.year} at 12:00am")
    end

    it 'flashes error if missing info', priority: "1", test_id: 202310 do
      get "/accounts/#{@account.id}/grading_standards"
      f('#add-period-button').click
      f('#period_title_new2').send_keys title, :return
      f('#update-button').click
      assert_flash_error_message(/All dates fields must be present and formatted correctly/)

      # fill out the rest of the fields
      f('#period_start_date_new2').send_keys start_date, :return
      f('#period_end_date_new2').send_keys end_date, :return
      f('#update-button').click
      expect(ff('.grading-period').length).to eq(1)
    end

    it 'reads only account level grading periods', priority: "1", test_id: 202311 do
      sub_account = Account.create(name: 'sub account from default account', parent_account: Account.default)
      account_grading_period = create_grading_periods_for(@account).first

      # these should NOT show up on account grading periods page
      create_grading_periods_for(sub_account).first.title = "Sub"
      create_grading_periods_for(@course).first.title = "Course"

      get "/accounts/#{@account.id}/grading_standards"
      expect(ff('.grading-period').length).to eq(1)
      expect(f("#period_title_#{account_grading_period.id}").attribute('value')).to eq(account_grading_period.title)
    end

    it 'flashes a notice message when saved', priority: "1", test_id: 202312 do
      get "/accounts/#{@account.id}/grading_standards"
      f('#add-period-button').click
      f('#period_title_new2').send_keys title, :return
      f('#period_start_date_new2').send_keys start_date, :return
      f('#period_end_date_new2').send_keys end_date, :return
      f('#update-button').click
      assert_flash_notice_message(/All changes were saved/)
    end

    it 'updates a grading period', priority: "1", test_id: 248024 do
      account_grading_period = create_grading_periods_for(@account).first
      id = account_grading_period.id
      get "/accounts/#{@account.id}/grading_standards"

      # edit grading period
      replace_content(f("#period_title_#{id}"), title + "\n")
      replace_content(f("#period_start_date_#{id}"), start_date + "\n")
      replace_content(f("#period_end_date_#{id}"), end_date + "\n")
      f('#update-button').click
      wait_for_ajax_requests

      # check UI
      expect(f("#period_title_#{id}")).to have_value(title)
      expect(f("#period_start_date_#{id}")).to have_value("#{start_date}, #{Time.zone.now.year} at 12:00am")
      expect(f("#period_end_date_#{id}")).to have_value("#{end_date}, #{Time.zone.now.year} at 12:00am")

      # check underlying object
      account_grading_period.reload
      expect(account_grading_period.title).to eq(title)
    end

    it 'verifies with alert modal before deletion', priority: "1", test_id: 202313 do
      create_grading_periods_for(@account)
      get "/accounts/#{@account.id}/grading_standards"
      ff('.icon-delete-grading-period').first.click
      expect(driver.switch_to.alert.text).to eq('Are you sure you want to delete this grading period?')
      driver.switch_to.alert.accept
      wait_for_ajaximations
      expect(ff('.grading-period').length).to eq(0)
    end

    it 'deletes an unsaved grading period', priority: "1", test_id: 202314 do
      get "/courses/#{@course.id}/grading_standards"
      f('#add-period-button').click
      expect(ff('.grading-period').length).to be(1)
      ff('.icon-delete-grading-period').first.click
      wait_for_ajaximations
      expect(ff('.grading-period').length).to be(0)
    end

    # there is a lot of repeated code in the inheritance tests, since we are testing 3 roles on 3 pages
    # the way this works will change soon (MGP version 3), so it makes more sense to wait for these
    # changes before refactoring these tests
    context 'inheritance' do
      before(:each) do
        @account_grading_period = create_grading_periods_for(@account).first
        @id = @account_grading_period.id
      end

      context 'as admin' do
        it 'is inherited by sub-account, reads account grading period', priority: "1", test_id: 202316 do
          sub_account = Account.create(name: 'sub account from default account', parent_account: Account.default)

          # access from sub-account grading_standards page
          # read
          get "/accounts/#{sub_account.id}/grading_standards"
          expect(ff('.grading-period').length).to eq(1)
          expect(f("#period_title_#{@id}")).to have_value(@account_grading_period.title)
          expect(f("#period_start_date_#{@id}")).to have_value(@account_grading_period.start_date.strftime(date_time_format))
          expect(f("#period_end_date_#{@id}")).to have_value(@account_grading_period.end_date.strftime(date_time_format))
        end

        it 'is inherited by sub-account, editing from sub-account page creates a copy', priority: "1", test_id: 250248 do
          sub_account = Account.create(name: 'sub account from default account', parent_account: Account.default)

          # access from sub-account grading_standards page
          get "/accounts/#{sub_account.id}/grading_standards"

          # edit grading period
          replace_content(f("#period_title_#{@id}"), title + "\n")
          replace_content(f("#period_start_date_#{@id}"), start_date + "\n")
          replace_content(f("#period_end_date_#{@id}"), end_date + "\n")
          f('#update-button').click
          wait_for_ajax_requests

          # should have created a new sub-account grading period - original should NOT change
          @account_grading_period.reload  # make sure original grading period is updated in case it changed

          new_grading_period = GradingPeriod.where(title: title).first
          new_id = new_grading_period.id
          expect(new_id).to_not eq(@id)
          expect(new_grading_period).to_not be(@account_grading_period) # check for same object

          # check UI
          expect(f("#period_title_#{new_id}")).to have_value(title)
          expect(f("#period_start_date_#{new_id}")).to have_value("#{start_date}, #{Time.zone.now.year} at 12:00am")
          expect(f("#period_end_date_#{new_id}")).to have_value("#{end_date}, #{Time.zone.now.year} at 12:00am")
        end

        it 'is inherited by course, reads account grading period', priority: "1", test_id: 250249 do
          # access from course grading_standards page
          # read
          get "/courses/#{@course.id}/grading_standards"

          expect(ff('.grading-period').length).to eq(1)
          expect(f("#period_title_#{@id}")).to have_value(@account_grading_period.title)
        end

        it 'is inherited by course, editing from sub-account page creates a copy', priority: "1", test_id: 250250 do
          # access from course grading_standards page
          get "/courses/#{@course.id}/grading_standards"

          # edit grading period
          replace_content(f("#period_title_#{@id}"), title + "\n")
          replace_content(f("#period_start_date_#{@id}"), start_date + "\n")
          replace_content(f("#period_end_date_#{@id}"), end_date + "\n")
          f('#update-button').click
          wait_for_ajax_requests

          # should have created a new sub-account grading period - original should NOT change
          @account_grading_period.reload  # make sure original grading period is updated in case it changed

          new_grading_period = GradingPeriod.where(title: title).first
          new_id = new_grading_period.id
          expect(new_id).to_not eq(@id)
          expect(new_grading_period).to_not be(@account_grading_period) # check for same object

          # check UI
          expect(f("#period_title_#{new_id}")).to have_value(title)
          expect(f("#period_start_date_#{new_id}")).to have_value("#{start_date}, #{Time.zone.now.year} at 12:00am")
          expect(f("#period_end_date_#{new_id}")).to have_value("#{end_date}, #{Time.zone.now.year} at 12:00am")
        end
      end # as admin

      context 'as sub-admin' do

        before(:each) do
          sub_account = Account.create(name: 'sub account from default account', parent_account: Account.default)
          sub_admin = account_admin_user({account: sub_account, name: "sub-admin"})

          # log in as sub-admin (admin of sub-account, but not admin of main account)
          user_session sub_admin

          # access from sub-account grading_standards page
          get "/accounts/#{sub_account.id}/grading_standards"
        end

        it 'is inherited by sub-account, sub-admin reads account grading period', priority: "1", test_id: 250251 do
          expect(ff('.grading-period').length).to eq(1)
          expect(f("#period_title_#{@id}")).to have_value(@account_grading_period.title)
        end

        it 'is inherited by sub-account, as sub-admin, editing from sub-account page creates a copy', priority: "1", test_id: 250252 do
          # edit grading period
          replace_content(f("#period_title_#{@id}"), title + "\n")
          replace_content(f("#period_start_date_#{@id}"), start_date + "\n")
          replace_content(f("#period_end_date_#{@id}"), end_date + "\n")
          f('#update-button').click
          wait_for_ajax_requests

          # should have created a new sub-account grading period - original should NOT change
          @account_grading_period.reload  # make sure original grading period is updated in case it changed

          new_grading_period = GradingPeriod.where(title: title).first
          new_id = new_grading_period.id
          expect(new_id).to_not eq(@id)
          expect(new_grading_period).to_not be(@account_grading_period) # check for same object

          # check UI
          expect(f("#period_title_#{new_id}")).to have_value(title)
          expect(f("#period_start_date_#{new_id}")).to have_value("#{start_date}, #{Time.zone.now.year} at 12:00am")
          expect(f("#period_end_date_#{new_id}")).to have_value("#{end_date}, #{Time.zone.now.year} at 12:00am")
        end

        it 'is inherited by sub-account, deleting as sub-admin reverts to account grading period', priority: "1", test_id: 250257 do
          # edit grading period
          replace_content(f("#period_title_#{@id}"), title + "\n")
          f('#update-button').click
          refresh_page

          # delete the last sub-account grading period
          ff('.icon-delete-grading-period').first.click
          driver.switch_to.alert.accept
          wait_for_ajaximations

          expect(ff('.grading-period').length).to be(1)
          expect(f("#period_title_#{@id}")).to have_value(@account_grading_period.title)
        end
      end # as sub-admin

      context 'as a teacher' do

        before(:each) do
          course_with_teacher(course: @course, name: 'teacher', active_enrollment: true)
          user_session @teacher

          # access from course grading_standards page as teacher
          get "/courses/#{@course.id}/grading_standards"
        end

        it 'is inherited by course, reads account grading period', priority: "1", test_id: 250253 do
          expect(ff('.grading-period').length).to eq(1)
          expect(f("#period_title_#{@id}")).to have_value(@account_grading_period.title)
        end

        it 'is inherited by course, editing from course page creates a copy', priority: "1", test_id: 250254 do
          # edit grading period
          replace_content(f("#period_title_#{@id}"), title + "\n")
          replace_content(f("#period_start_date_#{@id}"), start_date + "\n")
          replace_content(f("#period_end_date_#{@id}"), end_date + "\n")
          f('#update-button').click
          wait_for_ajax_requests

          # should have created a new sub-account grading period - original should NOT change
          @account_grading_period.reload  # make sure original grading period is updated in case it changed

          new_grading_period = GradingPeriod.where(title: title).first
          new_id = new_grading_period.id
          expect(new_id).to_not eq(@id)
          expect(new_grading_period).to_not be(@account_grading_period) # check for same object

          # check UI
          expect(f("#period_title_#{new_id}")).to have_value(title)
          expect(f("#period_start_date_#{new_id}")).to have_value("#{start_date}, #{Time.zone.now.year} at 12:00am")
          expect(f("#period_end_date_#{new_id}")).to have_value("#{end_date}, #{Time.zone.now.year} at 12:00am")
        end

        it 'is inherited by course, deleting reverts to account grading period', priority: "1", test_id: 250259 do
          # edit grading period
          replace_content(f("#period_title_#{@id}"), title + "\n")
          f('#update-button').click
          refresh_page

          # delete the last sub-account grading period
          ff('.icon-delete-grading-period').first.click
          driver.switch_to.alert.accept
          wait_for_ajaximations

          expect(ff('.grading-period').length).to be(1)
          expect(f("#period_title_#{@id}")).to have_value(@account_grading_period.title)
          expect(f('#admin-periods-message').text).to eq('These grading periods were created for you by an administrator.')
        end

        it 'is inherited by course, deleting second to last GP displays message', priority: "1", test_id: 250260 do
          # add a grading period
          f('#add-period-button').click
          f('#period_title_new2').send_keys title, :return
          f('#period_start_date_new2').send_keys start_date, :return
          f('#period_end_date_new2').send_keys end_date, :return
          f('#update-button').click
          refresh_page

          # delete the second to last sub-account grading period
          ff('.icon-delete-grading-period').first.click
          driver.switch_to.alert.accept
          wait_for_ajaximations

          expect(f('#disable-feature-message').text).to eq('You can disable this feature here.')
        end

        it 'is inherited by course, displays inherited grading periods message', priority: "1", test_id: 255259 do
          expect(f('#admin-periods-message').text).to eq('These grading periods were created for you by an administrator.')
        end
      end # as a teacher
    end # inheritance
  end # mgp feature on

  context 'with Multiple Grading Periods feature off', priority: "1", test_id: 202305 do
    it 'does not contain a tab for grading periods' do
      get "/courses/#{@course.id}/grading_standards"
      expect(f(".grading_periods_tab")).to be_nil
    end
  end # mgp feature off
end  # account grading periods
