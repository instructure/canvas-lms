# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe SIS::CSV::EnrollmentImporter do
  before { account_model }

  it "skips bad content" do
    course_model(account: @account, sis_source_id: "C001")
    @course.course_sections.create.update_attribute(:sis_source_id, "1B")
    user_with_managed_pseudonym(account: @account, sis_user_id: "U001")
    before_count = Enrollment.count
    importer = process_csv_data(
      "course_id,user_id,role,section_id,status,associated_user_id",
      ",U001,student,,active",
      "C001,,student,1B,active",
      "C001,U001,cheater,1B,active",
      "C001,U001,observer,1B,active,NONEXISTENT",
      "C001,U001,student,1B,semi-active"
    )
    expect(Enrollment.count).to eq before_count

    errors = importer.errors.map(&:last)
    # since accounts can define course roles, the "cheater" row can't be
    # rejected immediately on parse like the others; that's why the warning
    # comes out of order with the source data
    expect(errors).to eq ["No course_id or section_id given for an enrollment",
                          "No user_id given for an enrollment",
                          "Improper status \"semi-active\" for an enrollment",
                          "Improper role \"cheater\" for an enrollment",
                          "An enrollment referenced a non-existent associated user NONEXISTENT"]
  end

  it "warns about inconsistent data" do
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
      "C002,U001,student,1B,active"
    )
    errors = importer.errors.map(&:last)
    expect(errors).to eq ["An enrollment referenced a non-existent course NONEXISTENT",
                          "An enrollment referenced a non-existent section NONEXISTENT",
                          "An enrollment listed a section (1B) and a course (C002) that are unrelated for user (U001)"]
  end

  it "does not fail for really long course names" do
    # create course, users, and sections
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,active"
    )
    name = "0123456789" * 25
    process_csv_data_cleanly(
      "section_id,course_id,name,status,start_date,end_date",
      "S001,test_1,#{name},active,,"
    )
    # the enrollments
    expect do
      process_csv_data_cleanly(
        "course_id,user_id,role,section_id,status,associated_user_id,start_date,end_date",
        "test_1,user_1,teacher,S001,active,,,"
      )
    end.not_to raise_error
  end

  it "enrolls users" do
    # create course, users, and sections
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    importer = process_csv_data(
      "user_id,login_id,first_name,last_name,email,status,notify",
      "user_1,user1,User,Uno,user@example.com,active,true",
      "user_2,user2,User,Dos,user2@example.com,active,true",
      "user_3,user4,User,Tres,user3@example.com,active",
      "user_5,user5,User,Quatro,user5@example.com,active,false",
      "user_6,user6,User,Cinco,user6@example.com,active,false",
      "user_7,user7,User,Siete,user7@example.com,active",
      ",,,,,"
    )
    expect(importer.errors).to eq []
    # should skip empty lines without error or warning
    expect(importer.batch.reload.data[:counts][:users]).to eq 6

    process_csv_data_cleanly(
      "section_id,course_id,name,status,start_date,end_date",
      "S001,test_1,Sec1,active,,"
    )
    # the enrollments
    expect_any_instance_of(Enrollment).to receive(:add_to_favorites).once
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
    expect(course.teachers.map(&:name)).to include("User Uno")
    expect(course.students.first.name).to eq "User Dos"
    expect(course.tas.first.name).to eq "User Tres"
    expect(course.observers.first.name).to eq "User Quatro"
    expect(course.observer_enrollments.first.associated_user_id).to eq course.students.first.id
    expect(course.users.where(enrollments: { type: "DesignerEnrollment" }).first.name).to eq "User Cinco"
    siete = course.teacher_enrollments.detect { |e| e.user.name == "User Siete" }
    expect(siete).not_to be_nil
    expect(siete.start_at).to eq DateTime.new(1985, 8, 24)
    expect(siete.end_at).to eq DateTime.new(2011, 8, 29)
  end

  it "enrolls users by integration id" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "course_sis_id,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "user_id,integration_id,login_id,first_name,last_name,email,status",
      "user_1,user_1_int,user1,User,Uno,user@example.com,active"
    )
    process_csv_data_cleanly(
      "course_id,user_integration_id,role,section_id,status,associated_user_id,start_date,end_date",
      "course_sis_id,user_1_int,teacher,,active,,,"
    )
    pseudonym = @account.pseudonyms.where(integration_id: "user_1_int").first
    course = pseudonym.user.enrollments.first.course

    expect(pseudonym.sis_user_id).to eq "user_1"
    expect(course.sis_source_id).to eq "course_sis_id"
  end

  it "supports sis stickiness" do
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

  it "does not try looking up a section to enroll into if the section name is empty" do
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

  it "properly handles repeated courses and sections" do
    # create course, users, and sections
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

  it "resurrects deleted enrollments" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,active"
    )
    # should be able to create an enrollment in a deleted state
    importer = process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_1,user_1,student,,deleted,"
    )
    expect(importer.batch.data[:counts][:enrollments]).to eq 1
    @course = Course.where(sis_source_id: "test_1").first
    scope = Enrollment.where(course_id: @course)
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

  it "does not update an enrollment that is deleted and pseudonym is deleted" do
    # course
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    # deleted user
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,deleted"
    )
    # deleted enrollment
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_1,user_1,student,,deleted,"
    )
    # skipped enrollment update
    importer = process_csv_data(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_1,user_1,student,,active,"
    )
    errors = importer.errors.map(&:last)
    expect(errors).to include(/Attempted enrolling with deleted sis login user1 in course test_1/)
    expect(importer.batch.roll_back_data.count).to eq 0
  end

  it "counts re-deletions" do
    # because people get confused otherwise
    course_model(account: @account, sis_source_id: "C001")
    user_with_managed_pseudonym(account: @account, sis_user_id: "U001")

    process_csv_data_cleanly(
      "course_id,user_id,role,status",
      "C001,U001,student,deleted"
    )
    importer = process_csv_data_cleanly(
      "course_id,user_id,role,status",
      "C001,U001,student,deleted"
    )
    expect(importer.batch.data[:counts][:enrollments]).to eq 1
  end

  it "always updates sis_batch_id" do
    # because people get confused otherwise
    course = course_model(account: @account, sis_source_id: "C001")
    user = user_with_managed_pseudonym(account: @account, sis_user_id: "U001")

    importer = process_csv_data_cleanly(
      "course_id,user_id,role,status",
      "C001,U001,student,active"
    )
    enrollment = Enrollment.where(course_id: course.id, user_id: user.id).take
    expect(enrollment.sis_batch_id).to eq importer.batch.id
    importer = process_csv_data_cleanly(
      "course_id,user_id,role,status",
      "C001,U001,student,deleted"
    )
    expect(enrollment.reload.sis_batch_id).to eq importer.batch.id
    importer = process_csv_data_cleanly(
      "course_id,user_id,role,status",
      "C001,U001,student,deleted"
    )
    expect(enrollment.reload.sis_batch_id).to eq importer.batch.id
  end

  it "allows one user multiple enrollment types in the same section" do
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
    @course = Course.where(sis_source_id: "test_1").first
    expect(@course.enrollments.count).to eq 2
    @user = Pseudonym.where(sis_user_id: "user_1").first.user
    expect(@course.enrollments.map(&:user)).to eq [@user, @user]
  end

  it "sets limit_section_privileges" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,active",
      "user_2,user2,User,Uno,user2@example.com,active",
      "user_3,user3,User,Uno,user@example.com,active"
    )
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,limit_section_privileges",
      "test_1,user_1,student,,active,true",
      "test_1,user_2,teacher,,active,false",
      "test_1,user_3,student,,active,"
    )
    course = Course.where(sis_source_id: "test_1").first
    user1 = Pseudonym.where(sis_user_id: "user_1").first.user
    user2 = Pseudonym.where(sis_user_id: "user_2").first.user
    user3 = Pseudonym.where(sis_user_id: "user_3").first.user
    expect(course.enrollments.where(user_id: user1).first.limit_privileges_to_course_section).to be true
    expect(course.enrollments.where(user_id: user2).first.limit_privileges_to_course_section).to be false
    expect(course.enrollments.where(user_id: user3).first.limit_privileges_to_course_section).to be false
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,limit_section_privileges",
      "test_1,user_1,student,,active,"
    )
    expect(course.enrollments.where(user_id: user1).first.limit_privileges_to_course_section).to be true
  end

  it "allows one user to observe multiple students" do
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
    @course = Course.where(sis_source_id: "test_1").first
    expect(@course.enrollments.count).to eq 4
    @observer = Pseudonym.where(sis_user_id: "observer_1").first.user
    @user1 = Pseudonym.where(sis_user_id: "user_1").first.user
    @user2 = Pseudonym.where(sis_user_id: "user_2").first.user
    expect(@course.observer_enrollments.map(&:user)).to eq [@observer, @observer]
    expect(@course.observer_enrollments.map(&:associated_user_id).sort).to eq [@user1.id, @user2.id].sort
  end

  it "finds manually xlisted sections when enrolling by course id" do
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
    @course1 = Course.where(sis_source_id: "test_1").first
    @course2 = Course.where(sis_source_id: "test_2").first
    @course1.default_section.crosslist_to_course(@course2)
    expect(@course2.course_sections.count).to eq 2

    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_1,user_3,student,,active,"
    )
    expect(@course2.enrollments.count).to eq 3
    expect(@course1.enrollments.count).to eq 0
  end

  it "does not recycle an observer's associated user id in subsequent student enrollments" do
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
    @course = Course.where(sis_source_id: "test_1").first
    expect(@course.enrollments.count).to eq 3
    @observer = Pseudonym.where(sis_user_id: "observer_1").first.user
    @user1 = Pseudonym.where(sis_user_id: "user_1").first.user
    @user2 = Pseudonym.where(sis_user_id: "user_2").first.user

    expect(@observer.enrollments.size).to eq 1
    observer_enrollment = @observer.enrollments.first
    expect(observer_enrollment.type).to eq "ObserverEnrollment"
    expect(observer_enrollment.associated_user_id).to eq @user1.id

    expect(@user2.enrollments.size).to eq 1
    user2_enrollment = @user2.enrollments.first
    expect(user2_enrollment.type).to eq "StudentEnrollment"
    expect(user2_enrollment.associated_user_id).to be_nil
  end

  it "finds observed user who is deleted and clear observer correctly" do
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

    @observer = Pseudonym.where(sis_user_id: "observer_1").first.user
    expect(@observer.enrollments.count).to eq 1

    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_1,user_1,student,,completed,",
      "test_1,observer_1,observer,,completed,user_1"
    )

    @observer.reload
    expect(@observer.enrollments.count).to eq 1
    e = @observer.enrollments.first
    expect(e.workflow_state).to eq "completed"
    expect(e.completed_at).to be_present
  end

  it "enrolls observers when observer is added before restoring enrollment" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,status",
      "tc101,TC 101,Test Course 101,active"
    )

    process_csv_data_cleanly(
      "user_id,login_id,full_name,email,status",
      "user1,user1,User One,user1@example.com,active",
      "user2,user2,User Two,user2@example.com,active"
    )

    process_csv_data_cleanly(
      "course_id,user_id,role,status",
      "tc101,user1,student,deleted_last_completed"
    )

    process_csv_data_cleanly(
      "observer_id,student_id,status",
      "user2,user1,active"
    )

    process_csv_data_cleanly(
      "course_id,user_id,role,status",
      "tc101,user1,student,active"
    )

    course = Course.where(sis_source_id: "tc101").first
    student = Pseudonym.where(unique_id: "user1").first.user
    observer = Pseudonym.where(unique_id: "user2").first.user
    observations = observer.observer_enrollments

    expect(observations.count).to eq 1
    expect(observations.first.course).to eq course
    expect(observations.first.associated_user).to eq student
  end

  it "only queues up one SubmissionLifecycleManager job per course" do
    course1 = course_model(account: @account, sis_source_id: "C001")
    course2 = course_model(account: @account, sis_source_id: "C002")
    user1 = user_with_managed_pseudonym(account: @account, sis_user_id: "U001")
    user2 = user_with_managed_pseudonym(account: @account, sis_user_id: "U002")
    course1.enroll_user(user2)
    expect(SubmissionLifecycleManager).not_to receive(:recompute)
    # there are no assignments so this will just return, but we just want to see
    # that it gets called correctly and for the users that wre imported
    expect(SubmissionLifecycleManager).to receive(:recompute_users_for_course).with([user1.id], course1.id, nil, sis_import: true, update_grades: true)
    expect(SubmissionLifecycleManager).to receive(:recompute_users_for_course)
      .with([user1.id, user2.id], course2.id, nil, sis_import: true, update_grades: true)
    process_csv_data_cleanly(
      "course_id,user_id,role,status",
      "C001,U001,student,active",
      "C002,U001,student,active",
      "C002,U002,student,active"
    )
  end

  describe "#persist_errors" do
    it "gracefully handles string errors" do
      batch = Account.default.sis_batches.create!
      csv = double(:root_account => Account.default, :batch => batch, :[] => nil)
      importer = SIS::CSV::EnrollmentImporter.new(csv)
      importer.persist_errors(csv, ["a string error message"])
      expect(batch.sis_batch_errors.count).to eq(1)
    end
  end

  it "only queues up one recache_grade_distribution job per course" do
    skip unless Object.const_defined?(:CachedGradeDistribution)

    Course.create!(account: @account, sis_source_id: "C001", workflow_state: "available")
    user_with_managed_pseudonym(account: @account, sis_user_id: "U001")
    user_with_managed_pseudonym(account: @account, sis_user_id: "U002")
    expect_any_instance_of(CachedGradeDistribution).to receive(:recalculate!).once
    process_csv_data_cleanly(
      "course_id,user_id,role,status",
      "C001,U001,student,active",
      "C001,U002,student,active"
    )
  end

  describe "custom roles" do
    context "in an account" do
      before do
        @course = course_model(account: @account, sis_source_id: "TehCourse")
        @user1 = user_with_managed_pseudonym(account: @account, sis_user_id: "user1")
        @user2 = user_with_managed_pseudonym(account: @account, sis_user_id: "user2")
        @role = custom_role("StudentEnrollment", "cheater")
        @role2 = custom_role("StudentEnrollment", "insufferable know-it-all")
      end

      it "enrolls with a custom role" do
        process_csv_data_cleanly(
          "course_id,user_id,role,section_id,status,associated_user_id",
          "TehCourse,user1,student,,active,",
          "TehCourse,user2,cheater,,active,"
        )
        expect(@user1.enrollments.map { |e| [e.type, e.role.name] }).to eq [["StudentEnrollment", "StudentEnrollment"]]
        expect(@user2.enrollments.map { |e| [e.type, e.role.name] }).to eq [["StudentEnrollment", "cheater"]]
      end

      it "does not enroll with an inactive role" do
        @role.deactivate!
        importer = process_csv_data(
          "course_id,user_id,role,section_id,status,associated_user_id",
          "TehCourse,user1,cheater,,active,"
        )
        expect(@user1.enrollments.size).to eq 0
        expect(importer.errors.map(&:last)).to eq ["Improper role \"cheater\" for an enrollment"]
      end

      it "does not enroll with a nonexistent role" do
        importer = process_csv_data(
          "course_id,user_id,role,section_id,status,associated_user_id",
          "TehCourse,user1,basketweaver,,active,"
        )
        expect(@user1.enrollments.size).to eq 0
        expect(importer.errors.map(&:last)).to eq ["Improper role \"basketweaver\" for an enrollment"]
      end

      it "creates multiple enrollments with different roles having the same base type" do
        process_csv_data_cleanly(
          "course_id,user_id,role,section_id,status,associated_user_id",
          "TehCourse,user1,cheater,,active,",
          "TehCourse,user1,insufferable know-it-all,,active,"
        )
        expect(@user1.enrollments.sort_by(&:id).map(&:role).map(&:name)).to eq ["cheater", "insufferable know-it-all"]
      end

      it "finds by role_id" do
        process_csv_data_cleanly(
          "course_id,user_id,section_id,status,associated_user_id,role_id",
          "TehCourse,user1,,active,,#{@role.id}"
        )
        expect(@user1.enrollments.first.role).to eq @role
      end

      it "associates users for custom observer roles" do
        custom_role("ObserverEnrollment", "step mom")
        process_csv_data_cleanly(
          "course_id,user_id,role,section_id,status,associated_user_id",
          "TehCourse,user1,step mom,,active,user2"
        )
        expect(@user1.observer_enrollments.count).to eq 1
        e = @user1.observer_enrollments.first
        expect(e.associated_user_id).to eq @user2.id
      end
    end

    context "in a sub-account" do
      before do
        @role = @account.roles.build name: "instruc-TOR"
        @role.base_role_type = "TeacherEnrollment"
        @role.save!
        @user1 = user_with_managed_pseudonym(name: "Dolph Hauldhagen", account: @account, sis_user_id: "user1")
        @user2 = user_with_managed_pseudonym(name: "Strong Bad", account: @account, sis_user_id: "user2")
        @sub_account = @account.sub_accounts.create!(name: "The Rec Center")
        @course = course_model(account: @sub_account, name: "Battle Axe Lessons", sis_source_id: "TehCourse")
      end

      it "enrolls with an inherited custom role" do
        process_csv_data_cleanly(
          "course_id,user_id,role,section_id,status,associated_user_id",
          "TehCourse,user1,instruc-TOR,,active,",
          "TehCourse,user2,student,,active,"
        )
        expect(@user1.enrollments.map { |e| [e.type, e.role.name] }).to eq [["TeacherEnrollment", "instruc-TOR"]]
        expect(@user2.enrollments.map { |e| [e.type, e.role.name] }).to eq [["StudentEnrollment", "StudentEnrollment"]]
      end

      it "does not enroll with an inactive inherited role" do
        @role.deactivate!
        importer = process_csv_data(
          "course_id,user_id,role,section_id,status,associated_user_id",
          "TehCourse,user1,instruc-TOR,,active,",
          "TehCourse,user2,student,,active,"
        )
        expect(@user1.enrollments.size).to eq 0
        expect(@user2.enrollments.map { |e| [e.type, e.role.name] }).to eq [["StudentEnrollment", "StudentEnrollment"]]
        expect(importer.errors.map(&:last)).to eq ["Improper role \"instruc-TOR\" for an enrollment"]
      end

      it "enrolls with a custom role that overrides an inactive inherited role" do
        @role.deactivate!
        sub_role = @sub_account.roles.build name: "instruc-TOR"
        sub_role.base_role_type = "TeacherEnrollment"
        sub_role.save!
        process_csv_data_cleanly(
          "course_id,user_id,role,section_id,status,associated_user_id",
          "TehCourse,user1,instruc-TOR,,active,",
          "TehCourse,user2,student,,active,"
        )
        expect(@user1.enrollments.map { |e| [e.type, e.role.name] }).to eq [["TeacherEnrollment", "instruc-TOR"]]
        expect(@user2.enrollments.map { |e| [e.type, e.role.name] }).to eq [["StudentEnrollment", "StudentEnrollment"]]
      end

      it "does not enroll with a custom role defined in a sibling account" do
        other_account = @account.sub_accounts.create!
        other_role = other_account.roles.build name: "Pixel Pusher"
        other_role.base_role_type = "DesignerEnrollment"
        other_role.save!
        course_model(account: other_account, sis_source_id: "OtherCourse")
        importer = process_csv_data(
          "course_id,user_id,role,section_id,status,associated_user_id",
          "TehCourse,user1,Pixel Pusher,,active,",
          "OtherCourse,user2,Pixel Pusher,,active,"
        )
        expect(importer.errors.map(&:last)).to eq ["Improper role \"Pixel Pusher\" for an enrollment"]
        expect(@user1.enrollments.size).to eq 0
        expect(@user2.enrollments.map { |e| [e.type, e.role.name] }).to eq [["DesignerEnrollment", "Pixel Pusher"]]
      end
    end
  end

  it "allows cross-account imports" do
    # create course, users, and sections
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
    user = account2.pseudonyms.where(sis_user_id: "user_1").first.user
    expect(SisPseudonym).to receive(:for).with(user, @account, type: :implicit, require_sis: false).and_return(user.pseudonyms.first)

    warnings = []
    work = SIS::EnrollmentImporter::Work.new(@account.sis_batches.create!, @account, Rails.logger, warnings)
    expect(work).to receive(:root_account_from_id).once.and_return(account2)
    expect(SIS::EnrollmentImporter::Work).to receive(:new).with(any_args).and_return(work)

    # the enrollments
    process_csv_data_cleanly(
      "course_id,root_account,user_id,role,status",
      "test_1,account2,user_1,teacher,active"
    )
    course = @account.courses.where(sis_source_id: "test_1").first
    expect(course.teachers.map(&:name)).to eq ["User Uno"]
  end

  it "checks for a usable login for cross-account imports" do
    # create course, users, and sections
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
    user = account2.pseudonyms.where(sis_user_id: "user_1").first.user
    expect(SisPseudonym).to receive(:for).with(user, @account, type: :implicit, require_sis: false).once.and_return(nil)

    warnings = []
    work = SIS::EnrollmentImporter::Work.new(@account.sis_batches.create!, @account, Rails.logger, warnings)
    expect(work).to receive(:root_account_from_id).once.and_return(account2)
    expect(SIS::EnrollmentImporter::Work).to receive(:new).with(any_args).and_return(work)
    # the enrollments
    process_csv_data(
      "course_id,root_account,user_id,role,status",
      "test_1,account2,user_1,teacher,active"
    )
    expect(warnings.first.message).to eq "User account2:user_1 does not have a usable login for this account"
    course = @account.courses.where(sis_source_id: "test_1").first
    expect(course.teachers.to_a).to be_empty
  end

  it "skips cross-account imports that can't be found" do
    # create course, users, and sections
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
    user = account2.pseudonyms.where(sis_user_id: "user_1").first.user
    expect(SisPseudonym).not_to receive(:for).with(user, @account, type: :implicit, require_sis: false)

    warnings = []
    work = SIS::EnrollmentImporter::Work.new(@account.sis_batches.create!, @account, Rails.logger, warnings)
    expect(work).to receive(:root_account_from_id).once.and_return(nil)
    expect(SIS::EnrollmentImporter::Work).to receive(:new).with(any_args).and_return(work)
    # the enrollments
    process_csv_data_cleanly(
      "course_id,root_account,user_id,role,status",
      "test_1,account2,user_1,teacher,active"
    )
    course = @account.courses.where(sis_source_id: "test_1").first
    expect(course.teachers.to_a).to be_empty
  end

  it "links with observer enrollments" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,active"
    )
    course = Course.where(sis_source_id: "test_1").first
    course.offer!

    student = Pseudonym.where(unique_id: "user1").first.user

    observer = user_with_pseudonym(account: @account)
    add_linked_observer(student, observer, root_account: @account)

    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_1,user_1,student,,active,"
    )

    expect(observer.observer_enrollments.count).to eq 1
    e = observer.observer_enrollments.first
    expect(e.course_id).to eq course.id
    expect(e.associated_user_id).to eq student.id

    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_1,user_1,student,,deleted,"
    )
    expect(e.reload).to be_deleted
  end

  it "deletes observer enrollments when the student enrollment is already deleted" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "student_user,user1,User,Uno,user@example.com,active",
      "observer_user,user2,User,Two,user2@example.com,active"
    )
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_1,student_user,student,,active,",
      "test_1,observer_user,observer,,active,student_user"
    )

    student = Pseudonym.where(sis_user_id: "student_user").first.user
    observer = Pseudonym.where(sis_user_id: "observer_user").first.user

    expect(observer.enrollments.count).to eq 1
    expect(observer.enrollments.first.associated_user_id).to eq student.id

    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_1,student_user,student,,deleted,",
      "test_1,observer_user,observer,,deleted,student_user"
    )
    expect(observer.enrollments.count).to eq 1
    expect(observer.enrollments.first.workflow_state).to eq "deleted"
  end

  it "creates rollback data" do
    batch1 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "student_user,user1,User,Uno,user@example.com,active",
      "observer_user,user2,User,Two,user2@example.com,active"
    )
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_1,student_user,student,,active,",
      "test_1,observer_user,observer,,active,student_user",
      batch: batch1
    )
    course = @account.all_courses.where(sis_source_id: "test_1").take
    g = course.groups.create!(name: "group")
    g.group_memberships.create!(user: Pseudonym.where(sis_user_id: "student_user").take.user)
    batch2 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_1,student_user,student,,deleted,",
      "test_1,observer_user,observer,,deleted,student_user",
      batch: batch2
    )
    expect(batch1.roll_back_data.where(previous_workflow_state: "non-existent").count).to eq 2
    expect(batch2.roll_back_data.where(updated_workflow_state: "deleted").count).to eq 3
    expect(batch2.roll_back_data.where(context_type: "GroupMembership").count).to eq 1
    batch2.restore_states_for_batch
    expect(course.enrollments.active.count).to eq 2
    expect(g.group_memberships.active.count).to eq 1
  end

  it "does not create active enrollments for deleted users" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "student_user,user1,User,Uno,user@example.com,active"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "student_user,user1,User,Uno,user@example.com,deleted"
    )
    importer = process_csv_data(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_1,student_user,student,,active,"
    )
    errors = importer.errors.map(&:last)
    expect(errors).to eq ["Attempted enrolling of deleted user student_user in course test_1"]

    student = Pseudonym.where(sis_user_id: "student_user").first.user
    expect(student.enrollments.count).to eq 1
    expect(student.enrollments.first).to be_deleted
  end

  it "does not create new enrollments for an already deleted user and enrollment" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "student_user,user1,User,Uno,user@example.com,active"
    )
    User.where(id: Pseudonym.find_by(sis_user_id: "student_user").user_id).update_all(workflow_state: "deleted")
    process_csv_data(
      "user_id,course_id,role,status",
      "student_user,test_1,student,active"
    )
    importer = process_csv_data(
      "user_id,course_id,role,status",
      "student_user,test_1,student,active"
    )
    student = Pseudonym.where(sis_user_id: "student_user").first.user
    expect(student.enrollments.count).to eq 1
    expect(student.enrollments.first).to be_deleted
    errors = importer.errors.map(&:last)
    expect(errors).to include(/Attempted enrolling of deleted user/)
    expect(importer.batch.roll_back_data.count).to eq 0
  end

  it "do not create enrollments for deleted pseudonyms except when they have an active pseudonym too" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "student_user,user1,User,Uno,user@example.com,active"
    )
    p = Pseudonym.where(sis_user_id: "student_user").first
    p.user.pseudonyms.create(account: p.account, sis_user_id: "second_sis", unique_id: "second_sis")
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "student_user,user1,User,Uno,user@example.com,deleted"
    )
    importer = process_csv_data(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_1,student_user,student,,active,"
    )
    errors = importer.errors.map(&:last)
    expect(errors).to eq ["Enrolled a user student_user in course test_1, but referenced a deleted sis login"]

    student = p.user
    expect(student.enrollments.count).to eq 1
    expect(student.enrollments.first).to be_active
  end

  it "does not enroll users into deleted sections" do
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
      "S001,test_1,Sec1,deleted,,"
    )
    importer = process_csv_data(
      "course_id,user_id,role,section_id,status,associated_user_id,start_date,end_date",
      "test_1,user_1,teacher,S001,active,,,"
    )
    errors = importer.errors.map(&:last)
    expect(errors.first).to include("not a valid section")
  end

  it "still works when creating a completed enrollment" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "student_user,user1,User,Uno,user@example.com,active"
    )
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_1,student_user,student,,completed,"
    )
    student = Pseudonym.where(sis_user_id: "student_user").first.user
    expect(student.enrollments.count).to eq 1
    expect(student.enrollments.first).to be_completed
  end

  it "completes last and delete the rest" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "student_user,user1,User,Uno,user@example.com,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,status,start_date,end_date",
      "S001,test_1,Sec1,active,,",
      "S002,test_1,Sec1,active,,",
      "S003,test_1,Sec1,active,,"
    )
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_1,student_user,student,S001,deleted_last_completed,",
      "test_1,student_user,student,S002,deleted_last_completed,",
      "test_1,student_user,student,S003,deleted_last_completed,"
    )
    student = Pseudonym.where(sis_user_id: "student_user").first.user
    expect(Enrollment.where(user: student, workflow_state: "completed").count).to eq 1
    expect(Enrollment.where(user: student, workflow_state: "deleted").count).to eq 2
  end

  it "deletes enrollments if active exists" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "student_user,user1,User,Uno,user@example.com,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,status,start_date,end_date",
      "S001,test_1,Sec1,active,,",
      "S002,test_1,Sec1,active,,",
      "S003,test_1,Sec1,active,,"
    )
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "test_1,student_user,student,S001,active,",
      "test_1,student_user,student,S002,deleted_last_completed,",
      "test_1,student_user,student,S003,deleted_last_completed,"
    )
    student = Pseudonym.where(sis_user_id: "student_user").first.user
    expect(Enrollment.where(user: student, workflow_state: "active").count).to eq 1
    expect(Enrollment.where(user: student, workflow_state: "deleted").count).to eq 2
  end

  it "doesn't die if the last record is invalid" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,status",
      "c1,Course,Course,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,status",
      "s1,c1,Section,active"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "u1,user1,User,Uno,user@example.com,active",
      "u2,user2,User,Uno,user@example.com,active",
      "u3,user3,User,Uno,user@example.com,active",
      "u4,user4,User,Uno,user@example.com,active",
      "u5,user5,User,Uno,user@example.com,active",
      "u6,user6,User,Uno,user@example.com,active",
      "u7,user7,User,Uno,user@example.com,active",
      "u8,user8,User,Uno,user@example.com,active",
      "u9,user9,User,Uno,user@example.com,active",
      "u0,user0,User,Uno,user@example.com,active"
    )
    importer = process_csv_data(
      "course_id,user_id,role,section_id,status",
      "c1,u1,student,s1,active",
      "c1,u2,student,s1,active",
      "c1,u3,student,s1,active",
      "c1,u4,student,s1,active",
      "c1,u5,student,s1,active",
      "c1,u6,student,s1,active",
      "c1,u7,student,s1,active",
      "c1,u8,student,s1,active",
      "c1,u9,student,s1,active",
      "c1,u0,student,s1,active",
      "c1,u1,student,s2,active"
    )
    errors = importer.errors.map(&:last)
    expect(errors.first).to include("non-existent section")
  end

  it "associates to the correct accounts and doesn't die for invalid rows" do
    process_csv_data_cleanly(
      "account_id,name,parent_account_id,status",
      "a1,a1,,active",
      "a2,a2,,active"
    )
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,status",
      "c1,Course,Course,a1,active",
      "c2,Course,Course,a2,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,status,start_date,end_date",
      "s1,c1,Sec1,active,,",
      "s2,c2,Sec2,active,,",
      "s3,c1,Sec3,active,,"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "u1,user1,User,Uno,user@example.com,active",
      "u2,user2,User,Uno,user@example.com,active",
      "u3,user3,User,Uno,user@example.com,active",
      "u4,user4,User,Uno,user@example.com,active",
      "u5,user5,User,Uno,user@example.com,active",
      "u6,user6,User,Uno,user@example.com,active",
      "u7,user7,User,Uno,user@example.com,active",
      "u8,user8,User,Uno,user@example.com,active",
      "u9,user9,User,Uno,user@example.com,active",
      "u0,user0,User,Uno,user@example.com,active",
      "v1,vser1,User,Uno,user@example.com,active"
    )
    importer = process_csv_data(
      "course_id,section_id,user_id,role,status",
      "c1,s1,u1,student,active",
      "c1,s1,u2,student,active",
      "c1,s1,u3,student,active",
      "c1,s1,u4,student,active",
      "c1,s1,u5,student,active",
      "c1,s1,u6,student,active",
      "c1,s1,u7,student,active",
      "c1,s1,u8,student,active",
      "c1,s1,u9,student,active",
      "c1,s1,u0,student,active",
      "c3,s3,v1,student,active", # invalid course_id
      "c2,s2,v1,student,active"
    )
    errors = importer.errors.map(&:last)
    expect(errors).to eq ["An enrollment referenced a non-existent course c3"]
    a1 = @account.sub_accounts.find_by(sis_source_id: "a1")
    a2 = @account.sub_accounts.find_by(sis_source_id: "a2")
    u1 = @account.pseudonyms.active.find_by(sis_user_id: "u1").user
    v1 = @account.pseudonyms.active.find_by(sis_user_id: "v1").user
    expect(u1.associated_accounts).not_to include(a2)
    expect(v1.associated_accounts).not_to include(a1)
  end

  it "does not enroll students in blueprint courses" do
    course_factory(account: @account, sis_source_id: "blue")
    @teacher = user_with_managed_pseudonym(account: @account, sis_user_id: "daba")
    @student = user_with_managed_pseudonym(account: @account, sis_user_id: "dee")
    MasterCourses::MasterTemplate.set_as_master_course(@course)
    importer = process_csv_data(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "blue,daba,teacher,,active,",
      "blue,dee,student,,active,"
    )
    expect(@teacher.enrollments.size).to eq 1
    expect(@student.enrollments.size).to eq 0
    expect(importer.errors.map(&:last)).to eq ["Student enrollment for \"dee\" not allowed in blueprint course \"blue\""]
  end

  it "does not enroll observers in blueprint courses" do
    course_factory(account: @account, sis_source_id: "blue")
    @teacher = user_with_managed_pseudonym(account: @account, sis_user_id: "daba")
    @observer = user_with_managed_pseudonym(account: @account, sis_user_id: "dee")
    MasterCourses::MasterTemplate.set_as_master_course(@course)
    importer = process_csv_data(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "blue,daba,teacher,,active,",
      "blue,dee,observer,,active,"
    )
    expect(@teacher.enrollments.size).to eq 1
    expect(@observer.enrollments.size).to eq 0
    expect(importer.errors.map(&:last)).to eq ["Observer enrollment for \"dee\" not allowed in blueprint course \"blue\""]
  end

  describe "temporary enrollments" do
    before(:once) do
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,,active"
      )
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "provider,provider,Temp,Provider,provider@example.com,active",
        "recipient,recipient,Temp,Recipient,recipient@example.com,active"
      )
      @course = Course.where(sis_source_id: "test_1").first
      @recipient = Pseudonym.where(sis_user_id: "recipient").first.user
      @provider = Pseudonym.where(sis_user_id: "provider").first.user
    end

    context "when feature flag is enabled" do
      before(:once) do
        @course.root_account.enable_feature!(:temporary_enrollments)
        process_csv_data_cleanly(
          "course_id,user_id,role,status,start_date,end_date,temporary_enrollment_source_user_id",
          "test_1,provider,teacher,active,2023-09-10T23:08:51Z,2023-09-30T23:08:51Z,,",
          "test_1,recipient,teacher,active,2023-09-10T23:08:51Z,2043-09-30T23:08:51Z,provider"
        )
      end

      it "creates a new temporary enrollment association" do
        expect(@course.enrollments.count).to eq 2
        expect(@recipient.enrollments.map(&:type)).to eq ["TeacherEnrollment"]
        expect(@recipient.enrollments.take.temporary_enrollment_source_user_id).to eq @provider.id
      end
    end

    context "when feature flag is disabled" do
      before(:once) do
        @course.root_account.disable_feature!(:temporary_enrollments)
        process_csv_data_cleanly(
          "course_id,user_id,role,status,start_date,end_date,temporary_enrollment_source_user_id",
          "test_1,provider,teacher,active,2023-09-10T23:08:51Z,2023-09-30T23:08:51Z,,",
          "test_1,recipient,teacher,active,2023-09-10T23:08:51Z,2043-09-30T23:08:51Z,provider"
        )
      end

      it "does not create a new temporary enrollment association" do
        expect(@course.enrollments.count).to eq 2
        expect(@recipient.enrollments.map(&:type)).to eq ["TeacherEnrollment"]
        expect(@recipient.enrollments.take.temporary_enrollment_source_user_id).to be_nil
      end
    end
  end
end
