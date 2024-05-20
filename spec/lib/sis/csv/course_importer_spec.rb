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

describe SIS::CSV::CourseImporter do
  before { account_model }

  it "skips bad content" do
    before_count = Course.count
    importer = process_csv_data(
      "course_id,short_name,long_name,term_id,status",
      "C001,Hum101,Humanities,T001,active",
      ",Hum102,Humanities 2,T001,active",
      "C003,Hum102,Humanities 2,T001,inactive",
      "C004,,Humanities 2,T001,active",
      "C005,Hum102,,T001,active"
    )
    expect(Course.count).to eq before_count + 1

    errors = importer.errors.map(&:last)
    expect(errors).to eq ["No course_id given for a course",
                          "Improper status \"inactive\" for course C003",
                          "No short_name given for course C004",
                          "No long_name given for course C005"]
  end

  it "creates new courses" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    course = @account.courses.where(sis_source_id: "test_1").first
    expect(course.course_code).to eql("TC 101")
    expect(course.name).to eql("Test Course 101")
    expect(course.associated_accounts.map(&:id).sort).to eq [@account.id]
  end

  it "throws an error when account is not found" do
    importer = process_csv_data(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,VERY_INVALID_ACCOUNT,,active"
    )
    errors = importer.errors.map(&:last)
    expect(errors).to eq ["Account not found \"VERY_INVALID_ACCOUNT\" for course test_1"]
  end

  it "supports term stickiness" do
    process_csv_data_cleanly(
      "term_id,name,status,start_date,end_date",
      "T001,Winter13,active,,",
      "T002,Spring14,active,,",
      "T003,Summer14,active,,",
      "T004,Fall14,active,,"
    )
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,blueprint_course_id",
      "test_1,TC 101,Test Course 101,,T001,active,\"\""
    )
    @account.courses.where(sis_source_id: "test_1").first.tap do |course|
      expect(course.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: "T001").first
    end
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,T002,active"
    )
    @account.courses.where(sis_source_id: "test_1").first.tap do |course|
      expect(course.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: "T002").first
      course.enrollment_term = EnrollmentTerm.where(sis_source_id: "T003").first
      course.save!
    end
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,T004,active"
    )
    @account.courses.where(sis_source_id: "test_1").first.tap do |course|
      expect(course.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: "T003").first
    end
  end

  it "supports account stickiness" do
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,Humanities,active",
      "A002,,Humanities,active",
      "A003,,Humanities,active",
      "A004,,Humanities,active"
    )
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,A001,,active"
    )
    @account.all_courses.where(sis_source_id: "test_1").first.tap do |course|
      expect(course.account).to eq Account.where(sis_source_id: "A001").take
    end
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,A002,,active"
    )
    @account.all_courses.where(sis_source_id: "test_1").first.tap do |course|
      expect(course.account).to eq Account.where(sis_source_id: "A002").take
      course.account = Account.where(sis_source_id: "A003").first
      course.save!
    end
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,A004,,active"
    )
    @account.all_courses.where(sis_source_id: "test_1").first.tap do |course|
      expect(course.account).to eq Account.where(sis_source_id: "A003").take
    end
  end

  it "supports term stickiness from abstract courses" do
    process_csv_data_cleanly(
      "term_id,name,status,start_date,end_date",
      "T001,Winter13,active,,",
      "T002,Spring14,active,,",
      "T003,Summer14,active,,",
      "T004,Fall14,active,,"
    )
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "AC001,Hum101,Humanities,A001,T001,active"
    )
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,abstract_course_id",
      "test_1,TC 101,Test Course 101,,,active,AC001"
    )
    @account.courses.where(sis_source_id: "test_1").first.tap do |course|
      expect(course.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: "T001").first
    end
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "AC001,Hum101,Humanities,A001,T002,active"
    )
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,abstract_course_id",
      "test_1,TC 101,Test Course 101,,,active,AC001"
    )
    @account.courses.where(sis_source_id: "test_1").first.tap do |course|
      expect(course.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: "T002").first
      course.enrollment_term = EnrollmentTerm.where(sis_source_id: "T003").first
      course.save!
    end
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "AC001,Hum101,Humanities,A001,T004,active"
    )
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,abstract_course_id",
      "test_1,TC 101,Test Course 101,,,active,AC001"
    )
    @account.courses.where(sis_source_id: "test_1").first.tap do |course|
      expect(course.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: "T003").first
    end
  end

  it "does not blow away the account id if it's already set" do
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,Humanities,active"
    )
    account = @account.sub_accounts.where(sis_source_id: "A001").first
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    course = @account.courses.where(sis_source_id: "test_1").first
    expect(course.account).to eq @account
    expect(course.associated_accounts.map(&:id).sort).to eq [@account.id]
    expect(account).not_to eq @account
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,A001,,active"
    )
    course.reload
    expect(course.account).to eq account
    expect(course.associated_accounts.map(&:id).sort).to eq [account.id, @account.id].sort
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    course.reload
    expect(course.account).to eq account
    expect(course.associated_accounts.map(&:id).sort).to eq [account.id, @account.id].sort
  end

  it "supports falling back to a fallback account if the primary one doesn't exist" do
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,Humanities,active"
    )
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,fallback_account_id",
      "test_1,TC 101,Test Course 101,NOEXIST,,active,A001"
    )
    account = @account.sub_accounts.where(sis_source_id: "A001").first
    course = account.courses.where(sis_source_id: "test_1").first
    expect(course.account).to eq account
  end

  it "renames courses that have not had their name manually changed" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active",
      "test_2,TB 101,Testing & Breaking 101,,,active"
    )
    course = @account.courses.where(sis_source_id: "test_1").first
    expect(course.course_code).to eql("TC 101")
    expect(course.name).to eql("Test Course 101")

    course = @account.courses.where(sis_source_id: "test_2").first
    expect(course.name).to eql("Testing & Breaking 101")

    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 102,Test Course 102,,,active",
      "test_2,TB 102,Testing & Breaking 102,,,active"
    )

    course = @account.courses.where(sis_source_id: "test_1").first
    expect(course.course_code).to eql("TC 102")
    expect(course.name).to eql("Test Course 102")

    course = @account.courses.where(sis_source_id: "test_2").first
    expect(course.name).to eql("Testing & Breaking 102")
  end

  it "does not rename courses that have had their names manually changed" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    course = @account.courses.where(sis_source_id: "test_1").first
    expect(course.course_code).to eql("TC 101")
    expect(course.name).to eql("Test Course 101")

    course.name = "Haha my course lol"
    course.course_code = "SUCKERS 101"
    course.save

    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 102,Test Course 102,,,active"
    )
    course = @account.courses.where(sis_source_id: "test_1").first
    expect(course.course_code).to eql("SUCKERS 101")
    expect(course.name).to eql("Haha my course lol")
  end

  it "overrides term dates if the start or end dates are set" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "test1,TC 101,Test Course 1,,,active,,",
      "test2,TC 102,Test Course 2,,,active,,2011-05-14 00:00:00",
      "test3,TC 103,Test Course 3,,,active,2011-04-14 00:00:00,",
      "test4,TC 104,Test Course 4,,,active,2011-04-14 00:00:00,2011-05-14 00:00:00"
    )
    expect(@account.courses.where(sis_source_id: "test1").first.restrict_enrollments_to_course_dates).to be_falsey
    expect(@account.courses.where(sis_source_id: "test2").first.restrict_enrollments_to_course_dates).to be_truthy
    expect(@account.courses.where(sis_source_id: "test3").first.restrict_enrollments_to_course_dates).to be_truthy
    expect(@account.courses.where(sis_source_id: "test4").first.restrict_enrollments_to_course_dates).to be_truthy
  end

  it "removes dates with <delete>" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "test4,TC 104,Test Course 4,,,active,2011-04-14 00:00:00,2011-05-14 00:00:00"
    )
    expect(@account.courses.where(sis_source_id: "test4").first.restrict_enrollments_to_course_dates).to be_truthy
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "test4,TC 104,Test Course 4,,,active,<delete>,<delete>"
    )
    expect(@account.courses.where(sis_source_id: "test4").first.restrict_enrollments_to_course_dates).to be_falsey
  end

  it "supports start/end date and restriction stickiness" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "test4,TC 104,Test Course 4,,,active,2011-04-14 00:00:00,2011-05-14 00:00:00"
    )
    @account.courses.where(sis_source_id: "test4").first.tap do |course|
      expect(course.restrict_enrollments_to_course_dates).to be_truthy
      expect(course.start_at).to eq Time.zone.parse("2011-04-14 00:00:00")
      expect(course.conclude_at).to eq Time.zone.parse("2011-05-14 00:00:00")
      course.restrict_enrollments_to_course_dates = false # should be able to change this without stickying dates
      course.save!
    end

    # should not change restrict_enrollments_to_course_dates or start_at or end_at when columns are not supplied
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test4,TC 104,Test Course 4,,,active"
    )
    @account.courses.where(sis_source_id: "test4").first.tap do |course|
      expect(course.restrict_enrollments_to_course_dates).to be_falsey
      expect(course.start_at).to eq Time.zone.parse("2011-04-14 00:00:00")
      expect(course.conclude_at).to eq Time.zone.parse("2011-05-14 00:00:00")
    end

    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "test4,TC 104,Test Course 4,,,active,2012-04-14 00:00:00,2012-05-14 00:00:00"
    )
    @account.courses.where(sis_source_id: "test4").first.tap do |course|
      expect(course.restrict_enrollments_to_course_dates).to be_falsey
      expect(course.start_at).to eq Time.zone.parse("2012-04-14 00:00:00")
      expect(course.conclude_at).to eq Time.zone.parse("2012-05-14 00:00:00")
      course.start_at = Time.zone.parse("2010-04-14 00:00:00")
      course.conclude_at = Time.zone.parse("2010-05-14 00:00:00") # now get sticky
      course.save!
    end

    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "test4,TC 104,Test Course 4,,,active,2011-04-14 00:00:00,2011-05-14 00:00:00"
    )
    @account.courses.where(sis_source_id: "test4").first.tap do |course|
      expect(course.restrict_enrollments_to_course_dates).to be_falsey
      expect(course.start_at).to eq Time.zone.parse("2010-04-14 00:00:00")
      expect(course.conclude_at).to eq Time.zone.parse("2010-05-14 00:00:00")
    end
  end

  it "does not change templated course names or course codes if the course has those fields marked as sticky" do
    process_csv_data_cleanly(
      "term_id,name,status,start_date,end_date",
      "T001,Winter13,active,,",
      "T002,Spring14,active,,",
      "T003,Summer14,active,,",
      "T004,Fall14,active,,"
    )
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,Humanities,active",
      "A002,,Humanities,active",
      "A003,,Humanities,active",
      "A004,,Humanities,active"
    )
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "c1,TC 101,Test Course 1,A001,T001,active,2011-04-14 00:00:00,2011-05-14 00:00:00"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "s1,c1,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active",
      "s2,c1,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
    )
    process_csv_data_cleanly(
      "xlist_course_id,section_id,status",
      "c2,s1,active",
      "c3,s2,active"
    )
    Course.where(sis_source_id: %w[c1 c2 c3]).each do |c|
      expect(c.account).to eq Account.where(sis_source_id: "A001").first
      expect(c.name).to eq "Test Course 1"
      expect(c.course_code).to eq "TC 101"
      expect(c.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: "T001").first
      expect(c.start_at).to eq DateTime.parse("2011-04-14 00:00:00")
      expect(c.conclude_at).to eq DateTime.parse("2011-05-14 00:00:00")
      expect(c.restrict_enrollments_to_course_dates).to be_truthy
    end
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "c1,TC 102,Test Course 2,A002,T002,active,2011-04-12 00:00:00,2011-05-12 00:00:00"
    )
    Course.where(sis_source_id: %w[c1 c2 c3]).each do |c|
      expect(c.account).to eq Account.where(sis_source_id: "A002").first
      expect(c.name).to eq "Test Course 2"
      expect(c.course_code).to eq "TC 102"
      expect(c.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: "T002").first
      expect(c.start_at).to eq DateTime.parse("2011-04-12 00:00:00")
      expect(c.conclude_at).to eq DateTime.parse("2011-05-12 00:00:00")
      expect(c.restrict_enrollments_to_course_dates).to be_truthy
    end
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "c1,TC 102,Test Course 2,A002,T002,active,,"
    )
    Course.where(sis_source_id: %w[c1 c2 c3]).each do |c|
      expect(c.account).to eq Account.where(sis_source_id: "A002").first
      expect(c.name).to eq "Test Course 2"
      expect(c.course_code).to eq "TC 102"
      expect(c.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: "T002").first
      expect(c.start_at).to be_nil
      expect(c.conclude_at).to be_nil
      expect(c.restrict_enrollments_to_course_dates).to be_falsey
    end
    Course.where(sis_source_id: "c1").each do |c|
      c.account = Account.where(sis_source_id: "A003").first
      c.name = "Test Course 3"
      c.course_code = "TC 103"
      c.enrollment_term = EnrollmentTerm.where(sis_source_id: "T003").first
      c.start_at = DateTime.parse("2011-04-13 00:00:00")
      c.conclude_at = DateTime.parse("2011-05-13 00:00:00")
      c.restrict_enrollments_to_course_dates = true
      c.save!
    end
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "c1,TC 104,Test Course 4,A004,T004,active,2011-04-16 00:00:00,2011-05-16 00:00:00"
    )
    Course.where(sis_source_id: "c1").each do |c|
      expect(c.account).to eq Account.where(sis_source_id: "A003").first
      expect(c.name).to eq "Test Course 3"
      expect(c.course_code).to eq "TC 103"
      expect(c.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: "T003").first
      expect(c.start_at).to eq DateTime.parse("2011-04-13 00:00:00")
      expect(c.conclude_at).to eq DateTime.parse("2011-05-13 00:00:00")
      expect(c.restrict_enrollments_to_course_dates).to be_truthy
    end
    Course.where(sis_source_id: ["c2", "c3"]).each do |c|
      expect(c.account).to eq Account.where(sis_source_id: "A002").first
      expect(c.name).to eq "Test Course 2"
      expect(c.course_code).to eq "TC 102"
      expect(c.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: "T002").first
      expect(c.start_at).to be_nil
      expect(c.conclude_at).to be_nil
      expect(c.restrict_enrollments_to_course_dates).to be_falsey
    end
  end

  it "does not change templated course names or course codes if the templated course has those fields marked as sticky" do
    process_csv_data_cleanly(
      "term_id,name,status,start_date,end_date",
      "T001,Winter13,active,,",
      "T002,Spring14,active,,",
      "T003,Summer14,active,,",
      "T004,Fall14,active,,"
    )
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,Humanities,active",
      "A002,,Humanities,active",
      "A003,,Humanities,active",
      "A004,,Humanities,active"
    )
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "c1,TC 101,Test Course 1,A001,T001,active,2011-04-14 00:00:00,2011-05-14 00:00:00"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "s1,c1,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active",
      "s2,c1,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
    )
    process_csv_data_cleanly(
      "xlist_course_id,section_id,status",
      "c2,s1,active",
      "c3,s2,active"
    )
    Course.where(sis_source_id: %w[c1 c2 c3]).each do |c|
      expect(c.account).to eq Account.where(sis_source_id: "A001").first
      expect(c.name).to eq "Test Course 1"
      expect(c.course_code).to eq "TC 101"
      expect(c.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: "T001").first
      expect(c.start_at).to eq DateTime.parse("2011-04-14 00:00:00")
      expect(c.conclude_at).to eq DateTime.parse("2011-05-14 00:00:00")
      expect(c.restrict_enrollments_to_course_dates).to be_truthy
    end
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "c1,TC 102,Test Course 2,A002,T002,active,2011-04-12 00:00:00,2011-05-12 00:00:00"
    )
    Course.where(sis_source_id: %w[c1 c2 c3]).each do |c|
      expect(c.account).to eq Account.where(sis_source_id: "A002").first
      expect(c.name).to eq "Test Course 2"
      expect(c.course_code).to eq "TC 102"
      expect(c.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: "T002").first
      expect(c.start_at).to eq DateTime.parse("2011-04-12 00:00:00")
      expect(c.conclude_at).to eq DateTime.parse("2011-05-12 00:00:00")
      expect(c.restrict_enrollments_to_course_dates).to be_truthy
    end
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "c1,TC 102,Test Course 2,A002,T002,active,,"
    )
    Course.where(sis_source_id: %w[c1 c2 c3]).each do |c|
      expect(c.account).to eq Account.where(sis_source_id: "A002").first
      expect(c.name).to eq "Test Course 2"
      expect(c.course_code).to eq "TC 102"
      expect(c.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: "T002").first
      expect(c.start_at).to be_nil
      expect(c.conclude_at).to be_nil
      expect(c.restrict_enrollments_to_course_dates).to be_falsey
    end
    Course.where(sis_source_id: ["c2", "c3"]).each do |c|
      c.account = Account.where(sis_source_id: "A003").first
      c.name = "Test Course 3"
      c.course_code = "TC 103"
      c.enrollment_term = EnrollmentTerm.where(sis_source_id: "T003").first
      c.start_at = DateTime.parse("2011-04-13 00:00:00")
      c.conclude_at = DateTime.parse("2011-05-13 00:00:00")
      c.restrict_enrollments_to_course_dates = true
      c.save!
    end
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "c1,TC 104,Test Course 4,A004,T004,active,2011-04-16 00:00:00,2011-05-16 00:00:00"
    )
    Course.where(sis_source_id: ["c2", "c3"]).each do |c|
      expect(c.account).to eq Account.where(sis_source_id: "A003").first
      expect(c.name).to eq "Test Course 3"
      expect(c.course_code).to eq "TC 103"
      expect(c.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: "T003").first
      expect(c.start_at).to eq DateTime.parse("2011-04-13 00:00:00")
      expect(c.conclude_at).to eq DateTime.parse("2011-05-13 00:00:00")
      expect(c.restrict_enrollments_to_course_dates).to be_truthy
    end
    Course.where(sis_source_id: "c1").each do |c|
      expect(c.account).to eq Account.where(sis_source_id: "A004").first
      expect(c.name).to eq "Test Course 4"
      expect(c.course_code).to eq "TC 104"
      expect(c.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: "T004").first
      expect(c.start_at).to eq DateTime.parse("2011-04-16 00:00:00")
      expect(c.conclude_at).to eq DateTime.parse("2011-05-16 00:00:00")
      expect(c.restrict_enrollments_to_course_dates).to be_truthy
    end
  end

  it "uses the default term if none given" do
    @default_term = @account.default_enrollment_term
    expect(@default_term).to be_present
    @nil_id_term = @account.enrollment_terms.create!(name: "nil")
    @with_id_term = @account.enrollment_terms.create!(name: "test") { |t| t.sis_source_id = "test" }
    process_csv_data_cleanly(
      "course_id,short_name,long_name,status",
      "c1,c1,c1,active"
    )
    @course = @account.courses.where(sis_source_id: "c1").first
    expect(@course.enrollment_term).to eq @default_term
  end

  context "account associations" do
    before do
      process_csv_data_cleanly(
        "account_id,parent_account_id,name,status",
        "A001,,Humanities,active",
        "A002,A001,English,active",
        "A003,A002,English Literature,active",
        "A004,,Awesomeness,active"
      )
    end

    it "changes course account associations when a course account changes" do
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,,active"
      )
      expect(Course.where(sis_source_id: "test_1").first.associated_accounts.map(&:id)).to eq [@account.id]
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,A001,,active"
      )
      expect(Course.where(sis_source_id: "test_1").first.associated_accounts.map(&:id).sort).to eq [Account.where(sis_source_id: "A001").first.id, @account.id].sort
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,A004,,active"
      )
      expect(Course.where(sis_source_id: "test_1").first.associated_accounts.map(&:id).sort).to eq [Account.where(sis_source_id: "A004").first.id, @account.id].sort
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,A003,,active"
      )
      expect(Course.where(sis_source_id: "test_1").first.associated_accounts.map(&:id).sort).to eq [Account.where(sis_source_id: "A003").first.id, Account.where(sis_source_id: "A002").first.id, Account.where(sis_source_id: "A001").first.id, @account.id].sort
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,A001,,active"
      )
      expect(Course.where(sis_source_id: "test_1").first.associated_accounts.map(&:id).sort).to eq [Account.where(sis_source_id: "A001").first.id, @account.id].sort
    end
  end

  it "throws error when restoring a course form deleted account" do
    # create account and course that are active
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,del acc,active"
    )
    process_csv_data_cleanly(
      "course_id,short_name,long_name,status,account_id",
      "C001,del course,del course,active,A001"
    )
    expect(Course.where(sis_source_id: "C001").first.associated_accounts.map(&:id).sort).to eq [Account.where(sis_source_id: "A001").first.id, @account.id].sort

    # delete account and course
    process_csv_data_cleanly(
      "course_id,short_name,long_name,status",
      "C001,del course,del course,deleted"
    )
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,del acc,deleted"
    )
    # restore deleted course
    importer = process_csv_data(
      "course_id,short_name,long_name,status",
      "C001,del course,del course,active"
    )

    expect(importer.errors.map(&:last)).to include "Cannot restore course C001 because the associated account A001 is deleted"
  end

  it "makes workflow_state sticky" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    course = Course.where(sis_source_id: "test_1").first
    expect(course).to be_claimed
    course.process_event("offer")
    course.complete
    expect(course).to be_completed
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    course.reload
    expect(course).to be_completed
  end

  it "allows publishing a course" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,published"
    )
    course = Course.where(sis_source_id: "test_1").first
    expect(course).to be_available
  end

  it "allows publishing an existing course" do
    course = @account.courses.create!(sis_source_id: "test_1", workflow_state: "claimed")
    Course.where(id: course).update_all(stuck_sis_fields: Set.new)
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,published"
    )
    expect(course.reload).to be_available
  end

  it "sets and updates course_format" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,course_format",
      "test_1,TC 101,Test Course 101,,,active,online",
      "test_2,TC 102,Test Course 102,,,active,blended",
      "test_3,TC 103,Test Course 103,,,active,on_campus"
    )
    expect(Course.find_by(sis_source_id: "test_1").course_format).to eq "online"
    expect(Course.find_by(sis_source_id: "test_2").course_format).to eq "blended"
    expect(Course.find_by(sis_source_id: "test_3").course_format).to eq "on_campus"

    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,course_format",
      "test_1,TC 101,Test Course 101,,,active,",
      "test_2,TC 102,Test Course 102,,,active,\"\"",
      "test_3,TC 103,Test Course 103,,,active,blended"
    )
    expect(Course.find_by(sis_source_id: "test_1").course_format).not_to be_present
    expect(Course.find_by(sis_source_id: "test_2").course_format).not_to be_present
    expect(Course.find_by(sis_source_id: "test_3").course_format).to eq "blended"

    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_3,TC 103,Test Course 103,,,active"
    )
    expect(Course.find_by(sis_source_id: "test_3").course_format).to eq "blended"
  end

  it "rejects invalid course_format" do
    importer = process_csv_data(
      "course_id,short_name,long_name,account_id,term_id,status,course_format",
      "test_1,TC 101,Test Course 101,,,active,FAT32"
    )
    expect(importer.errors.map(&:last)).to include "Invalid course_format \"FAT32\" for course test_1"
  end

  it "allows unpublished to be passed for active" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "c1,TC 101,Test Course 1,,T001,unpublished"
    )
    expect(Course.active.where(sis_source_id: "c1").take).to be_present
  end

  it "creates rollback data" do
    sis_user = user_model
    batch1 = @account.sis_batches.create! do |sb|
      sb.data = {}
      sb.user = sis_user
    end
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "data_1,TC 101,Test Course 101,,,active",
      "data_2,TC 102,Test Course 102,,,active",
      batch: batch1
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "student_user,user1,User,Uno,user@example.com,active"
    )
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      "data_2,student_user,student,,active,"
    )
    batch2 = @account.sis_batches.create! do |sb|
      sb.data = {}
      sb.user = sis_user
    end
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "data_1,TC 101,Test Course 101,,,active",
      "data_2,TC 102,Test Course 102,,,deleted",
      batch: batch2
    )
    expect(batch1.roll_back_data.where(previous_workflow_state: "non-existent").count).to eq 2
    expect(batch2.roll_back_data.count).to eq 2
    expect(batch2.roll_back_data.where(context_type: "Course").first.previous_workflow_state).to eq "claimed"
    expect(batch2.roll_back_data.where(context_type: "Course").first.updated_workflow_state).to eq "deleted"
    expect(batch2.roll_back_data.where(context_type: "Enrollment").first.updated_workflow_state).to eq "deleted"
    batch2.restore_states_for_batch
    course = @account.all_courses.where(sis_source_id: "data_2").take
    expect(course.workflow_state).to eq "claimed"
    expect(course.enrollments.take.workflow_state).to eq "active"
  end

  context "blueprint courses" do
    before :once do
      account_model
      @mc = @account.courses.create!(sis_source_id: "blahprint")
      @template = MasterCourses::MasterTemplate.set_as_master_course(@mc)
    end

    it "gives a warning when trying to associate an existing blueprint course" do
      mc2 = @account.courses.create!(sis_source_id: "anothermastercourse")
      MasterCourses::MasterTemplate.set_as_master_course(mc2)
      importer = process_csv_data(
        "course_id,short_name,long_name,status,blueprint_course_id",
        "#{mc2.sis_source_id},shortname,long name,active,#{@mc.sis_source_id}"
      )
      expect(importer.errors.map(&:last)).to include("Cannot associate course \"#{mc2.sis_source_id}\" - is a blueprint course")
    end

    it "gives a warning when trying to associate an already associated course" do
      mc2 = @account.courses.create!(sis_source_id: "anothermastercourse")
      template2 = MasterCourses::MasterTemplate.set_as_master_course(mc2)
      ac = @account.courses.create!(sis_source_id: "anassociatedcourse")
      template2.add_child_course!(ac)
      importer = process_csv_data(
        "course_id,short_name,long_name,status,blueprint_course_id",
        "#{ac.sis_source_id},shortname,long name,active,#{@mc.sis_source_id}"
      )
      expect(importer.errors.map(&:last)).to include("Cannot associate course \"#{ac.sis_source_id}\" - is associated to another blueprint course")
    end

    it "gives a warning when trying to associate to a course not in the account chain" do
      sub_account = @account.sub_accounts.create!
      mc2 = sub_account.courses.create!(sis_source_id: "otheraccountmastercourse")
      MasterCourses::MasterTemplate.set_as_master_course(mc2)

      ac = @account.courses.create!(sis_source_id: "otheraccountcoursetoassociate")

      importer = process_csv_data(
        "course_id,short_name,long_name,status,blueprint_course_id",
        "#{ac.sis_source_id},shortname,long name,active,#{mc2.sis_source_id}"
      )
      expect(importer.errors.map(&:last)).to include("Cannot associate course \"#{ac.sis_source_id}\" - is not in the same or lower account as the blueprint course")
    end

    it "does not fail if a course is already associated to the target" do
      ac = @account.courses.create!(sis_source_id: "anassociatedcourse")
      @template.add_child_course!(ac)
      expect do
        process_csv_data_cleanly(
          "course_id,short_name,long_name,status,blueprint_course_id",
          "#{ac.sis_source_id},shortname,long name,active,#{@mc.sis_source_id}"
        )
      end.not_to raise_error
    end

    it "allows destroying" do
      ac = @account.courses.create!(sis_source_id: "anassociatedcourse")
      child = @template.add_child_course!(ac)
      process_csv_data_cleanly(
        "course_id,short_name,long_name,status,blueprint_course_id",
        "#{ac.sis_source_id},shortname,long name,active,dissociate"
      )
      expect(child.reload.workflow_state).to eq "deleted"
    end

    it "is able to associate courses in bulk" do
      c1 = @account.courses.create!(sis_source_id: "acourse1")
      c2 = @account.courses.create!(sis_source_id: "acourse2")
      mc2 = @account.courses.create!(sis_source_id: "anothermastercourse")
      template2 = MasterCourses::MasterTemplate.set_as_master_course(mc2)
      c3 = @account.courses.create!(sis_source_id: "acourse3")
      process_csv_data_cleanly(
        "course_id,short_name,long_name,status,blueprint_course_id",
        "#{c1.sis_source_id},shortname,long name,active,#{@mc.sis_source_id}",
        "#{c2.sis_source_id},shortname,long name,active,#{@mc.sis_source_id}",
        "#{c3.sis_source_id},shortname,long name,active,#{mc2.sis_source_id}"
      )
      expect(@template.child_subscriptions.active.pluck(:child_course_id)).to match_array([c1.id, c2.id])
      expect(template2.child_subscriptions.active.pluck(:child_course_id)).to eq([c3.id])
    end

    it "gives one warning per row" do
      courses = (1..3).map { |x| @account.courses.create!(sis_source_id: "acourse#{x}") }
      rows = ["course_id,short_name,long_name,status,blueprint_course_id"] +
             courses.map { |c| "#{c.sis_source_id},shortname,long name,active,missingid" }
      importer = process_csv_data(*rows)
      expected = courses.map { |c| "Unknown blueprint course \"missingid\" for course \"#{c.sis_source_id}\"" }
      expect(importer.errors.map(&:last)).to match_array(expected)
    end

    it "tries to queue a migration afterwards" do
      account_admin_user(active_all: true)
      c1 = @account.courses.create!(sis_source_id: "acourse1")
      expect(MasterCourses::MasterMigration).to receive(:start_new_migration!)
        .with(anything, anything, hash_including(priority: 25, retry_later: true))
        .and_call_original
      process_csv_data_cleanly(
        "course_id,short_name,long_name,status,blueprint_course_id",
        "#{c1.sis_source_id},shortname,long name,active,#{@mc.sis_source_id}",
        batch: @account.sis_batches.create!(user: @admin, data: {})
      )
      mm = @template.master_migrations.last
      expect(mm).to be_completed # jobs should have kept running now
    end

    it "tries to queue the migration in another job if one is already running" do
      other_mm = @template.master_migrations.create!(user: @admin)
      @template.active_migration = other_mm
      @template.save!

      account_admin_user(active_all: true)
      c1 = @account.courses.create!(sis_source_id: "acourse1")
      process_csv_data_cleanly(
        "course_id,short_name,long_name,status,blueprint_course_id",
        "#{c1.sis_source_id},shortname,long name,active,#{@mc.sis_source_id}",
        batch: @account.sis_batches.create!(user: @admin, data: {})
      )
      # should wait to requeue
      job = Delayed::Job.last
      expect(job.tag).to eq "MasterCourses::MasterMigration.start_new_migration!"
      expect(job.run_at > 5.minutes.from_now).to be_truthy
      job.update_attribute(:run_at, Time.now.utc)
      other_mm.update_attribute(:workflow_state, "completed")
      run_jobs
      mm = @template.reload.master_migrations.last
      expect(mm).to_not eq other_mm
      expect(mm).to be_completed
    end

    it "sets and updates grade_passback_setting" do
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status,grade_passback_setting",
        "test_1,TC 101,Test Course 101,,,active,disabled",
        "test_2,TC 102,Test Course 102,,,active,not_set",
        "test_3,TC 103,Test Course 103,,,active,nightly_sync"
      )
      expect(Course.where(sis_source_id: "test_1").take.grade_passback_setting).to eq "disabled"
      expect(Course.where(sis_source_id: "test_2").take.grade_passback_setting).to be_nil
      expect(Course.where(sis_source_id: "test_3").take.grade_passback_setting).to eq "nightly_sync"

      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status,grade_passback_setting",
        "test_1,TC 101,Test Course 101,,,active,",
        "test_2,TC 102,Test Course 102,,,active,\"\"",
        "test_3,TC 103,Test Course 103,,,active,nightly_sync"
      )
      expect(Course.where(sis_source_id: "test_1").take.grade_passback_setting).to be_nil
      expect(Course.where(sis_source_id: "test_2").take.grade_passback_setting).to be_nil
      expect(Course.where(sis_source_id: "test_3").take.grade_passback_setting).to eq "nightly_sync"

      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_3,TC 103,Test Course 103,,,active"
      )
      expect(Course.where(sis_source_id: "test_3").take.grade_passback_setting).to eq "nightly_sync"
    end

    it "respects stuck grade_passback setting" do
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status,grade_passback_setting",
        "test_1,TC 101,Test Course 101,,,active,nightly_sync"
      )
      expect((course = Course.where(sis_source_id: "test_1").take).grade_passback_setting).to eq "nightly_sync"
      course.grade_passback_setting = nil
      course.save!

      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status,grade_passback_setting",
        "test_1,TC 101,Test Course 101,,,active,nightly_sync"
      )
      expect(Course.where(sis_source_id: "test_1").take.grade_passback_setting).to be_nil
    end

    describe "homeroom_course setting" do
      it "creates course with homeroom_course setting" do
        process_csv_data_cleanly(
          "course_id,short_name,long_name,account_id,term_id,status,homeroom_course",
          "test_1,TC 101,Test Course 101,,,active,true",
          "test_2,TC 102,Test Course 102,,,active,0",
          "test_3,TC 103,Test Course 103,,,active,"
        )
        expect(Course.where(sis_source_id: "test_1").take).to be_homeroom_course
        expect(Course.where(sis_source_id: "test_2").take).not_to be_homeroom_course
        expect(Course.where(sis_source_id: "test_3").take).not_to be_homeroom_course
      end

      it "updates homeroom course setting" do
        course1 = @account.courses.create!(sis_source_id: "test_1")
        course1.homeroom_course = true
        course1.save!
        course2 = @account.courses.create!(sis_source_id: "test_2")
        process_csv_data_cleanly(
          "course_id,short_name,long_name,account_id,term_id,status,homeroom_course",
          "test_1,TC 101,Test Course 101,,,active,false",
          "test_2,TC 101,Test Course 101,,,active,1"
        )
        expect(course1.reload).not_to be_homeroom_course
        expect(course2.reload).to be_homeroom_course
      end

      it "leaves the setting unchanged if not provided in csv" do
        course1 = @account.courses.create!(sis_source_id: "test_1")
        course1.homeroom_course = true
        course1.save!
        course2 = @account.courses.create!(sis_source_id: "test_2")
        process_csv_data_cleanly(
          "course_id,short_name,long_name,account_id,term_id,status",
          "test_1,TC 101,Test Course 101,,,active",
          "test_2,TC 101,Test Course 101,,,active"
        )
        expect(course1.reload).to be_homeroom_course
        expect(course2.reload).not_to be_homeroom_course
      end
    end

    it "applies an account's course template" do
      @account.root_account.enable_feature!(:course_templates)
      template = @account.courses.create!(name: "Template Course", template: true)
      template.assignments.create!(title: "my assignment")
      @account.update!(course_template: template)
      expect_any_instance_of(ContentMigration).to receive(:queue_migration).with(priority: 25).and_call_original
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,,active"
      )
      run_jobs

      course = @account.courses.where(sis_source_id: "test_1").first
      expect(course.name).to eq "Test Course 101"
      expect(course.assignments.length).to eq 1
      expect(course.assignments.first.title).to eq "my assignment"
      expect(course.content_migrations.first.strand).to eq "sis_import_course_templates"
    end
  end

  it "imports friendly name for elementary account" do
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,Humanities,active"
    )

    account = @account.sub_accounts.where(sis_source_id: "A001").first
    account.enable_as_k5_account!

    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,friendly_name",
      "test_1,TC 101,Test Course 101,A001,,active,george"
    )

    course = @account.all_courses.where(sis_source_id: "test_1").first
    expect(course.name).to eq "Test Course 101"
    expect(course.friendly_name).to eq "george"
  end

  it "does not import friendly name if it's blank" do
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,Humanities,active"
    )

    account = @account.sub_accounts.where(sis_source_id: "A001").first
    account.enable_as_k5_account!

    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,A001,,active"
    )

    course = @account.all_courses.where(sis_source_id: "test_1").first
    expect(course.name).to eq "Test Course 101"
    expect(course.friendly_name).to be_nil
  end

  it "does not import friendly name for not elementary account" do
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,Humanities,active"
    )

    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,friendly_name",
      "test_1,TC 101,Test Course 101,A001,,active,george"
    )

    course = @account.all_courses.where(sis_source_id: "test_1").first
    expect(course.name).to eq "Test Course 101"
    expect(course.friendly_name).to be_nil
  end
end
