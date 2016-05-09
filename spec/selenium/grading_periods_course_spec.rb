require File.expand_path(File.dirname(__FILE__) + '/common')


describe 'Course Grading Periods' do
  include_examples 'in-process server selenium tests'

  context 'with Multiple Grading Periods feature on,' do
    before(:each) do
      course_with_teacher_logged_in
      @course.root_account.enable_feature!(:multiple_grading_periods)
    end

    it 'shows grading periods created at the course-level', priority: "1", test_id: 239998 do
      @course_grading_period = create_grading_periods_for(@course).first
      get "/courses/#{@course.id}/grading_standards"
      period_title = f("#period_title_#{@course_grading_period.id}")
      expect(period_title).to have_value(@course_grading_period.title)
    end

    it 'shows grading periods created by an associated account', priority: "1", test_id: 239997 do
      @account_grading_period = create_grading_periods_for(@course.root_account).first
      get "/courses/#{@course.id}/grading_standards"
      period_title = f("#period_title_#{@account_grading_period.id}").text
      expect(period_title).to eq(@account_grading_period.title)
    end

    it 'allows grading periods to be deleted', priority: "1", test_id: 202320 do
      grading_period_selector = '.grading-period'
      create_grading_periods_for(@course, grading_periods: [:old, :current])
      get "/courses/#{@course.id}/grading_standards"
      expect(ff(grading_period_selector).length).to be 2
      f('.icon-delete-grading-period').click
      driver.switch_to.alert.accept
      wait_for_ajaximations
      expect(ff(grading_period_selector).length).to be 1
    end

    it 'does not allow adding grading periods', priority: "1", test_id: 239999 do
      get "/courses/#{@course.id}/grading_standards"
      expect(f('#grading_periods')).to_not contain_css(('#add-period-button'))
    end

    it 'allows updating grading periods', priority: "1", test_id: 202317 do
      create_grading_periods_for(@course)
      get "/courses/#{@course.id}/grading_standards"
      expect(f("#update-button")).to be_present
    end
  end
end

# there is a lot of repeated code in the inheritance tests, since we are testing 3 roles on 3 pages
# the way this works will change soon (MGP version 3), so it makes more sense to wait for these
# changes before refactoring these tests
describe 'Course Grading Periods Inheritance' do
  include_examples 'in-process server selenium tests'

  let(:title) {'hi'}
  let(:start_date) { format_date_for_view(3.months.from_now) }
  let(:end_date) { format_date_for_view(4.months.from_now - 1.day) }

  before(:each) do
    course_with_admin_logged_in
    @account = @course.root_account
    @account.enable_feature!(:multiple_grading_periods)
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
      end

      it 'reads sub-account grading period on sub-account course grading standards page', priority: "1", test_id: 202321 do
        user_session @admin
        get "/courses/#{@sub_account_course.id}/grading_standards"
        expect(ff('.grading-period').length).to eq(1)
        expect(f("#period_title_#{@sub_account_grading_period.id}")).to have_value(@sub_account_grading_period.title)
      end
    end
  end
end
