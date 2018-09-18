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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe SIS::CSV::SectionImporter do

  before { account_model }

  it 'should skip bad content' do
    before_count = CourseSection.count
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C010,TC 101,Test Course 101,,,active"
    )
    importer = process_csv_data(
      "section_id,course_id,name,start_date,end_date,status",
      "S001,C010,Sec1,,,active",
      "S002,,Sec2,,,active",
      ",C001,Sec2,,,active",
      "S003,C002,Sec1,,,inactive",
      "S004,C002,,,,active",
      "S005,C001,Sec1,,,active"
    )
    expect(CourseSection.count).to eq before_count + 1

    errors = importer.errors.map { |r| r.last }
    expect(errors).to eq ["No course_id given for a section S002",
                      "No section_id given for a section in course C001",
                      "Improper status \"inactive\" for section S003 in course C002",
                      "No name given for section S004 in course C002",
                      "Section S005 references course C001 which doesn't exist"]
  end

  it 'should not die when a course is deleted' do
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
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status",
      "C001,U001,student,1B,active")
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C002,TC 101,Test Course 101,,,deleted"
    )
    importer = process_csv_data(
      "section_id,course_id,name,start_date,end_date,status",
      "1B,C002,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
    )
    expect(importer.errors).to eq []
  end

  it 'should not require a name when section is being deleted' do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C001,TC 101,Test Course 101,,,active"
    )
    importer = process_csv_data(
      "section_id,course_id,name,start_date,end_date,status",
      "section,C001,,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
    )
    expect(importer.errors.first.last).to eq "No name given for section section in course C001"
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "section,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,status",
      "section,C001,,deleted"
    )
    expect(CourseSection.where(sis_source_id: 'section').take.workflow_state).to eq 'deleted'
  end

  it 'should still require a name for new deleted sections' do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C001,TC 101,Test Course 101,,,active"
    )
    importer = process_csv_data(
      "section_id,course_id,name,status",
      "sec1,C001,Sec1,deleted"
    )
    expect(importer.errors).to eq []
  end

  it 'should create rollback data' do
    batch1 = @account.sis_batches.create! { |sb| sb.data = {} }
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C001,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "1B,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "U001,user1,User,Uno,user@example.com,active"
    )
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status",
      "C001,U001,student,1B,active"
    )

    g = Course.where(sis_source_id: 'C001').take.groups.create!(name: 'group')
    g.group_memberships.create!(user: Pseudonym.where(sis_user_id: 'U001').take.user)
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "1B,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,deleted",
      batch: batch1
    )
    # 1. section, 2. enrollment, 3. group_membership
    expect(batch1.roll_back_data.count).to eq 3
    batch1.restore_states_for_batch
    expect(@account.course_sections.where(sis_source_id: '1B').active.count).to eq 1
  end

  it 'should ignore unsupported column account_id' do
    process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "C001,TC 101,Test Course 101,,,active"
    )
    before_count = CourseSection.count
    process_csv_data_cleanly(
        "section_id,course_id,name,start_date,end_date,status,account_id",
        "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active,bogus")
    expect(CourseSection.count).to eq before_count + 1
    expect(CourseSection.last.name).to eq "Sec1"
  end

  it 'should support stickiness' do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C001,TC 101,Test Course 101,,,active"
    )
    before_count = CourseSection.count
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active")
    expect(CourseSection.count).to eq before_count + 1
    expect(CourseSection.last.name).to eq "Sec1"
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "S001,C001,Sec2,2011-1-05 00:00:00,2011-4-14 00:00:00,active")
    expect(CourseSection.count).to eq before_count + 1
    CourseSection.last.tap do |s|
      expect(s.name).to eq "Sec2"
      s.name = "Sec3"
      s.save!
    end
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "S001,C001,Sec4,2011-1-05 00:00:00,2011-4-14 00:00:00,active")
    expect(CourseSection.count).to eq before_count + 1
    expect(CourseSection.last.name).to eq "Sec3"
  end

  it 'should create sections' do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C001,TC 101,Test Course 101,,,active"
    )
    before_count = CourseSection.count
    importer = process_csv_data(
      "section_id,course_id,name,start_date,end_date,status",
      "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active",
      "S002,C001,Sec2,2012-13-05 00:00:00,2012-14-14 00:00:00,active",
      "S003,C002,Sec1,,,active"
    )
    expect(CourseSection.count).to eq before_count + 2

    course = @account.courses.where(sis_source_id: "C001").first

    s1 = course.course_sections.where(sis_source_id: 'S001').first
    expect(s1).not_to be_nil
    expect(s1.name).to eq 'Sec1'
    expect(s1.start_at.to_s(:db)).to eq '2011-01-05 00:00:00'
    expect(s1.end_at.to_s(:db)).to eq '2011-04-14 00:00:00'

    s2 = course.course_sections.where(sis_source_id: 'S002').first
    expect(s2).not_to be_nil
    expect(s2.name).to eq 'Sec2'
    expect(s2.start_at).to be_nil
    expect(s2.end_at).to be_nil

    expect(importer.errors.map{|r|r.last}).to eq ["Bad date format for section S002",
                                                "Section S003 references course C002 which doesn't exist"]
  end

  it 'should override term dates if the start or end dates are set' do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "test1,TC 101,Test Course 1,,,active,,"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,status,start_date,end_date",
      "sec1,test1,Test Course 1,active,,",
      "sec2,test1,Test Course 2,active,,2011-05-14 00:00:00",
      "sec3,test1,Test Course 3,active,2011-04-14 00:00:00,",
      "sec4,test1,Test Course 4,active,2011-04-14 00:00:00,2011-05-14 00:00:00"
    )
    course = @account.courses.where(sis_source_id: 'test1').first
    expect(course.course_sections.where(sis_source_id: "sec1").first.restrict_enrollments_to_section_dates).to be_falsey
    expect(course.course_sections.where(sis_source_id: "sec2").first.restrict_enrollments_to_section_dates).to be_truthy
    expect(course.course_sections.where(sis_source_id: "sec3").first.restrict_enrollments_to_section_dates).to be_truthy
    expect(course.course_sections.where(sis_source_id: "sec4").first.restrict_enrollments_to_section_dates).to be_truthy
  end

  it 'should support start/end date and restriction stickiness' do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
      "test1,TC 101,Test Course 1,,,active,,"
    )
    course = @account.courses.where(sis_source_id: 'test1').first
    process_csv_data_cleanly(
      "section_id,course_id,name,status,start_date,end_date",
      "sec4,test1,Test Course 4,active,2011-04-14 00:00:00,2011-05-14 00:00:00"
    )
    course.course_sections.where(sis_source_id: "sec4").first.tap do |section|
      expect(section.restrict_enrollments_to_section_dates).to be_truthy
      expect(section.start_at).to eq DateTime.parse("2011-04-14 00:00:00")
      expect(section.end_at).to eq DateTime.parse("2011-05-14 00:00:00")
      section.restrict_enrollments_to_section_dates = false
      section.start_at = DateTime.parse("2010-04-14 00:00:00")
      section.end_at = DateTime.parse("2010-05-14 00:00:00")
      section.save!
    end
    process_csv_data_cleanly(
      "section_id,course_id,name,status,start_date,end_date",
      "sec4,test1,Test Course 4,active,2011-04-14 00:00:00,2011-05-14 00:00:00"
    )
    course.course_sections.where(sis_source_id: "sec4").first.tap do |section|
      expect(section.restrict_enrollments_to_section_dates).to be_falsey
      expect(section.start_at).to eq DateTime.parse("2010-04-14 00:00:00")
      expect(section.end_at).to eq DateTime.parse("2010-05-14 00:00:00")
    end
  end


  it 'should verify xlist files' do
    importer = process_csv_data(
      "xlist_course_id,section_id,status",
      ",S001,active",
      "X001,,active",
      "X001,S001,",
      "X001,S001,baleeted"
    )
    expect(importer.errors.map{|r|r.last}).to eq ["No xlist_course_id given for a cross-listing",
                                                  "No section_id given for a cross-listing",
                                                  'Improper status "" for a cross-listing',
                                                  'Improper status "baleeted" for a cross-listing']
    expect(@account.courses.size).to eq 0
  end

  it 'should work with xlists with no xlist course' do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C001,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active",
      "S002,C001,Sec2,2012-12-05 00:00:00,2012-12-14 00:00:00,active"
    )

    course = @account.courses.where(sis_source_id: "C001").first
    s1 = course.course_sections.where(sis_source_id: "S001").first
    expect(s1).not_to be_nil
    expect(s1.nonxlist_course).to be_nil
    expect(course.course_sections.where(sis_source_id: "S002").first).not_to be_nil
    expect(course.associated_accounts.map(&:id).sort).to eq [@account.id]
    expect(@account.courses.where(sis_source_id: "X001").first).to be_nil

    process_csv_data_cleanly(
      "xlist_course_id,section_id,status",
      "X001,S001,active"
    )

    xlist_course = @account.courses.where(sis_source_id: "X001").first
    expect(xlist_course.associated_accounts.map(&:id).sort).to eq [@account.id]
    course = @account.courses.where(sis_source_id: "C001").first
    expect(course.associated_accounts.map(&:id).sort).to eq [@account.id]
    s1 = xlist_course.course_sections.where(sis_source_id: "S001").first
    expect(s1).not_to be_nil
    expect(s1.nonxlist_course).to eql(course)
    expect(course.course_sections.where(sis_source_id: "S001").first).to be_nil
    expect(course.course_sections.where(sis_source_id: "S002").first).not_to be_nil

    process_csv_data_cleanly(
      "xlist_course_id,section_id,status",
      "X001,S001,deleted"
    )

    xlist_course = @account.courses.where(sis_source_id: "X001").first
    course = @account.courses.where(sis_source_id: "C001").first
    expect(xlist_course.course_sections.where(sis_source_id: "S001").first).to be_nil
    expect(xlist_course.associated_accounts.map(&:id).sort).to eq [@account.id]
    s1 = course.course_sections.where(sis_source_id: "S001").first
    expect(s1).not_to be_nil
    expect(s1.nonxlist_course).to be_nil
    expect(course.course_sections.where(sis_source_id: "S002").first).not_to be_nil
    expect(course.associated_accounts.map(&:id).sort).to eq [@account.id]

    expect(xlist_course.name).to eq "Test Course 101"
    expect(xlist_course.short_name).to eq "TC 101"
    expect(xlist_course.sis_source_id).to eq "X001"
    expect(xlist_course.root_account_id).to eq @account.id
    expect(xlist_course.account_id).to eq @account.id
    expect(xlist_course.workflow_state).to eq "claimed"
  end

  it 'should preserve data into copied xlist courses' do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C001,TC 101,Test Course 101,,,active",
      "C002,TC 102,Test Course 102,,,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active",
      "S002,C001,Sec2,2012-12-05 00:00:00,2012-12-14 00:00:00,active",
      "S003,C001,Sec3,2012-12-05 00:00:00,2012-12-14 00:00:00,active",
      "S004,C002,Sec4,2012-12-05 00:00:00,2012-12-14 00:00:00,active",
      "S005,C002,Sec5,2012-12-05 00:00:00,2012-12-14 00:00:00,active"
    )
    expect(@account.courses.where(sis_source_id: "C001").first.deleted?).to be_falsey
    expect(@account.courses.where(sis_source_id: "C002").first.deleted?).to be_falsey
    process_csv_data_cleanly(
      "xlist_course_id,section_id,status",
      "X001,S001,active",
      "X001,S002,active",
      "X002,S004,active",
      "X002,S005,active"
    )
    expect(@account.courses.where(sis_source_id: "C001").first.deleted?).to be_falsey
    expect(@account.courses.where(sis_source_id: "C002").first.deleted?).to be_falsey
    expect(@account.courses.where(sis_source_id: "X001").first.deleted?).to be_falsey
    expect(@account.courses.where(sis_source_id: "X002").first.deleted?).to be_falsey
    expect(@account.courses.where(sis_source_id: "X001").first.name).to eq "Test Course 101"
    expect(@account.courses.where(sis_source_id: "X002").first.name).to eq "Test Course 102"
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C001,TC 103,Test Course 103,,,active",
      "C002,TC 104,Test Course 104,,,active"
    )
    expect(@account.courses.where(sis_source_id: "C001").first.deleted?).to be_falsey
    expect(@account.courses.where(sis_source_id: "C002").first.deleted?).to be_falsey
    expect(@account.courses.where(sis_source_id: "X001").first.deleted?).to be_falsey
    expect(@account.courses.where(sis_source_id: "X002").first.deleted?).to be_falsey
    expect(@account.courses.where(sis_source_id: "X001").first.name).to eq "Test Course 103"
    expect(@account.courses.where(sis_source_id: "X002").first.name).to eq "Test Course 104"
    process_csv_data_cleanly(
      "xlist_course_id,section_id,status",
      "X001,S001,deleted",
      "X001,S002,deleted",
      "X002,S004,deleted",
      "X002,S005,deleted"
    )
    expect(@account.courses.where(sis_source_id: "C001").first.deleted?).to be_falsey
    expect(@account.courses.where(sis_source_id: "C002").first.deleted?).to be_falsey
    expect(@account.courses.where(sis_source_id: "X001").first.deleted?).to be_falsey
    expect(@account.courses.where(sis_source_id: "X002").first.deleted?).to be_falsey
  end

  it 'should work with xlists with an xlist course defined' do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "X001,TC 102,Test Course 102,,,active",
      "C001,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active",
      "S002,C001,Sec2,2012-12-05 00:00:00,2012-12-14 00:00:00,active"
    )

    course = @account.courses.where(sis_source_id: "C001").first
    s1 = course.course_sections.where(sis_source_id: "S001").first
    expect(s1).not_to be_nil
    expect(s1.nonxlist_course).to be_nil
    expect(course.course_sections.where(sis_source_id: "S002").first).not_to be_nil
    expect(@account.courses.where(sis_source_id: "X001").first).not_to be_nil

    process_csv_data_cleanly(
      "xlist_course_id,section_id,status",
      "X001,S001,active"
    )

    xlist_course = @account.courses.where(sis_source_id: "X001").first
    course = @account.courses.where(sis_source_id: "C001").first
    s1 = xlist_course.course_sections.where(sis_source_id: "S001").first
    expect(s1).not_to be_nil
    expect(s1.nonxlist_course).to eql(course)
    expect(course.course_sections.where(sis_source_id: "S001").first).to be_nil
    expect(course.course_sections.where(sis_source_id: "S002").first).not_to be_nil

    process_csv_data_cleanly(
      "xlist_course_id,section_id,status",
      "X001,S001,deleted"
    )

    xlist_course = @account.courses.where(sis_source_id: "X001").first
    course = @account.courses.where(sis_source_id: "C001").first
    expect(xlist_course.course_sections.where(sis_source_id: "S001").first).to be_nil
    s1 = course.course_sections.where(sis_source_id: "S001").first
    expect(s1).not_to be_nil
    expect(s1.nonxlist_course).to be_nil
    expect(course.course_sections.where(sis_source_id: "S002").first).not_to be_nil

    expect(xlist_course.name).to eq "Test Course 102"
  end

  it 'should work with xlist courses in crazy orders' do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C001,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active",
      "S002,C001,Sec2,2011-1-05 00:00:00,2011-4-14 00:00:00,active",
      "S003,C001,Sec3,2011-1-05 00:00:00,2011-4-14 00:00:00,active",
      "S004,C001,Sec4,2011-1-05 00:00:00,2011-4-14 00:00:00,active",
      "S005,C001,Sec5,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
    )
    process_csv_data_cleanly(
      "xlist_course_id,section_id,status",
      "X001,S001,active",
      "X001,S002,active",
      "X001,S003,active",
      "X002,S004,active",
      "X001,S005,active"
    )

    xlist_course_1 = @account.courses.where(sis_source_id: "X001").first
    xlist_course_2 = @account.courses.where(sis_source_id: "X002").first
    expect(xlist_course_1.course_sections.where(sis_source_id: "S001").first).not_to be_nil
    expect(xlist_course_1.course_sections.where(sis_source_id: "S002").first).not_to be_nil
    expect(xlist_course_1.course_sections.where(sis_source_id: "S003").first).not_to be_nil
    expect(xlist_course_2.course_sections.where(sis_source_id: "S004").first).not_to be_nil
    expect(xlist_course_1.course_sections.where(sis_source_id: "S005").first).not_to be_nil
  end

  it 'should be idempotent with active xlists' do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C001,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
    )
    3.times do
      process_csv_data_cleanly(
        "xlist_course_id,section_id,status",
        "X001,S001,active"
      )

      xlist_course = @account.courses.where(sis_source_id: "X001").first
      course = @account.courses.where(sis_source_id: "C001").first
      s1 = xlist_course.course_sections.where(sis_source_id: "S001").first
      expect(s1).not_to be_nil
      expect(s1.nonxlist_course).to eql(course)
    end
  end

  it 'should be idempotent with deleted xlists' do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C001,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
    )
    process_csv_data_cleanly(
      "xlist_course_id,section_id,status",
      "X001,S001,active"
    )

    xlist_course = @account.courses.where(sis_source_id: "X001").first
    course = @account.courses.where(sis_source_id: "C001").first
    s1 = xlist_course.course_sections.where(sis_source_id: "S001").first
    expect(s1).not_to be_nil
    expect(s1.nonxlist_course).to eql(course)

    3.times do
      process_csv_data_cleanly(
        "xlist_course_id,section_id,status",
        "X001,S001,deleted"
      )

      course = @account.courses.where(sis_source_id: "C001").first
      s1 = course.course_sections.where(sis_source_id: "S001").first
      expect(s1).not_to be_nil
      expect(s1.nonxlist_course).to be_nil
    end
  end

  it 'should be able to move around a section and then uncrosslist back to the original' do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C001,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
    )
    3.times do |i|
      process_csv_data_cleanly(
        "xlist_course_id,section_id,status",
        "X00#{i},S001,active"
      )

      xlist_course = @account.courses.where(sis_source_id: "X00#{i}").first
      course = @account.courses.where(sis_source_id: "C001").first
      s1 = xlist_course.course_sections.where(sis_source_id: "S001").first
      expect(s1).not_to be_nil
      expect(s1.nonxlist_course).to eql(course)
      expect(s1.course).to eql(xlist_course)
      expect(s1.crosslisted?).to be_truthy
    end
    process_csv_data_cleanly(
      "xlist_course_id,section_id,status",
      "X101,S001,deleted"
    )

    course = @account.courses.where(sis_source_id: "C001").first
    s1 = course.course_sections.where(sis_source_id: "S001").first
    expect(s1).not_to be_nil
    expect(s1.nonxlist_course).to be_nil
    expect(s1.course).to eql(course)
    expect(s1.crosslisted?).to be_falsey
  end

  it 'should be able to handle additional section updates and not screw up the crosslisting' do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C001,TC 101,Test Course 101,,,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
    )
    process_csv_data_cleanly(
      "xlist_course_id,section_id,status",
      "X001,S001,active"
    )
    xlist_course = @account.courses.where(sis_source_id: "X001").first
    course = @account.courses.where(sis_source_id: "C001").first
    s1 = xlist_course.course_sections.where(sis_source_id: "S001").first
    expect(s1).not_to be_nil
    expect(s1.nonxlist_course).to eql(course)
    expect(s1.course).to eql(xlist_course)
    expect(s1.crosslisted?).to be_truthy
    expect(s1.name).to eq "Sec1"
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "S001,C001,Sec2,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
    )
    xlist_course = @account.courses.where(sis_source_id: "X001").first
    course = @account.courses.where(sis_source_id: "C001").first
    s1 = xlist_course.course_sections.where(sis_source_id: "S001").first
    expect(s1).not_to be_nil
    expect(s1.nonxlist_course).to eql(course)
    expect(s1.course).to eql(xlist_course)
    expect(s1.crosslisted?).to be_truthy
    expect(s1.name).to eq "Sec2"
  end

  it 'should be able to move a non-crosslisted section between courses' do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C001,TC 101,Test Course 101,,,active",
      "C002,TC 102,Test Course 102,,,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
    )
    course1 = @account.courses.where(sis_source_id: "C001").first
    course2 = @account.courses.where(sis_source_id: "C002").first
    s1 = course1.course_sections.where(sis_source_id: "S001").first
    expect(s1.course).to eql(course1)
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "S001,C002,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
    )
    course1.reload
    course2.reload
    s1.reload
    expect(s1.course).to eql(course2)
  end

  it 'should uncrosslist a section if it is getting moved from the original course' do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C001,TC 101,Test Course 101,,,active",
      "C002,TC 102,Test Course 102,,,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
    )
    process_csv_data_cleanly(
      "xlist_course_id,section_id,status",
      "X001,S001,active"
    )
    xlist_course = @account.courses.where(sis_source_id: "X001").first
    course1 = @account.courses.where(sis_source_id: "C001").first
    course2 = @account.courses.where(sis_source_id: "C002").first
    s1 = xlist_course.course_sections.where(sis_source_id: "S001").first
    expect(s1).not_to be_nil
    expect(s1.nonxlist_course).to eql(course1)
    expect(s1.course).to eql(xlist_course)
    expect(s1.crosslisted?).to be_truthy
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "S001,C002,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
    )
    s1.reload
    expect(s1.nonxlist_course).to be_nil
    expect(s1.course).to eql(course2)
    expect(s1.crosslisted?).to be_falsey
  end

  it 'should uncrosslist a section if the course has been deleted' do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C001,TC 101,Test Course 101,,,active",
      "C002,TC 102,Test Course 102,,,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
    )
    process_csv_data_cleanly(
      "xlist_course_id,section_id,status",
      "X001,S001,active"
    )
    xlist_course = @account.courses.where(sis_source_id: "X001").first
    course1 = @account.courses.where(sis_source_id: "C001").first
    s1 = xlist_course.course_sections.where(sis_source_id: "S001").first
    expect(s1).not_to be_nil
    expect(s1.nonxlist_course).to eql(course1)
    expect(s1.course).to eql(xlist_course)
    expect(s1.crosslisted?).to be_truthy
    xlist_course.destroy
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
    )
    s1.reload
    expect(s1.nonxlist_course).to be_nil
    expect(s1.course).to eql(course1)
    expect(s1.crosslisted?).to be_falsey
  end

  it 'should leave a section alone if a section has been crosslisted manually' do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C001,TC 101,Test Course 101,,,active",
      "C002,TC 102,Test Course 102,,,active",
      "C003,TC 103,Test Course 103,,,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
    )

    def with_section(&block)
      CourseSection.where(root_account_id: @account, sis_source_id: 'S001').first.tap(&block)
    end

    def check_section_crosslisted(sis_id)
      with_section do |s|
        expect(s.course.sis_source_id).to eq sis_id
        expect(s.nonxlist_course.sis_source_id).to eq 'C001'
      end
    end

    def check_section_not_crosslisted
      with_section do |s|
        expect(s.course.sis_source_id).to eq 'C001'
        expect(s.nonxlist_course).to be_nil
      end
    end

    check_section_not_crosslisted
    process_csv_data_cleanly(
      "xlist_course_id,section_id,status",
      "C002,S001,active"
    )
    check_section_crosslisted 'C002'
    process_csv_data_cleanly(
      "xlist_course_id,section_id,status",
      "C002,S001,deleted"
    )
    check_section_not_crosslisted
    with_section do |s|
      s.crosslist_to_course(Course.where(root_account_id: @account, sis_source_id: 'C002').first)
    end
    check_section_crosslisted 'C002'
    process_csv_data_cleanly(
      "xlist_course_id,section_id,status",
      "C002,S001,deleted"
    )
    check_section_crosslisted 'C002'
    process_csv_data_cleanly(
      "xlist_course_id,section_id,status",
      "C003,S001,active"
    )
    check_section_crosslisted 'C002'
    with_section do |s|
      s.uncrosslist
      s.clear_sis_stickiness :course_id
      s.save!
    end
    check_section_not_crosslisted
    process_csv_data_cleanly(
      "xlist_course_id,section_id,status",
      "C003,S001,active"
    )
    check_section_crosslisted 'C003'
    process_csv_data_cleanly(
      "xlist_course_id,section_id,status",
      "C003,S001,deleted"
    )
    check_section_not_crosslisted
  end

  it 'should leave a section alone if a section has been decrosslisted manually' do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C001,TC 101,Test Course 101,,,active",
      "C002,TC 102,Test Course 102,,,active",
      "C003,TC 103,Test Course 103,,,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
    )

    def with_section(&block)
      CourseSection.where(root_account_id: @account, sis_source_id: 'S001').first.tap(&block)
    end

    def check_section_crosslisted(sis_id)
      with_section do |s|
        expect(s.course.sis_source_id).to eq sis_id
        expect(s.nonxlist_course.sis_source_id).to eq 'C001'
      end
    end

    def check_section_not_crosslisted
      with_section do |s|
        expect(s.course.sis_source_id).to eq 'C001'
        expect(s.nonxlist_course).to be_nil
      end
    end

    check_section_not_crosslisted
    process_csv_data_cleanly(
      "xlist_course_id,section_id,status",
      "C002,S001,active"
    )
    check_section_crosslisted 'C002'
    with_section { |s| s.uncrosslist }
    check_section_not_crosslisted
    process_csv_data_cleanly(
      "xlist_course_id,section_id,status",
      "C002,S001,active"
    )
    with_section do |s|
      s.clear_sis_stickiness :course_id
      s.save!
    end
    check_section_not_crosslisted
    process_csv_data_cleanly(
      "xlist_course_id,section_id,status",
      "C002,S001,active"
    )
    check_section_crosslisted 'C002'
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
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "C001,TC 101,Test Course 101,,,active",
        "C002,TC 101,Test Course 101,A001,,active",
        "C003,TC 101,Test Course 101,A002,,active",
        "C004,TC 101,Test Course 101,A003,,active",
        "C005,TC 101,Test Course 101,A004,,active"
      )
    end

    it 'should change course account associations when a section is not crosslisted and the original section\'s course changes via sis' do
      process_csv_data_cleanly(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C003,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
      )
      expect(Course.where(sis_source_id: "C003").first.associated_accounts.map(&:id).sort).to eq [@account.id, Account.where(sis_source_id: 'A001').first.id, Account.where(sis_source_id: 'A002').first.id].sort
      expect(CourseSection.where(sis_source_id: "S001").first.course_account_associations.map(&:account_id).sort).to eq [@account.id, Account.where(sis_source_id: 'A001').first.id, Account.where(sis_source_id: 'A002').first.id].sort
      expect(Course.where(sis_source_id: "C002").first.associated_accounts.map(&:id).sort).to eq [Account.where(sis_source_id: 'A001').first.id, @account.id].sort
      process_csv_data_cleanly(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C002,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
      )
      expect(Course.where(sis_source_id: "C003").first.associated_accounts.map(&:id).sort).to eq [@account.id, Account.where(sis_source_id: 'A001').first.id, Account.where(sis_source_id: 'A002').first.id].sort
      expect(Course.where(sis_source_id: "C002").first.associated_accounts.map(&:id).sort).to eq [Account.where(sis_source_id: 'A001').first.id, @account.id].sort
      expect(CourseSection.where(sis_source_id: "S001").first.course_account_associations.map(&:account_id).sort).to eq [Account.where(sis_source_id: 'A001').first.id, @account.id].sort
    end

    it 'should change course account associations when a section is crosslisted and the original section\'s course changes via sis' do
      process_csv_data_cleanly(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C002,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
      )
      expect(Course.where(sis_source_id: "C002").first.associated_accounts.map(&:id).sort).to eq [@account.id, Account.where(sis_source_id: 'A001').first.id].sort
      expect(CourseSection.where(sis_source_id: "S001").first.course_account_associations.map(&:account_id).sort).to eq [@account.id, Account.where(sis_source_id: 'A001').first.id].sort
      process_csv_data_cleanly(
        "xlist_course_id,section_id,status",
        "X001,S001,active"
      )
      expect(Course.where(sis_source_id: "C002").first.associated_accounts.map(&:id).sort).to eq [Account.where(sis_source_id: 'A001').first.id, @account.id].sort
      expect(Course.where(sis_source_id: "X001").first.associated_accounts.map(&:id).sort).to eq [Account.where(sis_source_id: 'A001').first.id, @account.id].sort
      expect(CourseSection.where(sis_source_id: "S001").first.course_account_associations.map(&:account_id).sort).to eq [@account.id, Account.where(sis_source_id: 'A001').first.id].sort
      process_csv_data_cleanly(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C003,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
      )
      expect(Course.where(sis_source_id: "C003").first.associated_accounts.map(&:id).sort).to eq [@account.id, Account.where(sis_source_id: 'A001').first.id, Account.where(sis_source_id: 'A002').first.id].sort
      expect(Course.where(sis_source_id: "C002").first.associated_accounts.map(&:id).sort).to eq [Account.where(sis_source_id: 'A001').first.id, @account.id].sort
      expect(Course.where(sis_source_id: "X001").first.associated_accounts.map(&:id).sort).to eq [Account.where(sis_source_id: 'A001').first.id, @account.id].sort
      expect(CourseSection.where(sis_source_id: "S001").first.course_account_associations.map(&:account_id).sort).to eq [@account.id, Account.where(sis_source_id: 'A001').first.id, Account.where(sis_source_id: 'A002').first.id].sort
    end
  end

end
