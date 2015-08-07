require File.expand_path(File.dirname(__FILE__) + '/common')


describe 'Course Grading Periods' do
  include_examples 'in-process server selenium tests'

  before(:each) do
    course_with_teacher_logged_in
  end

  context 'with Multiple Grading Periods feature on,' do
    before(:each) do
      @course.root_account.enable_feature!(:multiple_grading_periods)
    end

    it 'shows grading periods created at the course-level', priority: "1", test_id: 239998 do
      course_grading_period = create_grading_periods_for(@course).first
      get "/courses/#{@course.id}/grading_standards"
      expect(f("#period_title_#{course_grading_period.id}").attribute("value")).to eq(course_grading_period.title)
    end

    it 'shows grading periods created by an associated account', priority: "1", test_id: 239997 do
      account_grading_period = create_grading_periods_for(@course.root_account).first
      get "/courses/#{@course.id}/grading_standards"
      period_title = f("#period_title_#{account_grading_period.id}").attribute("value")
      expect(period_title).to eq(account_grading_period.title)
    end

    it 'allows grading periods to be deleted if there are more than 1', priority: "1", test_id: 202320 do
      grading_period_selector = '.grading-period'
      create_grading_periods_for(@course, grading_periods: [:old, :current])
      get "/courses/#{@course.id}/grading_standards"
      expect(ff(grading_period_selector).length).to be 2
      f('.icon-delete-grading-period').click
      driver.switch_to.alert.accept
      wait_for_ajaximations
      expect(ff(grading_period_selector).length).to be 1
    end

    it 'creates a blank grading period form when Add Grading Period is clicked', priority: "1", test_id: 239999 do
      get "/courses/#{@course.id}/grading_standards"
      expect(ff('.grading-period').length).to eq(0)
      f('#add-period-button').click
      expect(ff('.grading-period').length).to eq(1)
    end

    it 'removes an unsaved grading period from the dom gracefully', priority: "1", test_id: 240000 do
      create_grading_periods_for(@course)
      get "/courses/#{@course.id}/grading_standards"
      f('#add-period-button').click
      expect(ff('.grading-period').length).to be(2)
      ff('.icon-delete-grading-period').second.click
      expect(ff('.grading-period').length).to be(1)
    end

    it 'flashes an error to the user if start_date occurs after end_date', priority: "1", test_id: 202309 do
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

    it 'flashes an error if the user removes start_date', priority: "1", test_id: 240230 do
      create_grading_periods_for(@course)
      get "/courses/#{@course.id}/grading_standards"

      f("\#period_start_date_#{GradingPeriod.last.id}").clear

      f('#update-button').click
      assert_flash_error_message(/All dates fields must be present and formatted correctly/)
    end

    it 'flashes an error if the user removes end_date', priority: "1", test_id: 240231 do
      create_grading_periods_for(@course)
      get "/courses/#{@course.id}/grading_standards"

      f("\#period_end_date_#{GradingPeriod.last.id}").clear

      f('#update-button').click
      assert_flash_error_message(/All dates fields must be present and formatted correctly/)
    end

    it 'allows a user to add multiple grading periods simultaneously', priority: "1", test_id: 240002 do
      get "/courses/#{@course.id}/grading_standards"
      3.times { f('#add-period-button').click }
      expect(ff('.grading-period').length).to eq(3)
    end

    it 'allows a user to save a grading period', priority: "1", test_id: 202317 do
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

    it 'allows users to update a grading period', priority: "1", test_id: 202319 do
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
  end # mgp feature on

  context 'with Multiple Grading Periods feature off', priority: "1", test_id: 240005 do
    it 'does not contain a tab for grading periods' do
      get "/courses/#{@course.id}/grading_standards"
      expect(f(".grading_periods_tab")).to be_nil
    end
  end # mgp feature off
end # course grading periods


