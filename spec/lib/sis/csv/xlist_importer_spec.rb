#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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

describe SIS::CSV::XlistImporter do

  before { account_model }

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

    it 'should have proper account associations when new' do
      process_csv_data_cleanly(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C002,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
      )
      process_csv_data_cleanly(
        "xlist_course_id,section_id,status",
        "X001,S001,active"
      )
      Course.where(sis_source_id: "X001").first.associated_accounts.map(&:id).sort.should == [Account.where(sis_source_id: 'A001').first.id, @account.id].sort
      process_csv_data_cleanly(
        "xlist_course_id,section_id,status",
        "X001,S001,deleted"
      )
      Course.where(sis_source_id: "X001").first.associated_accounts.map(&:id).sort.should == [Account.where(sis_source_id: 'A001').first.id, @account.id].sort
    end

    it 'should have proper account associations when being undeleted' do
      process_csv_data_cleanly(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C002,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active",
        "S002,C002,Sec2,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
      )
      process_csv_data_cleanly(
        "xlist_course_id,section_id,status",
        "X001,S001,active"
      )
      Course.where(sis_source_id: "X001").first.deleted?.should be_false
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "X001,TC 101,Test Course 101,,,deleted"
      )
      Course.where(sis_source_id: "X001").first.deleted?.should be_true
      process_csv_data_cleanly(
        "xlist_course_id,section_id,status",
        "X001,S002,active"
      )
      Course.where(sis_source_id: "X001").first.deleted?.should be_false
      Course.where(sis_source_id: "X001").first.associated_accounts.map(&:id).sort.should == [Account.where(sis_source_id: 'A001').first.id, @account.id].sort
    end

    it 'should have proper account associations when a section is added and then removed' do
      process_csv_data_cleanly(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C005,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
      )
      Course.where(sis_source_id: "C005").first.associated_accounts.map(&:id).sort.should == [Account.where(sis_source_id: 'A004').first.id, @account.id].sort
      Course.where(sis_source_id: "C002").first.associated_accounts.map(&:id).sort.should == [Account.where(sis_source_id: 'A001').first.id, @account.id].sort
      process_csv_data_cleanly(
        "xlist_course_id,section_id,status",
        "C002,S001,active"
      )
      Course.where(sis_source_id: "C005").first.associated_accounts.map(&:id).should == [Account.where(sis_source_id: 'A004').first.id, @account.id]
      Course.where(sis_source_id: "C002").first.associated_accounts.map(&:id).sort.should == [Account.where(sis_source_id: 'A001').first.id, Account.where(sis_source_id: 'A004').first.id, @account.id].sort
      process_csv_data_cleanly(
        "xlist_course_id,section_id,status",
        "C002,S001,deleted"
      )
      Course.where(sis_source_id: "C005").first.associated_accounts.map(&:id).sort.should == [Account.where(sis_source_id: 'A004').first.id, @account.id].sort
      Course.where(sis_source_id: "C002").first.associated_accounts.map(&:id).sort.should == [Account.where(sis_source_id: 'A001').first.id, @account.id].sort
    end

    it 'should get account associations updated when the template course is updated' do
      process_csv_data_cleanly(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
      )
      process_csv_data_cleanly(
        "xlist_course_id,section_id,status",
        "X001,S001,active"
      )
      Course.where(sis_source_id: "C001").first.associated_accounts.map(&:id).should == [@account.id]
      Course.where(sis_source_id: "X001").first.associated_accounts.map(&:id).should == [@account.id]
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "C001,TC 101,Test Course 101,A004,,active"
      )
      Course.where(sis_source_id: "C001").first.associated_accounts.map(&:id).sort.should == [Account.where(sis_source_id: 'A004').first.id, @account.id].sort
      Course.where(sis_source_id: "X001").first.associated_accounts.map(&:id).sort.should == [Account.where(sis_source_id: 'A004').first.id, @account.id].sort
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "C001,TC 101,Test Course 101,A001,,active"
      )
      Course.where(sis_source_id: "C001").first.associated_accounts.map(&:id).sort.should == [Account.where(sis_source_id: 'A001').first.id, @account.id].sort
      Course.where(sis_source_id: "X001").first.associated_accounts.map(&:id).sort.should == [Account.where(sis_source_id: 'A001').first.id, @account.id].sort
    end

    it 'should import active enrollments with states based on enrollment date restrictions' do
      process_csv_data_cleanly(
        "term_id,name,status,start_date,end_date",
        "T001,Winter13,active,#{2.days.from_now.strftime("%Y-%m-%d 00:00:00")},#{4.days.from_now.strftime("%Y-%m-%d 00:00:00")}"
      )
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "C001,TC 101,Test Course 101,,T001,active"
      )
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user@example.com,active"
      )
      process_csv_data_cleanly(
        "course_id,user_id,role,section_id,status,associated_user_id",
        "C001,user_1,student,,active,"
      )
      course = Course.where(sis_source_id: "C001").first
      course.enrollments.length.should == 1
      course.enrollments.first.state_based_on_date.should == :inactive
    end

    it "should allow enrollments on crosslisted sections' original course" do
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user@example.com,active"
      )
      process_csv_data_cleanly(
        "section_id,course_id,name,status,start_date,end_date",
        "S001,C001,Sec1,active,,"
      )
      process_csv_data_cleanly(
        "course_id,user_id,role,section_id,status,associated_user_id",
        "C001,user_1,student,S001,active,"
      )
      @account.courses.where(sis_source_id: "C001").first.students.first.name.should == "User Uno"
      @account.courses.where(sis_source_id: "X001").first.should be_nil
      process_csv_data_cleanly(
        "xlist_course_id,section_id,status",
        "X001,S001,active"
      )
      process_csv_data_cleanly(
        "course_id,user_id,role,section_id,status,associated_user_id",
        "C001,user_1,student,S001,active,"
      )
      @account.courses.where(sis_source_id: "C001").first.students.size.should == 0
      @account.courses.where(sis_source_id: "X001").first.students.first.name.should == "User Uno"
    end

  end

end
