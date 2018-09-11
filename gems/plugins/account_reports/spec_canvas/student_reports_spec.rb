#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/report_spec_helper')

describe 'Student reports' do
  include ReportSpecHelper

  before :once do
    Notification.where(name: "Report Generated").first_or_create
    Notification.where(name: "Report Generation Failed").first_or_create
    @account = Account.create(name: 'New Account', default_time_zone: 'UTC')
    @course1 = course_factory(:course_name => 'English 101', :account => @account,
                      :active_course => true)
    @course1.sis_source_id = 'SIS_COURSE_ID_1'
    @course1.save!
    @course1.offer
    @course2 = course_factory(:course_name => 'Math 101', :account => @account,
                      :active_course => true)
    @course2.offer
    @course3 = Course.create(:name => 'Science 101', :course_code => 'SCI101',
                             :account => @account)
    @course3.offer

    @teacher = User.create!
    @course1.enroll_teacher(@teacher)
    @course2.enroll_teacher(@teacher)
    @course3.enroll_teacher(@teacher)

    @assignment1 = @course1.assignments.create!(:title => 'My Assignment')
    @assignment2 = @course2.assignments.create!(:title => 'My Assignment')
    @assignment3 = @course3.assignments.create!(:title => 'My Assignment')
    @assignment4 = @course3.assignments.create!(:title => 'My Assignment')
    @user1 = user_with_managed_pseudonym(
      :active_all => true, :account => @account, :name => 'John St. Clair',
      :sortable_name => 'St. Clair, John', :username => 'john@stclair.com',
      :sis_user_id => 'user_sis_id_01')
    @user2 = user_with_managed_pseudonym(
      :active_all => true, :username => 'micheal@michaelbolton.com',
      :name => 'Michael Bolton', :account => @account,
      :sis_user_id => 'user_sis_id_02')
    @user3 = user_with_managed_pseudonym(
      :active_all => true, :account => @account, :name => 'Rick Astley',
      :sortable_name => 'Astley, Rick', :username => 'rick@roll.com',
      :sis_user_id => 'user_sis_id_03')

    enrollment_params = {enrollment_state: 'active', type: 'StudentEnrollment', return_type: :record}
    @e_u1_c1, @e_u2_c1 = create_enrollments(@course1, [@user1, @user2], enrollment_params)
    @e_u1_c2, @e_u2_c2 = create_enrollments(@course2, [@user1, @user2], enrollment_params)

    @section1 = @course1.course_sections.first
    @section2 = @course2.course_sections.first
    @section3 = @course3.course_sections.first
  end

  describe 'students with no submissions report' do
    before :once do
      @type = 'students_with_no_submissions_csv'
      @start_at = 2.months.ago
      @start_at2 = 10.days.ago
      @end_at = 1.day.ago

      @submission_time = 1.month.ago
      @assignment1.grade_student(@user1, grade: '4', grader: @teacher)
      s = Submission.where(assignment_id: @assignment1, user_id: @user1).first
      s.submitted_at = @submission_time
      s.save!

      @submission_time2 = 40.days.ago
      @assignment1.grade_student(@user2, grade: '5', grader: @teacher)
      s = Submission.where(assignment_id: @assignment1, user_id: @user2).first
      s.submitted_at = @submission_time2
      s.save!

      @assignment2.grade_student(@user1, grade: '9', grader: @teacher)
      s = Submission.where(assignment_id: @assignment2, user_id: @user1).first
      s.submitted_at = @submission_time2
      s.save!
    end

    it 'should find users that with no submissions after a date in all states' do
      Enrollment.where(id: @e_u1_c1).update_all(workflow_state: 'completed')
      Enrollment.where(id: @e_u2_c2).update_all(workflow_state: 'deleted')
      Enrollment.where(id: @e_u1_c2).update_all(workflow_state: 'invited')
      Enrollment.where(id: @e_u2_c1).update_all(workflow_state: 'rejected')
      parameters = {}
      parameters['start_at'] = @start_at2
      parameters['include_enrollment_state'] = true
      parameters['enrollment_state'] = ['all']
      parsed = read_report(@type, {params: parameters, order: [1,8]})
      expect(parsed.length).to eq 4

      expect(parsed[0]).to eq [@user1.id.to_s, 'user_sis_id_01',
                           @user1.sortable_name, @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101',
                           'completed']
      expect(parsed[1]).to eq [@user1.id.to_s, 'user_sis_id_01',
                           @user1.sortable_name, @section2.id.to_s,
                           @section2.sis_source_id, @section2.name,
                           @course2.id.to_s, nil, 'Math 101', 'invited']
      expect(parsed[2]).to eq [@user2.id.to_s, 'user_sis_id_02',
                           'Bolton, Michael', @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101',
                           'rejected']
      expect(parsed[3]).to eq [@user2.id.to_s, 'user_sis_id_02',
                           'Bolton, Michael', @section2.id.to_s,
                           @section2.sis_source_id, @section2.name,
                           @course2.id.to_s, nil, 'Math 101', 'deleted']
    end

    it 'should filter on enrollment states' do
      Enrollment.where(id: @e_u1_c1).update_all(workflow_state: 'completed')
      Enrollment.where(id: @e_u2_c2).update_all(workflow_state: 'deleted')
      Enrollment.where(id: @e_u1_c2).update_all(workflow_state: 'invited')
      parameters = {}
      parameters['start_at'] = @start_at2
      parameters['include_enrollment_state'] = true
      parameters['enrollment_state'] = ['invited', 'completed']
      parsed = read_report(@type, {params: parameters, order: [1,8]})
      expect(parsed.length).to eq 2

      expect(parsed[0]).to eq [@user1.id.to_s, 'user_sis_id_01',
                           @user1.sortable_name, @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101',
                           'completed']
      expect(parsed[1]).to eq [@user1.id.to_s, 'user_sis_id_01',
                           @user1.sortable_name, @section2.id.to_s,
                           @section2.sis_source_id, @section2.name,
                           @course2.id.to_s, nil, 'Math 101', 'invited']
    end

    it 'should filter on enrollment state' do
      Enrollment.where(id: @e_u1_c1).update_all(workflow_state: 'completed')
      Enrollment.where(id: @e_u2_c2).update_all(workflow_state: 'deleted')
      Enrollment.where(id: @e_u1_c2).update_all(workflow_state: 'invited')
      parameters = {}
      parameters['start_at'] = @start_at2
      parameters['include_enrollment_state'] = true
      parameters['enrollment_state'] = 'active'
      parsed = read_report(@type, params: parameters)
      expect(parsed.length).to eq 1

      expect(parsed[0]).to eq [@user2.id.to_s, 'user_sis_id_02',
                           'Bolton, Michael', @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101',
                           'active']
    end

    it 'should find users that have not submitted anything in a date range' do
      parameters = {}
      parameters['start_at'] = 45.days.ago
      parameters['end_at'] = 35.days.ago
      parsed = read_report(@type, {params: parameters, order: 1})
      expect(parsed.length).to eq 2

      expect(parsed[0]).to eq [@user1.id.to_s, 'user_sis_id_01',
                           @user1.sortable_name, @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101']
      expect(parsed[1]).to eq [@user2.id.to_s, 'user_sis_id_02',
                           'Bolton, Michael', @section2.id.to_s,
                           @section2.sis_source_id, @section2.name,
                           @course2.id.to_s, nil, 'Math 101']
    end

    it 'should find users that have not submitted anything in the past 2 weeks' do
      parsed = read_report(@type, {order: [1,8]})

      expect(parsed[0]).to eq [@user1.id.to_s, 'user_sis_id_01',
                           @user1.sortable_name, @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101']
      expect(parsed[1]).to eq [@user1.id.to_s, 'user_sis_id_01',
                           @user1.sortable_name, @section2.id.to_s,
                           @section2.sis_source_id, @section2.name,
                           @course2.id.to_s, nil, 'Math 101']
      expect(parsed[2]).to eq [@user2.id.to_s, 'user_sis_id_02',
                           'Bolton, Michael', @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101']
      expect(parsed[3]).to eq [@user2.id.to_s, 'user_sis_id_02',
                           'Bolton, Michael', @section2.id.to_s,
                           @section2.sis_source_id, @section2.name,
                           @course2.id.to_s, nil, 'Math 101']
      expect(parsed.length).to eq 4
    end

    it 'should adjust date range to 2 weeks' do
      @term1 = @account.enrollment_terms.create(:name => 'Fall')
      @term1.save!
      @course1.enrollment_term = @term1
      @course1.save

      parameters = {}
      parameters['start_at'] = @start_at.to_s
      parameters['end_at'] = @end_at.to_s(:db)
      parameters['enrollment_term'] = @term1.id
      parsed = read_report(@type, {params: parameters, order: 1})

      expect(parsed[0]).to eq [@user1.id.to_s, 'user_sis_id_01',
                           @user1.sortable_name, @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101']
      expect(parsed[1]).to eq [@user2.id.to_s, 'user_sis_id_02',
                           'Bolton, Michael', @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101']
      expect(parsed.length).to eq 2
    end

    it 'should find users that have not submitted under a sub account' do
      sub_account = Account.create(:parent_account => @account,
                                    :name => 'English')
      @course2.account = sub_account
      @course2.save
      parsed = read_report(@type, {account: sub_account, order: 1})

      expect(parsed[0]).to eq [@user1.id.to_s, 'user_sis_id_01',
                           @user1.sortable_name, @section2.id.to_s,
                           @section2.sis_source_id, @section2.name,
                           @course2.id.to_s, nil, 'Math 101']
      expect(parsed[1]).to eq [@user2.id.to_s, 'user_sis_id_02',
                           'Bolton, Michael', @section2.id.to_s,
                           @section2.sis_source_id, @section2.name,
                           @course2.id.to_s, nil, 'Math 101']
      expect(parsed.length).to eq 2

    end

    it 'should find users that have not submitted for one course' do
      parameters = {}
      parameters['course'] = @course2.id
      parameters['include_enrollment_state'] = true
      parsed = read_report(@type, {params: parameters, order: 1})

      expect(parsed[0]).to eq [@user1.id.to_s, 'user_sis_id_01',
                           @user1.sortable_name, @section2.id.to_s,
                           @section2.sis_source_id, @section2.name,
                           @course2.id.to_s, nil, 'Math 101', 'active']
      expect(parsed[1]).to eq [@user2.id.to_s, 'user_sis_id_02',
                           'Bolton, Michael', @section2.id.to_s,
                           @section2.sis_source_id, @section2.name,
                           @course2.id.to_s, nil, 'Math 101', 'active']
      expect(parsed.length).to eq 2
    end
  end

  describe 'zero activity report' do
    before(:once) do
      @type = 'zero_activity_csv'

      @course1.enroll_user(@user3, 'StudentEnrollment', {enrollment_state: 'active'})
      @course3.enroll_user(@user3, 'StudentEnrollment', {:enrollment_state => 'active'})

      @user4 = user_with_managed_pseudonym(name: 'User 4', account: @account, sis_user_id: 'user_sis_id_04')
      @user5 = user_with_managed_pseudonym(name: 'User 5', account: @account, sis_user_id: 'user_sis_id_05')
      @course4 = course_factory(course_name: 'Course 4', account: @account, active_course: true)
      @section4 = @course4.default_section
      create_enrollments(@course4, [@user4, @user5], {enrollment_state: 'active', type: 'StudentEnrollment'})

      [[@user1, @course1], [@user2, @course2], [@user3, @course3], [@user5, @course4]].each do |user, course|
        user.enrollments.where(course_id: course).update_all(last_activity_at: Time.now.utc)
      end

      @term1 = EnrollmentTerm.create(:name => 'Fall')
      @term1.root_account = @account
      @term1.sis_source_id = 'fall12'
      @term1.save!

      @course4.enrollment_term = @term1
      @course4.save
    end

    it 'should run the zero activity report for course' do
      param = {}
      param['course'] = @course1.id
      parsed = read_report(@type, {params: param, order: 1})
      expect(parsed).to eq_stringified_array [
        [@user2.id, 'user_sis_id_02', 'Bolton, Michael', @section1.id, @section1.sis_source_id,
         @section1.name, @course1.id, 'SIS_COURSE_ID_1', 'English 101'],
        [@user3.id, 'user_sis_id_03', @user3.sortable_name, @section1.id, @section1.sis_source_id,
         @section1.name, @course1.id, 'SIS_COURSE_ID_1', 'English 101']
      ]
    end

    it 'should run the zero activity report for term' do
      @course1.enrollment_term = @term1
      @course1.save
      param = {}
      param['enrollment_term'] = 'sis_term_id:fall12'
      parsed = read_report(@type, {params: param, order: 1})
      expect(parsed).to eq_stringified_array [
        [@user2.id, 'user_sis_id_02', 'Bolton, Michael', @section1.id, @section1.sis_source_id,
         @section1.name, @course1.id, 'SIS_COURSE_ID_1', 'English 101'],
        [@user3.id, 'user_sis_id_03', @user3.sortable_name, @section1.id, @section1.sis_source_id,
         @section1.name, @course1.id, 'SIS_COURSE_ID_1', 'English 101'],
        [@user4.id, 'user_sis_id_04', '4, User', @section4.id, nil,
         @section4.name, @course4.id, nil, 'Course 4']
      ]
    end

    it 'should run the zero activity report with no params' do
      report = run_report
      expect(report.parameters["extra_text"]).to eq "Term: All Terms;"
      parsed = parse_report(report, {order: 1})

      expect(parsed).to eq_stringified_array [
        [@user1.id, 'user_sis_id_01', @user1.sortable_name, @section2.id, @section2.sis_source_id,
         @section2.name, @course2.id, nil, 'Math 101'],
        [@user2.id, 'user_sis_id_02', 'Bolton, Michael', @section1.id, @section1.sis_source_id,
         @section1.name, @course1.id, 'SIS_COURSE_ID_1', 'English 101'],
        [@user3.id, 'user_sis_id_03', @user3.sortable_name, @section1.id, @section1.sis_source_id,
         @section1.name, @course1.id, 'SIS_COURSE_ID_1', 'English 101'],
        [@user4.id, 'user_sis_id_04', '4, User', @course4.default_section.id, nil,
         @course4.default_section.name, @course4.id, nil, 'Course 4']
      ]
    end

    it 'should run zero activity report on a sub account' do
      sub_account = Account.create(parent_account: @account, name: 'Math')
      @course2.account = sub_account
      @course2.save!

      parsed = read_report(@type, {account: sub_account})
      expect(parsed).to eq_stringified_array [
        [@user1.id, 'user_sis_id_01', @user1.sortable_name, @section2.id, @section2.sis_source_id,
         @section2.name, @course2.id, nil, 'Math 101']
      ]
    end

    it 'should ignore everything before the start date' do
      @user1.enrollments.where(course_id: @course1).update_all(last_activity_at: 6.days.ago)
      parameter = {}
      parameter['start_at'] = 3.days.ago
      report = run_report(@type, {params: parameter})
      expect(report.parameters["extra_text"].include?("Start At:")).to eq true
      parsed = parse_report(report, {order: [1,5]})
      expect(parsed).to eq_stringified_array [
        [@user1.id, 'user_sis_id_01', @user1.sortable_name, @section1.id, @section1.sis_source_id,
         @section1.name, @course1.id, 'SIS_COURSE_ID_1', 'English 101'],
        [@user1.id, 'user_sis_id_01', @user1.sortable_name, @section2.id, @section2.sis_source_id,
         @section2.name, @course2.id, nil, 'Math 101'],
        [@user2.id, 'user_sis_id_02', 'Bolton, Michael', @section1.id, @section1.sis_source_id,
         @section1.name, @course1.id, 'SIS_COURSE_ID_1', 'English 101'],
        [@user3.id, 'user_sis_id_03', @user3.sortable_name, @section1.id, @section1.sis_source_id,
         @section1.name, @course1.id, 'SIS_COURSE_ID_1', 'English 101'],
        [@user4.id, 'user_sis_id_04', '4, User', @course4.default_section.id, nil,
         'Course 4', @course4.id, nil, 'Course 4']
      ]
    end

    it 'should exclude multi-section users who have activity in at least one section' do
      lonely_section = @course1.course_sections.create!(name: "forever alone")
      active_enrollment = lonely_section.enroll_user(@user2, 'StudentEnrollment', 'active')
      active_enrollment.update_attribute(:last_activity_at, 1.day.ago)

      param = {}
      param['course'] = @course1.id
      parsed = read_report(@type, {params: param, order: 1})

      expect(parsed).to eq_stringified_array [
        [@user3.id, 'user_sis_id_03', @user3.sortable_name, @section1.id, @section1.sis_source_id,
         @section1.name, @course1.id, 'SIS_COURSE_ID_1', 'English 101']
      ]
    end
  end

  describe 'last user access report' do
    before(:once) do
      @type = 'last_user_access_csv'
      @last_login_time = 1.week.ago
      @last_login_time2 = 8.days.ago
      @p1 = @user1.pseudonyms.first
      @p1.last_login_at = @last_login_time2
      @p1.last_request_at = @last_login_time2
      @p1.save
      @p2 = @user2.pseudonyms.first
      @p2.last_login_at = @last_login_time
      @p2.last_request_at = @last_login_time
      @p2.save
      @p3 = @user3.pseudonyms.first
      @p3.last_login_at = @last_login_time2
      @p3.last_request_at = @last_login_time2
      @p3.save
    end

    it 'should run the last user access report' do
      parsed = read_report(@type, {order: 1})
      expect(parsed).to eq_stringified_array [
        [@user1.id, 'user_sis_id_01', 'Clair, John St.', @last_login_time2.iso8601, @p1.current_login_ip],
        [@user2.id, 'user_sis_id_02', 'Bolton, Michael', @last_login_time.iso8601, @p2.current_login_ip],
        [@user3.id, 'user_sis_id_03', 'Astley, Rick', @last_login_time2.iso8601, @p3.current_login_ip]
      ]
    end

    it 'should run the last user access report for a term' do
      @term1 = EnrollmentTerm.create(name: 'Fall')
      @term1.root_account = @account
      @term1.save!
      @course1.enrollment_term = @term1
      @course1.save
      param = {}
      param['enrollment_term'] = @term1.id
      parsed = read_report(@type, {params: param, order: 1})
      expect(parsed).to eq_stringified_array [
        [@user1.id, 'user_sis_id_01', 'Clair, John St.', @last_login_time2.iso8601, @p1.current_login_ip],
        [@user2.id, 'user_sis_id_02', 'Bolton, Michael', @last_login_time.iso8601, @p2.current_login_ip]
      ]
    end

    it 'should run the last user access report for a course' do
      param = {}
      param['course'] = @course.id
      parsed = read_report(@type, {params: param, order: 1})
      expect(parsed).to eq_stringified_array [
        [@user1.id, 'user_sis_id_01', 'Clair, John St.', @last_login_time2.iso8601, @p1.current_login_ip],
        [@user2.id, 'user_sis_id_02', 'Bolton, Michael', @last_login_time.iso8601, @p2.current_login_ip]
      ]
    end

    it 'should not include a user multiple times for multiple enrollments' do
      @course1.enroll_user(@user1, 'ObserverEnrollment', {enrollment_state: 'active'})
      term1 = @account.enrollment_terms.create(name: 'Fall')
      term1.root_account = @account
      term1.save!
      @course1.enrollment_term = term1
      @course1.save!
      param = {}
      param['enrollment_term'] = term1.id

      parsed = read_report(@type, {params: param, order: 1})
      expect(parsed).to eq_stringified_array [
        [@user1.id, 'user_sis_id_01', 'Clair, John St.', @last_login_time2.iso8601, @p1.current_login_ip],
        [@user2.id, 'user_sis_id_02', 'Bolton, Michael', @last_login_time.iso8601, @p2.current_login_ip]
      ]
    end

    it 'should include each pseudonym for users' do
      @course1.enroll_user(@user1, 'ObserverEnrollment', {enrollment_state: 'active'})
      term1 = @account.enrollment_terms.create(name: 'Fall')
      term1.root_account = @account
      term1.save!
      @course1.enrollment_term = term1
      @course1.save!
      p1b = @user1.pseudonyms.build(unique_id: 'unique@example.com')
      p1b.account = @account
      p1b.sis_user_id = 'secondSIS'
      p1b.last_login_at = @last_login_time
      p1b.last_request_at = @last_login_time
      p1b.save_without_session_maintenance
      param = {}
      param['enrollment_term'] = term1.id

      report = run_report(@type, {params: param})
      expect(report.parameters["extra_text"]).to eq "Term: Fall;"
      parsed = parse_report(report, {order: 1})
      expect(parsed).to eq_stringified_array [
        [@user1.id, 'secondSIS', 'Clair, John St.', @last_login_time.iso8601, p1b.current_login_ip],
        [@user1.id, 'user_sis_id_01', 'Clair, John St.', @last_login_time2.iso8601, @p1.current_login_ip],
        [@user2.id, 'user_sis_id_02', 'Bolton, Michael', @last_login_time.iso8601, @p2.current_login_ip]
      ]
    end

    it 'should not include a user with a deleted enrollment' do
      @course2.enroll_user(@user3, 'StudentEnrollment', {:enrollment_state => 'deleted'})
      param = {}
      param['course'] = @course2.id
      param['include_deleted'] = false
      parsed = read_report(@type, {params: param, order: 1})
      expect(parsed).to eq_stringified_array [
        [@user1.id, 'user_sis_id_01', 'Clair, John St.', @last_login_time2.iso8601, @p1.current_login_ip],
        [@user2.id, 'user_sis_id_02', 'Bolton, Michael', @last_login_time.iso8601, @p2.current_login_ip]
      ]
    end

    it 'should include a user with a deleted enrollment' do
      @course2.enroll_user(@user3, 'StudentEnrollment', {:enrollment_state => 'deleted'})
      param = {}
      param['course'] = @course2.id
      param['include_deleted'] = true
      parsed = read_report(@type, {params: param, order: 1})
      expect(parsed).to eq_stringified_array [
        [@user1.id.to_s, 'user_sis_id_01', 'Clair, John St.', @last_login_time2.iso8601, @p1.current_login_ip],
        [@user2.id.to_s, 'user_sis_id_02', 'Bolton, Michael', @last_login_time.iso8601, @p2.current_login_ip],
        [@user3.id.to_s, 'user_sis_id_03', 'Astley, Rick', @last_login_time2.iso8601, @p3.current_login_ip]
      ]
    end
  end

  describe 'last enrollment activity report' do
    before(:once) do
      @type = 'last_enrollment_activity_csv'
      @later_activity = 1.week.ago
      @earlier_activity = 8.days.ago
      # user 1
      @e_u1_c1.last_activity_at = @later_activity
      @e_u1_c2.last_activity_at = @earlier_activity
      # user 2
      @e_u2_c2.last_activity_at = @later_activity
      @e_u2_c1.last_activity_at = @earlier_activity
      [@e_u1_c1, @e_u2_c2, @e_u1_c2, @e_u2_c1].each(&:save!)
    end

    it 'should show the lastest activity for each user' do
      report = run_report(@type)
      parsed = parse_report(report, {order: 1})

      expect(parsed).to eq_stringified_array [
        [@user2.id.to_s, 'Bolton, Michael', @later_activity.iso8601],
        [@user1.id.to_s,'Clair, John St.', @later_activity.iso8601]
      ]
    end

    it 'does not include a user who has no enrollment activity' do
      @e_u1_c1.last_activity_at = nil
      @e_u1_c2.last_activity_at = nil
      @e_u1_c1.save!
      @e_u1_c2.save!

      report = run_report(@type)
      parsed = parse_report(report, { order: 1 })

      expect(parsed).to eq_stringified_array [[@user2.id.to_s, 'Bolton, Michael', @later_activity.iso8601]]
    end

    it 'should scope by course if param given' do
      parameters = {}
      parameters['course'] = @course1.id
      report = run_report(@type, {params: parameters})
      parsed = parse_report(report, {order: 1})

      # Bolton will show earlier time if restricted to course 1
      expect(parsed).to eq_stringified_array [
        [@user2.id.to_s, 'Bolton, Michael', @earlier_activity.iso8601],
        [@user1.id.to_s,'Clair, John St.', @later_activity.iso8601]
      ]
    end

    it 'should scope by term if param given' do
      @term1 = @account.enrollment_terms.create(name: 'Fall')
      @term1.save!
      @course1.enrollment_term = @term1
      @course1.save

      parameters = {}
      parameters['enrollment_term'] = @term1.id
      report = run_report(@type, {params: parameters})
      parsed = parse_report(report, {order: 1})

      # Bolton will show earlier time if restricted to course 1 (via term restriction)
      expect(parsed).to eq_stringified_array [
        [@user2.id.to_s, 'Bolton, Michael', @earlier_activity.iso8601],
        [@user1.id.to_s,'Clair, John St.', @later_activity.iso8601]
      ]
    end

    it 'should show data for users in other accounts with enrollments on this account' do
      @different_account = Account.create(name: 'New Account', default_time_zone: 'UTC')

      @course3 = course_factory(course_name: 'English 101', account: @account, active_course: true)
      @course3.save!
      @course3.offer

      @different_account_user = user_with_managed_pseudonym(
        active_all: true, account: @different_account, name: 'Diego Renault',
        sortable_name: 'Renault, Diego', username: 'diegor@diff_account.com')

      e3 = @course3.enroll_user(@different_account_user, 'StudentEnrollment', {enrollment_state: 'active'})
      @very_recent_acivity = 1.minute.ago
      e3.last_activity_at = @very_recent_acivity
      e3.save!

      report = run_report(@type, account: @account)
      parsed = parse_report(report, {order: 1})

      expect(parsed).to eq_stringified_array [
        [@user2.id.to_s, 'Bolton, Michael', @later_activity.iso8601],
        [@user1.id.to_s,'Clair, John St.', @later_activity.iso8601],
        [@different_account_user.id.to_s,'Renault, Diego', @very_recent_acivity.iso8601]
      ]
    end
  end

  describe 'user access token report' do
    before(:once) do
      @type = 'user_access_tokens_csv'
      @at1 = AccessToken.create!(
        user: @user1,
        developer_key: DeveloperKey.default,
        expires_at: 2.hours.ago
      )
      @user1.destroy

      @at2 = AccessToken.create!(
        user: @user2,
        developer_key: DeveloperKey.default,
        expires_at: 2.hours.from_now
      )

      @at2.update_attribute(:last_used_at, 2.hours.ago)

      @at3 = AccessToken.create!(
        user: @user3,
        developer_key: DeveloperKey.default,
        expires_at: nil
      )
    end

    it 'should run and include deleted users' do
      parsed = read_report(@type, {params: {"include_deleted" => true}, order: 1})
      expect(parsed).to eq_stringified_array [
        [@user3.id, "Astley, Rick", @at3.token_hint.gsub(/.+~/, ''), 'never',
         'never', DeveloperKey.default.id, "User-Generated"],
        [@user2.id, "Bolton, Michael", @at2.token_hint.gsub(/.+~/, ''), @at2.expires_at.iso8601,
         @at2.last_used_at.iso8601, DeveloperKey.default.id, "User-Generated"],
        [@user1.id, "Clair, John St.", @at1.token_hint.gsub(/.+~/, ''), @at1.expires_at.iso8601,
         'never', DeveloperKey.default.id, "User-Generated"]
      ]
    end

    it 'should run and exclude deleted users' do
      parsed = read_report(@type, {order: 1})
      expect(parsed.length).to eq 2
    end
  end
end
