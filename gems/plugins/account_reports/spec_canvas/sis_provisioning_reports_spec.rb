#
# Copyright (C) 2012 - present Instructure, Inc.
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

  def create_some_users_with_pseudonyms
    sis = @account.sis_batches.create
    @user1 = user_with_pseudonym(:active_all => true, :account => @account, :name => "John St. Clair",
                                 :sortable_name => "St. Clair,John", :username => 'john@stclair.com')
    @user.pseudonym.sis_user_id = "user_sis_id_01"
    @user.pseudonym.sis_batch_id = sis.id
    @user.pseudonym.save!
    @user2 = user_with_pseudonym(:active_all => true, :username => 'micheal@michaelbolton.com',
                                 :name => 'Michael Bolton', :account => @account)
    @user.pseudonym.sis_user_id = "user_sis_id_02"
    @user.pseudonym.sis_batch_id = sis.id
    @user.pseudonym.save!
    @user3 = user_with_pseudonym(:active_all => true, :account => @account, :name => "Rick Astley",
                                 :sortable_name => "Astley,Rick", :username => 'rick@roll.com')
    @user.pseudonym.sis_user_id = "user_sis_id_03"
    @user.pseudonym.sis_batch_id = sis.id
    @user.pseudonym.save!
    @user4 = user_with_pseudonym(:active_all => true, :username => 'jason@donovan.com',
                                 :name => 'Jason Donovan', :account => @account)
    @user.pseudonym.sis_user_id = "user_sis_id_04"
    @user.pseudonym.save!
    @user5 = user_with_pseudonym(:name => 'James Brown', :account => @account)
    @user.pseudonym.sis_user_id = "user_sis_id_05"
    @user.pseudonym.sis_batch_id = sis.id
    @user.pseudonym.save!
    @user5.destroy
    @user6 = user_with_pseudonym(:active_all => true, :username => 'john@smith.com',
                                 :name => 'John Smith', :sortable_name => "Smith,John",
                                 :account => @account)
    @user7 = user_with_pseudonym(:active_all => true, :username => 'jony@apple.com',
                                 :name => 'Jony Ive', :account => @account)
    @user8 = user_with_pseudonym(:active_all => true, :username => 'steve@apple.com',
                                 :name => 'Steve Jobs', :account => @account)
    @user8.destroy
  end

  def create_an_account
    @sis = @account.sis_batches.create
    @sub_account = Account.create(:parent_account => @account, :name => 'English')
    @sub_account.sis_source_id = 'sub1'
    @sub_account.sis_batch_id = @sis.id
    @sub_account.save!
  end

  def create_some_accounts
    create_an_account
    @sub_sub_account = Account.create(:parent_account => @sub_account, :name => 'sESL')
    @sub_sub_account.sis_source_id = 'subsub1'
    @sub_sub_account.sis_batch_id = @sis.id
    @sub_sub_account.save!
    @sub_account3 = Account.create(:parent_account => @account, :name => 'math')
    @sub_account3.sis_source_id = 'sub3'
    @sub_account3.sis_batch_id = @sis.id
    @sub_account3.save!
    @sub_account4 = Account.create(:parent_account => @account, :name => 'deleted sis account')
    @sub_account4.sis_source_id = 'sub4'
    @sub_account4.sis_batch_id = @sis.id
    @sub_account4.save!
    @sub_account4.destroy
    @sub_account5 = Account.create(:parent_account => @account, :name => 'other')
    @sub_account6 = Account.create(:parent_account => @account, :name => 'the deleted account')
    @sub_account6.destroy
  end

  def create_a_term
    @sis = @account.sis_batches.create
    @term1 = EnrollmentTerm.create(:name => 'Fall', :start_at => 6.months.ago,
                                   :end_at => 1.year.from_now)
    @term1.root_account = @account
    @term1.sis_source_id = 'fall12'
    @term1.sis_batch_id = @sis.id
    @term1.save!
  end

  def create_some_group_categories
    create_some_courses
    @group_category1 = GroupCategory.create(
      name: 'Test Group Category',
      account: @account,
    )
    @group_category2 = GroupCategory.create(
      name: 'Test Group Category2',
      account: @account,
    )
    @group_category1.save!
    @group_category2.auto_leader = 'first'
    @group_category2.group_limit = 2
    @group_category2.save!
    @group_category3 = GroupCategory.create(
      name: 'Test Group Category Deleted',
      course: @course3,
    )
    @group_category4 = GroupCategory.create(
      name: 'Test Group Category Course',
      course: @course3,
    )
    @account.group_categories << @group_category1
    @account.group_categories << @group_category2
    @account.group_categories << @group_category3
    @course3.group_categories << @group_category4
    @group_category3.destroy
    @account.save!
  end

  def create_some_terms
    create_a_term
    @term2 = EnrollmentTerm.create(:name => 'Winter', :start_at => 3.weeks.ago,
                                   :end_at => 2.years.from_now)
    @term2.root_account = @account
    @term2.sis_source_id = 'winter13'
    @term2.sis_batch_id = @sis.id
    @term2.save!
    @term2.destroy
    @term3 = EnrollmentTerm.create(:name => 'Spring', :start_at => 1.week.ago,
                                   :end_at => 6.months.from_now)
    @term3.root_account = @account
    @term3.save!
  end

  def create_some_courses
    create_an_account
    create_a_term
    start_at = 1.day.ago
    end_at = 3.months.from_now
    @course1 = Course.new(:name => 'English 101', :course_code => 'ENG101',
                          :start_at => start_at, :conclude_at => end_at)
    @course1.account_id = @sub_account.id
    @course1.enrollment_term_id = @term1.id
    @course1.workflow_state = 'available'
    @course1.sis_source_id = "SIS_COURSE_ID_1"
    @course1.restrict_enrollments_to_course_dates = true
    @course1.sis_batch_id = @sis.id
    @course1.course_format = 'on_campus'
    @course1.save!

    @course2 = Course.new(:name => 'Math 101', :course_code => 'MAT101',
                          :conclude_at => end_at, :account => @account)
    @course2.workflow_state = 'available'
    @course2.sis_source_id = "SIS_COURSE_ID_2"
    @course2.restrict_enrollments_to_course_dates = true
    @course2.sis_batch_id = @sis.id
    @course2.course_format = 'online'
    @course2.save!

    @course3 = Course.new(:name => 'Science 101', :course_code => 'SCI101',
                          :account => @account)
    @course3.workflow_state = 'available'
    @course3.sis_source_id = "SIS_COURSE_ID_3"
    @course3.sis_batch_id = @sis.id
    @course3.save!

    @course4 = Course.new(:name => 'self help', :course_code => 'self',
                          :account => @account)
    @course4.workflow_state = 'claimed'
    @course4.save!

    @course5 = Course.new(:name => 'Sd Math 100', :course_code => 'ENG101',
                          :start_at => start_at, :conclude_at => end_at)
    @course5.account_id = @sub_account.id
    @course5.enrollment_term_id = @term1.id
    @course5.sis_source_id = "SIS_COURSE_ID_5"
    @course5.workflow_state = 'deleted'
    @course5.sis_batch_id = @sis.id
    @course5.save!

    @course6 = Course.new(:name => 'talking 101', :course_code => 'Tal101',
                          :account => @account)
    @course6.workflow_state = 'completed'
    @course6.save!
  end

  def create_some_courses_and_sections
    create_some_courses

    @section1 = CourseSection.new(:name => 'English_01', :course => @course1,
                                  :start_at => @course1.start_at, :end_at => @course1.conclude_at)
    @section1.sis_source_id = 'english_section_1'
    @section1.restrict_enrollments_to_section_dates = true
    @section1.sis_batch_id = @sis.id
    @section1.save!

    @section2 = CourseSection.new(:name => 'English_02', :course => @course1,
                                  :end_at => @course1.conclude_at)
    @section2.sis_source_id = 'english_section_2'
    @section2.root_account_id = @account.id
    @section2.restrict_enrollments_to_section_dates = true
    @section2.sis_batch_id = @sis.id
    @section2.save!

    @section3 = CourseSection.new(:name => 'Math_01', :course => @course2,
                                  :end_at => @course2.conclude_at)
    @section3.sis_source_id = 'english_section_3'
    @section3.root_account_id = @account.id
    @section3.restrict_enrollments_to_section_dates = true
    @section3.sis_batch_id = @sis.id
    @section3.save!

    @section4 = CourseSection.new(:name => 'Math_02', :course => @course2)
    @section4.root_account_id = @account.id
    @section4.save!

    @section5 = CourseSection.new(:name => 'Science_01', :course => @course3)
    @section5.root_account_id = @account.id
    @section5.save!
    @section5.destroy
  end

  def create_some_enrolled_users
    create_some_courses_and_sections
    create_some_users_with_pseudonyms

    @role = @account.roles.build :name => 'Pixel Engineer'
    @role.base_role_type = 'DesignerEnrollment'
    @role.save!

    @enrollment1 = create_enrollment(@course1, @user1, sis_batch_id: @sis.id, enrollment_type: 'ObserverEnrollment')
    @enrollment2 = create_enrollment(@course3, @user2, sis_batch_id: @sis.id)
    @enrollment3 = create_enrollment(@course1, @user2, sis_batch_id: @sis.id, enrollment_type: 'TaEnrollment')
    @enrollment4 = create_enrollment(@course1, @user3, sis_batch_id: @sis.id)
    @enrollment5 = create_enrollment(@course2, @user3, sis_batch_id: @sis.id)
    @enrollment6 = create_enrollment(@course1, @user4, sis_batch_id: @sis.id, enrollment_type: 'TeacherEnrollment',
                                     enrollment_state: 'deleted')
    @enrollment7 = create_enrollment(@course2, @user1, sis_batch_id: @sis.id, enrollment_type: 'ObserverEnrollment',
                                     associated_user_id: @user3.id)
    @enrollment8 = create_enrollment(@course4, @user5, enrollment_type: 'TeacherEnrollment')
    @enrollment9 = create_enrollment(@course1, @user4, sis_batch_id: @sis.id, enrollment_type: 'TeacherEnrollment',
                                     section: @section1)
    @enrollment10 = create_enrollment(@course1, @user6, enrollment_type: 'TeacherEnrollment',
                                      enrollment_state: 'completed')
    @enrollment11 = create_enrollment(@course2, @user4, sis_batch_id: @sis.id, enrollment_type: 'DesignerEnrollment',
                                      role: @role)
    @enrollment12 = create_enrollment(@course4, @user4, enrollment_state: 'creation_pending')
  end

  def create_some_groups
    create_some_group_categories
    @group1 = @account.groups.create(:name => 'group1name')
    @group1.group_category = @group_category1
    @group1.sis_source_id = 'group1sis'
    @group1.sis_batch_id = @sis.id
    @group1.save!
    @group2 = @sub_account.groups.create(:name => 'group2name')
    @group2.sis_source_id = 'group2sis'
    @group2.group_category = @group_category2
    @group2.sis_batch_id = @sis.id
    @group2.save!
    @group3 = @sub_account.groups.create(:name => 'group3name')
    @group3.save!
    @group4 = @account.groups.create(:name => 'group4name')
    @group4.sis_source_id = 'group4sis'
    @group4.sis_batch_id = @sis.id
    @group4.save!
    @group4.destroy
    @group5 = @course1.groups.create(:name => 'group5name')
    @group5.sis_source_id = 'group5sis'
    @group5.sis_batch_id = @sis.id
    @group5.save!
  end

  def create_some_group_memberships_n_stuff
    create_some_users_with_pseudonyms
    create_some_groups
    batch = @group1.root_account.sis_batches.create!
    @gm1 = GroupMembership.create(:group => @group1, :user => @user1, :workflow_state => "accepted")
    @gm1.sis_batch_id = batch.id
    @gm1.save!
    @gm2 = GroupMembership.create(:group => @group2, :user => @user2, :workflow_state => "accepted")
    @gm2.sis_batch_id = batch.id
    @gm2.save!
    @gm3 = GroupMembership.create(:group => @group3, :user => @user3, :workflow_state => "accepted")
    @gm3.save!
    @gm4 = GroupMembership.create(:group => @group2, :user => @user3, :workflow_state => "accepted")
    @gm4.sis_batch_id = batch.id
    @gm4.save!
    @gm4.destroy
  end

  describe "SIS export and Provisioning reports" do
    before(:once) do
      Notification.where(name: "Report Generated").first_or_create
      Notification.where(name: "Report Generation Failed").first_or_create
      @account = Account.create(name: 'New Account', default_time_zone: 'UTC')
      @admin = account_admin_user(account: @account, name: 'default admin')
      @default_term = @account.default_enrollment_term
    end

    describe "Users" do
      before(:once) do
        create_some_users_with_pseudonyms
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
        expect(headers).to eq ['user_id', 'integration_id', 'authentication_provider_id',
                               'login_id', 'password', 'first_name', 'last_name',
                               'full_name', 'sortable_name', 'short_name', 'email',
                               'status']
        expect(parsed.length).to eq 4

        expect(parsed).to match_array [["user_sis_id_01", nil, nil, "john@stclair.com",
                                        nil, "John St.", "Clair", "John St. Clair",
                                        "Clair, John St.", nil,
                                        "john@stclair.com", "active"],
                                       ["user_sis_id_02", nil, nil, "micheal@michaelbolton.com",
                                        nil, "Michael", "Bolton", "Michael Bolton",
                                        "Bolton, Michael", nil,
                                        "micheal@michaelbolton.com", "active"],
                                       ["user_sis_id_03", nil, nil, "rick@roll.com",
                                        nil, "Rick", "Astley", "Rick Astley", "Astley, Rick",
                                        nil, "rick@roll.com", "active"],
                                       ["user_sis_id_05", nil, nil, "nobody@example.com",
                                        nil, "James", "Brown", "James Brown",
                                        "Brown, James", nil, nil, "deleted"]]
      end

      it "should run sis report" do
        parameters = {}
        parameters["users"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 0})
        expect(parsed.length).to eq 4

        expect(parsed).to match_array [["user_sis_id_01", nil, nil, "john@stclair.com",
                                        nil, "John St.", "Clair", "John St. Clair",
                                        "Clair, John St.", nil,
                                        "john@stclair.com", "active"],
                                       ["user_sis_id_02", nil, nil,
                                        "micheal@michaelbolton.com", nil, "Michael",
                                        "Bolton", "Michael Bolton", "Bolton, Michael",
                                        nil, "micheal@michaelbolton.com", "active"],
                                       ["user_sis_id_03", nil, nil, "rick@roll.com",
                                        nil, "Rick", "Astley", "Rick Astley", "Astley, Rick",
                                        nil, "rick@roll.com", "active"],
                                       ["user_sis_id_04", nil, nil, "jason@donovan.com",
                                        nil, "Jason", "Donovan", "Jason Donovan",
                                        "Donovan, Jason", nil, "jason@donovan.com",
                                        "active"]]
      end

      it "should run sis report on a sub_acocunt" do
        create_an_account
        @course1 = Course.new(:name => 'English 101', :course_code => 'ENG101')
        @course1.account_id = @sub_account.id
        @course1.workflow_state = 'available'
        @course1.save!
        @enrollment1 = @course1.enroll_user(@user1, 'StudentEnrollment', :enrollment_state => :active)

        parameters = {}
        parameters["users"] = true
        parsed = read_report("sis_export_csv", {params: parameters, account: @sub_account})
        expect(parsed.length).to eq 1

        expect(parsed).to match_array [["user_sis_id_01", nil, nil, "john@stclair.com",
                                        nil, "John St.", "Clair", "John St. Clair",
                                        "Clair, John St.", nil,
                                        "john@stclair.com", "active"]]
      end

      it "should run provisioning report" do
        parameters = {}
        parameters["users"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: [1, 2], header: true})

        headers = parsed.shift
        expect(headers).to eq ["canvas_user_id", "user_id", "integration_id",
                               "authentication_provider_id", "login_id",
                               "first_name", "last_name", "full_name",
                               "sortable_name", "short_name", "email", "status",
                               "created_by_sis"]
        expect(parsed.length).to eq 6

        expect(parsed).to match_array [[@user6.id.to_s, nil, nil, nil, "john@smith.com",
                                        "John", "Smith", "John Smith", "Smith, John",
                                        nil, "john@smith.com", "active", "false"],
                                       [@user7.id.to_s, nil, nil, nil, "jony@apple.com",
                                        "Jony", "Ive", "Jony Ive", "Ive, Jony", nil,
                                        "jony@apple.com", "active", "false"],
                                       [@user1.id.to_s, "user_sis_id_01", nil, nil,
                                        "john@stclair.com", "John St.", "Clair",
                                        "John St. Clair", "Clair, John St.", nil,
                                        "john@stclair.com", "active", "true"],
                                       [@user2.id.to_s, "user_sis_id_02", nil, nil,
                                        "micheal@michaelbolton.com", "Michael",
                                        "Bolton", "Michael Bolton", "Bolton, Michael",
                                        nil, "micheal@michaelbolton.com", "active", "true"],
                                       [@user3.id.to_s, "user_sis_id_03", nil, nil,
                                        "rick@roll.com", "Rick", "Astley",
                                        "Rick Astley", "Astley, Rick", nil,
                                        "rick@roll.com", "active", "true"],
                                       [@user4.id.to_s, "user_sis_id_04", nil, nil,
                                        "jason@donovan.com", "Jason", "Donovan",
                                        "Jason Donovan", "Donovan, Jason", nil,
                                        "jason@donovan.com", "active", "false"]]
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

        expect(parsed).to match_array [[@user1.id.to_s, "user_sis_id_01", nil, nil,
                                        "john@stclair.com", "John St.", "Clair",
                                        "John St. Clair", "Clair, John St.", nil,
                                        "john@stclair.com", "active", "true"],
                                       [@user2.id.to_s, "user_sis_id_02", nil, nil,
                                        "micheal@michaelbolton.com", "Michael",
                                        "Bolton", "Michael Bolton", "Bolton, Michael",
                                        nil, "micheal@michaelbolton.com", "active", "true"],
                                       [@user3.id.to_s, "user_sis_id_03", nil, nil,
                                        "rick@roll.com", "Rick", "Astley",
                                        "Rick Astley", "Astley, Rick", nil,
                                        "rick@roll.com", "active", "true"],
                                       [@user5.id.to_s, "user_sis_id_05", nil, nil,
                                        "nobody@example.com", "James", "Brown",
                                        "James Brown", "Brown, James", nil, nil,
                                        "deleted", "true"]]
      end
    end

    describe "Accounts" do
      before(:once) do
        create_some_accounts
      end

      it "should run the SIS report" do
        parameters = {}
        parameters["enrollment_term"] = @default_term.id
        parameters["accounts"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 0})

        expect(parsed.length).to eq 3
        expect(parsed).to match_array [["sub1", nil, "English", "active"],
                                       ["sub3", nil, "math", "active"],
                                       ["subsub1", "sub1", "sESL", "active"]]
      end

      it "should run the SIS report on a sub account" do
        parameters = {}
        parameters["accounts"] = true
        parsed = read_report("sis_export_csv", {params: parameters, account: @sub_account})

        expect(parsed.length).to eq 1
        expect(parsed).to match_array [["subsub1", "sub1", "sESL", "active"]]
      end

      it "should run the SIS report including deleted accounts" do
        parameters = {}
        parameters["accounts"] = true
        parameters["include_deleted"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 0})

        expect(parsed.length).to eq 4
        expect(parsed).to match_array [["sub1", nil, "English", "active"],
                                       ["sub3", nil, "math", "active"],
                                       ["sub4", nil, "deleted sis account", "deleted"],
                                       ["subsub1", "sub1", "sESL", "active"]]
      end

      it "should run the provisioning report including deleted accounts" do
        parameters = {}
        parameters["accounts"] = true
        parameters["enrollment_term"] = ''
        parameters["include_deleted"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: 4})

        expect(parsed.length).to eq 5
        expect(parsed).to match_array [[@sub_account.id.to_s, "sub1", @account.id.to_s,
                                        nil, "English", "active", "true"],
                                       [@sub_account4.id.to_s, "sub4", @account.id.to_s,
                                        nil, "deleted sis account", "deleted", "true"],
                                       [@sub_account3.id.to_s, "sub3", @account.id.to_s,
                                        nil, "math", "active", "true"],
                                       [@sub_account5.id.to_s, nil, @account.id.to_s, nil,
                                        "other", "active", "false"],
                                       [@sub_sub_account.id.to_s, "subsub1",
                                        @sub_account.id.to_s, "sub1", "sESL", "active", "true"]]
      end
    end

    describe "Terms" do
      before(:once) do
        create_some_terms
      end

      it "should run the SIS report" do
        parameters = {}
        parameters["enrollment_term"] = @term3.id
        parameters["include_deleted"] = true
        parameters["terms"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 0})

        expect(parsed.length).to eq 2
        expect(parsed).to match_array [["fall12", "Fall", "active", @term1.start_at.iso8601,
                                        @term1.end_at.iso8601],
                                       ["winter13", "Winter", "deleted", @term2.start_at.iso8601,
                                        @term2.end_at.iso8601]]
      end

      it "should run the provisioning report" do
        parameters = {}
        parameters["terms"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: 2})

        expect(parsed.length).to eq 3
        expect(parsed).to match_array [[@default_term.id.to_s, nil, "Default Term", "active", nil, nil, "false"],
                                       [@term1.id.to_s, "fall12", "Fall", "active",
                                        @term1.start_at.iso8601, @term1.end_at.iso8601, "true"],
                                       [@term3.id.to_s, nil, "Spring", "active",
                                        @term3.start_at.iso8601, @term3.end_at.iso8601, "false"]]
      end

      it "should run the provisioning report with deleted terms" do
        parameters = {}
        parameters["terms"] = true
        parameters["include_deleted"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: 2})

        expect(parsed.length).to eq 4
        expect(parsed).to match_array [[@default_term.id.to_s, nil, "Default Term", "active", nil, nil, "false"],
                                       [@term1.id.to_s, "fall12", "Fall", "active",
                                        @term1.start_at.iso8601, @term1.end_at.iso8601, "true"],
                                       [@term3.id.to_s, nil, "Spring", "active",
                                        @term3.start_at.iso8601, @term3.end_at.iso8601, "false"],
                                       [@term2.id.to_s, "winter13", "Winter", "deleted",
                                        @term2.start_at.iso8601, @term2.end_at.iso8601, "true"]]
      end
    end

    describe "Courses" do
      before(:once) do
        create_some_courses
      end

      it "should run the SIS report" do
        parameters = {}
        parameters["enrollment_term"] = ''
        parameters["courses"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 0})

        expect(parsed.length).to eq 3
        expect(parsed).to match_array [[@course1.sis_source_id, nil, @course1.course_code, @course1.name,
                                        @sub_account.sis_source_id, @term1.sis_source_id, "active",
                                        @course1.start_at.iso8601, @course1.end_at.iso8601, @course1.course_format],
                                       ["SIS_COURSE_ID_2", nil, "MAT101", "Math 101", nil, nil,
                                        "active", nil, @course2.end_at.iso8601, @course2.course_format],
                                       ["SIS_COURSE_ID_3", nil, "SCI101", "Science 101", nil, nil, "active", nil, nil, nil]]
      end

      it "should run the SIS report with sis term and deleted courses" do
        @course1.complete
        parameters = {}
        parameters["enrollment_term_id"] = "sis_term_id:fall12"
        parameters["include_deleted"] = true
        parameters["courses"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 0})

        expect(parsed.length).to eq 2
        expect(parsed).to match_array [[@course1.sis_source_id, nil, @course1.course_code, @course1.name,
                                        @sub_account.sis_source_id, @term1.sis_source_id, "completed",
                                        @course1.start_at.iso8601, @course1.conclude_at.iso8601, @course1.course_format],
                                       ["SIS_COURSE_ID_5", nil, "ENG101", "Sd Math 100", "sub1",
                                        "fall12", "deleted", nil, nil, nil]]
      end

      it "should run the provisioning report" do
        @course6.destroy
        @course4.destroy
        Course.where(id: @course6.id).update_all(updated_at: 122.days.ago)
        parameters = {}
        parameters["include_deleted"] = true
        parameters["courses"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: 3})

        expect(parsed).to match_array [[@course5.id.to_s, @course5.sis_source_id, nil,
                                        @course5.course_code, @course5.name,
                                        @sub_account.id.to_s, "sub1", @term1.id.to_s,
                                        "fall12", "deleted", nil, nil, nil, "true"],
                                       [@course1.id.to_s, "SIS_COURSE_ID_1", nil, "ENG101",
                                        "English 101", @course1.account_id.to_s,
                                        @sub_account.sis_source_id, @term1.id.to_s,
                                        @term1.sis_source_id, "active",
                                        @course1.start_at.iso8601,
                                        @course1.conclude_at.iso8601, @course1.course_format, "true"],
                                       [@course2.id.to_s, "SIS_COURSE_ID_2", nil, "MAT101",
                                        "Math 101", @course2.account_id.to_s, nil,
                                        @default_term.id.to_s, nil, "active", nil,
                                        @course2.conclude_at.iso8601, @course2.course_format, "true"],
                                       [@course3.id.to_s, "SIS_COURSE_ID_3", nil, "SCI101",
                                        "Science 101", @course3.account_id.to_s, nil,
                                        @default_term.id.to_s, nil, "active", nil, nil, nil,
                                        "true"],
                                       [@course4.id.to_s, nil, nil, "self", "self help",
                                        @course4.account_id.to_s, nil, @default_term.id.to_s,
                                        nil, "deleted", nil, nil, nil, "false"]]
        expect(parsed.length).to eq 5
      end

      it "should run the sis report on a sub account" do
        parameters = {}
        parameters["courses"] = true
        # all I care about is that it didn't throw a database error due to ambiguous columns
        expect {
          read_report("sis_export_csv", {params: parameters, account: @sub_account})
        }.not_to raise_error
      end

      it "should run the provisioning report on a sub account" do
        parameters = {}
        parameters["courses"] = true
        parsed = read_report("provisioning_csv", {params: parameters, account: @sub_account, order: 3})

        expect(parsed.length).to eq 1
        expect(parsed).to match_array [[@course1.id.to_s, @course1.sis_source_id, nil,
                                        @course1.course_code, @course1.name,
                                        @sub_account.id.to_s, @sub_account.sis_source_id,
                                        @term1.id.to_s, @term1.sis_source_id, "active",
                                        @course1.start_at.iso8601,
                                        @course1.conclude_at.iso8601, @course1.course_format, "true"]]
      end

      it "should run the sis report with the default term" do
        parameters = {}
        parameters["enrollment_term_id"] = @default_term.id
        parameters["courses"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 0})

        expect(parsed.length).to eq 2
        expect(parsed).to match_array [["SIS_COURSE_ID_2", nil, "MAT101", "Math 101", nil,
                                        nil, "active", nil, @course2.end_at.iso8601, @course2.course_format],
                                       ["SIS_COURSE_ID_3", nil, "SCI101", "Science 101", nil, nil, "active", nil, nil, nil]]
      end
    end


    describe "Sections" do
      before(:once) do
        create_some_courses_and_sections
      end

      it "should run the SIS report for a term" do
        parameters = {}
        parameters["enrollment_term_id"] = @default_term.id
        parameters["sections"] = true
        parsed = read_report("sis_export_csv", {params: parameters})

        expect(parsed.length).to eq 1
        expect(parsed).to match_array [[@section3.sis_source_id, @course2.sis_source_id,
                                        nil, @section3.name, "active", nil,
                                        @course2.conclude_at.iso8601]]
      end

      it "should not include sections from deleted courses" do
        @course2.destroy
        parameters = {}
        parameters["sections"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 0})

        expect(parsed.length).to eq 2
        expect(parsed).to match_array [[@section1.sis_source_id, @course1.sis_source_id,
                                        nil, @section1.name, "active",
                                        @course1.start_at.iso8601,
                                        @course1.conclude_at.iso8601],
                                       [@section2.sis_source_id, @course1.sis_source_id,
                                        nil, @section2.name, "active", nil,
                                        @course1.conclude_at.iso8601]]
      end

      it "should run the provisioning report" do
        @section1.crosslist_to_course(@course2)
        parameters = {}
        parameters["sections"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: 4})
        expect(parsed.length).to eq 4
        expect(parsed).to match_array [[@section1.id.to_s, @section1.sis_source_id,
                                        @course1.id.to_s, @course1.sis_source_id, nil,
                                        @section1.name, "active",
                                        @course1.start_at.iso8601,
                                        @course1.conclude_at.iso8601, @sub_account.id.to_s,
                                        "sub1", "true"],
                                       [@section4.id.to_s, nil, @course2.id.to_s,
                                        @course2.sis_source_id, nil, @section4.name,
                                        "active", nil, nil, @account.id.to_s, nil,
                                        "false"],
                                       [@section3.id.to_s, @section3.sis_source_id,
                                        @course2.id.to_s, "SIS_COURSE_ID_2", nil,
                                        "Math_01", "active", nil,
                                        @course2.conclude_at.iso8601,
                                        @account.id.to_s, nil, "true"],
                                       [@section2.id.to_s, @section2.sis_source_id,
                                        @course1.id.to_s, "SIS_COURSE_ID_1", nil,
                                        "English_02", "active", nil,
                                        @course2.conclude_at.iso8601,
                                        @sub_account.id.to_s, "sub1", "true"]]
      end

      it "should run the provisioning report with deleted sections" do
        @section1.destroy
        parameters = {}
        parameters["sections"] = true
        parameters["include_deleted"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: 4})
        expect(parsed.length).to eq 4
        expect(parsed).to match_array [[@section4.id.to_s, nil, @course2.id.to_s,
                                        "SIS_COURSE_ID_2", nil, "Math_02", "active",
                                        nil, nil, @account.id.to_s, nil, "false"],
                                       [@section3.id.to_s, @section3.sis_source_id,
                                        @course2.id.to_s, "SIS_COURSE_ID_2", nil,
                                        "Math_01", "active", nil,
                                        @course2.conclude_at.iso8601, @account.id.to_s,
                                        nil, "true"],
                                       [@section2.id.to_s, @section2.sis_source_id,
                                        @course1.id.to_s, @course1.sis_source_id, nil,
                                        @section2.name, "active", nil,
                                        @course1.conclude_at.iso8601,
                                        @sub_account.id.to_s, "sub1", "true"],
                                       [@section1.id.to_s, @section1.sis_source_id,
                                        @course1.id.to_s, @course1.sis_source_id, nil,
                                        @section1.name, "deleted",
                                        @course1.start_at.iso8601,
                                        @course1.conclude_at.iso8601,
                                        @sub_account.id.to_s, "sub1", "true"]]
      end

      it "should run the provisioning report with deleted sections on a sub account" do
        @section2.destroy

        parameters = {}
        parameters["sections"] = true
        parameters["include_deleted"] = true
        parsed = read_report("provisioning_csv", {params: parameters, account: @sub_account, order: 4})
        expect(parsed.length).to eq 2

        expect(parsed).to match_array [[@section2.id.to_s, @section2.sis_source_id,
                                        @course1.id.to_s, @course1.sis_source_id, nil,
                                        @section2.name, "deleted", nil,
                                        @course1.conclude_at.iso8601,
                                        @sub_account.id.to_s, "sub1", "true"],
                                       [
                                         @section1.id.to_s, @section1.sis_source_id,
                                         @course1.id.to_s, @course1.sis_source_id, nil,
                                         @section1.name, "active",
                                         @course1.start_at.iso8601,
                                         @course1.conclude_at.iso8601,
                                         @sub_account.id.to_s, "sub1", "true"]]
      end
    end

    describe "Enrollments" do
      before(:once) do
        create_some_enrolled_users
      end

      it "should run the SIS report" do
        parameters = {}
        parameters["enrollments"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: [1, 0]})
        # should ignore creation pending enrollments on sis_export
        expect(parsed.length).to eq 8

        expect(parsed).to match_array [["SIS_COURSE_ID_1", "user_sis_id_01", "observer",
                                        observer_role.id.to_s, nil, "active", nil,
                                        "false"],
                                       ["SIS_COURSE_ID_2", "user_sis_id_01", "observer",
                                        observer_role.id.to_s, nil,
                                        "active", "user_sis_id_03", "false"],
                                       ["SIS_COURSE_ID_1", "user_sis_id_02", "ta",
                                        ta_role.id.to_s, nil, "active", nil,
                                        "false"],
                                       ["SIS_COURSE_ID_3", "user_sis_id_02", "student",
                                        student_role.id.to_s, nil, "active", nil,
                                        "false"],
                                       ["SIS_COURSE_ID_1", "user_sis_id_03", "student",
                                        student_role.id.to_s, nil, "active", nil,
                                        "false"],
                                       ["SIS_COURSE_ID_2", "user_sis_id_03", "student",
                                        student_role.id.to_s, nil, "active", nil,
                                        "false"],
                                       ["SIS_COURSE_ID_1", "user_sis_id_04", "teacher",
                                        teacher_role.id.to_s,
                                        "english_section_1", "active", nil, "false"],
                                       ["SIS_COURSE_ID_2", "user_sis_id_04", "Pixel Engineer",
                                        @role.id.to_s, nil, "active", nil, "false"]]
      end

      it "should run sis report for a term" do
        parameters = {}
        parameters["enrollment_term_id"] = @default_term.id
        parameters["enrollments"] = true
        # this extra pseudonym should not cause an extra row in the output
        @user2.pseudonyms.create!(unique_id: "pseudonym2@instructure.com")
        parsed = read_report("sis_export_csv", {params: parameters, order: [1, 0]})
        expect(parsed.length).to eq 4

        expect(parsed).to match_array [["SIS_COURSE_ID_2", "user_sis_id_01", "observer",
                                        observer_role.id.to_s, nil, "active",
                                        "user_sis_id_03", "false"],
                                       ["SIS_COURSE_ID_3", "user_sis_id_02", "student",
                                        student_role.id.to_s, nil, "active", nil,
                                        "false"],
                                       ["SIS_COURSE_ID_2", "user_sis_id_03", "student",
                                        student_role.id.to_s, nil, "active", nil,
                                        "false"],
                                       ["SIS_COURSE_ID_2", "user_sis_id_04", "Pixel Engineer",
                                        @role.id.to_s, nil, "active", nil, "false"]]
      end

      it "should run the provisioning report with deleted enrollments" do
        c = Course.create(:name => 'course1')
        c.student_view_student
        Course.where(id: @course2.id).update_all(workflow_state: 'deleted')
        parameters = {}
        parameters["enrollments"] = true
        parameters["include_deleted"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: "skip"})
        expect(parsed).to match_array [[@course1.id.to_s, "SIS_COURSE_ID_1", @user6.id.to_s, nil,
                                        "teacher", teacher_role.id.to_s, @enrollment10.course_section_id.to_s,
                                        nil, "concluded", nil, nil, "false", 'TeacherEnrollment', 'false',
                                        @enrollment10.id.to_s],
                                       [@course1.id.to_s, "SIS_COURSE_ID_1", @user1.id.to_s, "user_sis_id_01",
                                        "observer", observer_role.id.to_s,
                                        @enrollment1.course_section_id.to_s, nil, "active", nil, nil, "true",
                                        'ObserverEnrollment', 'false', @enrollment1.id.to_s],
                                       [@course2.id.to_s, "SIS_COURSE_ID_2", @user1.id.to_s, "user_sis_id_01",
                                        "observer", observer_role.id.to_s,
                                        @enrollment7.course_section_id.to_s, nil, "deleted",
                                        @user3.id.to_s, "user_sis_id_03", "true", 'ObserverEnrollment', 'false',
                                        @enrollment7.id.to_s],
                                       [@course1.id.to_s, "SIS_COURSE_ID_1", @user2.id.to_s, "user_sis_id_02",
                                        "ta", ta_role.id.to_s,
                                        @enrollment3.course_section_id.to_s, nil, "active", nil, nil, "true",
                                        'TaEnrollment', 'false', @enrollment3.id.to_s],
                                       [@course3.id.to_s, "SIS_COURSE_ID_3", @user2.id.to_s, "user_sis_id_02",
                                        "student", student_role.id.to_s,
                                        @enrollment2.course_section_id.to_s, nil, "active", nil, nil, "true",
                                        'StudentEnrollment', 'false', @enrollment2.id.to_s],
                                       [@course1.id.to_s, "SIS_COURSE_ID_1", @user3.id.to_s, "user_sis_id_03",
                                        "student", student_role.id.to_s,
                                        @enrollment4.course_section_id.to_s, nil, "active", nil, nil, "true",
                                        'StudentEnrollment', 'false', @enrollment4.id.to_s],
                                       [@course2.id.to_s, "SIS_COURSE_ID_2", @user3.id.to_s, "user_sis_id_03",
                                        "student", student_role.id.to_s,
                                        @enrollment5.course_section_id.to_s, nil, "deleted", nil, nil, "true",
                                        'StudentEnrollment', 'false', @enrollment5.id.to_s],
                                       [@course1.id.to_s, "SIS_COURSE_ID_1", @user4.id.to_s, "user_sis_id_04",
                                        "teacher", teacher_role.id.to_s, @enrollment9.course_section_id.to_s,
                                        "english_section_1", "active", nil, nil, "true",
                                        'TeacherEnrollment', 'false', @enrollment9.id.to_s],
                                       [@course1.id.to_s, "SIS_COURSE_ID_1", @user4.id.to_s, "user_sis_id_04",
                                        "teacher", teacher_role.id.to_s,
                                        @enrollment6.course_section_id.to_s, nil, "deleted", nil, nil, "true",
                                        'TeacherEnrollment', 'false', @enrollment6.id.to_s],
                                       [@course2.id.to_s, "SIS_COURSE_ID_2", @user4.id.to_s, "user_sis_id_04",
                                        "Pixel Engineer", @role.id.to_s, @enrollment11.course_section_id.to_s,
                                        nil, "deleted", nil, nil, "true", 'DesignerEnrollment', 'false',
                                        @enrollment11.id.to_s],
                                       [@course4.id.to_s, nil, @user4.id.to_s,
                                        "user_sis_id_04", "student",
                                        student_role.id.to_s,
                                        @enrollment12.course_section_id.to_s, nil,
                                        "invited", nil, nil, "false", 'StudentEnrollment', 'false', @enrollment12.id.to_s],
                                       [@course4.id.to_s, nil, @user5.id.to_s,
                                        "user_sis_id_05", "teacher", teacher_role.id.to_s,
                                        @enrollment8.course_section_id.to_s, nil, "active", nil, nil, "false",
                                        'TeacherEnrollment', 'false', @enrollment8.id.to_s]]
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

        expect(parsed).to match_array [[@course1.id.to_s, "SIS_COURSE_ID_1", @user6.id.to_s, nil, "teacher",
                                        teacher_role.id.to_s, @enrollment10.course_section_id.to_s,
                                        nil, "concluded", nil, nil, "false", 'TeacherEnrollment', 'false',
                                        @enrollment10.id.to_s],
                                       [@course1.id.to_s, "SIS_COURSE_ID_1", @user1.id.to_s, "user_sis_id_01",
                                        "observer", observer_role.id.to_s, @enrollment1.course_section_id.to_s,
                                        nil, "active", nil, nil, "true", 'ObserverEnrollment', 'false',
                                        @enrollment1.id.to_s],
                                       [@course1.id.to_s, "SIS_COURSE_ID_1", @user2.id.to_s, "user_sis_id_02",
                                        "ta", ta_role.id.to_s, @enrollment3.course_section_id.to_s,
                                        nil, "active", nil, nil, "true", 'TaEnrollment', 'false',
                                        @enrollment3.id.to_s],
                                       [@course1.id.to_s, "SIS_COURSE_ID_1", @user3.id.to_s, "user_sis_id_03",
                                        "student", student_role.id.to_s,
                                        @enrollment4.course_section_id.to_s, nil, "active", nil, nil, "true",
                                        'StudentEnrollment', 'false', @enrollment4.id.to_s],
                                       [@course1.id.to_s, "SIS_COURSE_ID_1", @user4.id.to_s, "user_sis_id_04",
                                        "teacher", teacher_role.id.to_s, @enrollment9.course_section_id.to_s,
                                        "english_section_1", "active", nil, nil, "true", 'TeacherEnrollment',
                                        'false', @enrollment9.id.to_s],
                                       [@course1.id.to_s, "SIS_COURSE_ID_1", @user4.id.to_s, "user_sis_id_04",
                                        "teacher", teacher_role.id.to_s, @enrollment6.course_section_id.to_s,
                                        nil, "deleted", nil, nil, "true", 'TeacherEnrollment', 'false',
                                        @enrollment6.id.to_s]]
      end

      it 'should handle cross listed enrollments' do
        sub = @account.sub_accounts.create!
        course = sub.courses.create!(name: 'the course', sis_source_id: 'sis1')
        @section1.crosslist_to_course(course)
        parsed = read_report("provisioning_csv", {params: {'enrollments' => true}, account: sub, order: 0})
        expect(parsed).to eq [[course.id.to_s, "sis1", @user4.id.to_s, "user_sis_id_04",
                               "teacher", teacher_role.id.to_s, @enrollment9.course_section_id.to_s,
                               "english_section_1", "active", nil, nil, "true", 'TeacherEnrollment',
                               'false', @enrollment9.id.to_s]]
      end

      describe "sharding" do
        specs_require_sharding

        it "should run with cross shard pseudonyms" do
          @shard1.activate do
            @root = Account.create
            @user1 = user_with_managed_pseudonym(active_all: true, account: @root, name: 'Jimmy John',
                                                username: 'other_shard@example.com', sis_user_id: 'other_shard')
            @user2 = user_with_managed_pseudonym(active_all: true, account: @root, name: 'James John',
                                                 username: 'other_shar2d@example.com', sis_user_id: 'other_shard2')
          end
          allow_any_instantiation_of(@account).to receive(:trusted_account_ids).and_return([@account.id, @root.id])
          allow_any_instantiation_of(@account).to receive(:trust_exists?).and_return(true)
          @e1 = @course1.enroll_user(@user1)
          @course1.enroll_user(@user2)

          parameters = {}
          parameters["enrollments"] = true
          parsed = read_report("provisioning_csv", {params: parameters, order: [3, 1, 8]})
          expect(parsed.length).to eq 11

          expect(parsed[0]).to eq [@course1.id.to_s, "SIS_COURSE_ID_1", @user1.id.to_s,
                                   'other_shard', "student", student_role.id.to_s,
                                   @course1.enrollments.where(user_id: @user1).take.course_section_id.to_s,
                                   nil, "invited", nil, nil, "false", 'StudentEnrollment',
                                   "false", @e1.id.to_s, HostUrl.context_host(@root)]
        end
      end
    end

    describe "Groups" do
      before(:once) do
        create_some_groups
      end

      it "should run the SIS report" do
        GroupCategory.where(id: @group_category1).update_all(sis_source_id: 'gc101', sis_batch_id: @sis.id)
        GroupCategory.where(id: @group_category2).update_all(sis_source_id: 'gc102', sis_batch_id: @sis.id)
        parameters = {}
        parameters["enrollment_term_id"] = @default_term.id
        parameters["groups"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 2})
        expect(parsed.length).to eq 3
        expect(parsed).to match_array [["group1sis", "gc101", nil, nil, "group1name", "available"],
                                       ["group2sis", "gc102", "sub1", nil, "group2name", "available"],
                                       ["group5sis", nil, nil, "SIS_COURSE_ID_1", "group5name", "available"]]
      end

      it "should run the SIS report with deleted groups" do
        parameters = {}
        parameters["include_deleted"] = true
        parameters["groups"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 2})
        expect(parsed.length).to eq 4
        expect(parsed).to match_array [["group1sis", nil, nil, nil, "group1name", "available"],
                                       ["group2sis", nil, "sub1", nil, "group2name", "available"],
                                       ["group4sis", nil, nil, nil, "group4name", "deleted",],
                                       ["group5sis", nil, nil, "SIS_COURSE_ID_1", "group5name", "available"]]
      end

      it "should run the provisioning report" do
        parameters = {}
        parameters["groups"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: 4})
        expect(parsed.length).to eq 4
        expect(parsed).to match_array [[@group1.id.to_s, "group1sis", @group1.group_category_id.to_s, nil,
                                        @account.id.to_s, nil, nil, nil, "group1name", "available", "true",
                                        @account.id.to_s, 'Account', @group1.group_category.id.to_s, nil],
                                       [@group2.id.to_s, "group2sis", @group2.group_category_id.to_s, nil,
                                        @sub_account.id.to_s, "sub1", nil, nil, "group2name", "available",
                                        "true", @sub_account.id.to_s, 'Account', @group2.group_category.id.to_s, "2"],
                                       [@group3.id.to_s, nil, nil, nil, @sub_account.id.to_s, "sub1", nil,
                                        nil, "group3name", "available", "false", @sub_account.id.to_s,
                                        'Account', nil, nil],
                                       [@group5.id.to_s, "group5sis", @group5.group_category_id.to_s, nil,
                                        nil, nil,
                                        @course1.id.to_s, "SIS_COURSE_ID_1", "group5name", "available", "true",
                                        @course1.id.to_s, 'Course', @group5.group_category.id.to_s, nil]]
      end

      it "should run the provisioning report on a sub account" do
        parameters = {}
        parameters["groups"] = true
        parsed = read_report("provisioning_csv", {params: parameters, account: @sub_account, order: 4})
        expect(parsed.length).to eq 3
        expect(parsed).to match_array [[@group2.id.to_s, "group2sis", @group2.group_category_id.to_s, nil,
                                        @sub_account.id.to_s, "sub1", nil, nil, "group2name", "available",
                                        "true", @sub_account.id.to_s, 'Account', @group2.group_category.id.to_s, "2"],
                                       [@group3.id.to_s, nil, nil, nil, @sub_account.id.to_s, "sub1", nil,
                                        nil, "group3name", "available", "false", @sub_account.id.to_s, 'Account', nil,
                                        nil],
                                       [@group5.id.to_s, "group5sis", @group5.group_category_id.to_s, nil,
                                        nil, nil, @course1.id.to_s, "SIS_COURSE_ID_1", "group5name", "available",
                                        "true", @course1.id.to_s, 'Course', @group5.group_category.id.to_s, nil]]
      end

      it "includes sub-sub-account groups when run on a sub account" do
        sub_sub_account = Account.create(:parent_account => @sub_account, :name => 'sESL')
        group6 = sub_sub_account.groups.create!(:name => 'group6name')
        parameters = {}
        parameters["groups"] = true
        parsed = read_report("provisioning_csv", {params: parameters, account: @sub_account, order: 4})
        expect(parsed.length).to eq 4
        expect(parsed).to match_array [[@group2.id.to_s, "group2sis", @group2.group_category_id.to_s, nil,
                                        @sub_account.id.to_s, "sub1", nil, nil, "group2name", "available", "true",
                                        @sub_account.id.to_s, 'Account', @group2.group_category.id.to_s, "2"],
                                       [@group3.id.to_s, nil, nil, nil, @sub_account.id.to_s, "sub1", nil, nil,
                                        "group3name", "available", "false", @sub_account.id.to_s, 'Account', nil, nil],
                                       [@group5.id.to_s, "group5sis", @group5.group_category_id.to_s, nil, nil, nil,
                                        @course1.id.to_s, "SIS_COURSE_ID_1", "group5name", "available", "true",
                                        @course1.id.to_s, 'Course', @group5.group_category.id.to_s, nil],
                                       [group6.id.to_s, nil, nil, nil, sub_sub_account.id.to_s, nil, nil, nil,
                                        "group6name", "available", "false", sub_sub_account.id.to_s, 'Account', nil,
                                        nil]]
      end
    end

    describe "Group Categories" do
      before(:once) do
        create_some_groups
        @student_category = GroupCategory.where(name: "Student Groups").first
      end

      it 'should run the provisioning report' do
        parameters = {}
        parameters["group_categories"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: 5})
        expect(parsed.length).to eq 4
        expect(parsed).to match_array [[@group_category1.id.to_s, @group_category1.sis_source_id, @account.id.to_s, "Account", "Test Group Category", nil, nil, nil, nil, 'active'],
                                       [@group_category2.id.to_s, @group_category2.sis_source_id, @account.id.to_s, "Account", "Test Group Category2", nil, nil, "2", "first", 'active'],
                                       [@group_category4.id.to_s, nil, @course3.id.to_s, "Course", "Test Group Category Course", nil, nil, nil, nil, 'active'],
                                       [@student_category.id.to_s, nil, @course1.id.to_s, "Course", "Student Groups", "student_organized", nil, nil, nil, 'active']]
      end

      it 'should run the sis report' do
        GroupCategory.where(id: @group_category1).update_all(sis_source_id: 'gc101', sis_batch_id: @sis.id)
        GroupCategory.where(id: @group_category2).update_all(sis_source_id: 'gc102', sis_batch_id: @sis.id)
        GroupCategory.where(id: @group_category4).update_all(sis_source_id: 'gc104', sis_batch_id: @sis.id)
        parameters = {}
        parameters["group_categories"] = true
        parsed = read_report("sis_export_csv", {params: parameters, header: true, order: 4})
        expect(parsed.length).to eq 4
        expect(parsed).to match_array [["group_category_id", "account_id", "course_id", "category_name", "status"],
                                       ['gc101', @account.sis_source_id, nil, "Test Group Category", 'active'],
                                       ['gc102', @account.sis_source_id, nil, "Test Group Category2", 'active'],
                                       ['gc104', nil, "SIS_COURSE_ID_3", "Test Group Category Course", 'active']]
      end

      it 'should run the provisioning report for a sub account' do
        parameters = {}
        parameters["group_categories"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: 4, account: @sub_account})
        expect(parsed.length).to eq 1
        expect(parsed).to match_array [[@student_category.id.to_s, nil, @course1.id.to_s, "Course", "Student Groups", "student_organized", nil, nil, nil, 'active']]
      end

      it 'should run the report for deleted categories' do
        parameters = {}
        parameters["group_categories"] = true
        parameters["include_deleted"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: 5})
        expect(parsed.length).to eq 5
        expect(parsed).to match_array [[@group_category1.id.to_s, @group_category1.sis_source_id, @account.id.to_s, "Account", "Test Group Category", nil, nil, nil, nil, 'active'],
                                       [@group_category2.id.to_s, @group_category2.sis_source_id, @account.id.to_s, "Account", "Test Group Category2", nil, nil, "2", "first", 'active'],
                                       [@group_category3.id.to_s, @group_category3.sis_source_id, @account.id.to_s, "Account", "Test Group Category Deleted", nil, nil, nil, nil, 'deleted'],
                                       [@group_category4.id.to_s, nil, @course3.id.to_s, "Course", "Test Group Category Course", nil, nil, nil, nil, 'active'],
                                       [@student_category.id.to_s, nil, @course1.id.to_s, "Course", "Student Groups", "student_organized", nil, nil, nil, 'active']]
      end

      it "should include account_id column even if there isn't one for any rows" do
        process_csv_data_cleanly(
          "course_id,short_name,long_name,status",
          "C1,COUR,SIS Import Course,active"
        )
        process_csv_data_cleanly(
          "group_category_id,course_id,category_name,status",
          "GC1,C1,Some Group Category,active"
        )
        parameters = {}
        parameters['group_categories'] = true
        parsed = read_report("sis_export_csv", {params: parameters, header: true, order: 0})
        expect(parsed).to match_array [['group_category_id', 'account_id', 'course_id', 'category_name', 'status'],
                                       ['GC1', nil, 'C1', 'Some Group Category', 'active']]
      end
    end

    describe "Group Memberships" do
      before(:once) do
        create_some_group_memberships_n_stuff
      end

      it "should run the sis report" do
        parameters = {}
        parameters["enrollment_term_id"] = @default_term.id
        parameters["group_membership"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 0})
        expect(parsed.length).to eq 2
        expect(parsed).to match_array [[@group1.sis_source_id, "user_sis_id_01", "accepted"],
                                       [@group2.sis_source_id, "user_sis_id_02", "accepted"]]
      end

      it "should run the sis report with deleted group memberships" do
        parameters = {}
        parameters["group_membership"] = true
        parameters["include_deleted"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: [0, 1]})
        expect(parsed.length).to eq 3
        expect(parsed).to match_array [[@group1.sis_source_id, "user_sis_id_01", "accepted"],
                                       [@group2.sis_source_id, "user_sis_id_02", "accepted"],
                                       [@group2.sis_source_id, "user_sis_id_03", "deleted"]]
      end

      it "should run the provisioning report" do
        parameters = {}
        parameters["group_membership"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: "skip"})
        expect(parsed).to match_array([
                                        [@group1.id.to_s, @group1.sis_source_id,
                                         @user1.id.to_s, "user_sis_id_01", "accepted", "true"],
                                        [@group2.id.to_s, @group2.sis_source_id,
                                         @user2.id.to_s, "user_sis_id_02", "accepted", "true"],
                                        [@group3.id.to_s, nil, @user3.id.to_s,
                                         "user_sis_id_03", "accepted", "false"]
                                      ])
      end

      it "should run the provisioning report for a subaccount" do
        @gm5 = GroupMembership.create(:group => @group5, :user => @user3, :workflow_state => "accepted")
        parameters = {}
        parameters["group_membership"] = true
        parsed = read_report("provisioning_csv", {params: parameters, account: @sub_account, order: [1, 3]})
        expect(parsed.length).to eq 3
        expect(parsed).to match_array [[@group3.id.to_s, nil, @user3.id.to_s,
                                        "user_sis_id_03", "accepted", "false"],
                                       [@group2.id.to_s, @group2.sis_source_id,
                                        @user2.id.to_s, "user_sis_id_02", "accepted", "true"],
                                       [@group5.id.to_s, @group5.sis_source_id,
                                        @user3.id.to_s, "user_sis_id_03", "accepted", "false"]]
      end
    end

    describe "Cross List" do
      before(:once) do
        create_some_courses_and_sections
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
        expect(parsed).to match_array [["SIS_COURSE_ID_2", "english_section_1",
                                        "active"]]
        expect(parsed.length).to eq 1
      end

      it "should run sis report with deleted sections" do
        @section3.destroy
        parameters = {}
        parameters["xlist"] = true
        parameters["include_deleted"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 0})
        expect(parsed).to match_array [["SIS_COURSE_ID_1", "english_section_3",
                                        "deleted"],
                                       ["SIS_COURSE_ID_2", "english_section_1",
                                        "active"]]
        expect(parsed.length).to eq 2
      end

      it "should run sis report with deleted sections on a sub account" do
        @section3.destroy
        parameters = {}
        parameters["xlist"] = true
        parameters["include_deleted"] = true
        report = run_report("sis_export_csv", {params: parameters, account: @sub_account})
        expect(report.parameters['extra_text']).to eq "Term: All Terms; Include Deleted Objects; Reports: xlist "
        parsed = parse_report(report)
        expect(parsed).to match_array [["SIS_COURSE_ID_1", "english_section_3",
                                        "deleted"]]
        expect(parsed.length).to eq 1
      end

      it "should run the provisioning report" do
        parameters = {}
        parameters["xlist"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: 1})
        expect(parsed).to match_array [[@course1.id.to_s, "SIS_COURSE_ID_1",
                                        @section3.id.to_s, "english_section_3", "active",
                                        @course2.id.to_s, @course2.sis_source_id],
                                       [@course2.id.to_s, "SIS_COURSE_ID_2",
                                        @section1.id.to_s, "english_section_1", "active",
                                        @course1.id.to_s, @course1.sis_source_id]]
        expect(parsed.length).to eq 2
      end

      it "should run the provisioning report with deleted sections" do
        parameters = {}
        parameters["include_deleted"] = true
        parameters["xlist"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: 1})
        expect(parsed).to match_array [[@course1.id.to_s, "SIS_COURSE_ID_1",
                                        @section3.id.to_s, "english_section_3", "active",
                                        @course2.id.to_s, @course2.sis_source_id],
                                       [@course2.id.to_s, "SIS_COURSE_ID_2",
                                        @section1.id.to_s, "english_section_1", "active",
                                        @course1.id.to_s, @course1.sis_source_id]]
        expect(parsed.length).to eq 2
      end
    end

    describe "user_observers" do
      before(:once) do
        create_an_account
        create_some_users_with_pseudonyms
        @uo1 = UserObservationLink.create_or_restore(student: @user1, observer: @user2, root_account: @account)
        uo2 = UserObservationLink.create_or_restore(student: @user3, observer: @user4, root_account: @account)
        UserObservationLink.create_or_restore(student: @user6, observer: @user7, root_account: @account)
        UserObservationLink.where(id: [@uo1.id, uo2.id]).update_all(sis_batch_id: @sis.id)
      end

      it 'should run user_observer provisioning report' do
        parameters = {}
        parameters["user_observers"] = true
        parsed = read_report("provisioning_csv", {params: parameters, order: 0, header: true})
        expect(parsed).to match_array [['canvas_observer_id', 'observer_id', 'canvas_student_id',
                                        'student_id', 'status', 'created_by_sis'],
                                       [@user2.id.to_s, "user_sis_id_02",
                                        @user1.id.to_s, "user_sis_id_01", "active", 'true'],
                                       [@user4.id.to_s, "user_sis_id_04",
                                        @user3.id.to_s, "user_sis_id_03", "active", 'true'],
                                       [@user7.id.to_s, nil,
                                        @user6.id.to_s, nil, "active", 'false']]
        expect(parsed.length).to eq 4
      end

      it 'should run user_observer sis_export report' do
        parameters = {}
        parameters["user_observers"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 0, header: true})
        expect(parsed).to match_array [['observer_id', 'student_id', 'status'],
                                      ["user_sis_id_02", "user_sis_id_01", "active"],
                                      ["user_sis_id_04", "user_sis_id_03", "active"]]
        expect(parsed.length).to eq 3
      end

      it 'should exclude deleted observers by default' do
        @uo1.destroy
        parameters = {}
        parameters["user_observers"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 0})
        expect(parsed).to match_array [["user_sis_id_04", "user_sis_id_03", "active"]]
        expect(parsed.length).to eq 1
      end

      it 'should include deleted observers by when param is present' do
        @uo1.destroy
        parameters = {}
        parameters["user_observers"] = true
        parameters["include_deleted"] = true
        parsed = read_report("sis_export_csv", {params: parameters, order: 0})
        expect(parsed).to match_array [["user_sis_id_02", "user_sis_id_01", "deleted"],
                                       ["user_sis_id_04", "user_sis_id_03", "active"]]
        expect(parsed.length).to eq 2
      end

      it 'should not include unassociated observers when running from a sub-account' do
        parameters = {}
        parameters["user_observers"] = true
        parsed = read_report("sis_export_csv", {account: @sub_account, params: parameters, order: 0, header: true})
        expect(parsed).to match_array [['observer_id', 'student_id', 'status']]
      end

      it "should include associated observers when running from a sub-account" do
        course_with_student(:account => @sub_account, :user => @user1)
        parameters = {}
        parameters["user_observers"] = true
        parsed = read_report("sis_export_csv", {account: @sub_account, params: parameters, order: 0, header: true})
        expect(parsed).to match_array [['observer_id', 'student_id', 'status'],
          ["user_sis_id_02", "user_sis_id_01", "active"]]
      end
    end

    describe 'admins' do
      before(:once) do
        create_an_account
        @u1 = user_with_managed_pseudonym(account: @account, sis_user_id: 'U001', name: 'user 1')
        @u2 = user_with_managed_pseudonym(account: @account, sis_user_id: 'U002', name: 'user 2')
        @admin2 = @sub_account.account_users.create(user: @u1)
        @admin2.sis_batch_id=@sis.id
        @admin2.save!
        @role1 = custom_account_role('role1', account: @account)
        @admin3 = @account.account_users.create(user: @u2, role: @role1)
        @admin3.sis_batch_id=@sis.id
        @admin3.save!
      end

      it 'should run sis' do
        parameters = {}
        parameters['admins'] = true
        parameters['include_deleted'] = true
        parsed = read_report('sis_export_csv', {params: parameters, order: 3, header: true})
        expect(parsed).to match_array [['user_id', 'account_id', 'role_id', 'role', 'status'],
                                       ['U001', 'sub1', admin_role.id.to_s, 'AccountAdmin', 'active'],
                                       ['U002', nil, @role1.id.to_s, 'role1', 'active']]
      end

      it 'should run provisioning' do
        parameters = {}
        parameters['admins'] = true
        parameters['include_deleted'] = true
        @admin.pseudonyms.create!(account: @account, unique_id: 'deleted').destroy
        parsed = read_report('provisioning_csv', {params: parameters, order: [1, 5], header: true})
        expect(parsed).to match_array [['admin_user_name', 'canvas_user_id', 'user_id', 'canvas_account_id',
                                        'account_id', 'role_id', 'role', 'status', 'created_by_sis'],
                                       ['user 1', @u1.id.to_s, 'U001', @sub_account.id.to_s, 'sub1',
                                        admin_role.id.to_s, 'AccountAdmin', 'active', 'true'],
                                       ['user 2', @u2.id.to_s, 'U002', @account.id.to_s, nil,
                                        @role1.id.to_s, 'role1', 'active', 'true'],
                                       ['default admin', @admin.id.to_s, nil, @account.id.to_s, nil,
                                        admin_role.id.to_s, 'AccountAdmin', 'active', 'false']]
      end

      describe 'sharding' do
        specs_require_sharding

        it 'should run with cross shard pseudonyms' do
          @shard1.activate do
            @root = Account.create
            @user = user_with_managed_pseudonym(active_all: true, account: @root, name: 'Jimmy John',
                                                username: 'other_shard@example.com', sis_user_id: 'other_shard')
          end
          allow(@account).to receive(:trusted_account_ids).and_return([@account.id, @root.id])
          allow(@account).to receive(:trust_exists?).and_return(true)
          @admin4 = @account.account_users.create(user: @user)
          @admin4.sis_batch_id=@sis.id
          @admin4.save!

          parameters = {}
          parameters['admins'] = true
          parsed = read_report('sis_export_csv', {params: parameters, order: [3, 0], header: true})

          expect(parsed).to match_array [['user_id', 'account_id', 'role_id', 'role', 'status', 'root_account'],
                                         ['U001', 'sub1', admin_role.id.to_s, 'AccountAdmin',
                                          'active', HostUrl.context_host(@account)],
                                         ['U002', nil, @role1.id.to_s, 'role1',
                                          'active', HostUrl.context_host(@account)],
                                         ['other_shard', nil, admin_role.id.to_s, 'AccountAdmin',
                                          'active', HostUrl.context_host(@root)]]
        end
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

      accounts_report = parsed["accounts.csv"][1..-1].sort_by {|r| r[0]}
      expect(accounts_report[0]).to eq ["sub1", nil, "English", "active"]
      expect(accounts_report[1]).to eq ["sub3", nil, "math", "active"]
      expect(accounts_report[2]).to eq ["subsub1", "sub1", "sESL", "active"]

      users_report = parsed["users.csv"][1..-1].sort_by {|r| r[0]}
      expect(users_report.length).to eq 4
      expect(users_report[0]).to eq ["user_sis_id_01", nil, nil,
                                     "john@stclair.com", nil, "John St.",
                                     "Clair", "John St. Clair", "Clair, John St.",
                                     nil, "john@stclair.com", "active"]
      expect(users_report[1]).to eq ["user_sis_id_02", nil, nil,
                                     "micheal@michaelbolton.com", nil, "Michael",
                                     "Bolton", "Michael Bolton", "Bolton, Michael",
                                     nil, "micheal@michaelbolton.com", "active"]
      expect(users_report[2]).to eq ["user_sis_id_03", nil, nil, "rick@roll.com",
                                     nil, "Rick", "Astley", "Rick Astley",
                                     "Astley, Rick", nil, "rick@roll.com",
                                     "active"]
      expect(users_report[3]).to eq ["user_sis_id_04", nil, nil,
                                     "jason@donovan.com", nil, "Jason", "Donovan",
                                     "Jason Donovan", "Donovan, Jason", nil,
                                     "jason@donovan.com", "active"]
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
      parameters["group_categories"] = true
      parameters["group_membership"] = true
      parameters["xlist"] = true
      parsed = read_report("sis_export_csv", {params: parameters, header: true})

      expect(parsed["accounts.csv"]).to eq [["account_id", "parent_account_id", "name", "status"]]
      expect(parsed["terms.csv"]).to eq [["term_id", "name", "status", "start_date", "end_date"]]
      expect(parsed["users.csv"]).to eq [['user_id', 'integration_id', 'authentication_provider_id',
                                          'login_id', 'password', 'first_name', 'last_name',
                                          'full_name', 'sortable_name', 'short_name', 'email', 'status']]
      expect(parsed["courses.csv"]).to eq [["course_id", "integration_id", "short_name", "long_name",
                                            "account_id", "term_id", "status", "start_date", "end_date", "course_format"]]
      expect(parsed["sections.csv"]).to eq [["section_id", "course_id", "integration_id", "name", "status",
                                             "start_date", "end_date"]]
      expect(parsed["enrollments.csv"]).to eq [["course_id", "user_id", "role", "role_id", "section_id",
                                                "status", "associated_user_id",
                                                "limit_section_privileges"]]
      expect(parsed["groups.csv"]).to eq [["group_id", "group_category_id", "account_id", "course_id", "name", "status"]]
      expect(parsed["group_categories.csv"]).to eq [["group_category_id", "account_id", "course_id", "category_name", "status"]]
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
      expect(parsed["users.csv"]).to eq [['user_id', 'integration_id', 'authentication_provider_id',
                                          'login_id', 'password', 'first_name', 'last_name',
                                          'full_name', 'sortable_name', 'short_name', 'email', 'status']]
      expect(parsed["courses.csv"]).to eq nil
      expect(parsed["sections.csv"]).to eq nil
      expect(parsed["enrollments.csv"]).to eq nil
      expect(parsed["groups.csv"]).to eq [["group_id", "group_category_id", "account_id", "course_id", "name", "status"]]
      expect(parsed["group_membership.csv"]).to eq [["group_id", "user_id", "status"]]
      expect(parsed["xlist.csv"]).to eq [["xlist_course_id", "section_id", "status"]]
    end
  end
end
