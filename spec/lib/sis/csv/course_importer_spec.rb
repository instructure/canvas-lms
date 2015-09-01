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

describe SIS::CSV::CourseImporter do

  before { account_model }

  it 'should skip bad content' do
    before_count = Course.count
    importer = process_csv_data(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C001,Hum101,Humanities,A001,T001,active",
      ",Hum102,Humanities 2,A001,T001,active",
      "C003,Hum102,Humanities 2,A001,T001,inactive",
      "C004,,Humanities 2,A001,T001,active",
      "C005,Hum102,,A001,T001,active"
    )
    expect(Course.count).to eq before_count + 1

    expect(importer.errors).to eq []
    warnings = importer.warnings.map { |r| r.last }
    expect(warnings).to eq ["No course_id given for a course",
                        "Improper status \"inactive\" for course C003",
                        "No short_name given for course C004",
                        "No long_name given for course C005"]
  end

  it "should create new courses" do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active"
    )
    course = @account.courses.where(sis_source_id: "test_1").first
    expect(course.course_code).to eql("TC 101")
    expect(course.name).to eql("Test Course 101")
    expect(course.associated_accounts.map(&:id).sort).to eq [@account.id]
  end

  it "should support term stickiness" do
    process_csv_data_cleanly(
      "term_id,name,status,start_date,end_date",
      "T001,Winter13,active,,",
      "T002,Spring14,active,,",
      "T003,Summer14,active,,",
      "T004,Fall14,active,,"
    )
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,T001,active"
    )
    @account.courses.where(sis_source_id: "test_1").first.tap do |course|
      expect(course.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: 'T001').first
    end
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,T002,active"
    )
    @account.courses.where(sis_source_id: "test_1").first.tap do |course|
      expect(course.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: 'T002').first
      course.enrollment_term = EnrollmentTerm.where(sis_source_id: 'T003').first
      course.save!
    end
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,T004,active"
    )
    @account.courses.where(sis_source_id: "test_1").first.tap do |course|
      expect(course.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: 'T003').first
    end
  end

  it "should support term stickiness from abstract courses" do
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
      expect(course.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: 'T001').first
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
      expect(course.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: 'T002').first
      course.enrollment_term = EnrollmentTerm.where(sis_source_id: 'T003').first
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
      expect(course.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: 'T003').first
    end
  end

  it "shouldn't blow away the account id if it's already set" do
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

  it "should support falling back to a fallback account if the primary one doesn't exist" do
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

  it "should rename courses that have not had their name manually changed" do
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

  it "should not rename courses that have had their names manually changed" do
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

  it 'should override term dates if the start or end dates are set' do
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

  it 'should support start/end date and restriction stickiness' do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "test4,TC 104,Test Course 4,,,active,2011-04-14 00:00:00,2011-05-14 00:00:00"
    )
    @account.courses.where(sis_source_id: "test4").first.tap do |course|
      expect(course.restrict_enrollments_to_course_dates).to be_truthy
      expect(course.start_at).to eq DateTime.parse("2011-04-14 00:00:00")
      expect(course.conclude_at).to eq DateTime.parse("2011-05-14 00:00:00")
      course.restrict_enrollments_to_course_dates = false # should be able to change this without stickying dates
      course.save!
    end

    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "test4,TC 104,Test Course 4,,,active,2012-04-14 00:00:00,2012-05-14 00:00:00"
    )
    @account.courses.where(sis_source_id: "test4").first.tap do |course|
      expect(course.restrict_enrollments_to_course_dates).to be_falsey
      expect(course.start_at).to eq DateTime.parse("2012-04-14 00:00:00")
      expect(course.conclude_at).to eq DateTime.parse("2012-05-14 00:00:00")
      course.start_at = DateTime.parse("2010-04-14 00:00:00")
      course.conclude_at = DateTime.parse("2010-05-14 00:00:00") # now get sticky
      course.save!
    end

    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "test4,TC 104,Test Course 4,,,active,2011-04-14 00:00:00,2011-05-14 00:00:00"
    )
    @account.courses.where(sis_source_id: "test4").first.tap do |course|
      expect(course.restrict_enrollments_to_course_dates).to be_falsey
      expect(course.start_at).to eq DateTime.parse("2010-04-14 00:00:00")
      expect(course.conclude_at).to eq DateTime.parse("2010-05-14 00:00:00")
    end
  end

  it 'should not change templated course names or course codes if the course has those fields marked as sticky' do
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
    Course.where(sis_source_id: ['c1', 'c2', 'c3']).each do |c|
      expect(c.account).to eq Account.where(sis_source_id: 'A001').first
      expect(c.name).to eq 'Test Course 1'
      expect(c.course_code).to eq 'TC 101'
      expect(c.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: 'T001').first
      expect(c.start_at).to eq DateTime.parse("2011-04-14 00:00:00")
      expect(c.conclude_at).to eq DateTime.parse("2011-05-14 00:00:00")
      expect(c.restrict_enrollments_to_course_dates).to be_truthy
    end
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "c1,TC 102,Test Course 2,A002,T002,active,2011-04-12 00:00:00,2011-05-12 00:00:00"
    )
    Course.where(sis_source_id: ['c1', 'c2', 'c3']).each do |c|
      expect(c.account).to eq Account.where(sis_source_id: 'A002').first
      expect(c.name).to eq 'Test Course 2'
      expect(c.course_code).to eq 'TC 102'
      expect(c.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: 'T002').first
      expect(c.start_at).to eq DateTime.parse("2011-04-12 00:00:00")
      expect(c.conclude_at).to eq DateTime.parse("2011-05-12 00:00:00")
      expect(c.restrict_enrollments_to_course_dates).to be_truthy
    end
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "c1,TC 102,Test Course 2,A002,T002,active,,"
    )
    Course.where(sis_source_id: ['c1', 'c2', 'c3']).each do |c|
      expect(c.account).to eq Account.where(sis_source_id: 'A002').first
      expect(c.name).to eq 'Test Course 2'
      expect(c.course_code).to eq 'TC 102'
      expect(c.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: 'T002').first
      expect(c.start_at).to be_nil
      expect(c.conclude_at).to be_nil
      expect(c.restrict_enrollments_to_course_dates).to be_falsey
    end
    Course.where(sis_source_id: 'c1').each do |c|
      c.account = Account.where(sis_source_id: 'A003').first
      c.name = 'Test Course 3'
      c.course_code = 'TC 103'
      c.enrollment_term = EnrollmentTerm.where(sis_source_id: 'T003').first
      c.start_at = DateTime.parse("2011-04-13 00:00:00")
      c.conclude_at = DateTime.parse("2011-05-13 00:00:00")
      c.restrict_enrollments_to_course_dates = true
      c.save!
    end
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "c1,TC 104,Test Course 4,A004,T004,active,2011-04-16 00:00:00,2011-05-16 00:00:00"
    )
    Course.where(sis_source_id: 'c1').each do |c|
      expect(c.account).to eq Account.where(sis_source_id: 'A004').first
      expect(c.name).to eq 'Test Course 3'
      expect(c.course_code).to eq 'TC 103'
      expect(c.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: 'T003').first
      expect(c.start_at).to eq DateTime.parse("2011-04-13 00:00:00")
      expect(c.conclude_at).to eq DateTime.parse("2011-05-13 00:00:00")
      expect(c.restrict_enrollments_to_course_dates).to be_truthy
    end
    Course.where(sis_source_id: ['c2', 'c3']).each do |c|
      expect(c.account).to eq Account.where(sis_source_id: 'A004').first
      expect(c.name).to eq 'Test Course 2'
      expect(c.course_code).to eq 'TC 102'
      expect(c.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: 'T002').first
      expect(c.start_at).to be_nil
      expect(c.conclude_at).to be_nil
      expect(c.restrict_enrollments_to_course_dates).to be_falsey
    end
  end

  it 'should not change templated course names or course codes if the templated course has those fields marked as sticky' do
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
    Course.where(sis_source_id: ['c1', 'c2', 'c3']).each do |c|
      expect(c.account).to eq Account.where(sis_source_id: 'A001').first
      expect(c.name).to eq 'Test Course 1'
      expect(c.course_code).to eq 'TC 101'
      expect(c.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: 'T001').first
      expect(c.start_at).to eq DateTime.parse("2011-04-14 00:00:00")
      expect(c.conclude_at).to eq DateTime.parse("2011-05-14 00:00:00")
      expect(c.restrict_enrollments_to_course_dates).to be_truthy
    end
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "c1,TC 102,Test Course 2,A002,T002,active,2011-04-12 00:00:00,2011-05-12 00:00:00"
    )
    Course.where(sis_source_id: ['c1', 'c2', 'c3']).each do |c|
      expect(c.account).to eq Account.where(sis_source_id: 'A002').first
      expect(c.name).to eq 'Test Course 2'
      expect(c.course_code).to eq 'TC 102'
      expect(c.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: 'T002').first
      expect(c.start_at).to eq DateTime.parse("2011-04-12 00:00:00")
      expect(c.conclude_at).to eq DateTime.parse("2011-05-12 00:00:00")
      expect(c.restrict_enrollments_to_course_dates).to be_truthy
    end
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "c1,TC 102,Test Course 2,A002,T002,active,,"
    )
    Course.where(sis_source_id: ['c1', 'c2', 'c3']).each do |c|
      expect(c.account).to eq Account.where(sis_source_id: 'A002').first
      expect(c.name).to eq 'Test Course 2'
      expect(c.course_code).to eq 'TC 102'
      expect(c.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: 'T002').first
      expect(c.start_at).to be_nil
      expect(c.conclude_at).to be_nil
      expect(c.restrict_enrollments_to_course_dates).to be_falsey
    end
    Course.where(sis_source_id: ['c2', 'c3']).each do |c|
      c.account = Account.where(sis_source_id: 'A003').first
      c.name = 'Test Course 3'
      c.course_code = 'TC 103'
      c.enrollment_term = EnrollmentTerm.where(sis_source_id: 'T003').first
      c.start_at = DateTime.parse("2011-04-13 00:00:00")
      c.conclude_at = DateTime.parse("2011-05-13 00:00:00")
      c.restrict_enrollments_to_course_dates = true
      c.save!
    end
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "c1,TC 104,Test Course 4,A004,T004,active,2011-04-16 00:00:00,2011-05-16 00:00:00"
    )
    Course.where(sis_source_id: ['c2', 'c3']).each do |c|
      expect(c.account).to eq Account.where(sis_source_id: 'A004').first
      expect(c.name).to eq 'Test Course 3'
      expect(c.course_code).to eq 'TC 103'
      expect(c.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: 'T003').first
      expect(c.start_at).to eq DateTime.parse("2011-04-13 00:00:00")
      expect(c.conclude_at).to eq DateTime.parse("2011-05-13 00:00:00")
      expect(c.restrict_enrollments_to_course_dates).to be_truthy
    end
    Course.where(sis_source_id: 'c1').each do |c|
      expect(c.account).to eq Account.where(sis_source_id: 'A004').first
      expect(c.name).to eq 'Test Course 4'
      expect(c.course_code).to eq 'TC 104'
      expect(c.enrollment_term).to eq EnrollmentTerm.where(sis_source_id: 'T004').first
      expect(c.start_at).to eq DateTime.parse("2011-04-16 00:00:00")
      expect(c.conclude_at).to eq DateTime.parse("2011-05-16 00:00:00")
      expect(c.restrict_enrollments_to_course_dates).to be_truthy
    end
  end

  it "should use the default term if none given" do
    @default_term = @account.default_enrollment_term
    expect(@default_term).to be_present
    @nil_id_term = @account.enrollment_terms.create!(:name => "nil")
    @with_id_term = @account.enrollment_terms.create!(:name => "test") { |t| t.sis_source_id = "test" }
    process_csv_data_cleanly(
      "course_id,short_name,long_name,status",
      "c1,c1,c1,active")
    @course = @account.courses.where(sis_source_id: "c1").first
    expect(@course.enrollment_term).to eq @default_term
  end

  context 'account associations' do
    before(:each) do
      process_csv_data_cleanly(
        "account_id,parent_account_id,name,status",
        "A001,,Humanities,active",
        "A002,A001,English,active",
        "A003,A002,English Literature,active",
        "A004,,Awesomeness,active"
      )
    end

    it 'should change course account associations when a course account changes' do
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,,active"
      )
      expect(Course.where(sis_source_id: "test_1").first.associated_accounts.map(&:id)).to eq [@account.id]
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,A001,,active"
      )
      expect(Course.where(sis_source_id: "test_1").first.associated_accounts.map(&:id).sort).to eq [Account.where(sis_source_id: 'A001').first.id, @account.id].sort
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,A004,,active"
      )
      expect(Course.where(sis_source_id: "test_1").first.associated_accounts.map(&:id).sort).to eq [Account.where(sis_source_id: 'A004').first.id, @account.id].sort
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,A003,,active"
      )
      expect(Course.where(sis_source_id: "test_1").first.associated_accounts.map(&:id).sort).to eq [Account.where(sis_source_id: 'A003').first.id, Account.where(sis_source_id: 'A002').first.id, Account.where(sis_source_id: 'A001').first.id, @account.id].sort
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,A001,,active"
      )
      expect(Course.where(sis_source_id: "test_1").first.associated_accounts.map(&:id).sort).to eq [Account.where(sis_source_id: 'A001').first.id, @account.id].sort
    end
  end

  it "should make workflow_state sticky" do
    process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,,active"
    )
    course = Course.where(sis_source_id: "test_1").first
    expect(course).to be_claimed
    course.process_event('offer')
    course.complete
    expect(course).to be_completed
    process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,,active"
    )
    course.reload
    expect(course).to be_completed
  end
end
