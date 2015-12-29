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

  context 'student view' do
    let(:account) { Account.default }
    let(:test_course) { account.courses.create!(name: 'New Course', workflow_state: 'active') }
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
