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

    it 'multiple grading period dropdown should filter assignments by selected grading period', priority: "1", test_id: 202330 do
      get "/courses/#{@course.id}/gradebook"

      # select future grading period
      f('.grading-period-select-button').click
      fj('.ui-menu-item label:contains("Course Period 1: future period")').click
      wait_for_ajaximations
      element = ff('.slick-header-column a').select { |a| a.text == 'second assignment' }
      expect(element.first).to be_displayed

      # select current grading period
      f('.grading-period-select-button').click
      fj('.ui-menu-item label:contains("Course Period 2: current period")').click
      wait_for_ajaximations
      element = ff('.slick-header-column a').select { |a| a.text == 'assignment three' }
      expect(element.first).to be_displayed

      # select all grading periods
      f('.grading-period-select-button').click
      fj('.ui-menu-item label:contains("All Grading Periods")').click
      wait_for_ajaximations

      element = ff('.slick-header-column a').select { |a| a.text == 'assignment three' }
      expect(element.first).to be_displayed
      element = ff('.slick-header-column a').select { |a| a.text == 'second assignment' }
      expect(element.first).to be_displayed
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
      fj('button.add_standard_button').click
      expect(fj('input.scheme_name')).not_to be_nil
      expect(fj('button.add_standard_button')).to have_class('disabled')
    end

    context 'assignment index page' do
      let(:account) { Account.default }
      let(:test_course) { account.courses.create!(name: 'New Course', workflow_state: 'active') }
      let(:teacher) { user(active_all: true) }
      let!(:enroll_teacher) { test_course.enroll_user(teacher, 'TeacherEnrollment', enrollment_state: 'active') }
      let!(:enable_mgp_flag) { account.enable_feature!(:multiple_grading_periods) }
      let!(:enable_course_mgp_flag) { test_course.enable_feature!(:multiple_grading_periods) }
      let!(:grading_period_group) { test_course.grading_period_groups.create! }
      let!(:course_grading_period_current) do
        grading_period_group.grading_periods.create!(
          title: 'Course Grading Period 1',
          start_date: Time.zone.now,
          end_date: 4.weeks.from_now
        )
      end
      let!(:course_grading_period_past) do
        grading_period_group.grading_periods.create!(
          title: 'Course Grading Period 2',
          start_date: 4.weeks.ago,
          end_date: 1.day.ago
        )
      end
      let!(:assignment) { test_course.assignments.create!(title: 'Assignment 1', due_at: 1.day.ago, points: 10) }

      it 'should list an assignment from a previous grading period', priority: "2", test_course: 381145 do
        user_session(teacher)
        get "/courses/#{test_course.id}/assignments"
        expect(fj("#assignment_#{assignment.id} a.ig-title")).to include_text('Assignment 1')
      end

      it 'should list an assignment from a current grading period when due date is updated', priority: "2", test_course: 576764 do
        assignment.update_attributes(due_at: 3.days.from_now)
        user_session(teacher)
        get "/courses/#{test_course.id}/assignments"
        expect(fj("#assignment_#{assignment.id} a.ig-title")).to include_text('Assignment 1')
      end
    end
  end

  context 'sub-accounts' do
    # top-level account & grading periods setup
    let(:parent_account) { Account.default }
    let(:parent_account_admin) { account_admin_user(account: parent_account) }
    let!(:enable_mgp_flag) { parent_account.enable_feature!(:multiple_grading_periods) }
    let!(:grading_period_group) { parent_account.grading_period_groups.create! }
    let!(:parent_account_grading_period) do
      grading_period_group.grading_periods.create!(
        title: 'Account Grading Period 1',
        start_date: Time.zone.now,
        end_date: 3.weeks.from_now
      )
    end
    # sub-account & grading periods setup
    let(:sub_account) { Account.create(name: 'Sub Account', parent_account: parent_account) }
    let(:sub_account_admin) { account_admin_user(account: sub_account) }
    let(:sub_account_grading_period_group) { sub_account.grading_period_groups.create! }
    let(:sub_account_grading_period) do
      sub_account_grading_period_group.grading_periods.create!(
        title: 'Sub-Account Grading Period',
        start_date: Time.zone.now,
        end_date: 3.weeks.from_now
      )
    end
    # sub-account course setup
    let(:sub_account_course) do
      sub_account.courses.create(
        name: 'Sub-Account Course',
        workflow_state: 'active'
      )
    end
    let(:sub_account_teacher) { user(active_all: true) }
    let(:enroll_teacher) do
      sub_account_course.enroll_user(
        sub_account_teacher,
        'TeacherEnrollment',
        enrollment_state: 'active'
      )
    end
    let(:view_sub_account_grading_period) do
      user_session(sub_account_admin)
      get "/accounts/#{sub_account.id}/grading_standards"
    end
    let(:view_sub_course_grading_period) do
      sub_account_grading_period
      sub_account_course
      enroll_teacher
      user_session(sub_account_teacher)
      get "/courses/#{sub_account_course.id}/grading_standards"
    end
    let(:add_new_grading_period) do
      f('#add-period-button').click
      replace_content(f('#period_title_new2'), 'Edited Grading Period')
      replace_content(f('#period_start_date_new2'), 4.weeks.from_now)
      replace_content(f('#period_end_date_new2'), 5.weeks.from_now)
      f('button#update-button').click
      wait_for_ajaximations
    end

    it 'displays GPs from parent account', priority: "1", test_id: 585571 do
      view_sub_account_grading_period

      id = parent_account_grading_period.id
      expect(f("#period_title_#{id}")).to have_attribute('value', 'Account Grading Period 1')
    end

    it 'allows editing of inherited GP without messing upstream', priority: "1", test_id: 585572 do
      view_sub_account_grading_period

      id = parent_account_grading_period.id
      replace_content(f("#period_title_#{id}"), "Edited Grading Period")

      user_session(parent_account_admin)
      get "/accounts/#{parent_account.id}/grading_standards"
      expect(f("#period_title_#{id}")).to have_attribute('value', 'Account Grading Period 1')
    end

    it 'allows creation of a sub-account GP', priority: "1", test_id: 202324 do
      view_sub_account_grading_period
      add_new_grading_period

      sub_id = sub_account.grading_periods[0].id
      expect(f("#period_title_#{sub_id}")).to have_attribute('value','Edited Grading Period')
    end

    it 'displays GPs from parent account on course level', priority: "1", test_id: 202325 do
      view_sub_course_grading_period

      id = sub_account_grading_period.id
      expect(f("#period_title_#{id}")).to have_attribute('value', 'Sub-Account Grading Period')
    end

    it 'allows creation of a GP in sub-account course', priority: "1", test_id: 587759 do
      view_sub_course_grading_period
      add_new_grading_period

      sub_id = sub_account_course.grading_periods[0].id
      expect(f("#period_title_#{sub_id}")).to have_attribute('value','Edited Grading Period')
    end
  end

  context 'student view' do
    let(:account) { Account.default }
    let(:test_course) { account.courses.create!(name: 'New Course') }
    let(:student) { user(active_all: true) }
    let!(:enroll_student) { test_course.enroll_user(student, 'StudentEnrollment', enrollment_state: 'active') }
    let!(:enable_mgp_flag) { account.enable_feature!(:multiple_grading_periods) }
    let!(:enable_course_mgp_flag) { test_course.enable_feature!(:multiple_grading_periods) }
    let!(:grading_period_group) { test_course.grading_period_groups.create! }
    let!(:course_grading_period_1) do
      grading_period_group.grading_periods.create!(
        title: 'Course Grading Period 1',
        start_date: Time.zone.now,
        end_date: 3.weeks.from_now
      )
    end
    let!(:course_grading_period_2) do
      grading_period_group.grading_periods.create!(
        title: 'Course Grading Period 2',
        start_date: 4.weeks.from_now,
        end_date: 7.weeks.from_now
      )
    end
    let!(:assignment1) { test_course.assignments.create!(title: 'Assignment 1', due_at: 3.days.from_now, points: 10) }
    let!(:assignment2) { test_course.assignments.create!(title: 'Assignment 2', due_at: 6.weeks.from_now, points: 10) }
    let!(:grade_assignment1) { assignment1.grade_student(student, { grade: 8 }) }

    before(:each) do
      test_course.offer!
      user_session(student)
      get "/courses/#{test_course.id}/grades"
    end

    it 'should dispay the current grading period and assignments in grades page', priority: "1", test_id: 202326 do
      expect(fj(".grading_periods_selector option[selected='selected']")).to include_text('Course Grading Period 1')
      expect(fj("#submission_#{assignment1.id} th a")).to include_text('Assignment 1')
    end

    it 'should update assignments when a different period is selected in grades page', priority: "1", test_id: 562596 do
      fj(".grading_periods_selector option:nth-child(3)").click
      expect(fj("#submission_#{assignment2.id} th a")).to include_text('Assignment 2')
    end

    it 'should update assignments when a different period is selected in grades page', priority: "1", test_id: 571756 do
      fj(".grading_periods_selector option:nth-child(1)").click
      expect(fj("#submission_#{assignment1.id} th a")).to include_text('Assignment 1')
      expect(fj("#submission_#{assignment2.id} th a")).to include_text('Assignment 2')
    end
  end
end
