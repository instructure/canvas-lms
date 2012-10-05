#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/reports_helper')

describe "Default Account Reports" do

  describe "SIS export reports and Provisioning reports" do

    it "should run the SIS and Provisioning Users reports" do
      Notification.find_or_create_by_name("Report Generated")
      Notification.find_or_create_by_name("Report Generation Failed")

      @account = Account.default
      @admin = account_admin_user(:account => @account)
      user1 = user_with_pseudonym(:active_all => true, :account => @account, :name => "John St. Clair", :sortable_name => "St. Clair, John", :username => 'john@stclair.com')
      @user.pseudonym.sis_user_id = "user_sis_id_01"
      @user.pseudonym.save!
      user2 = user_with_pseudonym(:active_all => true, :username => 'micheal@michaelbolton.com', :name => 'Michael Bolton', :account => @account)
      @user.pseudonym.sis_user_id = "user_sis_id_02"
      @user.pseudonym.save!
      user3 = user_with_pseudonym(:name => 'Rick Astley', :account => @account)
      #user3 has no sis_id and should not be in the sis report

      parameters = {}
      parameters["enrollment_term"] = @account.enrollment_terms.active.find_or_create_by_name(EnrollmentTerm::DEFAULT_TERM_NAME).id
      parameters["users"] = true
      parsed = ReportsSpecHelper.run_report(@account,"sis_export_csv", parameters)
      parsed.length.should == 2

      parsed[0].should == ["user_sis_id_01", "john@stclair.com", nil, "John St.", "Clair", "john@stclair.com", "active"]
      parsed[1].should == ["user_sis_id_02", "micheal@michaelbolton.com", nil, "Michael", "Bolton", "micheal@michaelbolton.com", "active"]

      parameters = {}
      parameters["users"] = true
      parsed = ReportsSpecHelper.run_report(@account,"sis_export_csv", parameters)
      parsed.length.should == 2

      parsed[0].should == ["user_sis_id_01", "john@stclair.com", nil, "John St.", "Clair", "john@stclair.com", "active"]
      parsed[1].should == ["user_sis_id_02", "micheal@michaelbolton.com", nil, "Michael", "Bolton", "micheal@michaelbolton.com", "active"]

      parsed = ReportsSpecHelper.run_report(@account,"provisioning_csv", parameters,2)
      parsed.length.should == 3

      parsed[0].should == [user1.id.to_s, "user_sis_id_01", "john@stclair.com", "John St.", "Clair", "john@stclair.com", "active"]
      parsed[1].should == [user2.id.to_s, "user_sis_id_02", "micheal@michaelbolton.com", "Michael", "Bolton", "micheal@michaelbolton.com", "active"]
      parsed[2].should == [user3.id.to_s, nil, "nobody@example.com", "Rick", "Astley", "nobody@example.com", "active"]
    end

    it "should run the SIS and Provisioning Accounts reports" do
      Notification.find_or_create_by_name("Report Generated")
      Notification.find_or_create_by_name("Report Generation Failed")

      @account = Account.default
      sub_account = Account.create(:parent_account => @account, :name => 'English')
      sub_account.sis_source_id = 'sub1'
      sub_account.save!
      sub_sub_account = Account.create(:parent_account => sub_account, :name => 'sESL')
      sub_sub_account.sis_source_id = 'subsub1'
      sub_sub_account.save!
      sub_account2 = Account.create(:parent_account => @account, :name => 'Math')
      sub_account2.sis_source_id = 'sub2'
      sub_account2.save!
      sub_account3 = Account.create(:parent_account => @account, :name => 'other')
      #sub_account 3 does not have sis id and should not be in the sis report
      parameters = {}
      parameters["enrollment_term"] = @account.enrollment_terms.active.find_or_create_by_name(EnrollmentTerm::DEFAULT_TERM_NAME).id
      parameters["accounts"] = true
      parsed = ReportsSpecHelper.run_report(@account,"sis_export_csv", parameters)
      parsed.length.should == 3

      parsed[0].should == ["sub1", nil, "English", "active"]
      parsed[1].should == ["sub2", nil, "Math", "active"]
      parsed[2].should == ["subsub1", "sub1", "sESL", "active"]

      parameters = {}
      parameters["accounts"] = true
      parsed = ReportsSpecHelper.run_report(@account,"sis_export_csv", parameters)
      parsed.length.should == 3
      parsed[0].should == ["sub1", nil, "English", "active"]
      parsed[1].should == ["sub2", nil, "Math", "active"]
      parsed[2].should == ["subsub1", "sub1", "sESL", "active"]

      parsed = ReportsSpecHelper.run_report(@account,"provisioning_csv", parameters, 3)
      parsed.length.should == 4
      parsed[0].should == [sub_account.id.to_s, "sub1", nil, "English", "active"]
      parsed[1].should == [sub_account2.id.to_s, "sub2", nil, "Math", "active"]
      parsed[2].should == [sub_account3.id.to_s, nil, nil, "other", "active"]
      parsed[3].should == [sub_sub_account.id.to_s, "subsub1", "sub1", "sESL", "active"]

    end

    it "should run the SIS and Provisioning Terms reports" do
      Notification.find_or_create_by_name("Report Generated")
      Notification.find_or_create_by_name("Report Generation Failed")

      @account = Account.default
      term1 = EnrollmentTerm.create(:name => 'Fall', :start_at => '20-08-2012', :end_at => '20-12-2012')
      term1.root_account = @account
      term1.sis_source_id = 'fall12'
      term1.save!
      term2 = EnrollmentTerm.create(:name => 'Winter', :start_at => '07-01-2013', :end_at => '28-04-2013')
      term2.root_account = @account
      term2.sis_source_id = 'winter13'
      term2.save!
      term3 = @account.enrollment_terms.active.find_or_create_by_name(EnrollmentTerm::DEFAULT_TERM_NAME)
      #default term should not be included in the sis report since it does not have an sis id
      parameters = {}
      parameters["enrollment_term"] = term3.id
      parameters["terms"] = true
      parsed = ReportsSpecHelper.run_report(@account,"sis_export_csv", parameters)
      parsed.length.should == 2

      parsed[0][0].should == term1.sis_source_id
      parsed[0][1].should == term1.name
      parsed[0][2].should == "active"
      parsed[0][3].should == term1.start_at.iso8601
      parsed[0][4].should == term1.end_at.iso8601

      parsed[1][0].should == term2.sis_source_id
      parsed[1][1].should == term2.name
      parsed[1][2].should == "active"
      parsed[1][3].should == term2.start_at.iso8601
      parsed[1][4].should == term2.end_at.iso8601

      parameters = {}
      parameters["terms"] = true
      parsed = ReportsSpecHelper.run_report(@account,"sis_export_csv", parameters)
      parsed.length.should == 2
      parsed[0].should == ["fall12", "Fall", "active", "2012-08-20T00:00:00Z", "2012-12-20T00:00:00Z"]
      parsed[1].should == ["winter13", "Winter", "active", "2013-01-07T00:00:00Z", "2013-04-28T00:00:00Z"]

      parsed = ReportsSpecHelper.run_report(@account,"provisioning_csv", parameters, 2)
      parsed.length.should == 3
      parsed[0].should == [term3.id.to_s, nil, "Default Term", "active", nil, nil]
      parsed[1].should == [term1.id.to_s, "fall12", "Fall", "active", "2012-08-20T00:00:00Z", "2012-12-20T00:00:00Z"]
      parsed[2].should == [term2.id.to_s, "winter13", "Winter", "active", "2013-01-07T00:00:00Z", "2013-04-28T00:00:00Z"]
    end

    it "should run the SIS and Provisioning Course reports" do
      Notification.find_or_create_by_name("Report Generated")
      Notification.find_or_create_by_name("Report Generation Failed")

      @account = Account.default
      sub_account = Account.create(:parent_account => @account, :name => 'English')
      sub_account.sis_source_id = 'sub1'
      sub_account.save!

      term1 = EnrollmentTerm.create(:name => 'Fall', :start_at => '20-08-2012', :end_at => '20-12-2012')
      term1.root_account = @account
      term1.sis_source_id = 'fall12'
      term1.save!

      start_at = 1.day.ago
      end_at = 10.days.from_now

      course1 = Course.new(:name => 'English 101', :course_code => 'ENG101', :start_at => start_at, :conclude_at => end_at, :account => sub_account, :enrollment_term => term1)
      course1.save
      course1.workflow_state = 'available'
      course1.sis_source_id = "SIS_COURSE_ID_1"
      course1.restrict_enrollments_to_course_dates = true
      course1.save!

      course2 = Course.new(:name => 'Math 101', :course_code => 'MAT101', :conclude_at => end_at, :account => @account)
      course2.save
      course2.workflow_state = 'available'
      course2.sis_source_id = "SIS_COURSE_ID_2"
      course2.restrict_enrollments_to_course_dates = true
      course2.save!

      course3 = Course.new(:name => 'Science 101', :course_code => 'SCI101', :account => @account)
      course3.save
      course3.workflow_state = 'available'
      course3.sis_source_id = "SIS_COURSE_ID_3"
      course3.save!

      course4 = Course.new(:name => 'self help',:course_code => 'self')
      course4.workflow_state = 'claimed'
      course4.save!
      #course4 should not show up in the sis report since it does not have sis id

      course5 = Course.new(:name => 'math 100', :course_code => 'ENG101', :start_at => start_at, :conclude_at => end_at, :account => sub_account, :enrollment_term => term1)
      course5.sis_source_id = "SIS_COURSE_ID_5"
      course5.workflow_state = 'deleted'
      course5.save!
      #course5 should not show up since it is not active

      course6 = Course.new(:name => 'talking 101', :course_code => 'Tal101')
      course6.workflow_state = 'completed'
      course6.save!
      parameters = {}
      parameters["courses"] = true
      parsed = ReportsSpecHelper.run_report(@account,"sis_export_csv", parameters)
      parsed.length.should == 3

      parsed[0].should == [course1.sis_source_id, course1.course_code, course1.name, sub_account.sis_source_id, term1.sis_source_id, "active", start_at.iso8601, end_at.iso8601]
      parsed[1].should == ["SIS_COURSE_ID_2", "MAT101", "Math 101", nil, nil, "active", nil, end_at.iso8601]
      parsed[2].should == ["SIS_COURSE_ID_3", "SCI101", "Science 101", nil, nil, "active", nil, nil]

      parsed = ReportsSpecHelper.run_report(@account,"provisioning_csv", parameters,3)
      parsed.length.should == 5
      parsed[0].should == [course1.id.to_s, course1.sis_source_id, course1.course_code, course1.name, sub_account.sis_source_id, term1.sis_source_id, "active", start_at.iso8601, end_at.iso8601]
      parsed[1].should == [course2.id.to_s, "SIS_COURSE_ID_2", "MAT101", "Math 101", nil, nil, "active", nil, end_at.iso8601]
      parsed[2].should == [course3.id.to_s, "SIS_COURSE_ID_3", "SCI101", "Science 101", nil, nil, "active", nil, nil]
      parsed[3].should == [course4.id.to_s, nil, "self", "self help", nil, nil, "unpublished", nil, nil]
      parsed[4].should == [course6.id.to_s, nil, "Tal101", "talking 101", nil, nil, "concluded", nil, nil]

      parameters = {}
      parameters["enrollment_term"] = @account.enrollment_terms.active.find_or_create_by_name(EnrollmentTerm::DEFAULT_TERM_NAME).id
      parameters["courses"] = true
      parsed = ReportsSpecHelper.run_report(@account,"sis_export_csv", parameters)
      parsed.length.should == 2
      parsed[0].should == ["SIS_COURSE_ID_2", "MAT101", "Math 101", nil, nil, "active", nil, end_at.iso8601]
      parsed[1].should == ["SIS_COURSE_ID_3", "SCI101", "Science 101", nil, nil, "active", nil, nil]


    end

    it "should run the SIS and Provisioning Sections reports" do
      Notification.find_or_create_by_name("Report Generated")
      Notification.find_or_create_by_name("Report Generation Failed")

      @account = Account.default
      sub_account = Account.create(:parent_account => @account, :name => 'English')
      sub_account.sis_source_id = 'sub1'
      sub_account.save!
      term1 = EnrollmentTerm.create(:name => 'Fall', :start_at => '20-08-2012', :end_at => '20-12-2012')
      term1.root_account = @account
      term1.sis_source_id = 'fall12'
      term1.save!

      start_at = 1.day.ago
      end_at = 10.days.from_now

      course1 = Course.new(:name => 'English 101', :course_code => 'ENG101', :start_at => start_at, :conclude_at => end_at, :account => sub_account)
      course1.save
      course1.sis_source_id = "SIS_COURSE_ID_1"
      course1.save!

      course2 = Course.new(:name => 'Math 101', :course_code => 'MAT101', :conclude_at => end_at, :account => @account, :enrollment_term => term1)
      course2.save
      course2.sis_source_id = "SIS_COURSE_ID_2"
      course2.save!

      section1 = CourseSection.new(:name => 'English_01', :course => course1, :account => sub_account, :start_at => start_at, :end_at => end_at)
      section1.sis_source_id = 'english_section_1'
      section1.root_account_id = @account.id
      section1.restrict_enrollments_to_section_dates = true
      section1.save!

      section2 = CourseSection.new(:name => 'English_02', :course => course1, :end_at => end_at)
      section2.sis_source_id = 'english_section_2'
      section2.root_account_id = @account.id
      section2.restrict_enrollments_to_section_dates = true
      section2.save!

      section3 = CourseSection.new(:name => 'Math_01', :course => course2, :end_at => end_at)
      section3.sis_source_id = 'english_section_3'
      section3.root_account_id = @account.id
      section3.restrict_enrollments_to_section_dates = true
      section3.save!

      section4 = CourseSection.new(:name => 'Math_02', :course => course2)
      section4.root_account_id = @account.id
      section4.save!

      parameters = {}
      parameters["enrollment_term"] = @account.enrollment_terms.active.find_or_create_by_name(EnrollmentTerm::DEFAULT_TERM_NAME).id
      parameters["sections"] = true
      parsed = ReportsSpecHelper.run_report(@account,"sis_export_csv", parameters)

      parsed.length.should == 2
      parsed[0].should ==[section1.sis_source_id, course1.sis_source_id, section1.name, "active", start_at.iso8601, end_at.iso8601, sub_account.sis_source_id]
      parsed[1].should == [section2.sis_source_id, course1.sis_source_id, section2.name, "active", nil, end_at.iso8601, nil]

      parameters = {}
      parameters["sections"] = true
      parsed = ReportsSpecHelper.run_report(@account,"sis_export_csv", parameters)

      parsed.length.should == 3
      parsed[0].should ==[section1.sis_source_id, course1.sis_source_id, section1.name, "active", start_at.iso8601, end_at.iso8601, sub_account.sis_source_id]
      parsed[1].should == [section2.sis_source_id, course1.sis_source_id, section2.name, "active", nil, end_at.iso8601, nil]
      parsed[2].should == ["english_section_3", "SIS_COURSE_ID_2", "Math_01", "active", nil, end_at.iso8601, nil]

      parsed = ReportsSpecHelper.run_report(@account,"provisioning_csv", parameters,5)
      parsed.length.should == 4
      parsed[0].should ==[section1.id.to_s, section1.sis_source_id, course1.id.to_s, course1.sis_source_id, section1.name, "active", start_at.iso8601, end_at.iso8601, sub_account.id.to_s, sub_account.sis_source_id]
      parsed[1].should == [section2.id.to_s, section2.sis_source_id, course1.id.to_s, course1.sis_source_id, section2.name, "active", nil, end_at.iso8601, nil, nil]
      parsed[2].should == [section3.id.to_s, "english_section_3", course2.id.to_s, "SIS_COURSE_ID_2", "Math_01", "active", nil, end_at.iso8601, nil, nil]
      parsed[3].should == [section4.id.to_s, nil, course2.id.to_s, "SIS_COURSE_ID_2", "Math_02", "active", nil, nil, nil, nil]
    end

    it "should run the SIS and provisioning Enrollment reports" do
      Notification.find_or_create_by_name("Report Generated")
      Notification.find_or_create_by_name("Report Generation Failed")

      @account = Account.default

      term1 = EnrollmentTerm.create(:name => 'Fall', :start_at => '20-08-2012', :end_at => '20-12-2012')
      term1.root_account = @account
      term1.sis_source_id = 'fall12'
      term1.save!

      course1 = Course.new(:name => 'English 101', :course_code => 'ENG101', :account => @account)
      course1.save
      course1.sis_source_id = "SIS_COURSE_ID_1"
      course1.save!
      course2 = Course.new(:name => 'Math 101', :course_code => 'MAT101', :account => @account, :enrollment_term => term1)
      course2.save
      course2.sis_source_id = "SIS_COURSE_ID_2"
      course2.save!
      course3 = Course.new(:name => 'Science 101', :course_code => 'SCI101', :account => @account)
      course3.save!
      course4 = Course.new(:name => 'Spanish 101', :course_code => 'SPA101', :account => @account)
      course4.save!
      #this course should not be in the sis report since it does not have an sis id
      section1 = CourseSection.new(:name => 'sci_01', :course => course3)
      section1.sis_source_id = 'science_section_1'
      section1.root_account_id = @account.id
      section1.save!

      user1 = user_with_pseudonym(:active_all => true, :account => @account, :name => "John St. Clair", :sortable_name => "St. Clair, John", :username => 'john@stclair.com')
      @user.pseudonym.sis_user_id = "user_sis_id_01"
      @user.pseudonym.save!
      user2 = user_with_pseudonym(:active_all => true, :username => 'micheal@michaelbolton.com', :name => 'Michael Bolton', :account => @account)
      @user.pseudonym.sis_user_id = "user_sis_id_02"
      @user.pseudonym.save!
      user3 = user_with_pseudonym(:active_all => true, :account => @account, :name => "Rick Astley", :sortable_name => "Astley, Rick", :username => 'rick@roll.com')
      @user.pseudonym.sis_user_id = "user_sis_id_03"
      @user.pseudonym.save!
      user4 = user_with_pseudonym(:active_all => true, :username => 'jason@donovan.com', :name => 'Jason Donovan', :account => @account)
      @user.pseudonym.sis_user_id = "user_sis_id_04"
      @user.pseudonym.save!
      user5 = user_with_pseudonym(:name => 'James Brown', :account => @account)
      @user.pseudonym.sis_user_id = "user_sis_id_05"
      @user.pseudonym.save!
      user6 = user_with_pseudonym(:active_all => true, :username => 'john@smith.com', :name => 'John Smith',:sortable_name => "Smith, John", :account => @account)
      @user.pseudonym.sis_user_id = "user_sis_id_06"
      @user.pseudonym.save!

      enrollment1 = course1.enroll_user(user1, 'ObserverEnrollment')
      enrollment1.invite
      enrollment1.accept
      enrollment1.save!
      enrollment2 = course3.enroll_user(user2, 'StudentEnrollment')
      enrollment2.invite
      enrollment2.accept
      enrollment2.save!
      enrollment3 = course1.enroll_user(user2, 'TaEnrollment')
      enrollment3.accept
      enrollment3.save!
      user2.reload
      enrollment4 = course1.enroll_user(user3, 'StudentEnrollment')
      enrollment4.invite
      enrollment4.accept
      enrollment4.save!
      enrollment5 = course2.enroll_user(user3, 'StudentEnrollment')
      enrollment5.invite
      enrollment5.accept
      enrollment5.save!
      user3.reload
      enrollment6 = course1.enroll_user(user4, 'TeacherEnrollment')
      enrollment6.accept
      enrollment6.save!
      enrollment7 = course2.enroll_user(user1, 'ObserverEnrollment')
      enrollment7.associated_user_id = user3.id
      enrollment7.invite
      enrollment7.accept
      enrollment7.save!
      user1.reload
      enrollment8 = course4.enroll_user(user5, 'TeacherEnrollment')
      enrollment8.accept
      enrollment8.save!
      user5.reload
      enrollment9 = section1.enroll_user(user4, 'TeacherEnrollment')
      enrollment9.accept
      enrollment9.save!
      user4.reload
      enrollment10 = course1.enroll_user(user6, 'TeacherEnrollment')
      enrollment10.accept
      enrollment10.save!
      enrollment10.workflow_state = 'completed'
      enrollment10.save!
      user6.reload

      parameters = {}
      parameters["enrollments"] = true
      parsed = ReportsSpecHelper.run_report(@account,"sis_export_csv", parameters, 1)
      parsed.length.should == 7

      parsed[0].should == ["SIS_COURSE_ID_1", "user_sis_id_01", "observer", nil, "active", nil]
      parsed[1].should == ["SIS_COURSE_ID_2", "user_sis_id_01", "observer", nil, "active", "user_sis_id_03"]
      parsed[2].should == ["SIS_COURSE_ID_1", "user_sis_id_02", "ta", nil, "active", nil]
      parsed[3].should == ["SIS_COURSE_ID_1", "user_sis_id_03", "student", nil, "active", nil]
      parsed[4].should == ["SIS_COURSE_ID_2", "user_sis_id_03", "student", nil, "active", nil]
      parsed[5].should == ["SIS_COURSE_ID_1", "user_sis_id_04", "teacher", nil, "active", nil]
      parsed[6].should == [nil, "user_sis_id_04", "teacher", "science_section_1", "active", nil]

      parsed = ReportsSpecHelper.run_report(@account,"provisioning_csv", parameters, 3)
      parsed.length.should == 9

      parsed[0].should == [course1.id.to_s, "SIS_COURSE_ID_1", user1.id.to_s, "user_sis_id_01", "observer", enrollment1.course_section_id.to_s, nil, "active", nil, nil]
      parsed[1].should == [course2.id.to_s, "SIS_COURSE_ID_2", user1.id.to_s, "user_sis_id_01", "observer", enrollment7.course_section_id.to_s, nil, "active", user3.id.to_s, "user_sis_id_03"]
      parsed[2].should == [course3.id.to_s, nil, user2.id.to_s, "user_sis_id_02", "student", enrollment2.course_section_id.to_s, nil, "active", nil, nil]
      parsed[3].should == [course1.id.to_s, "SIS_COURSE_ID_1", user2.id.to_s, "user_sis_id_02", "ta", enrollment3.course_section_id.to_s, nil, "active", nil, nil]
      parsed[4].should == [course1.id.to_s, "SIS_COURSE_ID_1", user3.id.to_s, "user_sis_id_03", "student", enrollment4.course_section_id.to_s, nil, "active", nil, nil]
      parsed[5].should == [course2.id.to_s, "SIS_COURSE_ID_2", user3.id.to_s, "user_sis_id_03", "student", enrollment5.course_section_id.to_s, nil, "active", nil, nil]
      parsed[6].should == [course1.id.to_s, "SIS_COURSE_ID_1", user4.id.to_s, "user_sis_id_04", "teacher", enrollment6.course_section_id.to_s, nil, "active", nil, nil]
      parsed[7].should == [course3.id.to_s, nil, user4.id.to_s, "user_sis_id_04", "teacher", enrollment9.course_section_id.to_s, "science_section_1", "active", nil, nil]
      parsed[8].should == [course4.id.to_s, nil, user5.id.to_s, "user_sis_id_05", "teacher", enrollment8.course_section_id.to_s, nil, "active", nil, nil]

      parameters = {}
      parameters["enrollment_term"] = @account.enrollment_terms.active.find_or_create_by_name(EnrollmentTerm::DEFAULT_TERM_NAME).id
      parameters["enrollments"] = true
      parsed = ReportsSpecHelper.run_report(@account,"sis_export_csv", parameters, 1)
      parsed.length.should == 5

      parsed[0].should == ["SIS_COURSE_ID_1", "user_sis_id_01", "observer", nil, "active", nil]
      parsed[1].should == ["SIS_COURSE_ID_1", "user_sis_id_02", "ta", nil, "active", nil]
      parsed[2].should == ["SIS_COURSE_ID_1", "user_sis_id_03", "student", nil, "active", nil]
      parsed[3].should == ["SIS_COURSE_ID_1", "user_sis_id_04", "teacher", nil, "active", nil]
      parsed[4].should == [nil, "user_sis_id_04", "teacher", "science_section_1", "active", nil]

    end

    it "should run the SIS and provisioning Groups reports" do
      Notification.find_or_create_by_name("Report Generated")
      Notification.find_or_create_by_name("Report Generation Failed")

      @account = Account.default
      sub_account = Account.create(:parent_account => @account, :name => 'English')
      sub_account.sis_source_id = 'sub1'
      sub_account.save!

      group1 = @account.groups.create(:name => 'group1name')
      group1.sis_source_id = 'group1sis'
      group1.save!
      group2 = sub_account.groups.create(:name => 'group2name')
      group2.sis_source_id = 'group2sis'
      group2.save!
      group3 = sub_account.groups.create(:name => 'group3name')
      group3.save!
      parameters = {}
      parameters["enrollment_term"] = @account.enrollment_terms.active.find_or_create_by_name(EnrollmentTerm::DEFAULT_TERM_NAME).id
      parameters["groups"] = true
      parsed = ReportsSpecHelper.run_report(@account,"sis_export_csv", parameters, 2)
      parsed.length.should == 2
      parsed[0].should == ["group1sis", nil, "group1name", "available"]
      parsed[1].should == ["group2sis", "sub1", "group2name", "available"]

      parameters = {}
      parameters["groups"] = true
      parsed = ReportsSpecHelper.run_report(@account,"sis_export_csv", parameters, 2)
      parsed.length.should == 2
      parsed[0].should == ["group1sis", nil, "group1name", "available"]
      parsed[1].should == ["group2sis", "sub1", "group2name", "available"]

      parsed = ReportsSpecHelper.run_report(@account,"provisioning_csv", parameters, 4)
      parsed.length.should == 3
      parsed[0].should == [group1.id.to_s, "group1sis", @account.id.to_s, nil, "group1name", "available"]
      parsed[1].should == [group2.id.to_s, "group2sis", sub_account.id.to_s, "sub1", "group2name", "available"]
      parsed[2].should == [group3.id.to_s, nil, sub_account.id.to_s, "sub1", "group3name", "available"]
    end

    it "should run the SIS and provisioning Groups Membership reports" do
      Notification.find_or_create_by_name("Report Generated")
      Notification.find_or_create_by_name("Report Generation Failed")

      @account = Account.default
      user1 = user_with_pseudonym(:active_all => true, :account => @account, :name => "John St. Clair", :sortable_name => "St. Clair, John", :username => 'john@stclair.com')
      @user.pseudonym.sis_user_id = "user_sis_id_01"
      @user.pseudonym.save!
      user2 = user_with_pseudonym(:active_all => true, :username => 'micheal@michaelbolton.com', :name => 'Michael Bolton', :account => @account)
      @user.pseudonym.sis_user_id = "user_sis_id_02"
      @user.pseudonym.save!
      user3 = user_with_pseudonym(:active_all => true, :username => 'micheal@michaelscott.com', :name => 'Michael Scott', :account => @account)
      @user.pseudonym.save!
      sub_account = Account.create(:parent_account => @account, :name => 'English')
      sub_account.sis_source_id = 'sub1'
      sub_account.save!

      group1 = @account.groups.create(:name => 'group1name')
      group1.sis_source_id = 'group1sis'
      group1.save!
      group2 = sub_account.groups.create(:name => 'group2name')
      group2.sis_source_id = 'group2sis'
      group2.save!
      group3 = sub_account.groups.create(:name => 'group3name')
      group3.sis_source_id = 'group3sis'
      group3.save!
      gm1 = GroupMembership.create(:group => group1, :user => user1, :workflow_state => "accepted")
      gm1.sis_batch_id = 1
      gm1.save!
      gm2 = GroupMembership.create(:group => group2, :user => user2, :workflow_state => "accepted")
      gm2.sis_batch_id = 1
      gm2.save!
      gm3 = GroupMembership.create(:group => group3, :user => user3, :workflow_state => "accepted")
      gm3.save!

      parameters = {}
      parameters["enrollment_term"] = @account.enrollment_terms.active.find_or_create_by_name(EnrollmentTerm::DEFAULT_TERM_NAME).id
      parameters["group_membership"] = true
      parsed = ReportsSpecHelper.run_report(@account,"sis_export_csv", parameters)
      parsed.length.should == 2
      parsed[0].should == [group1.sis_source_id, "user_sis_id_01", "accepted"]
      parsed[1].should == [group2.sis_source_id, "user_sis_id_02", "accepted"]

      parameters = {}
      parameters["group_membership"] = true
      parsed = ReportsSpecHelper.run_report(@account,"sis_export_csv", parameters)
      parsed.length.should == 2
      parsed[0].should == [group1.sis_source_id, "user_sis_id_01", "accepted"]
      parsed[1].should == [group2.sis_source_id, "user_sis_id_02", "accepted"]

      parsed = ReportsSpecHelper.run_report(@account,"provisioning_csv", parameters, 1)
      parsed.length.should == 3
      parsed[0].should == [group1.id.to_s, group1.sis_source_id, user1.id.to_s, "user_sis_id_01", "accepted"]
      parsed[1].should == [group2.id.to_s, group2.sis_source_id, user2.id.to_s, "user_sis_id_02", "accepted"]
      parsed[2].should == [group3.id.to_s, group3.sis_source_id, user3.id.to_s, nil, "accepted"]
    end

    it "should run the x list reports" do
      Notification.find_or_create_by_name("Report Generated")
      Notification.find_or_create_by_name("Report Generation Failed")

      @account = Account.default
      term1 = EnrollmentTerm.create(:name => 'Fall', :start_at => '20-08-2012', :end_at => '20-12-2012')
      term1.root_account = @account
      term1.sis_source_id = 'fall12'
      term1.save!
      course1 = Course.new(:name => 'English 101', :course_code => 'ENG101', :account => @account, :enrollment_term => term1)
      course1.save
      course1.sis_source_id = "SIS_COURSE_ID_1"
      course1.save!
      course2 = Course.new(:name => 'Math 101', :course_code => 'MAT101', :account => @account, :enrollment_term => term1)
      course2.save
      course2.sis_source_id = "SIS_COURSE_ID_2"
      course2.save!
      course3 = Course.new(:name => 'Science 101', :course_code => 'SCI101', :account => @account)
      course3.save
      course3.sis_source_id = "SIS_COURSE_ID_3"
      course3.save!
      course4 = Course.new(:name => 'Science 1011', :course_code => 'SCI1011', :account => @account)
      course4.save
      course4.sis_source_id = "SIS_COURSE_ID_4"
      course4.save!
      course5 = Course.new(:name => 'Spanish 203', :course_code => 'SPA203', :account => @account)
      course5.save
      course6 = Course.new(:name => 'Science 304', :course_code => 'SCI304', :account => @account)
      course6.save
      course6.sis_source_id = "SIS_COURSE_ID_6"
      course6.save!
      section1 = CourseSection.new(:name => 'English_01', :course => course1)
      section1.sis_source_id = 'english_section_1'
      section1.root_account_id = @account.id
      section1.save!
      section2 = CourseSection.new(:name => 'English_02', :course => course2)
      section2.sis_source_id = 'english_section_2'
      section2.root_account_id = @account.id
      section2.save!
      section3 = CourseSection.new(:name => 'Math_01', :course => course3)
      section3.sis_source_id = 'english_section_3'
      section3.root_account_id = @account.id
      section3.save!
      section4 = CourseSection.new(:name => 'Math_012', :course => course4)
      section4.sis_source_id = 'english_section_4'
      section4.root_account_id = @account.id
      section4.save!
      section5 = CourseSection.new(:name => 'spanish_012', :course => course5)
      section5.root_account_id = @account.id
      section5.save!

      section1.crosslist_to_course(course2)
      section3.crosslist_to_course(course4)
      section5.crosslist_to_course(course6)

      parameters = {}
      parameters["enrollment_term"] = @account.enrollment_terms.active.find_or_create_by_name(EnrollmentTerm::DEFAULT_TERM_NAME).id
      parameters["xlist"] = true
      parsed = ReportsSpecHelper.run_report(@account,"sis_export_csv", parameters)
      parsed.length.should == 1
      parsed[0].should == ["SIS_COURSE_ID_4", "english_section_3", "active"]

      parameters = {}
      parameters["xlist"] = true
      parsed = ReportsSpecHelper.run_report(@account,"sis_export_csv", parameters)
      parsed.length.should == 2
      parsed[0].should == ["SIS_COURSE_ID_2", "english_section_1", "active"]
      parsed[1].should == ["SIS_COURSE_ID_4", "english_section_3", "active"]

      parsed = ReportsSpecHelper.run_report(@account,"provisioning_csv", parameters,1)
      parsed.length.should == 3
      parsed[0].should == [course2.id.to_s, "SIS_COURSE_ID_2", section1.id.to_s, "english_section_1", "active"]
      parsed[1].should == [course4.id.to_s, "SIS_COURSE_ID_4", section3.id.to_s, "english_section_3", "active"]
      parsed[2].should == [course6.id.to_s, "SIS_COURSE_ID_6", section5.id.to_s, nil, "active"]
    end

    it "should run the SIS Export" do
      @account = Account.default
      @admin = account_admin_user(:account => @account)
      user1 = user_with_pseudonym(:active_all => true, :account => @account, :name => "John St. Clair", :sortable_name => "St. Clair, John", :username => 'john@stclair.com')
      @user.pseudonym.sis_user_id = "user_sis_id_01"
      @user.pseudonym.save!
      user2 = user_with_pseudonym(:active_all => true, :username => 'micheal@michaelbolton.com', :name => 'Michael Bolton', :account => @account)
      @user.pseudonym.sis_user_id = "user_sis_id_02"
      @user.pseudonym.save!
      user3 = user_with_pseudonym(:name => 'Rick Astley', :account => @account)
      sub_account = Account.create(:parent_account => @account, :name => 'English')
      sub_account.sis_source_id = 'sub1'
      sub_account.save!
      sub_sub_account = Account.create(:parent_account => sub_account, :name => 'ESL')
      sub_sub_account.sis_source_id = 'subsub1'
      sub_sub_account.save!
      sub_account2 = Account.create(:parent_account => @account, :name => 'Math')
      sub_account2.sis_source_id = 'sub2'
      sub_account2.save!
      term1 = EnrollmentTerm.create(:name => 'Fall', :start_at => '20-08-2012', :end_at => '20-12-2012')
      term1.root_account = @account
      term1.sis_source_id = 'fall12'
      term1.save!
      term2 = EnrollmentTerm.create(:name => 'Winter', :start_at => '07-01-2013', :end_at => '28-04-2013')
      term2.root_account = @account
      term2.sis_source_id = 'winter13'
      term2.save!
      start_at = 1.day.ago
      end_at = 10.days.from_now

      course1 = Course.new(:name => 'English 101', :course_code => 'ENG101', :start_at => start_at, :conclude_at => end_at, :account => sub_account, :enrollment_term => term1)
      course1.save
      course1.workflow_state = 'available'
      course1.sis_source_id = "SIS_COURSE_ID_1"
      course1.restrict_enrollments_to_course_dates = true
      course1.save!

      course2 = Course.new(:name => 'Math 101', :course_code => 'MAT101', :conclude_at => end_at, :account => @account)
      course2.save
      course2.workflow_state = 'available'
      course2.sis_source_id = "SIS_COURSE_ID_2"
      course2.restrict_enrollments_to_course_dates = true
      course2.save!

      course3 = Course.new(:name => 'Science 101', :course_code => 'SCI101', :account => @account)
      course3.save
      course3.workflow_state = 'available'
      course3.sis_source_id = "SIS_COURSE_ID_3"
      course3.save!

      Notification.find_or_create_by_name("Report Generated")
      Notification.find_or_create_by_name("Report Generation Failed")

      parameters = {}
      parameters["enrollment_term"] = @account.enrollment_terms.active.find_or_create_by_name(EnrollmentTerm::DEFAULT_TERM_NAME).id
      parameters["accounts"] = true
      parameters["users"] = true
      parameters["courses"] = true
      parsed = ReportsSpecHelper.run_report(@account,"sis_export_csv", parameters)

      accounts_report = parsed["accounts"][1..-1].sort_by { |r| r[0] }
      accounts_report[0].should == ["sub1", nil, "English", "active"]
      accounts_report[1].should == ["sub2", nil, "Math", "active"]
      accounts_report[2].should == ["subsub1", "sub1", "ESL", "active"]

      users_report = parsed["users"][1..-1].sort_by { |r| r[0] }
      users_report[0].should == ["user_sis_id_01", "john@stclair.com", nil, "John St.", "Clair", "john@stclair.com", "active"]
      users_report[1].should == ["user_sis_id_02", "micheal@michaelbolton.com", nil, "Michael", "Bolton", "micheal@michaelbolton.com", "active"]

      courses_report = parsed["courses"][1..-1].sort_by { |r| r[0] }
      courses_report[0].should == ["SIS_COURSE_ID_2", "MAT101", "Math 101", nil, nil, "active", nil, end_at.iso8601]
      courses_report[1].should == ["SIS_COURSE_ID_3", "SCI101", "Science 101", nil, nil, "active", nil, nil]

      parameters = {}
      parameters["accounts"] = true
      parameters["users"] = true
      parameters["courses"] = true
      parsed = ReportsSpecHelper.run_report(@account,"sis_export_csv", parameters)

      accounts_report = parsed["accounts"][1..-1].sort_by { |r| r[0] }
      accounts_report[0].should == ["sub1", nil, "English", "active"]
      accounts_report[1].should == ["sub2", nil, "Math", "active"]
      accounts_report[2].should == ["subsub1", "sub1", "ESL", "active"]

      users_report = parsed["users"][1..-1].sort_by { |r| r[0] }
      users_report[0].should == ["user_sis_id_01", "john@stclair.com", nil, "John St.", "Clair", "john@stclair.com", "active"]
      users_report[1].should == ["user_sis_id_02", "micheal@michaelbolton.com", nil, "Michael", "Bolton", "micheal@michaelbolton.com", "active"]

      courses_report = parsed["courses"][1..-1].sort_by { |r| r[0] }
      courses_report[0].should == ["SIS_COURSE_ID_1", "ENG101", "English 101", "sub1", "fall12", "active", start_at.iso8601, end_at.iso8601]
      courses_report[1].should == ["SIS_COURSE_ID_2", "MAT101", "Math 101", nil, nil, "active", nil, end_at.iso8601]
      courses_report[2].should == ["SIS_COURSE_ID_3", "SCI101", "Science 101", nil, nil, "active", nil, nil]
    end
    it "should run the SIS Export reports with no data" do
      @account = Account.default
      @admin = account_admin_user(:account => @account)
      Notification.find_or_create_by_name("Report Generated")
      Notification.find_or_create_by_name("Report Generation Failed")

      parameters = {}
      parameters["accounts"] = true
      parameters["users"] = true
      parameters["terms"] = true
      parameters["courses"] = true
      parameters["sections"] = true
      parameters["enrollments"] = true
      parameters["groups"] = true
      parameters["group_membership"] = true
      parameters["xlist"] = true
      parsed = ReportsSpecHelper.run_report(@account,"sis_export_csv", parameters)

      parsed["accounts"].should == [["account_id", "parent_account_id", "name", "status"]]
      parsed["terms"].should == [["term_id", "name", "status", "start_date", "end_date"]]
      parsed["users"].should == [["user_id", "login_id", "password", "first_name", "last_name", "email", "status"]]
      parsed["courses"].should == [["course_id", "short_name", "long_name", "account_id", "term_id", "status", "start_date", "end_date"]]
      parsed["sections"].should == [["section_id", "course_id", "name", "status", "start_date", "end_date", "account_id"]]
      parsed["enrollments"].should == [["course_id", "user_id", "role", "section_id", "status", "associated_user_id"]]
      parsed["groups"].should == [["group_id", "account_id", "name", "status"]]
      parsed["group_membership"].should == [["group_id", "user_id", "status"]]
      parsed["xlist"].should == [["xlist_course_id", "section_id", "status"]]
    end
  end
end
