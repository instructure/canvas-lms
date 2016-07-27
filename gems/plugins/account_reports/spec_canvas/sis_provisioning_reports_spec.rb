#
# Copyright (C) 2012 - 2015 Instructure, Inc.
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

describe "Default Account Reports" do
  include ReportSpecHelper

  def create_some_users_with_pseudonyms()
    sis = @account.sis_batches.create
    @user1 = user_with_pseudonym(:active_all => true,:account => @account,:name => "John St. Clair",
                                 :sortable_name => "St. Clair,John",:username => 'john@stclair.com')
    @user.pseudonym.sis_user_id = "user_sis_id_01"
    @user.pseudonym.sis_batch_id = sis.id
    @user.pseudonym.save!
    @user2 = user_with_pseudonym(:active_all => true,:username => 'micheal@michaelbolton.com',
                                 :name => 'Michael Bolton',:account => @account)
    @user.pseudonym.sis_user_id = "user_sis_id_02"
    @user.pseudonym.sis_batch_id = sis.id
    @user.pseudonym.save!
    @user3 = user_with_pseudonym(:active_all => true,:account => @account,:name => "Rick Astley",
                                 :sortable_name => "Astley,Rick",:username => 'rick@roll.com')
    @user.pseudonym.sis_user_id = "user_sis_id_03"
    @user.pseudonym.sis_batch_id = sis.id
    @user.pseudonym.save!
    @user4 = user_with_pseudonym(:active_all => true,:username => 'jason@donovan.com',
                                 :name => 'Jason Donovan',:account => @account)
    @user.pseudonym.sis_user_id = "user_sis_id_04"
    @user.pseudonym.save!
    @user5 = user_with_pseudonym(:name => 'James Brown',:account => @account)
    @user.pseudonym.sis_user_id = "user_sis_id_05"
    @user.pseudonym.sis_batch_id = sis.id
    @user.pseudonym.save!
    @user5.destroy
    @user6 = user_with_pseudonym(:active_all => true,:username => 'john@smith.com',
                                 :name => 'John Smith',:sortable_name => "Smith,John",
                                 :account => @account)
    @user7 = user_with_pseudonym(:active_all => true,:username => 'jony@apple.com',
                                 :name => 'Jony Ive',:account => @account)
    @user8 = user_with_pseudonym(:active_all => true,:username => 'steve@apple.com',
                                 :name => 'Steve Jobs',:account => @account)
    @user8.destroy
  end

  def create_an_account()
    @sis = @account.sis_batches.create
    @sub_account = Account.create(:parent_account => @account,:name => 'English')
    @sub_account.sis_source_id = 'sub1'
    @sub_account.sis_batch_id = @sis.id
    @sub_account.save!
  end

  def create_some_accounts()
    create_an_account()
    @sub_sub_account = Account.create(:parent_account => @sub_account,:name => 'sESL')
    @sub_sub_account.sis_source_id = 'subsub1'
    @sub_sub_account.sis_batch_id = @sis.id
    @sub_sub_account.save!
    @sub_account3 = Account.create(:parent_account => @account,:name => 'math')
    @sub_account3.sis_source_id = 'sub3'
    @sub_account3.sis_batch_id = @sis.id
    @sub_account3.save!
    @sub_account4 = Account.create(:parent_account => @account,:name => 'deleted sis account')
    @sub_account4.sis_source_id = 'sub4'
    @sub_account4.sis_batch_id = @sis.id
    @sub_account4.save!
    @sub_account4.destroy
    @sub_account5 = Account.create(:parent_account => @account,:name => 'other')
    @sub_account6 = Account.create(:parent_account => @account,:name => 'the deleted account')
    @sub_account6.destroy
  end

  def create_a_term()
    @sis = @account.sis_batches.create
    @term1 = EnrollmentTerm.create(:name => 'Fall',:start_at => 6.months.ago,
                                   :end_at => 1.year.from_now)
    @term1.root_account = @account
    @term1.sis_source_id = 'fall12'
    @term1.sis_batch_id = @sis.id
    @term1.save!
  end

  def create_some_terms()
    create_a_term
    @term2 = EnrollmentTerm.create(:name => 'Winter',:start_at => 3.weeks.ago,
                                   :end_at => 2.years.from_now)
    @term2.root_account = @account
    @term2.sis_source_id = 'winter13'
    @term2.sis_batch_id = @sis.id
    @term2.save!
    @term2.destroy
    @term3 = EnrollmentTerm.create(:name => 'Spring',:start_at => 1.week.ago,
                                   :end_at => 6.months.from_now)
    @term3.root_account = @account
    @term3.save!
  end

  def create_some_courses()
    create_an_account()
    create_a_term()
    start_at = 1.day.ago
    end_at = 3.months.from_now
    @course1 = Course.new(:name => 'English 101',:course_code => 'ENG101',
                          :start_at => start_at,:conclude_at => end_at)
    @course1.account_id = @sub_account.id
    @course1.enrollment_term_id = @term1.id
    @course1.workflow_state = 'available'
    @course1.sis_source_id = "SIS_COURSE_ID_1"
    @course1.restrict_enrollments_to_course_dates = true
    @course1.sis_batch_id = @sis.id
    @course1.save!

    @course2 = Course.new(:name => 'Math 101',:course_code => 'MAT101',
                          :conclude_at => end_at, :account => @account)
    @course2.workflow_state = 'available'
    @course2.sis_source_id = "SIS_COURSE_ID_2"
    @course2.restrict_enrollments_to_course_dates = true
    @course2.sis_batch_id = @sis.id
    @course2.save!

    @course3 = Course.new(:name => 'Science 101',:course_code => 'SCI101',
                          :account => @account)
    @course3.workflow_state = 'available'
    @course3.sis_source_id = "SIS_COURSE_ID_3"
    @course3.sis_batch_id = @sis.id
    @course3.save!

    @course4 = Course.new(:name => 'self help',:course_code => 'self',
                          :account => @account)
    @course4.workflow_state = 'claimed'
    @course4.save!

    @course5 = Course.new(:name => 'Sd Math 100',:course_code => 'ENG101',
                          :start_at => start_at,:conclude_at => end_at)
    @course5.account_id = @sub_account.id
    @course5.enrollment_term_id = @term1.id
    @course5.sis_source_id = "SIS_COURSE_ID_5"
    @course5.workflow_state = 'deleted'
    @course5.sis_batch_id = @sis.id
    @course5.save!

    @course6 = Course.new(:name => 'talking 101',:course_code => 'Tal101',
                          :account => @account)
    @course6.workflow_state = 'completed'
    @course6.save!
  end

  def create_some_courses_and_sections()
    create_some_courses()

    @section1 = CourseSection.new(:name => 'English_01',:course => @course1,
                                  :start_at => @course1.start_at,:end_at => @course1.conclude_at)
    @section1.sis_source_id = 'english_section_1'
    @section1.restrict_enrollments_to_section_dates = true
    @section1.sis_batch_id = @sis.id
    @section1.save!

    @section2 = CourseSection.new(:name => 'English_02',:course => @course1,
                                  :end_at => @course1.conclude_at)
    @section2.sis_source_id = 'english_section_2'
    @section2.root_account_id = @account.id
    @section2.restrict_enrollments_to_section_dates = true
    @section2.sis_batch_id = @sis.id
    @section2.save!

    @section3 = CourseSection.new(:name => 'Math_01',:course => @course2,
                                  :end_at => @course2.conclude_at)
    @section3.sis_source_id = 'english_section_3'
    @section3.root_account_id = @account.id
    @section3.restrict_enrollments_to_section_dates = true
    @section3.sis_batch_id = @sis.id
    @section3.save!

    @section4 = CourseSection.new(:name => 'Math_02',:course => @course2)
    @section4.root_account_id = @account.id
    @section4.save!

    @section5 = CourseSection.new(:name => 'Science_01',:course => @course3)
    @section5.root_account_id = @account.id
    @section5.save!
    @section5.destroy
  end

  def create_some_enrolled_users()
    create_some_courses_and_sections()
    create_some_users_with_pseudonyms()

    @role = @account.roles.build :name => 'Pixel Engineer'
    @role.base_role_type = 'DesignerEnrollment'
    @role.save!

    @enrollment1 = @course1.enroll_user(@user1,'ObserverEnrollment',:enrollment_state => :active)
    @enrollment1.sis_batch_id = @sis.id
    @enrollment1.save!
    @enrollment2 = @course3.enroll_user(@user2,'StudentEnrollment',:enrollment_state => :active)
    @enrollment2.sis_batch_id = @sis.id
    @enrollment2.save!
    @enrollment3 = @course1.enroll_user(@user2,'TaEnrollment',:enrollment_state => :active)
    @enrollment3.sis_batch_id = @sis.id
    @enrollment3.save!
    @enrollment4 = @course1.enroll_user(@user3,'StudentEnrollment',:enrollment_state => :active)
    @enrollment4.sis_batch_id = @sis.id
    @enrollment4.save!
    @enrollment5 = @course2.enroll_user(@user3,'StudentEnrollment',:enrollment_state => :active)
    @enrollment5.sis_batch_id = @sis.id
    @enrollment5.save!
    @enrollment6 = @course1.enroll_user(@user4,'TeacherEnrollment',:enrollment_state => :active)
    @enrollment6.sis_batch_id = @sis.id
    @enrollment6.save!
    @enrollment6.destroy
    @enrollment7 = @course2.enroll_user(@user1,'ObserverEnrollment',:enrollment_state => :active,
                                        :associated_user_id => @user3.id)
    @enrollment7.sis_batch_id = @sis.id
    @enrollment7.save!
    @enrollment8 = @course4.enroll_user(@user5,'TeacherEnrollment',:enrollment_state => :active)
    @enrollment9 = @course1.enroll_user(@user4, 'TeacherEnrollment',
                                        enrollment_state: 'active',
                                        allow_multiple_enrollments: true,
                                        section: @section1)
    @enrollment9.sis_batch_id = @sis.id
    @enrollment9.save!
    @enrollment10 = @course1.enroll_user(@user6,'TeacherEnrollment',
                                         :enrollment_state => :completed)
    @enrollment11 = @course2.enroll_user(@user4,'DesignerEnrollment',
                                         :role => @role,
                                         :enrollment_state => :active)
    @enrollment11.sis_batch_id = @sis.id
    @enrollment11.save!
    @enrollment12 = @course4.enroll_user(@user4,'StudentEnrollment',
                                         :enrollment_state => :active)
    Enrollment.where(id: @enrollment12).update_all(workflow_state: 'creation_pending')
  end

  def create_some_groups()
    create_an_account()
    @group1 = @account.groups.create(:name => 'group1name')
    @group1.sis_source_id = 'group1sis'
    @group1.sis_batch_id = @sis.id
    @group1.save!
    @group2 = @sub_account.groups.create(:name => 'group2name')
    @group2.sis_source_id = 'group2sis'
    @group2.sis_batch_id = @sis.id
    @group2.save!
    @group3 = @sub_account.groups.create(:name => 'group3name')
    @group3.save!
    @group4 = @account.groups.create(:name => 'group4name')
    @group4.sis_source_id = 'group4sis'
    @group4.sis_batch_id = @sis.id
    @group4.save!
    @group4.destroy
  end

  def create_some_group_memberships_n_stuff()
    create_some_users_with_pseudonyms()
    create_some_groups()
    batch = @group1.root_account.sis_batches.create!
    @gm1 = GroupMembership.create(:group => @group1,:user => @user1,:workflow_state => "accepted")
    @gm1.sis_batch_id = batch.id
    @gm1.save!
    @gm2 = GroupMembership.create(:group => @group2,:user => @user2,:workflow_state => "accepted")
    @gm2.sis_batch_id = batch.id
    @gm2.save!
    @gm3 = GroupMembership.create(:group => @group3,:user => @user3,:workflow_state => "accepted")
    @gm3.save!
    @gm4 = GroupMembership.create(:group => @group2,:user => @user3,:workflow_state => "accepted")
    @gm4.sis_batch_id = batch.id
    @gm4.save!
    @gm4.destroy
  end

  describe "SIS export and Provisioning reports" do
    before(:each) do
      Notification.where(name: "Report Generated").first_or_create
      Notification.where(name: "Report Generation Failed").first_or_create
      @account = Account.create(name: 'New Account', default_time_zone: 'UTC')
      @admin = account_admin_user(:account => @account)
      @default_term = @account.default_enrollment_term
    end

    describe "Users" do
      before(:each) do
        create_some_users_with_pseudonyms()
      end

      it "should run sis report with term parameter and include deleted users" do
        parameters = {}
        parameters["enrollment_term"] = @default_term.id
        #term does not impact user report
        parameters["include_deleted"] = true
        parameters["created_by_sis"] = true
        parameters["users"] = true
        parsed = read_report("sis_export_csv", {params: parameters, header: true, order: 0})
        headers = parsed.shift
        expect(headers).to eq ['user_id', 'login_id', 'password', 'first_name',
                               'last_name', 'full_name', 'sortable_name',
                               'short_name', 'email', 'status']
        expect(parsed.length).to eq 4

        expect(parsed[0]).to eq ["user_sis_id_01", "john@stclair.com", nil,
                                 "John St.", "Clair", "John St. Clair",
                                 "Clair, John St.", nil,
                                 "john@stclair.com", "active"]
        expect(parsed[1]).to eq ["user_sis_id_02", "micheal@michaelbolton.com",
                                 nil, "Michael", "Bolton", "Michael Bolton",
                                 "Bolton, Michael", nil,
                                 "micheal@michaelbolton.com", "active"]
        expect(parsed[2]).to eq ["user_sis_id_03", "rick@roll.com", nil, "Rick",
                                 "Astley", "Rick Astley", "Astley, Rick", nil,
                                 "rick@roll.com", "active"]
        expect(parsed[3]).to eq ["user_sis_id_05", "nobody@example.com", nil,
                                 "James", "Brown", "James Brown",
                                 "Brown, James", nil, nil, "deleted"]
      end

      it "should run sis report" do
        parameters = {}
        parameters["users"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 0})
        expect(parsed.length).to eq 4

        expect(parsed[0]).to eq ["user_sis_id_01", "john@stclair.com", nil,
                                 "John St.", "Clair", "John St. Clair",
                                 "Clair, John St.", nil,
                                 "john@stclair.com", "active"]
        expect(parsed[1]).to eq ["user_sis_id_02", "micheal@michaelbolton.com",
                                 nil, "Michael", "Bolton", "Michael Bolton",
                                 "Bolton, Michael", nil,
                                 "micheal@michaelbolton.com", "active"]
        expect(parsed[2]).to eq ["user_sis_id_03", "rick@roll.com", nil, "Rick",
                                 "Astley", "Rick Astley", "Astley, Rick", nil,
                                 "rick@roll.com", "active"]
        expect(parsed[3]).to eq ["user_sis_id_04", "jason@donovan.com", nil,
                                 "Jason", "Donovan", "Jason Donovan",
                                 "Donovan, Jason", nil, "jason@donovan.com",
                                 "active"]
      end

      it "should run sis report on a sub_acocunt" do
        create_an_account()
        @course1 = Course.new(:name => 'English 101', :course_code => 'ENG101')
        @course1.account_id = @sub_account.id
        @course1.workflow_state = 'available'
        @course1.save!
        @enrollment1 = @course1.enroll_user(@user1, 'StudentEnrollment', :enrollment_state => :active)

        parameters = {}
        parameters["users"] = true
        parsed = read_report("sis_export_csv", {params: parameters, account: @sub_account})
        expect(parsed.length).to eq 1

        expect(parsed[0]).to eq ["user_sis_id_01", "john@stclair.com", nil,
                                 "John St.", "Clair", "John St. Clair",
                                 "Clair, John St.", nil,
                                 "john@stclair.com", "active"]
      end

      it "should run provisioning report" do
        parameters = {}
        parameters["users"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: [1, 2], header: true})

        headers = parsed.shift
        expect(headers).to eq ["canvas_user_id", "user_id", "login_id",
                               "first_name", "last_name", "full_name",
                               "sortable_name", "short_name", "email", "status", "created_by_sis"]
        expect(parsed.length).to eq 6

        expect(parsed[0]).to eq [@user6.id.to_s, nil, "john@smith.com", "John",
                                 "Smith", "John Smith", "Smith, John", nil,
                                 "john@smith.com", "active", "false"]
        expect(parsed[1]).to eq [@user7.id.to_s, nil, "jony@apple.com", "Jony",
                                 "Ive", "Jony Ive", "Ive, Jony", nil,
                                 "jony@apple.com", "active", "false"]
        expect(parsed[2]).to eq [@user1.id.to_s, "user_sis_id_01",
                                 "john@stclair.com", "John St.", "Clair",
                                 "John St. Clair", "Clair, John St.", nil,
                                 "john@stclair.com", "active", "true"]
        expect(parsed[3]).to eq [@user2.id.to_s, "user_sis_id_02",
                                 "micheal@michaelbolton.com", "Michael",
                                 "Bolton", "Michael Bolton", "Bolton, Michael",
                                 nil, "micheal@michaelbolton.com", "active", "true"]
        expect(parsed[4]).to eq [@user3.id.to_s, "user_sis_id_03",
                                 "rick@roll.com", "Rick", "Astley",
                                 "Rick Astley", "Astley, Rick", nil,
                                 "rick@roll.com", "active", "true"]
        expect(parsed[5]).to eq [@user4.id.to_s, "user_sis_id_04",
                                 "jason@donovan.com", "Jason", "Donovan",
                                 "Jason Donovan", "Donovan, Jason", nil,
                                 "jason@donovan.com", "active", "false"]
      end

      it "should run provisioning report including deleted users" do
        c = Course.create(:name => 'course1')
        c.student_view_student
        parameters = {}
        parameters["users"] = true
        parameters["include_deleted"] = true
        parameters["created_by_sis"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: [1, 2]})
        expect(parsed.length).to eq 4

        expect(parsed[0]).to eq [@user1.id.to_s, "user_sis_id_01",
                                 "john@stclair.com", "John St.", "Clair",
                                 "John St. Clair", "Clair, John St.", nil,
                                 "john@stclair.com", "active", "true"]
        expect(parsed[1]).to eq [@user2.id.to_s, "user_sis_id_02",
                                 "micheal@michaelbolton.com", "Michael",
                                 "Bolton", "Michael Bolton", "Bolton, Michael",
                                 nil, "micheal@michaelbolton.com", "active", "true"]
        expect(parsed[2]).to eq [@user3.id.to_s, "user_sis_id_03",
                                 "rick@roll.com", "Rick", "Astley",
                                 "Rick Astley", "Astley, Rick", nil,
                                 "rick@roll.com", "active", "true"]
        expect(parsed[3]).to eq [@user5.id.to_s, "user_sis_id_05",
                                 "nobody@example.com", "James", "Brown",
                                 "James Brown", "Brown, James", nil, nil,
                                 "deleted", "true"]
      end
    end

    describe "Accounts" do
      before(:each) do
        create_some_accounts()
      end

      it "should run the SIS report" do
        parameters = {}
        parameters["enrollment_term"] = @default_term.id
        parameters["accounts"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 0})

        expect(parsed.length).to eq 3
        expect(parsed[0]).to eq ["sub1",nil,"English","active"]
        expect(parsed[1]).to eq ["sub3",nil,"math","active"]
        expect(parsed[2]).to eq ["subsub1","sub1","sESL","active"]
      end

      it "should run the SIS report on a sub account" do
        parameters = {}
        parameters["accounts"] = true
        parsed = read_report("sis_export_csv",{params: parameters, account: @sub_account})

        expect(parsed.length).to eq 1
        expect(parsed[0]).to eq ["subsub1","sub1","sESL","active"]
      end

      it "should run the SIS report including deleted accounts" do
        parameters = {}
        parameters["accounts"] = true
        parameters["include_deleted"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 0})

        expect(parsed.length).to eq 4
        expect(parsed[0]).to eq ["sub1",nil,"English","active"]
        expect(parsed[1]).to eq ["sub3",nil,"math","active"]
        expect(parsed[2]).to eq ["sub4",nil,"deleted sis account","deleted"]
        expect(parsed[3]).to eq ["subsub1","sub1","sESL","active"]
      end

      it "should run the provisioning report including deleted accounts" do
        parameters = {}
        parameters["accounts"] = true
        parameters["enrollment_term"] = ''
        parameters["include_deleted"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: 4})

        expect(parsed.length).to eq 5
        expect(parsed[0]).to eq [@sub_account.id.to_s, "sub1", @account.id.to_s, nil, "English", "active", "true"]
        expect(parsed[1]).to eq [@sub_account4.id.to_s, "sub4", @account.id.to_s, nil,
                                 "deleted sis account", "deleted", "true"]
        expect(parsed[2]).to eq [@sub_account3.id.to_s, "sub3", @account.id.to_s, nil, "math", "active", "true"]
        expect(parsed[3]).to eq [@sub_account5.id.to_s, nil, @account.id.to_s, nil, "other", "active", "false"]
        expect(parsed[4]).to eq [@sub_sub_account.id.to_s, "subsub1", @sub_account.id.to_s,
                                 "sub1", "sESL", "active", "true"]
      end
    end

    describe "Terms" do
      before(:each) do
        create_some_terms()
      end

      it "should run the SIS report" do
        parameters = {}
        parameters["enrollment_term"] = @term3.id
        parameters["include_deleted"] = true
        parameters["terms"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 0})

        expect(parsed.length).to eq 2
        expect(parsed[0]).to eq ["fall12","Fall","active",@term1.start_at.iso8601,
                             @term1.end_at.iso8601]
        expect(parsed[1]).to eq ["winter13","Winter","deleted",@term2.start_at.iso8601,
                             @term2.end_at.iso8601]
      end

      it "should run the provisioning report" do
        parameters = {}
        parameters["terms"] = true
        parsed = read_report("provisioning_csv",{params: parameters, order: 2})

        expect(parsed.length).to eq 3
        expect(parsed[0]).to eq [@default_term.id.to_s, nil, "Default Term", "active", nil, nil, "false"]
        expect(parsed[1]).to eq [@term1.id.to_s, "fall12", "Fall", "active",
                                 @term1.start_at.iso8601, @term1.end_at.iso8601, "true"]
        expect(parsed[2]).to eq [@term3.id.to_s, nil, "Spring", "active",
                                 @term3.start_at.iso8601, @term3.end_at.iso8601, "false"]
      end

      it "should run the provisioning report with deleted terms" do
        parameters = {}
        parameters["terms"] = true
        parameters["include_deleted"] = true
        parsed = read_report("provisioning_csv",{params: parameters, order: 2})

        expect(parsed.length).to eq 4
        expect(parsed[0]).to eq [@default_term.id.to_s, nil, "Default Term", "active", nil, nil, "false"]
        expect(parsed[1]).to eq [@term1.id.to_s, "fall12", "Fall", "active",
                                 @term1.start_at.iso8601, @term1.end_at.iso8601, "true"]
        expect(parsed[2]).to eq [@term3.id.to_s, nil, "Spring", "active",
                                 @term3.start_at.iso8601, @term3.end_at.iso8601, "false"]
        expect(parsed[3]).to eq [@term2.id.to_s, "winter13", "Winter", "deleted",
                                 @term2.start_at.iso8601, @term2.end_at.iso8601, "true"]
      end
    end

    describe "Courses" do
      before(:each) do
        create_some_courses()
      end

      it "should run the SIS report" do
        parameters = {}
        parameters["enrollment_term"] = ''
        parameters["courses"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 0})

        expect(parsed.length).to eq 3
        expect(parsed[0]).to eq [@course1.sis_source_id,@course1.course_code,@course1.name,
                             @sub_account.sis_source_id,@term1.sis_source_id,"active",
                             @course1.start_at.iso8601,@course1.end_at.iso8601]
        expect(parsed[1]).to eq ["SIS_COURSE_ID_2","MAT101","Math 101",nil,nil,
                             "active",nil,@course2.end_at.iso8601]
        expect(parsed[2]).to eq ["SIS_COURSE_ID_3","SCI101","Science 101",nil,nil,"active",nil,nil]
      end

      it "should run the SIS report with sis term and deleted courses" do
        @course1.complete
        parameters = {}
        parameters["enrollment_term_id"] = "sis_term_id:fall12"
        parameters["include_deleted"] = true
        parameters["courses"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 0})

        expect(parsed.length).to eq 2
        expect(parsed[0]).to eq [@course1.sis_source_id,@course1.course_code,@course1.name,
                             @sub_account.sis_source_id,@term1.sis_source_id,"completed",
                             @course1.start_at.iso8601,@course1.conclude_at.iso8601]
        expect(parsed[1]).to eq ["SIS_COURSE_ID_5","ENG101","Sd Math 100","sub1",
                             "fall12","deleted",nil,nil]
      end

      it "should run the provisioning report" do
        @course6.destroy
        @course4.destroy
        Course.where(id: @course6.id).update_all(updated_at: 122.days.ago)
        parameters = {}
        parameters["include_deleted"] = true
        parameters["courses"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: 3})

        expect(parsed[0]).to eq [@course1.id.to_s, @course1.sis_source_id, @course1.course_code,
                                 @course1.name, @sub_account.id.to_s, @sub_account.sis_source_id,
                                 @term1.id.to_s, @term1.sis_source_id, "active",
                                 @course1.start_at.iso8601, @course1.conclude_at.iso8601, "true"]
        expect(parsed[1]).to eq [@course2.id.to_s, "SIS_COURSE_ID_2", "MAT101", "Math 101",
                                 @course2.account_id.to_s, nil, @default_term.id.to_s, nil,
                                 "active", nil, @course2.conclude_at.iso8601, "true"]
        expect(parsed[2]).to eq [@course3.id.to_s, "SIS_COURSE_ID_3", "SCI101", "Science 101",
                                 @course3.account_id.to_s, nil, @default_term.id.to_s, nil,
                                 "active", nil, nil, "true"]
        expect(parsed[3]).to eq [@course5.id.to_s, "SIS_COURSE_ID_5", "ENG101", "Sd Math 100",
                                 @sub_account.id.to_s, "sub1", @term1.id.to_s, "fall12", "deleted", nil, nil, "true"]
        expect(parsed[4]).to eq [@course4.id.to_s, nil, "self", "self help", @course4.account_id.to_s, nil,
                                 @default_term.id.to_s, nil, "deleted", nil, nil, "false"]
        expect(parsed.length).to eq 5
      end

      it "should run the sis report on a sub account" do
        parameters = {}
        parameters["courses"] = true
        # all I care about is that it didn't throw a database error due to ambiguous columns
        parsed = read_report("sis_export_csv",{params: parameters, account: @sub_account})
      end

      it "should run the provisioning report on a sub account" do
        parameters = {}
        parameters["courses"] = true
        parsed = read_report("provisioning_csv", {params: parameters, account: @sub_account, order: 3})

        expect(parsed.length).to eq 1
        expect(parsed[0]).to eq [@course1.id.to_s, @course1.sis_source_id, @course1.course_code,
                                 @course1.name, @sub_account.id.to_s, @sub_account.sis_source_id,
                                 @term1.id.to_s, @term1.sis_source_id, "active",
                                 @course1.start_at.iso8601, @course1.conclude_at.iso8601, "true"]
      end

      it "should run the sis report with the default term" do
        parameters = {}
        parameters["enrollment_term_id"] = @default_term.id
        parameters["courses"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 0})

        expect(parsed.length).to eq 2
        expect(parsed[0]).to eq ["SIS_COURSE_ID_2","MAT101","Math 101",nil,
                             nil,"active",nil,@course2.end_at.iso8601]
        expect(parsed[1]).to eq ["SIS_COURSE_ID_3","SCI101","Science 101",nil,nil,"active",nil,nil]
      end
    end

    describe "Sections" do
      before(:each) do
        create_some_courses_and_sections()
      end

      it "should run the SIS report for a term" do
        parameters = {}
        parameters["enrollment_term_id"] = @default_term.id
        parameters["sections"] = true
        parsed = read_report("sis_export_csv",{params: parameters})

        expect(parsed.length).to eq 1
        expect(parsed[0]).to eq [@section3.sis_source_id,@course2.sis_source_id,@section3.name,
                             "active",nil,@course2.conclude_at.iso8601]
      end

      it "should not include sections from deleted courses" do
        @course2.destroy
        parameters = {}
        parameters["sections"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 0})

        expect(parsed.length).to eq 2
        expect(parsed[0]).to eq [@section1.sis_source_id,@course1.sis_source_id,@section1.name,"active",
                            @course1.start_at.iso8601,@course1.conclude_at.iso8601]
        expect(parsed[1]).to eq [@section2.sis_source_id,@course1.sis_source_id,@section2.name,"active",
                             nil,@course1.conclude_at.iso8601]
      end

      it "should run the provisioning report" do
        @section1.crosslist_to_course(@course2)
        parameters = {}
        parameters["sections"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: 4})
        expect(parsed.length).to eq 4
        expect(parsed[0]).to eq [@section1.id.to_s, @section1.sis_source_id, @course1.id.to_s,
                                 @course1.sis_source_id, @section1.name, "active",
                                 @course1.start_at.iso8601, @course1.conclude_at.iso8601,
                                 @sub_account.id.to_s, "sub1", "true"]
        expect(parsed[1]).to eq [@section2.id.to_s, @section2.sis_source_id, @course1.id.to_s,
                                 @course1.sis_source_id, @section2.name, "active", nil,
                                 @course1.conclude_at.iso8601, @sub_account.id.to_s, "sub1", "true"]
        expect(parsed[2]).to eq [@section3.id.to_s, "english_section_3", @course2.id.to_s,
                                 "SIS_COURSE_ID_2", "Math_01", "active", nil,
                                 @course2.conclude_at.iso8601, @account.id.to_s, nil, "true"]
        expect(parsed[3]).to eq [@section4.id.to_s, nil, @course2.id.to_s, "SIS_COURSE_ID_2",
                                 "Math_02", "active", nil, nil, @account.id.to_s, nil, "false"]
      end

      it "should run the provisioning report with deleted sections" do
        @section1.destroy
        parameters = {}
        parameters["sections"] = true
        parameters["include_deleted"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: 4})
        expect(parsed.length).to eq 4
        expect(parsed[0]).to eq [@section1.id.to_s, @section1.sis_source_id, @course1.id.to_s,
                                 @course1.sis_source_id, @section1.name, "deleted",
                                 @course1.start_at.iso8601, @course1.conclude_at.iso8601,
                                 @sub_account.id.to_s, "sub1", "true"]
        expect(parsed[1]).to eq [@section2.id.to_s, @section2.sis_source_id, @course1.id.to_s,
                                 @course1.sis_source_id, @section2.name, "active",
                                 nil, @course1.conclude_at.iso8601, @sub_account.id.to_s, "sub1", "true"]
        expect(parsed[2]).to eq [@section3.id.to_s, "english_section_3", @course2.id.to_s,
                                 "SIS_COURSE_ID_2", "Math_01", "active", nil,
                                 @course2.conclude_at.iso8601, @account.id.to_s, nil, "true"]
        expect(parsed[3]).to eq [@section4.id.to_s, nil, @course2.id.to_s, "SIS_COURSE_ID_2",
                                 "Math_02", "active", nil, nil, @account.id.to_s, nil, "false"]
      end

      it "should run the provisioning report with deleted sections on a sub account" do
        @section2.destroy

        parameters = {}
        parameters["sections"] = true
        parameters["include_deleted"] = true
        parsed = read_report("provisioning_csv", {params: parameters, account: @sub_account, order: 4})
        expect(parsed.length).to eq 2

        expect(parsed[0]).to eq [@section1.id.to_s, @section1.sis_source_id, @course1.id.to_s,
                                 @course1.sis_source_id, @section1.name, "active",
                                 @course1.start_at.iso8601, @course1.conclude_at.iso8601,
                                 @sub_account.id.to_s, "sub1", "true"]
        expect(parsed[1]).to eq [@section2.id.to_s, @section2.sis_source_id, @course1.id.to_s,
                                 @course1.sis_source_id, @section2.name, "deleted",
                                 nil, @course1.conclude_at.iso8601, @sub_account.id.to_s, "sub1", "true"]
      end
    end

    describe "Enrollments" do
      before(:each) do
        create_some_enrolled_users()
      end

      it "should run the SIS report" do
        parameters = {}
        parameters["enrollments"] = true
        parsed = read_report("sis_export_csv",{params: parameters, order: [1,0]})
        # should ignore creation pending enrollments on sis_export
        expect(parsed.length).to eq 8

        expect(parsed[0]).to eq ["SIS_COURSE_ID_1","user_sis_id_01","observer",observer_role.id.to_s,nil,"active",nil]
        expect(parsed[1]).to eq ["SIS_COURSE_ID_2","user_sis_id_01","observer",observer_role.id.to_s,nil,
                             "active","user_sis_id_03"]
        expect(parsed[2]).to eq ["SIS_COURSE_ID_1","user_sis_id_02","ta",ta_role.id.to_s,nil,"active",nil]
        expect(parsed[3]).to eq ["SIS_COURSE_ID_3","user_sis_id_02","student",student_role.id.to_s,nil,"active",nil]
        expect(parsed[4]).to eq ["SIS_COURSE_ID_1","user_sis_id_03","student",student_role.id.to_s,nil,"active",nil]
        expect(parsed[5]).to eq ["SIS_COURSE_ID_2","user_sis_id_03","student",student_role.id.to_s,nil,"active",nil]
        expect(parsed[6]).to eq ["SIS_COURSE_ID_1","user_sis_id_04","teacher",teacher_role.id.to_s,
                             "english_section_1","active",nil]
        expect(parsed[7]).to eq ["SIS_COURSE_ID_2","user_sis_id_04","Pixel Engineer",@role.id.to_s,nil,"active",nil]
      end

      it "should run sis report for a term" do
        parameters = {}
        parameters["enrollment_term_id"] = @default_term.id
        parameters["enrollments"] = true
        parsed = read_report("sis_export_csv",{params: parameters, order: [1,0]})
        expect(parsed.length).to eq 4

        expect(parsed[0]).to eq ["SIS_COURSE_ID_2","user_sis_id_01","observer",observer_role.id.to_s,
                             nil,"active","user_sis_id_03"]
        expect(parsed[1]).to eq ["SIS_COURSE_ID_3","user_sis_id_02","student",student_role.id.to_s,nil,"active",nil]
        expect(parsed[2]).to eq ["SIS_COURSE_ID_2","user_sis_id_03","student",student_role.id.to_s,nil,"active",nil]
        expect(parsed[3]).to eq ["SIS_COURSE_ID_2","user_sis_id_04","Pixel Engineer",@role.id.to_s,nil,"active",nil]
      end

      it "should run the provisioning report with deleted enrollments" do
        c = Course.create(:name => 'course1')
        c.student_view_student
        parameters = {}
        parameters["enrollments"] = true
        parameters["include_deleted"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: [3, 1, 8]})

        expect(parsed[0]).to eq [@course1.id.to_s, "SIS_COURSE_ID_1", @user6.id.to_s, nil,
                                 "teacher", teacher_role.id.to_s, @enrollment10.course_section_id.to_s,
                                 nil, "concluded", nil, nil, "false"]
        expect(parsed[1]).to eq [@course1.id.to_s, "SIS_COURSE_ID_1", @user1.id.to_s, "user_sis_id_01",
                                 "observer", observer_role.id.to_s,
                                 @enrollment1.course_section_id.to_s, nil, "active", nil, nil, "true"]
        expect(parsed[2]).to eq [@course2.id.to_s, "SIS_COURSE_ID_2", @user1.id.to_s, "user_sis_id_01",
                                 "observer", observer_role.id.to_s,
                                 @enrollment7.course_section_id.to_s, nil, "active",
                                 @user3.id.to_s, "user_sis_id_03", "true"]
        expect(parsed[3]).to eq [@course1.id.to_s, "SIS_COURSE_ID_1", @user2.id.to_s, "user_sis_id_02",
                                 "ta", ta_role.id.to_s,
                                 @enrollment3.course_section_id.to_s, nil, "active", nil, nil, "true"]
        expect(parsed[4]).to eq [@course3.id.to_s, "SIS_COURSE_ID_3", @user2.id.to_s, "user_sis_id_02",
                                 "student", student_role.id.to_s,
                                 @enrollment2.course_section_id.to_s, nil, "active", nil, nil, "true"]
        expect(parsed[5]).to eq [@course1.id.to_s, "SIS_COURSE_ID_1", @user3.id.to_s, "user_sis_id_03",
                                 "student", student_role.id.to_s,
                                 @enrollment4.course_section_id.to_s, nil, "active", nil, nil, "true"]
        expect(parsed[6]).to eq [@course2.id.to_s, "SIS_COURSE_ID_2", @user3.id.to_s, "user_sis_id_03",
                                 "student", student_role.id.to_s,
                                 @enrollment5.course_section_id.to_s, nil, "active", nil, nil, "true"]
        expect(parsed[7]).to eq [@course1.id.to_s, "SIS_COURSE_ID_1", @user4.id.to_s, "user_sis_id_04",
                                 "teacher", teacher_role.id.to_s, @enrollment9.course_section_id.to_s,
                                 "english_section_1", "active", nil, nil, "true"]
        expect(parsed[8]).to eq [@course1.id.to_s, "SIS_COURSE_ID_1", @user4.id.to_s, "user_sis_id_04",
                                 "teacher", teacher_role.id.to_s,
                                 @enrollment6.course_section_id.to_s, nil, "deleted", nil, nil, "true"]
        expect(parsed[9]).to eq [@course2.id.to_s, "SIS_COURSE_ID_2", @user4.id.to_s, "user_sis_id_04",
                                 "Pixel Engineer", @role.id.to_s, @enrollment11.course_section_id.to_s,
                                 nil, "active", nil, nil, "true"]
        expect(parsed[10]).to eq [@course4.id.to_s, nil, @user4.id.to_s,
                                  "user_sis_id_04", "student",
                                  student_role.id.to_s,
                                  @enrollment12.course_section_id.to_s, nil,
                                  "invited", nil, nil, "false"]
        expect(parsed[11]).to eq [@course4.id.to_s, nil, @user5.id.to_s,
                                  "user_sis_id_05", "teacher", teacher_role.id.to_s,
                                  @enrollment8.course_section_id.to_s, nil, "active", nil, nil, "false"]
        expect(parsed.length).to eq 12

      end

      it "should run the provisioning report on a term and sub account with deleted enrollments" do
        @course2.account = @sub_account
        @course2.save
        parameters = {}
        parameters["enrollments"] = true
        parameters["include_deleted"] = true
        parameters["enrollment_term_id"] = @term1.id
        parsed = read_report("provisioning_csv", {params: parameters, order: [3, 1, 8]})

        expect(parsed.length).to eq 6

        expect(parsed[0]).to eq [@course1.id.to_s, "SIS_COURSE_ID_1", @user6.id.to_s, nil, "teacher",
                                 teacher_role.id.to_s, @enrollment10.course_section_id.to_s,
                                 nil, "concluded", nil, nil, "false"]
        expect(parsed[1]).to eq [@course1.id.to_s, "SIS_COURSE_ID_1", @user1.id.to_s, "user_sis_id_01",
                                 "observer", observer_role.id.to_s, @enrollment1.course_section_id.to_s,
                                 nil, "active", nil, nil, "true"]
        expect(parsed[2]).to eq [@course1.id.to_s, "SIS_COURSE_ID_1", @user2.id.to_s, "user_sis_id_02",
                                 "ta", ta_role.id.to_s, @enrollment3.course_section_id.to_s,
                                 nil, "active", nil, nil, "true"]
        expect(parsed[3]).to eq [@course1.id.to_s, "SIS_COURSE_ID_1", @user3.id.to_s, "user_sis_id_03",
                                 "student", student_role.id.to_s,
                                 @enrollment4.course_section_id.to_s, nil, "active", nil, nil, "true"]
        expect(parsed[4]).to eq [@course1.id.to_s, "SIS_COURSE_ID_1", @user4.id.to_s, "user_sis_id_04",
                                 "teacher", teacher_role.id.to_s, @enrollment9.course_section_id.to_s,
                                 "english_section_1", "active", nil, nil, "true"]
        expect(parsed[5]).to eq [@course1.id.to_s, "SIS_COURSE_ID_1", @user4.id.to_s, "user_sis_id_04",
                                 "teacher", teacher_role.id.to_s, @enrollment6.course_section_id.to_s,
                                 nil, "deleted", nil, nil, "true"]
      end
    end

    describe "Groups" do
      before(:each) do
        create_some_groups()
      end

      it "should run the SIS report" do
        parameters = {}
        parameters["enrollment_term_id"] = @default_term.id
        parameters["groups"] = true
        parsed = read_report("sis_export_csv",{params: parameters, order: 2})
        expect(parsed.length).to eq 2
        expect(parsed[0]).to eq ["group1sis",nil,"group1name","available"]
        expect(parsed[1]).to eq ["group2sis","sub1","group2name","available"]
      end

      it "should run the SIS report with deleted groups" do
        parameters = {}
        parameters["include_deleted"] = true
        parameters["groups"] = true
        parsed = read_report("sis_export_csv",{params: parameters, order: 2})
        expect(parsed.length).to eq 3
        expect(parsed[0]).to eq ["group1sis",nil,"group1name","available"]
        expect(parsed[1]).to eq ["group2sis","sub1","group2name","available"]
        expect(parsed[2]).to eq ["group4sis",nil,"group4name","deleted"]
      end

      it "should run the provisioning report" do
        parameters = {}
        parameters["groups"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: 4})
        expect(parsed.length).to eq 3
        expect(parsed[0]).to eq [@group1.id.to_s, "group1sis", @account.id.to_s,
                                 nil, "group1name", "available", "true"]
        expect(parsed[1]).to eq [@group2.id.to_s, "group2sis", @sub_account.id.to_s,
                                 "sub1", "group2name", "available", "true"]
        expect(parsed[2]).to eq [@group3.id.to_s, nil, @sub_account.id.to_s,
                                 "sub1", "group3name", "available", "false"]
      end

      it "should run the provisioning report on a sub account" do
        parameters = {}
        parameters["groups"] = true
        parsed = read_report("provisioning_csv", {params: parameters, account: @sub_account, order: 4})
        expect(parsed.length).to eq 2
        expect(parsed[0]).to eq [@group2.id.to_s, "group2sis", @sub_account.id.to_s,
                                 "sub1", "group2name", "available", "true"]
        expect(parsed[1]).to eq [@group3.id.to_s, nil, @sub_account.id.to_s,
                                 "sub1", "group3name", "available", "false"]
      end
    end

    describe "Group Memberships" do
      before(:each) do
        create_some_group_memberships_n_stuff()
      end

      it "should run the sis report" do
        parameters = {}
        parameters["enrollment_term_id"] = @default_term.id
        parameters["group_membership"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 0})
        expect(parsed.length).to eq 2
        expect(parsed[0]).to eq [@group1.sis_source_id,"user_sis_id_01","accepted"]
        expect(parsed[1]).to eq [@group2.sis_source_id,"user_sis_id_02","accepted"]
      end

      it "should run the sis report with deleted group memberships" do
        parameters = {}
        parameters["group_membership"] = true
        parameters["include_deleted"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: [0, 1]})
        expect(parsed.length).to eq 3
        expect(parsed[0]).to eq [@group1.sis_source_id,"user_sis_id_01","accepted"]
        expect(parsed[1]).to eq [@group2.sis_source_id,"user_sis_id_02","accepted"]
        expect(parsed[2]).to eq [@group2.sis_source_id,"user_sis_id_03","deleted"]
      end

      it "should run the provisioning report" do
        parameters = {}
        parameters["group_membership"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: [1, 3]})
        expect(parsed.length).to eq 3
        expect(parsed[0]).to eq [@group1.id.to_s, @group1.sis_source_id,
                                 @user1.id.to_s, "user_sis_id_01", "accepted", "true"]
        expect(parsed[1]).to eq [@group2.id.to_s, @group2.sis_source_id,
                                 @user2.id.to_s, "user_sis_id_02", "accepted", "true"]
        expect(parsed[2]).to eq [@group3.id.to_s, nil, @user3.id.to_s,
                                 "user_sis_id_03", "accepted", "false"]
      end

      it "should run the provisioning report" do
        parameters = {}
        parameters["group_membership"] = true
        parsed = read_report("provisioning_csv", {params: parameters, account: @sub_account, order: [1, 3]})
        expect(parsed.length).to eq 2
        expect(parsed[0]).to eq [@group2.id.to_s, @group2.sis_source_id,
                                 @user2.id.to_s, "user_sis_id_02", "accepted", "true"]
        expect(parsed[1]).to eq [@group3.id.to_s, nil, @user3.id.to_s,
                                 "user_sis_id_03", "accepted", "false"]
      end
    end

    describe "Cross List" do
      before(:each) do
        create_some_courses_and_sections()
        @section1.crosslist_to_course(@course2)
        @section3.crosslist_to_course(@course1)
        @section5.crosslist_to_course(@course6)
      end

      it "should run the sis report with the default term" do
        parameters = {}
        parameters["enrollment_term_id"] = @default_term.id
        parameters["xlist"] = true
        parameters["include_deleted"] = false
        report = run_report("sis_export_csv", {params: parameters})
        expect(report.parameters['extra_text']).to eq "Term: Default Term; Reports: xlist "
        parsed = parse_report(report, {header: true})
        headers = parsed.shift
        expect(headers).to eq ['xlist_course_id', 'section_id', 'status']
        expect(parsed[0]).to eq ["SIS_COURSE_ID_2","english_section_1","active"]
        expect(parsed.length).to eq 1
      end

      it "should run sis report with deleted sections" do
        @section3.destroy
        parameters = {}
        parameters["xlist"] = true
        parameters["include_deleted"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 0})
        expect(parsed[0]).to eq ["SIS_COURSE_ID_1","english_section_3","deleted"]
        expect(parsed[1]).to eq ["SIS_COURSE_ID_2","english_section_1","active"]
        expect(parsed.length).to eq 2
      end

      it "should run sis report with deleted sections on a sub account" do
        @section3.destroy
        parameters = {}
        parameters["xlist"] = true
        parameters["include_deleted"] = true
        report = run_report("sis_export_csv",{params: parameters, account: @sub_account})
        expect(report.parameters['extra_text']).to eq "Term: All Terms; Include Deleted Objects; Reports: xlist "
        parsed = parse_report(report)
        expect(parsed[0]).to eq ["SIS_COURSE_ID_1","english_section_3","deleted"]
        expect(parsed.length).to eq 1
      end

      it "should run the provisioning report" do
        parameters = {}
        parameters["xlist"] = true
        parsed = read_report("provisioning_csv",{params: parameters, order: 1})
        expect(parsed[0]).to eq [@course1.id.to_s,"SIS_COURSE_ID_1",
                             @section3.id.to_s,"english_section_3","active",
                             @course2.id.to_s, @course2.sis_source_id]
        expect(parsed[1]).to eq [@course2.id.to_s,"SIS_COURSE_ID_2",
                             @section1.id.to_s,"english_section_1","active",
                             @course1.id.to_s, @course1.sis_source_id]
        expect(parsed.length).to eq 2
      end

      it "should run the provisioning report with deleted sections" do
        parameters = {}
        parameters["include_deleted"] = true
        parameters["xlist"] = true
        parsed = read_report("provisioning_csv",{params: parameters, order: 1})
        expect(parsed[0]).to eq [@course1.id.to_s,"SIS_COURSE_ID_1",
                             @section3.id.to_s,"english_section_3","active",
                             @course2.id.to_s, @course2.sis_source_id]
        expect(parsed[1]).to eq [@course2.id.to_s,"SIS_COURSE_ID_2",
                             @section1.id.to_s,"english_section_1","active",
                             @course1.id.to_s, @course1.sis_source_id]
        expect(parsed.length).to eq 2
      end
    end

    it "should run multiple SIS Export reports" do
      create_some_users_with_pseudonyms
      create_some_accounts

      parameters = {}
      parameters["enrollment_term_id"] = @default_term.id
      parameters["accounts"] = true
      parameters["users"] = true
      parameters["courses"] = true
      parsed = read_report("sis_export_csv", {params: parameters, header: true, order: 'skip'})

      accounts_report = parsed["accounts.csv"][1..-1].sort_by { |r| r[0] }
      expect(accounts_report[0]).to eq ["sub1", nil, "English", "active"]
      expect(accounts_report[1]).to eq ["sub3", nil, "math", "active"]
      expect(accounts_report[2]).to eq ["subsub1", "sub1", "sESL", "active"]

      users_report = parsed["users.csv"][1..-1].sort_by { |r| r[0] }
      expect(users_report.length).to eq 4
      expect(users_report[0]).to eq ["user_sis_id_01", "john@stclair.com", nil,
                                     "John St.", "Clair", "John St. Clair",
                                     "Clair, John St.", nil,
                                     "john@stclair.com", "active"]
      expect(users_report[1]).to eq ["user_sis_id_02", "micheal@michaelbolton.com",
                                     nil, "Michael", "Bolton", "Michael Bolton",
                                     "Bolton, Michael", nil,
                                     "micheal@michaelbolton.com", "active"]
      expect(users_report[2]).to eq ["user_sis_id_03", "rick@roll.com", nil, "Rick",
                                     "Astley", "Rick Astley", "Astley, Rick", nil,
                                     "rick@roll.com", "active"]
      expect(users_report[3]).to eq ["user_sis_id_04", "jason@donovan.com", nil,
                                     "Jason", "Donovan", "Jason Donovan",
                                     "Donovan, Jason", nil, "jason@donovan.com",
                                     "active"]
    end

    it "should run the SIS Export reports with no data" do
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
      parsed = read_report("sis_export_csv", {params: parameters, header: true})

      expect(parsed["accounts.csv"]).to eq [["account_id", "parent_account_id", "name", "status"]]
      expect(parsed["terms.csv"]).to eq [["term_id", "name", "status", "start_date", "end_date"]]
      expect(parsed["users.csv"]).to eq [['user_id', 'login_id', 'password', 'first_name',
                                          'last_name', 'full_name', 'sortable_name',
                                          'short_name', 'email', 'status']]
      expect(parsed["courses.csv"]).to eq [["course_id", "short_name", "long_name", "account_id",
                                            "term_id", "status", "start_date", "end_date"]]
      expect(parsed["sections.csv"]).to eq [["section_id", "course_id", "name", "status",
                                             "start_date", "end_date"]]
      expect(parsed["enrollments.csv"]).to eq [["course_id", "user_id", "role", "role_id", "section_id",
                                                "status", "associated_user_id"]]
      expect(parsed["groups.csv"]).to eq [["group_id", "account_id", "name", "status"]]
      expect(parsed["group_membership.csv"]).to eq [["group_id", "user_id", "status"]]
      expect(parsed["xlist.csv"]).to eq [["xlist_course_id", "section_id", "status"]]
    end

    it "should not return reports passed as false" do
      parameters = {}
      parameters["accounts"] = 0
      parameters["users"] = 1
      parameters["terms"] = true
      parameters["courses"] = false
      parameters["sections"] = false
      parameters["enrollments"] = false
      parameters["groups"] = true
      parameters["group_membership"] = true
      parameters["xlist"] = true
      parsed = read_report("sis_export_csv", {params: parameters, header: true})

      expect(parsed["accounts.csv"]).to eq nil
      expect(parsed["terms.csv"]).to eq [["term_id", "name", "status", "start_date", "end_date"]]
      expect(parsed["users.csv"]).to eq [['user_id', 'login_id', 'password', 'first_name',
                                          'last_name', 'full_name', 'sortable_name',
                                          'short_name', 'email', 'status']]
      expect(parsed["courses.csv"]).to eq nil
      expect(parsed["sections.csv"]).to eq nil
      expect(parsed["enrollments.csv"]).to eq nil
      expect(parsed["groups.csv"]).to eq [["group_id", "account_id", "name", "status"]]
      expect(parsed["group_membership.csv"]).to eq [["group_id", "user_id", "status"]]
      expect(parsed["xlist.csv"]).to eq [["xlist_course_id", "section_id", "status"]]
    end
  end
end
