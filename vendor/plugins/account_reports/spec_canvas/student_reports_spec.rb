#
# Copyright (C) 2013 - 2014 Instructure, Inc.
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

  before do
    Notification.find_or_create_by_name('Report Generated')
    Notification.find_or_create_by_name('Report Generation Failed')
    @account = Account.create(name: 'New Account', default_time_zone: 'UTC')
    @course1 = course(:course_name => 'English 101', :account => @account,
                      :active_course => true)
    @course1.sis_source_id = 'SIS_COURSE_ID_1'
    @course1.save!
    @course1.offer
    @course2 = course(:course_name => 'Math 101', :account => @account,
                      :active_course => true)
    @course2.offer
    @course3 = Course.create(:name => 'Science 101', :course_code => 'SCI101',
                             :account => @account)
    @course3.offer
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
    @e1 = @course1.enroll_user(@user1, 'StudentEnrollment', {enrollment_state: 'active'})
    @e2 = @course2.enroll_user(@user2, 'StudentEnrollment', {enrollment_state: 'active'})
    @e3 = @course2.enroll_user(@user1, 'StudentEnrollment', {enrollment_state: 'active'})
    @e4 = @course1.enroll_user(@user2, 'StudentEnrollment', {enrollment_state: 'active'})
    @section1 = @course1.course_sections.first
    @section2 = @course2.course_sections.first
    @section3 = @course3.course_sections.first
  end

  describe 'students with no submissions report' do
    before do
      @type = 'students_with_no_submissions_csv'
      @start_at = 2.months.ago
      @start_at2 = 10.days.ago
      @end_at = 1.day.ago

      @submission_time = 1.month.ago
      @assignment1.grade_student(@user1, {:grade => '4'})
      s = Submission.find_by_assignment_id_and_user_id(@assignment1.id, @user1.id)
      s.submitted_at = @submission_time
      s.save!

      @submission_time2 = 40.days.ago
      @assignment1.grade_student(@user2, {:grade => '5'})
      s = Submission.find_by_assignment_id_and_user_id(@assignment1.id, @user2.id)
      s.submitted_at = @submission_time2
      s.save!

      @assignment2.grade_student(@user1, {:grade => '9'})
      s = Submission.find_by_assignment_id_and_user_id(@assignment2.id, @user1.id)
      s.submitted_at = @submission_time2
      s.save!
    end

    it 'should find users that with no submissions after a date in all states' do
      Enrollment.where(id: @e1).update_all(workflow_state: 'completed')
      Enrollment.where(id: @e2).update_all(workflow_state: 'deleted')
      Enrollment.where(id: @e3).update_all(workflow_state: 'invited')
      Enrollment.where(id: @e4).update_all(workflow_state: 'rejected')
      parameters = {}
      parameters['start_at'] = @start_at2
      parameters['include_enrollment_state'] = true
      parameters['enrollment_state'] = ['all']
      parsed = read_report(@type, {params: parameters, order: [1,8]})
      parsed.length.should == 4

      parsed[0].should == [@user1.id.to_s, 'user_sis_id_01',
                           @user1.sortable_name, @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101',
                           'completed']
      parsed[1].should == [@user1.id.to_s, 'user_sis_id_01',
                           @user1.sortable_name, @section2.id.to_s,
                           @section2.sis_source_id, @section2.name,
                           @course2.id.to_s, nil, 'Math 101', 'invited']
      parsed[2].should == [@user2.id.to_s, 'user_sis_id_02',
                           'Bolton, Michael', @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101',
                           'rejected']
      parsed[3].should == [@user2.id.to_s, 'user_sis_id_02',
                           'Bolton, Michael', @section2.id.to_s,
                           @section2.sis_source_id, @section2.name,
                           @course2.id.to_s, nil, 'Math 101', 'deleted']
    end

    it 'should filter on enrollment states' do
      Enrollment.where(id: @e1).update_all(workflow_state: 'completed')
      Enrollment.where(id: @e2).update_all(workflow_state: 'deleted')
      Enrollment.where(id: @e3).update_all(workflow_state: 'invited')
      parameters = {}
      parameters['start_at'] = @start_at2
      parameters['include_enrollment_state'] = true
      parameters['enrollment_state'] = ['invited', 'completed']
      parsed = read_report(@type, {params: parameters, order: [1,8]})
      parsed.length.should == 2

      parsed[0].should == [@user1.id.to_s, 'user_sis_id_01',
                           @user1.sortable_name, @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101',
                           'completed']
      parsed[1].should == [@user1.id.to_s, 'user_sis_id_01',
                           @user1.sortable_name, @section2.id.to_s,
                           @section2.sis_source_id, @section2.name,
                           @course2.id.to_s, nil, 'Math 101', 'invited']
    end

    it 'should filter on enrollment state' do
      Enrollment.where(id: @e1).update_all(workflow_state: 'completed')
      Enrollment.where(id: @e2).update_all(workflow_state: 'deleted')
      Enrollment.where(id: @e3).update_all(workflow_state: 'invited')
      parameters = {}
      parameters['start_at'] = @start_at2
      parameters['include_enrollment_state'] = true
      parameters['enrollment_state'] = 'active'
      parsed = read_report(@type, params: parameters)
      parsed.length.should == 1

      parsed[0].should == [@user2.id.to_s, 'user_sis_id_02',
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
      parsed.length.should == 2

      parsed[0].should == [@user1.id.to_s, 'user_sis_id_01',
                           @user1.sortable_name, @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101']
      parsed[1].should == [@user2.id.to_s, 'user_sis_id_02',
                           'Bolton, Michael', @section2.id.to_s,
                           @section2.sis_source_id, @section2.name,
                           @course2.id.to_s, nil, 'Math 101']
    end

    it 'should find users that have not submitted anything in the past 2 weeks' do
      parsed = read_report(@type, {order: [1,8]})

      parsed[0].should == [@user1.id.to_s, 'user_sis_id_01',
                           @user1.sortable_name, @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101']
      parsed[1].should == [@user1.id.to_s, 'user_sis_id_01',
                           @user1.sortable_name, @section2.id.to_s,
                           @section2.sis_source_id, @section2.name,
                           @course2.id.to_s, nil, 'Math 101']
      parsed[2].should == [@user2.id.to_s, 'user_sis_id_02',
                           'Bolton, Michael', @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101']
      parsed[3].should == [@user2.id.to_s, 'user_sis_id_02',
                           'Bolton, Michael', @section2.id.to_s,
                           @section2.sis_source_id, @section2.name,
                           @course2.id.to_s, nil, 'Math 101']
      parsed.length.should == 4
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

      parsed[0].should == [@user1.id.to_s, 'user_sis_id_01',
                           @user1.sortable_name, @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101']
      parsed[1].should == [@user2.id.to_s, 'user_sis_id_02',
                           'Bolton, Michael', @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101']
      parsed.length.should == 2
    end

    it 'should find users that have not submitted under a sub account' do
      sub_account = Account.create(:parent_account => @account,
                                    :name => 'English')
      @course2.account = sub_account
      @course2.save
      parsed = read_report(@type, {account: sub_account, order: 1})

      parsed[0].should == [@user1.id.to_s, 'user_sis_id_01',
                           @user1.sortable_name, @section2.id.to_s,
                           @section2.sis_source_id, @section2.name,
                           @course2.id.to_s, nil, 'Math 101']
      parsed[1].should == [@user2.id.to_s, 'user_sis_id_02',
                           'Bolton, Michael', @section2.id.to_s,
                           @section2.sis_source_id, @section2.name,
                           @course2.id.to_s, nil, 'Math 101']
      parsed.length.should == 2

    end

    it 'should find users that have not submitted for one course' do
      parameters = {}
      parameters['course'] = @course2.id
      parameters['include_enrollment_state'] = true
      parsed = read_report(@type, {params: parameters, order: 1})

      parsed[0].should == [@user1.id.to_s, 'user_sis_id_01',
                           @user1.sortable_name, @section2.id.to_s,
                           @section2.sis_source_id, @section2.name,
                           @course2.id.to_s, nil, 'Math 101', 'active']
      parsed[1].should == [@user2.id.to_s, 'user_sis_id_02',
                           'Bolton, Michael', @section2.id.to_s,
                           @section2.sis_source_id, @section2.name,
                           @course2.id.to_s, nil, 'Math 101', 'active']
      parsed.length.should == 2
    end
  end

  describe 'zero activity report' do
    before(:each) do
      @type = 'zero_activity_csv'

      @course1.enroll_user(@user3, 'StudentEnrollment', {:enrollment_state => 'active'})
      @course3.enroll_user(@user3, 'StudentEnrollment', {:enrollment_state => 'active'})

      @asset1 = factory_with_protected_attributes(
        AssetUserAccess, :user => @user1, :context => @course1,
        :asset_code => @assignment1.asset_string
      )
      @asset2 = factory_with_protected_attributes(
        AssetUserAccess, :user => @user2, :context => @course2,
        :asset_code => @assignment2.asset_string
      )
      @asset3 = factory_with_protected_attributes(
        AssetUserAccess, :user => @user3, :context => @course3,
        :asset_code => @assignment3.asset_string
      )
      @asset4 = factory_with_protected_attributes(
        AssetUserAccess, :user => @user3, :context => @course3,
        :asset_code => @assignment4.asset_string
      )
    end

    it 'should run the zero activity report for course' do
      param = {}
      param['course'] = @course1.id
      parsed = read_report(@type, {params: param, order: 1})
      parsed.length.should == 2
      parsed[0].should == [@user2.id.to_s, 'user_sis_id_02',
                           'Bolton, Michael', @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101']
      parsed[1].should == [@user3.id.to_s, 'user_sis_id_03',
                           @user3.sortable_name, @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101']
    end

    it 'should run the zero activity report for term' do
      @term1 = EnrollmentTerm.create(:name => 'Fall')
      @term1.root_account = @account
      @term1.sis_source_id = 'fall12'
      @term1.save!
      @course1.enrollment_term = @term1
      @course1.save
      param = {}
      param['enrollment_term'] = 'sis_term_id:fall12'
      parsed = read_report(@type, {params: param, order: 1})
      parsed.length.should == 2
      parsed[0].should == [@user2.id.to_s, 'user_sis_id_02',
                           'Bolton, Michael', @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101']
      parsed[1].should == [@user3.id.to_s, 'user_sis_id_03',
                           @user3.sortable_name, @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101']
    end

    it 'should run the zero activity report with no params' do
      report = run_report
      report.parameters["extra_text"].should ==  "Term: All Terms;"
      parsed = parse_report(report, {order: 1})

      parsed.length.should == 3

      parsed[0].should == [@user1.id.to_s, 'user_sis_id_01',
                           @user1.sortable_name, @section2.id.to_s,
                           @section2.sis_source_id, @section2.name,
                           @course2.id.to_s, nil, 'Math 101']
      parsed[1].should == [@user2.id.to_s, 'user_sis_id_02',
                           'Bolton, Michael', @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101']
      parsed[2].should == [@user3.id.to_s, 'user_sis_id_03',
                           @user3.sortable_name, @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101']
    end

    it 'should run zero activity report on a sub account' do
      sub_account = Account.create(:parent_account => @account,:name => 'Math')
      @course2.account = sub_account
      @course2.save!

      parsed = read_report(@type, {account: sub_account})
      parsed.length.should == 1
      parsed[0].should == [@user1.id.to_s, 'user_sis_id_01',
                           @user1.sortable_name, @section2.id.to_s,
                           @section2.sis_source_id, @section2.name,
                           @course2.id.to_s, nil, 'Math 101']
    end

    it 'should ignore everything before the start date' do
      AssetUserAccess.where(:id => @asset1).
        update_all(:updated_at => 6.days.ago)
      parameter = {}
      parameter['start_at'] = 3.days.ago
      report = run_report(@type, {params: parameter})
      (report.parameters["extra_text"].include? "Start At:").should == true
      parsed = parse_report(report, {order: [1,5]})
      parsed.length.should == 4
      parsed[0].should == [@user1.id.to_s, 'user_sis_id_01',
                           @user1.sortable_name, @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101']
      parsed[1].should == [@user1.id.to_s, 'user_sis_id_01',
                           @user1.sortable_name, @section2.id.to_s,
                           @section2.sis_source_id, @section2.name,
                           @course2.id.to_s, nil, 'Math 101']
      parsed[2].should == [@user2.id.to_s, 'user_sis_id_02',
                           'Bolton, Michael', @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101']
      parsed[3].should == [@user3.id.to_s, 'user_sis_id_03',
                           @user3.sortable_name, @section1.id.to_s,
                           @section1.sis_source_id, @section1.name,
                           @course1.id.to_s, 'SIS_COURSE_ID_1', 'English 101']
    end
  end

  describe 'last user access report' do
    before(:each) do
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
      parsed.length.should == 3
      parsed[0].should == [@user1.id.to_s, 'user_sis_id_01', 'Clair, John St.', @last_login_time2.iso8601, @p1.current_login_ip]
      parsed[1].should == [@user2.id.to_s, 'user_sis_id_02', 'Bolton, Michael', @last_login_time.iso8601, @p2.current_login_ip]
      parsed[2].should == [@user3.id.to_s, 'user_sis_id_03', 'Astley, Rick', @last_login_time2.iso8601, @p3.current_login_ip]
    end

    it 'should run the last user access report for a term' do
      @term1 = EnrollmentTerm.create(:name => 'Fall')
      @term1.root_account = @account
      @term1.save!
      @course1.enrollment_term = @term1
      @course1.save
      param = {}
      param['enrollment_term'] = @term1.id
      parsed = read_report(@type, {params: param, order: 1})
      parsed.length.should == 2
      parsed[0].should == [@user1.id.to_s, 'user_sis_id_01', 'Clair, John St.', @last_login_time2.iso8601, @p1.current_login_ip]
      parsed[1].should == [@user2.id.to_s, 'user_sis_id_02', 'Bolton, Michael', @last_login_time.iso8601, @p2.current_login_ip]
    end

    it 'should run the last user access report for a course' do
      param = {}
      param['course'] = @course.id
      parsed = read_report(@type, {params: param, order: 1})
      parsed.length.should == 2
      parsed[0].should == [@user1.id.to_s, 'user_sis_id_01', 'Clair, John St.', @last_login_time2.iso8601, @p1.current_login_ip]
      parsed[1].should == [@user2.id.to_s, 'user_sis_id_02', 'Bolton, Michael', @last_login_time.iso8601, @p2.current_login_ip]
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
      parsed[0].should == [@user1.id.to_s, 'user_sis_id_01', 'Clair, John St.',
                           @last_login_time2.iso8601, @p1.current_login_ip]
      parsed[1].should == [@user2.id.to_s, 'user_sis_id_02', 'Bolton, Michael',
                           @last_login_time.iso8601, @p2.current_login_ip]
      parsed.length.should == 2
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
      report.parameters["extra_text"].should == "Term: Fall;"
      parsed = parse_report(report, {order: 1})
      parsed[0].should == [@user1.id.to_s, 'secondSIS', 'Clair, John St.',
                           @last_login_time.iso8601, p1b.current_login_ip]
      parsed[1].should == [@user1.id.to_s, 'user_sis_id_01', 'Clair, John St.',
                           @last_login_time2.iso8601, @p1.current_login_ip]
      parsed[2].should == [@user2.id.to_s, 'user_sis_id_02', 'Bolton, Michael',
                           @last_login_time.iso8601, @p2.current_login_ip]
      parsed.length.should == 3
    end
  end
end
