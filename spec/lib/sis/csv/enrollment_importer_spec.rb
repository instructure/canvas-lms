#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe SIS::CSV::EnrollmentImporter do

  before { account_model }

  it 'should skip bad content' do
    course_model(:account => @account, :sis_source_id => 'C001')
    @course.course_sections.create.update_attribute(:sis_source_id, '1B')
    user_with_managed_pseudonym(:account => @account, :sis_user_id => 'U001')
    before_count = Enrollment.count
    importer = process_csv_data(
      "course_id,user_id,role,section_id,status",
      ",U001,student,,active",
      "C001,,student,1B,active",
      "C001,U001,cheater,1B,active",
      "C001,U001,student,1B,semi-active"
    )
    expect(Enrollment.count).to eq before_count

    expect(importer.errors).to eq []
    warnings = importer.warnings.map { |r| r.last }
    # since accounts can define course roles, the "cheater" row can't be
    # rejected immediately on parse like the others; that's why the warning
    # comes out of order with the source data
    expect(warnings).to eq ["No course_id or section_id given for an enrollment",
                      "No user_id given for an enrollment",
                      "Improper status \"semi-active\" for an enrollment",
                      "Improper role \"cheater\" for an enrollment"]
  end

  it 'should warn about inconsistent data' do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C001,TC 101,Test Course 101,,,active",
      "C002,TC 102,Test Course 102,,,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "1B,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "U001,user1,User,Uno,user@example.com,active"
    )
    importer = process_csv_data(
      "course_id,user_id,role,section_id,status",
      "NONEXISTENT,U001,student,1B,active",
      "C001,U001,student,NONEXISTENT,active",
      "C002,U001,student,1B,active")
    warnings = importer.warnings.map { |r| r.last }
    expect(warnings).to eq ["An enrollment referenced a non-existent course NONEXISTENT",
                        "An enrollment referenced a non-existent section NONEXISTENT",
                        "An enrollment listed a section and a course that are unrelated"]
    expect(importer.errors).to eq []
  end

  it "should not fail for really long course names" do
    #create course, users, and sections
    process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user@example.com,active"
    )
    name = '0123456789' * 25
    process_csv_data_cleanly(
        "section_id,course_id,name,status,start_date,end_date",
        "S001,test_1,#{name},active,,"
    )
    # the enrollments
    process_csv_data_cleanly(
        "course_id,user_id,role,section_id,status,associated_user_id,start_date,end_date",
        "test_1,user_1,teacher,S001,active,,,"
    )
  end

  it "should enroll users" do
    #create course, users, and sections
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,active",
      "user_2,user2,User,Dos,user2@example.com,active",
      "user_3,user4,User,Tres,user3@example.com,active",
      "user_5,user5,User,Quatro,user5@example.com,active",
      "user_6,user6,User,Cinco,user6@example.com,active",
      "user_7,user7,User,Siete,user7@example.com,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,status,start_date,end_date",
      "S001,test_1,Sec1,active,,"
    )
    # the enrollments
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id,start_date,end_date",
      "test_1,user_1,teacher,,active,,,",
      ",user_2,student,S001,active,,,",
      "test_1,user_3,ta,S001,active,,,",
      "test_1,user_5,observer,S001,active,user_2,,",
      "test_1,user_6,designer,S001,active,,,",
      "test_1,user_7,teacher,S001,active,,1985-08-24,2011-08-29"
    )
    course = @account.courses.where(sis_source_id: "test_1").first
    expect(course.teachers.map(&:name)).to be_include("User Uno")
    expect(course.students.first.name).to eq "User Dos"
    expect(course.tas.first.name).to eq "User Tres"
    expect(course.observers.first.name).to eq "User Quatro"
    expect(course.observer_enrollments.first.associated_user_id).to eq course.students.first.id
    expect(course.designers.first.name).to eq "User Cinco"
    siete = course.teacher_enrollments.detect { |e| e.user.name == "User Siete" }
    expect(siete).not_to be_nil
    expect(siete.start_at).to eq DateTime.new(1985, 8, 24)
    expect(siete.end_at).to eq DateTime.new(2011, 8, 29)
  end

  it "should support sis stickiness" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,status,start_date,end_date",
      "S001,test_1,Sec1,active,,"
    )
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id,start_date,end_date",
      "test_1,user_1,teacher,,active,,1985-08-24,2011-08-29"
    )
    course = @account.courses.where(sis_source_id: "test_1").first
    course.teacher_enrollments.first.tap do |e|
      expect(e.start_at).to eq DateTime.parse("1985-08-24")
      expect(e.end_at).to eq DateTime.parse("2011-08-29")
      e.start_at = DateTime.parse("1985-05-24")
      e.end_at = DateTime.parse("2011-05-29")
      e.save!
    end
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id,start_date,end_date",
      "test_1,user_1,teacher,,active,,1985-08-24,2011-08-29"
    )
    course.reload
    course.teacher_enrollments.first.tap do |e|
      expect(e.start_at).to eq DateTime.parse("1985-05-24")
      expect(e.end_at).to eq DateTime.parse("2011-05-29")
    end
  end

  it "should not try looking up a section to enroll into if the section name is empty" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active",
      "test_2,TC 102,Test Course 102,,,active"
    )
    bad_course = @account.courses.where(sis_source_id: "test_1").first
    expect(bad_course.course_sections.length).to eq 0
    good_course = @account.courses.where(sis_source_id: "test_2").first
    expect(good_course.course_sections.length).to eq 0
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,active"
    )
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_2,user_1,teacher,,active,"
    )
    expect(good_course.teachers.first.name).to eq "User Uno"
  end

  it "should properly handle repeated courses and sections" do
    #create course, users, and sections
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active",
      "test_2,TC 102,Test Course 102,,,active"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,active",
      "user_2,user2,User,Dos,user2@example.com,active",
      "user_3,user3,User,Tres,user3@example.com,active",
      "user_4,user4,User,Cuatro,user4@example.com,active",
      "user_5,user5,User,Cinco,user5@example.com,active",
      "user_6,user6,User,Seis,user6@example.com,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,status,start_date,end_date",
      "S101,test_1,Sec1.1,active,,",
      "S102,test_1,Sec1.2,active,,",
      "S201,test_2,Sec2.1,active,,",
      "S202,test_2,Sec2.2,active,,"
    )
    # the enrollments
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_1,user_1,student,,active,",
      "test_1,user_2,student,S101,active,",
      "test_1,user_3,student,S102,active,",
      "test_2,user_4,student,S201,active,",
      ",user_5,student,S201,active,",
      ",user_6,student,S202,active,"
    )
    course1 = @account.courses.where(sis_source_id: "test_1").first
    course2 = @account.courses.where(sis_source_id: "test_2").first
    expect(course1.default_section.users.first.name).to eq "User Uno"
    section1_1 = course1.course_sections.where(sis_source_id: "S101").first
    expect(section1_1.users.first.name).to eq "User Dos"
    section1_2 = course1.course_sections.where(sis_source_id: "S102").first
    expect(section1_2.users.first.name).to eq "User Tres"
    section2_1 = course2.course_sections.where(sis_source_id: "S201").first
    expect(section2_1.users.map(&:name).sort).to eq ["User Cuatro", "User Cinco"].sort
    section2_2 = course2.course_sections.where(sis_source_id: "S202").first
    expect(section2_2.users.first.name).to eq "User Seis"

    # exercise batch updating account associations
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_10,user10,User,Uno,user10@example.com,active",
      "user_11,user11,User,Uno,user11@example.com,active",
      "user_12,user12,User,Uno,user12@example.com,active",
      "user_13,user13,User,Uno,user13@example.com,active",
      "user_14,user14,User,Uno,user14@example.com,active",
      "user_15,user15,User,Uno,user15@example.com,active",
      "user_16,user16,User,Uno,user16@example.com,active",
      "user_17,user17,User,Uno,user17@example.com,active",
      "user_18,user18,User,Uno,user18@example.com,active",
      "user_19,user19,User,Uno,user19@example.com,active",
      "user_20,user20,User,Uno,user20@example.com,active",
      "user_21,user21,User,Uno,user21@example.com,active",
      "user_22,user22,User,Uno,user22@example.com,active",
      "user_23,user23,User,Uno,user23@example.com,active",
      "user_24,user24,User,Uno,user24@example.com,active",
      "user_25,user25,User,Uno,user25@example.com,active",
      "user_26,user26,User,Uno,user26@example.com,active",
      "user_27,user27,User,Uno,user27@example.com,active",
      "user_28,user28,User,Uno,user28@example.com,active",
      "user_29,user29,User,Uno,user29@example.com,active",
      "user_30,user30,User,Uno,user30@example.com,active",
      "user_31,user31,User,Uno,user31@example.com,active",
      "user_32,user32,User,Uno,user32@example.com,active",
      "user_33,user33,User,Uno,user33@example.com,active",
      "user_34,user34,User,Uno,user34@example.com,active",
      "user_35,user35,User,Uno,user35@example.com,active",
      "user_36,user36,User,Uno,user36@example.com,active",
      "user_37,user37,User,Uno,user37@example.com,active",
      "user_38,user38,User,Uno,user38@example.com,active",
      "user_39,user39,User,Uno,user39@example.com,active"
    )
    # the enrollments
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_1,user_10,student,,active,",
      "test_1,user_11,student,,active,",
      "test_1,user_12,student,,active,",
      "test_1,user_13,student,,active,",
      "test_1,user_14,student,,active,",
      "test_1,user_15,student,,active,",
      "test_1,user_16,student,,active,",
      "test_1,user_17,student,,active,",
      "test_1,user_18,student,,active,",
      "test_1,user_19,student,,active,",
      "test_1,user_20,student,,active,",
      "test_1,user_21,student,,active,",
      "test_1,user_22,student,,active,",
      "test_1,user_23,student,,active,",
      "test_1,user_24,student,,active,",
      "test_2,user_25,student,,active,",
      "test_2,user_26,student,,active,",
      "test_2,user_27,student,,active,",
      "test_2,user_28,student,,active,",
      "test_2,user_29,student,,active,",
      "test_2,user_30,student,,active,",
      "test_2,user_31,student,,active,",
      "test_2,user_32,student,,active,",
      "test_2,user_33,student,,active,",
      "test_2,user_34,student,,active,",
      "test_2,user_35,student,,active,",
      "test_2,user_36,student,,active,",
      "test_2,user_37,student,,active,",
      "test_2,user_38,student,,active,",
      "test_2,user_39,student,,active,"
    )
  end

  it "should resurrect deleted enrollments" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,active"
    )
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_1,user_1,student,,deleted,"
    )
    @course = Course.where(sis_source_id: 'test_1').first
    scope = Enrollment.where(:course_id => @course)
    expect(scope.count).to eq 1
    @enrollment = scope.first
    expect(@enrollment).to be_deleted

    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_1,user_1,student,,active,"
    )
    expect(scope.count).to eq 1
    expect(@enrollment.reload).to be_active
  end

  it "should allow one user multiple enrollment types in the same section" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,active"
    )
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_1,user_1,student,,active,",
      "test_1,user_1,teacher,,active,"
    )
    @course = Course.where(sis_source_id: 'test_1').first
    expect(@course.enrollments.count).to eq 2
    @user = Pseudonym.where(sis_user_id: 'user_1').first.user
    expect(@course.enrollments.map(&:user)).to eq [@user, @user]
  end

  it "should allow one user to observe multiple students" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,active",
      "user_2,user2,User,Uno,user@example.com,active",
      "observer_1,user3,User,Uno,user@example.com,active"
    )
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_1,user_1,student,,active,",
      "test_1,user_2,student,,active,",
      "test_1,observer_1,observer,,active,user_1",
      "test_1,observer_1,observer,,active,user_2"
    )
    @course = Course.where(sis_source_id: 'test_1').first
    expect(@course.enrollments.count).to eq 4
    @observer = Pseudonym.where(sis_user_id: 'observer_1').first.user
    @user1 = Pseudonym.where(sis_user_id: 'user_1').first.user
    @user2 = Pseudonym.where(sis_user_id: 'user_2').first.user
    expect(@course.observer_enrollments.map(&:user)).to eq [@observer, @observer]
    expect(@course.observer_enrollments.map(&:associated_user_id).sort).to eq [@user1.id, @user2.id].sort
  end

  it "should find manually xlisted sections when enrolling by course id" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active",
      "test_2,TC 102,Test Course 102,,,active"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,active",
      "user_2,user2,User,Uno,user@example.com,active",
      "user_3,user3,User,Uno,user@example.com,active"
    )
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_1,user_1,student,,active,",
      "test_2,user_1,student,,active,"
    )
    @course1 = Course.where(sis_source_id: 'test_1').first
    @course2 = Course.where(sis_source_id: 'test_2').first
    @course1.default_section.crosslist_to_course(@course2)
    expect(@course2.course_sections.count).to eq 2

    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_1,user_3,student,,active,"
    )
    expect(@course2.enrollments.count).to eq 3
    expect(@course1.enrollments.count).to eq 0
  end

  it "should not recycle an observer's associated user id in subsequent student enrollments" do
    process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active",
        "user_2,user2,User,Dos,user2@example.com,active",
        "observer_1,observer1,Observer,Uno,observer1@example.com,active"
    )
    process_csv_data_cleanly(
        "course_id,user_id,role,section_id,status,associated_user_id",
        "test_1,user_1,student,,active,",
        "test_1,observer_1,observer,,active,user_1",
        "test_1,user_2,student,,active,"
    )
    @course = Course.where(sis_source_id: 'test_1').first
    expect(@course.enrollments.count).to eq 3
    @observer = Pseudonym.where(sis_user_id: 'observer_1').first.user
    @user1 = Pseudonym.where(sis_user_id: 'user_1').first.user
    @user2 = Pseudonym.where(sis_user_id: 'user_2').first.user

    expect(@observer.enrollments.size).to eq 1
    observer_enrollment = @observer.enrollments.first
    expect(observer_enrollment.type).to eq "ObserverEnrollment"
    expect(observer_enrollment.associated_user_id).to eq @user1.id

    expect(@user2.enrollments.size).to eq 1
    user2_enrollment = @user2.enrollments.first
    expect(user2_enrollment.type).to eq "StudentEnrollment"
    expect(user2_enrollment.associated_user_id).to be_nil
  end

  it "should find observed user who is deleted and clear observer correctly" do
    process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active",
        "observer_1,observer1,Observer,Uno,observer1@example.com,active"
    )
    process_csv_data_cleanly(
        "course_id,user_id,role,section_id,status,associated_user_id",
        "test_1,user_1,student,,active,",
        "test_1,observer_1,observer,,active,user_1"
    )

    @observer = Pseudonym.where(sis_user_id: 'observer_1').first.user
    expect(@observer.enrollments.count).to eq 1

    process_csv_data_cleanly(
        "course_id,user_id,role,section_id,status,associated_user_id",
        "test_1,user_1,student,,completed,",
        "test_1,observer_1,observer,,completed,user_1"
    )

    @observer.reload
    expect(@observer.enrollments.count).to eq 1
    expect(@observer.enrollments.first.workflow_state).to eq 'completed'
  end

  it "should only queue up one DueDateCacher job per course" do
    course_model(:account => @account, :sis_source_id => 'C001').assignments.create!
    course_model(:account => @account, :sis_source_id => 'C002').assignments.create!
    @course.assignments.create!
    user_with_managed_pseudonym(:account => @account, :sis_user_id => 'U001')
    user_with_managed_pseudonym(:account => @account, :sis_user_id => 'U002')
    DueDateCacher.expects(:recompute).never
    DueDateCacher.expects(:recompute_course).twice
    process_csv_data_cleanly(
        "course_id,user_id,role,status",
        "C001,U001,student,active",
        "C001,U002,student,active",
        "C002,U001,student,active",
        "C002,U002,student,active",
    )
  end

  describe "custom roles" do
    context "in an account" do
      before do
        @course = course_model(:account => @account, :sis_source_id => 'TehCourse')
        @user1 = user_with_managed_pseudonym(:account => @account, :sis_user_id => 'user1')
        @user2 = user_with_managed_pseudonym(:account => @account, :sis_user_id => 'user2')
        @role = custom_role('StudentEnrollment', 'cheater')
        @role2 = custom_role('StudentEnrollment', 'insufferable know-it-all')
      end

      it "should enroll with a custom role" do
        process_csv_data_cleanly(
            "course_id,user_id,role,section_id,status,associated_user_id",
            "TehCourse,user1,student,,active,",
            "TehCourse,user2,cheater,,active,"
        )
        expect(@user1.enrollments.map{|e|[e.type, e.role_name]}).to eq [['StudentEnrollment', nil]]
        expect(@user2.enrollments.map{|e|[e.type, e.role_name]}).to eq [['StudentEnrollment', 'cheater']]
      end

      it "should not enroll with an inactive role" do
        @role.deactivate!
        importer = process_csv_data(
            "course_id,user_id,role,section_id,status,associated_user_id",
            "TehCourse,user1,cheater,,active,"
        )
        expect(@user1.enrollments.size).to eq 0
        expect(importer.warnings.map(&:last)).to eq ["Improper role \"cheater\" for an enrollment"]
      end

      it "should not enroll with a nonexistent role" do
        importer = process_csv_data(
            "course_id,user_id,role,section_id,status,associated_user_id",
            "TehCourse,user1,basketweaver,,active,"
        )
        expect(@user1.enrollments.size).to eq 0
        expect(importer.warnings.map(&:last)).to eq ["Improper role \"basketweaver\" for an enrollment"]
      end

      it "should create multiple enrollments with different roles having the same base type" do
        process_csv_data_cleanly(
            "course_id,user_id,role,section_id,status,associated_user_id",
            "TehCourse,user1,cheater,,active,",
            "TehCourse,user1,insufferable know-it-all,,active,"
        )
        expect(@user1.enrollments.sort_by(&:id).map(&:role_name)).to eq ['cheater', 'insufferable know-it-all']
      end
    end

    context "in a sub-account" do
      before do
        @role = @account.roles.build :name => 'instruc-TOR'
        @role.base_role_type = 'TeacherEnrollment'
        @role.save!
        @user1 = user_with_managed_pseudonym(:name => 'Dolph Hauldhagen', :account => @account, :sis_user_id => 'user1')
        @user2 = user_with_managed_pseudonym(:name => 'Strong Bad', :account => @account, :sis_user_id => 'user2')
        @sub_account = @account.sub_accounts.create!(:name => "The Rec Center")
        @course = course_model(:account => @sub_account, :name => 'Battle Axe Lessons', :sis_source_id => 'TehCourse')
      end

      it "should enroll with an inherited custom role" do
        process_csv_data_cleanly(
            "course_id,user_id,role,section_id,status,associated_user_id",
            "TehCourse,user1,instruc-TOR,,active,",
            "TehCourse,user2,student,,active,"
        )
        expect(@user1.enrollments.map{|e|[e.type, e.role_name]}).to eq [['TeacherEnrollment', 'instruc-TOR']]
        expect(@user2.enrollments.map{|e|[e.type, e.role_name]}).to eq [['StudentEnrollment', nil]]
      end

      it "should not enroll with an inactive inherited role" do
        @role.deactivate!
        importer = process_csv_data(
            "course_id,user_id,role,section_id,status,associated_user_id",
            "TehCourse,user1,instruc-TOR,,active,",
            "TehCourse,user2,student,,active,"
        )
        expect(@user1.enrollments.size).to eq 0
        expect(@user2.enrollments.map{|e|[e.type, e.role_name]}).to eq [['StudentEnrollment', nil]]
        expect(importer.warnings.map(&:last)).to eq ["Improper role \"instruc-TOR\" for an enrollment"]
      end

      it "should enroll with a custom role that overrides an inactive inherited role" do
        @role.deactivate!
        sub_role = @sub_account.roles.build :name => 'instruc-TOR'
        sub_role.base_role_type = 'TeacherEnrollment'
        sub_role.save!
        process_csv_data_cleanly(
            "course_id,user_id,role,section_id,status,associated_user_id",
            "TehCourse,user1,instruc-TOR,,active,",
            "TehCourse,user2,student,,active,"
        )
        expect(@user1.enrollments.map{|e|[e.type, e.role_name]}).to eq [['TeacherEnrollment', 'instruc-TOR']]
        expect(@user2.enrollments.map{|e|[e.type, e.role_name]}).to eq [['StudentEnrollment', nil]]
      end

      it "should not enroll with a custom role defined in a sibling account" do
        other_account = @account.sub_accounts.create!
        other_role = other_account.roles.build :name => 'Pixel Pusher'
        other_role.base_role_type = 'DesignerEnrollment'
        other_role.save!
        course_model(:account => other_account, :sis_source_id => 'OtherCourse')
        importer = process_csv_data(
            "course_id,user_id,role,section_id,status,associated_user_id",
            "TehCourse,user1,Pixel Pusher,,active,",
            "OtherCourse,user2,Pixel Pusher,,active,"
        )
        expect(importer.warnings.map(&:last)).to eq ["Improper role \"Pixel Pusher\" for an enrollment"]
        expect(@user1.enrollments.size).to eq 0
        expect(@user2.enrollments.map{|e|[e.type, e.role_name]}).to eq [['DesignerEnrollment', 'Pixel Pusher']]
      end
    end
  end

  it "should allow cross-account imports" do
    #create course, users, and sections
    process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,,active"
    )
    account2 = Account.create!
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user@example.com,active",
        account: account2
    )
    user = account2.pseudonyms.where(sis_user_id: 'user_1').first.user
    user.any_instantiation.expects(:find_pseudonym_for_account).with(@account, true).once.returns(user.pseudonyms.first)
    SIS::EnrollmentImporter::Work.any_instance.expects(:root_account_from_id).with('account2').once.returns(account2)
    # the enrollments
    process_csv_data_cleanly(
        "course_id,root_account,user_id,role,status",
        "test_1,account2,user_1,teacher,active",
    )
    course = @account.courses.where(sis_source_id: 'test_1').first
    expect(course.teachers.map(&:name)).to eq ['User Uno']
  end

  it "should check for a usable login for cross-account imports" do
    #create course, users, and sections
    process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,,active"
    )
    account2 = Account.create!
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user@example.com,active",
        account: account2
    )
    user = account2.pseudonyms.where(sis_user_id: 'user_1').first.user
    user.any_instantiation.expects(:find_pseudonym_for_account).with(@account, true).once.returns(nil)
    SIS::EnrollmentImporter::Work.any_instance.expects(:root_account_from_id).with('account2').once.returns(account2)
    # the enrollments
    importer = process_csv_data(
        "course_id,root_account,user_id,role,status",
        "test_1,account2,user_1,teacher,active",
    )
    expect(importer.warnings.map(&:last)).to eq ["User account2:user_1 does not have a usable login for this account"]
    course = @account.courses.where(sis_source_id: 'test_1').first
    expect(course.teachers.to_a).to be_empty
  end

  it "should skip cross-account imports that can't be found" do
    #create course, users, and sections
    process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,,active"
    )
    account2 = Account.create!
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user@example.com,active",
        account: account2
    )
    user = account2.pseudonyms.where(sis_user_id: 'user_1').first.user
    user.any_instantiation.expects(:find_pseudonym_for_account).with(@account, true).never
    SIS::EnrollmentImporter::Work.any_instance.expects(:root_account_from_id).with('account2').once.returns(nil)
    # the enrollments
    importer = process_csv_data_cleanly(
        "course_id,root_account,user_id,role,status",
        "test_1,account2,user_1,teacher,active",
    )
    course = @account.courses.where(sis_source_id: 'test_1').first
    expect(course.teachers.to_a).to be_empty
  end

  it "should link with observer enrollments" do
    process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user@example.com,active"
    )
    course = Course.find_by_sis_source_id('test_1')
    course.offer!

    student = Pseudonym.where(:unique_id => "user1").first.user

    observer = user_with_pseudonym(:account => @account)
    student.observers << observer

    process_csv_data_cleanly(
        "course_id,user_id,role,section_id,status,associated_user_id",
        "test_1,user_1,student,,active,"
    )

    expect(observer.observer_enrollments.count).to eq 1
    e = observer.observer_enrollments.first
    expect(e.course_id).to eq course.id
    expect(e.associated_user_id).to eq student.id
  end

end