# there is a lot of repeated code in the inheritance tests, since we are testing 3 roles on 3 pages
# the way this works will change soon (MGP version 3), so it makes more sense to wait for these
# changes before refactoring these tests
describe 'Course Grading Periods Inheritance' do
  include_examples 'in-process server selenium tests'

  let(:title) {'hi'}
  let(:start_date) {'Feb 1'}
  let(:end_date)  {'Feb 28'}
  let(:date_time_format)  {'%b %-d, %Y at %-l:%M%P'}   # e.g. May 28, 2015 at 8:58pm

  before(:each) do
    course_with_admin_logged_in
    @account = @course.root_account
    @account_grading_period = create_grading_periods_for(@account).first

    @sub_account = Account.create(name: 'sub account from default account', parent_account: Account.default)
    @sub_admin = account_admin_user({account: @sub_account, name: 'sub-admin'})
    @sub_account_grading_period = create_grading_periods_for(@sub_account).first
    @sub_account_grading_period.title = 'sub account grading period'
    @sub_account_grading_period.save

    course_with_teacher(course: @course, name: 'teacher', active_enrollment: true)
    @account_course = @course
    @account_teacher = @teacher
  end

  context 'with Multiple Grading Periods feature on,' do
    before(:each) do
      @account.enable_feature!(:multiple_grading_periods)
    end

    it 'reads course grading periods instead of inherited grading periods', priority: "1", test_id: 202318 do
      user_session @account_teacher
      course_grading_period = create_grading_periods_for(@course).first
      get "/courses/#{@account_course.id}/grading_standards"
      expect(ff('.grading-period').length).to be(1)
      expect(f("#period_title_#{course_grading_period.id}")).to have_value(course_grading_period.title)
    end

    context 'with sub-account course and teacher,' do
      before(:each) do
        course_with_user('TeacherEnrollment', {account: @sub_account, course_name: 'sub account course', active_enrollment: true})
        @sub_account_course = @course
        @sub_account_teacher = @user
      end

      context 'as admin,' do
        it 'reads sub-account grading period on sub-account course grading standards page', priority: "1", test_id: 202321 do
          get "/courses/#{@sub_account_course.id}/grading_standards"
          expect(ff('.grading-period').length).to eq(1)
          expect(f("#period_title_#{@sub_account_grading_period.id}")).to have_value(@sub_account_grading_period.title)
        end

        it 'editing sub-account grading period on sub-account course grading standards page creates a copy', priority: "1", test_id: 270959 do
          get "/courses/#{@sub_account_course.id}/grading_standards"

          # edit grading period
          replace_content(f("#period_title_#{@sub_account_grading_period.id}"), title + "\n")
          replace_content(f("#period_start_date_#{@sub_account_grading_period.id}"), start_date + "\n")
          replace_content(f("#period_end_date_#{@sub_account_grading_period.id}"), end_date + "\n")
          f('#update-button').click
          wait_for_ajax_requests

          # should have created a new sub-account grading period - original should NOT change
          @sub_account_grading_period.reload  # make sure original grading period is updated in case it changed

          new_grading_period = GradingPeriod.where(title: title).first
          new_id = new_grading_period.id
          expect(new_id).to_not eq(@sub_account_grading_period.id)
          expect(new_grading_period).to_not be(@sub_account_grading_period) # check for same object

          # check UI
          expect(f("#period_title_#{new_id}")).to have_value(title)
          expect(f("#period_start_date_#{new_id}")).to have_value("#{start_date}, #{Time.zone.now.year} at 12:00am")
          expect(f("#period_end_date_#{new_id}")).to have_value("#{end_date}, #{Time.zone.now.year} at 12:00am")
        end
      end # as admin

      context 'as sub-admin,' do
        before(:each) do
          sub_admin = account_admin_user({account: @sub_account, name: "sub-admin"})

          # log in as sub-admin (admin of sub-account, but not admin of main account)
          user_session sub_admin
        end

        it 'editing sub-account grading period on sub-account course grading standards page creates a copy', priority: "1", test_id: 270960 do
          get "/courses/#{@sub_account_course.id}/grading_standards"

          # edit grading period
          replace_content(f("#period_title_#{@sub_account_grading_period.id}"), title + "\n")
          replace_content(f("#period_start_date_#{@sub_account_grading_period.id}"), start_date + "\n")
          replace_content(f("#period_end_date_#{@sub_account_grading_period.id}"), end_date + "\n")
          f('#update-button').click
          wait_for_ajax_requests

          # should have created a new sub-account grading period - original should NOT change
          @sub_account_grading_period.reload  # make sure original grading period is updated in case it changed

          new_grading_period = GradingPeriod.where(title: title).first
          new_id = new_grading_period.id
          expect(new_id).to_not eq(@sub_account_grading_period.id)
          expect(new_grading_period).to_not be(@sub_account_grading_period) # check for same object

          # check UI
          expect(f("#period_title_#{new_id}")).to have_value(title)
          expect(f("#period_start_date_#{new_id}")).to have_value("#{start_date}, #{Time.zone.now.year} at 12:00am")
          expect(f("#period_end_date_#{new_id}")).to have_value("#{end_date}, #{Time.zone.now.year} at 12:00am")
        end
      end # as sub-admin

      context 'as teacher for account course,' do
        before(:each) do
          user_session @account_teacher
        end

        it 'adding grading period to account course copies account grading period', priority: "1", test_id: 270961 do
          get "/courses/#{@account_course.id}/grading_standards"

          # add a course grading period
          f('#add-period-button').click
          f('#period_title_new2').send_keys title, :return
          f('#period_start_date_new2').send_keys start_date, :return
          f('#period_end_date_new2').send_keys end_date, :return
          f('#update-button').click
          refresh_page
          expect(ff('.grading-period').length).to eq(2)

          # should have created a new sub-account grading period - original should NOT change
          @account_grading_period.reload  # make sure original grading period is updated in case it changed

          # check that SECOND grading period with same title is a copy
          new_grading_period = GradingPeriod.where(title: @account_grading_period.title).second
          expect(new_grading_period).to be
          new_id = new_grading_period.id
          expect(new_id).to_not eq(@account_grading_period.id)
          expect(new_grading_period).to_not be(@account_grading_period) # check for same object
        end
      end # account teacher

      context 'as teacher for sub-account course,' do
        before(:each) do
          user_session @sub_account_teacher
        end

        it 'adding grading period to account course copies sub-account grading period', priority: "1", test_id: 270961 do
          get "/courses/#{@sub_account_course.id}/grading_standards"

          # add a course grading period
          f('#add-period-button').click
          f('#period_title_new2').send_keys title, :return
          f('#period_start_date_new2').send_keys start_date, :return
          f('#period_end_date_new2').send_keys end_date, :return
          f('#update-button').click
          refresh_page
          expect(ff('.grading-period').length).to eq(2)

          # should have created a new sub-account grading period - original should NOT change
          @account_grading_period.reload  # make sure original grading period is updated in case it changed

          # check that SECOND grading period with same title is a copy
          new_grading_period = GradingPeriod.where(title: @sub_account_grading_period.title).second
          expect(new_grading_period).to be
          new_id = new_grading_period.id
          expect(new_id).to_not eq(@sub_account_grading_period.id)
          expect(new_grading_period).to_not be(@sub_account_grading_period) # check for same object
        end
      end # sub-account teacher

    end # with sub-account course and teacher
  end # mgp feature on
end # course grading periods with Inheritance
