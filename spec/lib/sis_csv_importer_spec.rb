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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

def gen_ssha_password(password)
  salt = ActiveSupport::SecureRandom.random_bytes(10)
  "{SSHA}" + Base64.encode64(Digest::SHA1.digest(password+salt).unpack('H*').first+salt).gsub(/\s/, '')
end

describe SIS::CSV::Import do
  before do
    account_model
  end

  it "should error files with unknown headers" do
    importer = process_csv_data(
      "course_id,randomness,smelly",
      "test_1,TC 101,Test Course 101,,,active"
    )
    importer.errors.first.last.should == "Couldn't find Canvas CSV import headers"
  end

  it "should work for a mass import" do
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "U001,user1,User,One,user1@example.com,active",
      "U002,user2,User,Two,user2@example.com,active",
      "U003,user3,User,Three,user3@example.com,active",
      "U004,user4,User,Four,user4@example.com,active",
      "U005,user5,User,Five,user5@example.com,active",
      "U006,user6,User,Six,user6@example.com,active",
      "U007,user7,User,Seven,user7@example.com,active",
      "U008,user8,User,Eight,user8@example.com,active",
      "U009,user9,User,Nine,user9@example.com,active",
      "U010,user10,User,Ten,user10@example.com,active",
      "U011,user11,User,Eleven,user11@example.com,deleted"
    )
    process_csv_data_cleanly(
      "term_id,name,status,start_date,end_date",
      "T001,Term 1,active,,",
      "T002,Term 2,active,,",
      "T003,Term 3,active,,"
    )
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C001,C001,Test Course 1,,T001,active",
      "C002,C002,Test Course 2,,T001,deleted",
      "C003,C003,Test Course 3,,T002,deleted",
      "C004,C004,Test Course 4,,T002,deleted",
      "C005,C005,Test Course 5,,T003,active",
      "C006,C006,Test Course 6,,T003,active",
      "C007,C007,Test Course 7,,T003,active",
      "C008,C008,Test Course 8,,T003,active",
      "C009,C009,Test Course 9,,T003,active",
      "C001S,C001S,Test search Course 1,,T001,active",
      "C002S,C002S,Test search Course 2,,T001,deleted",
      "C003S,C003S,Test search Course 3,,T002,deleted",
      "C004S,C004S,Test search Course 4,,T002,deleted",
      "C005S,C005S,Test search Course 5,,T003,active",
      "C006S,C006S,Test search Course 6,,T003,active",
      "C007S,C007S,Test search Course 7,,T003,active",
      "C008S,C008S,Test search Course 8,,T003,active",
      "C009S,C009S,Test search Course 9,,T003,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,start_date,end_date,status",
      "S001,C001,Sec1,,,active",
      "S002,C002,Sec2,,,active",
      "S003,C003,Sec3,,,active",
      "S004,C004,Sec4,,,active",
      "S005,C005,Sec5,,,active",
      "S006,C006,Sec6,,,active",
      "S007,C007,Sec7,,,deleted",
      "S008,C001,Sec8,,,deleted",
      "S009,C008,Sec9,,,active",
      "S001S,C001S,Sec1,,,active",
      "S002S,C002S,Sec2,,,active",
      "S003S,C003S,Sec3,,,active",
      "S004S,C004S,Sec4,,,active",
      "S005S,C005S,Sec5,,,active",
      "S006S,C006S,Sec6,,,active",
      "S007S,C007S,Sec7,,,deleted",
      "S008S,C001S,Sec8,,,deleted",
      "S009S,C008S,Sec9,,,active"
    )
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id",
      ",U001,student,S001,active,",
      ",U002,student,S002,active,",
      ",U003,student,S003,active,",
      ",U004,student,S004,active,",
      ",U005,student,S005,active,",
      ",U006,student,S006,deleted,",
      ",U007,student,S007,active,",
      ",U008,student,S008,active,",
      ",U009,student,S005,deleted,",
      ",U001,student,S001S,active,",
      ",U002,student,S002S,active,",
      ",U003,student,S003S,active,",
      ",U004,student,S004S,active,",
      ",U005,student,S005S,active,",
      ",U006,student,S006S,deleted,",
      ",U007,student,S007S,active,",
      ",U008,student,S008S,active,",
      ",U009,student,S005S,deleted,"
    )
    process_csv_data_cleanly(
      "group_id,name,account_id,status",
      "G001,Group 1,,available",
      "G002,Group 2,,deleted",
      "G003,Group 3,,closed"
    )
  end

  it 'should support sis stickiness overriding' do
    before_count = AbstractCourse.count
    process_csv_data_cleanly(
      "term_id,name,status,start_date,end_date",
      "T001,Winter13,active,,"
    )
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,TestAccount,active"
    )
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Hum101,Humanities,A001,T001,active"
    )
    AbstractCourse.count.should == before_count + 1
    AbstractCourse.last.tap do |c|
      c.name.should == "Humanities"
      c.short_name.should == "Hum101"
    end
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Math101,Mathematics,A001,T001,active"
    )
    AbstractCourse.count.should == before_count + 1
    AbstractCourse.last.tap do |c|
      c.name.should == "Mathematics"
      c.short_name.should == "Math101"
      c.name = "Physics"
      c.short_name = "Phys101"
      c.save!
    end
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Thea101,Theater,A001,T001,active"
    )
    AbstractCourse.count.should == before_count + 1
    AbstractCourse.last.tap do |c|
      c.name.should == "Physics"
      c.short_name.should == "Phys101"
    end
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Thea101,Theater,A001,T001,active",
      {:override_sis_stickiness => true}
    )
    AbstractCourse.count.should == before_count + 1
    AbstractCourse.last.tap do |c|
      c.name.should == "Theater"
      c.short_name.should == "Thea101"
    end
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Fren101,French,A001,T001,active"
    )
    AbstractCourse.count.should == before_count + 1
    AbstractCourse.last.tap do |c|
      c.name.should == "Theater"
      c.short_name.should == "Thea101"
    end
  end

  it 'should allow turning on stickiness' do
    before_count = AbstractCourse.count
    process_csv_data_cleanly(
      "term_id,name,status,start_date,end_date",
      "T001,Winter13,active,,"
    )
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,TestAccount,active"
    )
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Hum101,Humanities,A001,T001,active"
    )
    AbstractCourse.count.should == before_count + 1
    AbstractCourse.last.tap do |c|
      c.name.should == "Humanities"
      c.short_name.should == "Hum101"
    end
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Math101,Mathematics,A001,T001,active"
    )
    AbstractCourse.count.should == before_count + 1
    AbstractCourse.last.tap do |c|
      c.name.should == "Mathematics"
      c.short_name.should == "Math101"
    end
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Phys101,Physics,A001,T001,active",
      {:add_sis_stickiness => true}
    )
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Thea101,Theater,A001,T001,active"
    )
    AbstractCourse.count.should == before_count + 1
    AbstractCourse.last.tap do |c|
      c.name.should == "Physics"
      c.short_name.should == "Phys101"
    end
  end

  it 'should allow turning off stickiness' do
    before_count = AbstractCourse.count
    process_csv_data_cleanly(
      "term_id,name,status,start_date,end_date",
      "T001,Winter13,active,,"
    )
    process_csv_data_cleanly(
      "account_id,parent_account_id,name,status",
      "A001,,TestAccount,active"
    )
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Hum101,Humanities,A001,T001,active"
    )
    AbstractCourse.count.should == before_count + 1
    AbstractCourse.last.tap do |c|
      c.name.should == "Humanities"
      c.short_name.should == "Hum101"
    end
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Math101,Mathematics,A001,T001,active"
    )
    AbstractCourse.count.should == before_count + 1
    AbstractCourse.last.tap do |c|
      c.name.should == "Mathematics"
      c.short_name.should == "Math101"
      c.name = "Physics"
      c.short_name = "Phys101"
      c.save!
    end
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Fren101,French,A001,T001,active"
    )
    AbstractCourse.count.should == before_count + 1
    AbstractCourse.last.tap do |c|
      c.name.should == "Physics"
      c.short_name.should == "Phys101"
    end
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Thea101,Theater,A001,T001,active",
      { :override_sis_stickiness => true,
        :clear_sis_stickiness => true }
    )
    AbstractCourse.count.should == before_count + 1
    AbstractCourse.last.tap do |c|
      c.name.should == "Theater"
      c.short_name.should == "Thea101"
    end
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Fren101,French,A001,T001,active"
    )
    AbstractCourse.count.should == before_count + 1
    AbstractCourse.last.tap do |c|
      c.name.should == "French"
      c.short_name.should == "Fren101"
    end
  end

  context "abstract course importing" do
    it 'should skip bad content' do
      before_count = AbstractCourse.count
      importer = process_csv_data(
        "abstract_course_id,short_name,long_name,account_id,term_id,status",
        "C001,Hum101,Humanities,A001,T001,active",
        ",Hum102,Humanities 2,A001,T001,active",
        "C003,Hum102,Humanities 2,A001,T001,inactive",
        "C004,,Humanities 2,A001,T001,active",
        "C005,Hum102,,A001,T001,active"
      )
      AbstractCourse.count.should == before_count + 1

      importer.errors.should == []
      importer.warnings.map(&:last).should == [
          "No abstract_course_id given for an abstract course",
          "Improper status \"inactive\" for abstract course C003",
          "No short_name given for abstract course C004",
          "No long_name given for abstract course C005"]
    end

    it 'should support sticky fields' do
      before_count = AbstractCourse.count
      process_csv_data_cleanly(
        "term_id,name,status,start_date,end_date",
        "T001,Winter13,active,,",
        "T002,Spring14,active,,",
        "T003,Summer14,active,,",
        "T004,Fall14,active,,"
      )
      process_csv_data_cleanly(
        "account_id,parent_account_id,name,status",
        "A001,,TestAccount,active"
      )
      process_csv_data_cleanly(
        "abstract_course_id,short_name,long_name,account_id,term_id,status",
        "C001,Hum101,Humanities,A001,T001,active"
      )
      AbstractCourse.count.should == before_count + 1
      AbstractCourse.last.tap do |c|
        c.name.should == "Humanities"
        c.short_name.should == "Hum101"
        c.enrollment_term.should == EnrollmentTerm.find_by_sis_source_id('T001')
      end
      process_csv_data_cleanly(
        "abstract_course_id,short_name,long_name,account_id,term_id,status",
        "C001,Math101,Mathematics,A001,T002,active"
      )
      AbstractCourse.count.should == before_count + 1
      AbstractCourse.last.tap do |c|
        c.name.should == "Mathematics"
        c.short_name.should == "Math101"
        c.enrollment_term.should == EnrollmentTerm.find_by_sis_source_id('T002')
        c.name = "Physics"
        c.short_name = "Phys101"
        c.enrollment_term = EnrollmentTerm.find_by_sis_source_id('T003')
        c.save!
      end
      process_csv_data_cleanly(
        "abstract_course_id,short_name,long_name,account_id,term_id,status",
        "C001,Thea101,Theater,A001,T004,active"
      )
      AbstractCourse.count.should == before_count + 1
      AbstractCourse.last.tap do |c|
        c.name.should == "Physics"
        c.short_name.should == "Phys101"
        c.enrollment_term.should == EnrollmentTerm.find_by_sis_source_id('T003')
      end
    end

    it 'should create new abstract courses' do
      before_count = AbstractCourse.count
      process_csv_data_cleanly(
        "term_id,name,status,start_date,end_date",
        "T001,Winter13,active,,"
      )
      process_csv_data_cleanly(
        "account_id,parent_account_id,name,status",
        "A001,,TestAccount,active"
      )
      process_csv_data_cleanly(
        "abstract_course_id,short_name,long_name,account_id,term_id,status",
        "C001,Hum101,Humanities,A001,T001,active"
      )
      AbstractCourse.count.should == before_count + 1
      AbstractCourse.last.tap{|c|
        c.sis_source_id.should == "C001"
        c.short_name.should == "Hum101"
        c.name.should == "Humanities"
        c.enrollment_term.should == EnrollmentTerm.last
        c.enrollment_term.name.should == "Winter13"
        c.account.should == Account.last
        c.account.name.should == "TestAccount"
        c.root_account.should == @account
        c.workflow_state.should == 'active'
      }
    end

    it 'should allow instantiations of abstract courses' do
      process_csv_data_cleanly(
        "term_id,name,status,start_date,end_date",
        "T001,Winter13,active,,"
      )
      process_csv_data_cleanly(
        "account_id,parent_account_id,name,status",
        "A001,,TestAccount,active"
      )
      process_csv_data_cleanly(
        "abstract_course_id,short_name,long_name,account_id,term_id,status",
        "AC001,Hum101,Humanities,A001,T001,active"
      )
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status,abstract_course_id",
        "C001,,,,,active,AC001"
      )
      Course.last.tap{|c|
        c.sis_source_id.should == "C001"
        c.abstract_course.should == AbstractCourse.last
        c.abstract_course.sis_source_id.should == "AC001"
        c.short_name.should == "Hum101"
        c.name.should == "Humanities"
        c.enrollment_term.should == EnrollmentTerm.last
        c.enrollment_term.name.should == "Winter13"
        c.account.should == Account.last
        c.account.name.should == "TestAccount"
        c.root_account.should == @account
      }
    end

    it 'should skip references to nonexistent abstract courses' do
      process_csv_data_cleanly(
        "term_id,name,status,start_date,end_date",
        "T001,Winter13,active,,"
      )
      process_csv_data_cleanly(
        "account_id,parent_account_id,name,status",
        "A001,,TestAccount,active"
      )
      process_csv_data(
        "course_id,short_name,long_name,account_id,term_id,status,abstract_course_id",
        "C001,shortname,longname,,,active,AC001"
      ).tap do |i|
        i.errors.should == []
        i.warnings.map(&:last).should == [
            "unknown abstract course id AC001, ignoring abstract course reference"]
      end
      Course.last.tap{|c|
        c.sis_source_id.should == "C001"
        c.abstract_course.should be_nil
        c.short_name.should == "shortname"
        c.name.should == "longname"
        c.enrollment_term.should == @account.default_enrollment_term
        c.account.should == @account
        c.root_account.should == @account
      }
      process_csv_data_cleanly(
        "abstract_course_id,short_name,long_name,account_id,term_id,status",
        "AC001,Hum101,Humanities,A001,T001,active"
      )
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status,abstract_course_id",
        "C001,shortname,longname,,,active,AC001"
      )
      Course.last.tap{|c|
        c.sis_source_id.should == "C001"
        c.abstract_course.should == AbstractCourse.last
        c.abstract_course.sis_source_id.should == "AC001"
        c.short_name.should == "shortname"
        c.name.should == "longname"
        c.enrollment_term.should == EnrollmentTerm.last
        c.enrollment_term.name.should == "Winter13"
        c.account.should == Account.last
        c.account.name.should == "TestAccount"
        c.root_account.should == @account
      }
    end

    it "should support falling back to a fallback account if the primary one doesn't exist" do
      before_count = AbstractCourse.count
      process_csv_data_cleanly(
        "account_id,parent_account_id,name,status",
        "A001,,TestAccount,active"
      )
      process_csv_data_cleanly(
        "abstract_course_id,short_name,long_name,account_id,term_id,status,fallback_account_id",
        "C001,Hum101,Humanities,NOEXIST,T001,active,A001"
      )
      AbstractCourse.count.should == before_count + 1
      AbstractCourse.last.tap{|c|
        c.account.should == Account.last
        c.account.name.should == "TestAccount"
        c.root_account.should == @account
      }
    end

  end

  context "course importing" do
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
      Course.count.should == before_count + 1

      importer.errors.should == []
      warnings = importer.warnings.map { |r| r.last }
      warnings.should == ["No course_id given for a course",
                          "Improper status \"inactive\" for course C003",
                          "No short_name given for course C004",
                          "No long_name given for course C005"]
    end

    it "should create new courses" do
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,,active"
      )
      course = @account.courses.find_by_sis_source_id("test_1")
      course.course_code.should eql("TC 101")
      course.name.should eql("Test Course 101")
      course.associated_accounts.map(&:id).sort.should == [@account.id]
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
      @account.courses.find_by_sis_source_id("test_1").tap do |course|
        course.enrollment_term.should == EnrollmentTerm.find_by_sis_source_id('T001')
      end
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,T002,active"
      )
      @account.courses.find_by_sis_source_id("test_1").tap do |course|
        course.enrollment_term.should == EnrollmentTerm.find_by_sis_source_id('T002')
        course.enrollment_term = EnrollmentTerm.find_by_sis_source_id('T003')
        course.save!
      end
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,T004,active"
      )
      @account.courses.find_by_sis_source_id("test_1").tap do |course|
        course.enrollment_term.should == EnrollmentTerm.find_by_sis_source_id('T003')
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
      @account.courses.find_by_sis_source_id("test_1").tap do |course|
        course.enrollment_term.should == EnrollmentTerm.find_by_sis_source_id('T001')
      end
      process_csv_data_cleanly(
        "abstract_course_id,short_name,long_name,account_id,term_id,status",
        "AC001,Hum101,Humanities,A001,T002,active"
      )
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status,abstract_course_id",
        "test_1,TC 101,Test Course 101,,,active,AC001"
      )
      @account.courses.find_by_sis_source_id("test_1").tap do |course|
        course.enrollment_term.should == EnrollmentTerm.find_by_sis_source_id('T002')
        course.enrollment_term = EnrollmentTerm.find_by_sis_source_id('T003')
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
      @account.courses.find_by_sis_source_id("test_1").tap do |course|
        course.enrollment_term.should == EnrollmentTerm.find_by_sis_source_id('T003')
      end
    end

    it "shouldn't blow away the account id if it's already set" do
      process_csv_data_cleanly(
        "account_id,parent_account_id,name,status",
        "A001,,Humanities,active"
      )
      account = @account.sub_accounts.find_by_sis_source_id("A001")
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,,active"
      )
      course = @account.courses.find_by_sis_source_id("test_1")
      course.account.should == @account
      course.associated_accounts.map(&:id).sort.should == [@account.id]
      account.should_not == @account
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,A001,,active"
      )
      course.reload
      course.account.should == account
      course.associated_accounts.map(&:id).sort.should == [account.id, @account.id].sort
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,,active"
      )
      course.reload
      course.account.should == account
      course.associated_accounts.map(&:id).sort.should == [account.id, @account.id].sort
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
      account = @account.sub_accounts.find_by_sis_source_id("A001")
      course = account.courses.find_by_sis_source_id("test_1")
      course.account.should == account
    end

    it "should rename courses that have not had their name manually changed" do
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,,active",
        "test_2,TB 101,Testing & Breaking 101,,,active"
      )
      course = @account.courses.find_by_sis_source_id("test_1")
      course.course_code.should eql("TC 101")
      course.name.should eql("Test Course 101")

      course = @account.courses.find_by_sis_source_id("test_2")
      course.name.should eql("Testing & Breaking 101")

      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 102,Test Course 102,,,active",
        "test_2,TB 102,Testing & Breaking 102,,,active"
      )

      course = @account.courses.find_by_sis_source_id("test_1")
      course.course_code.should eql("TC 102")
      course.name.should eql("Test Course 102")

      course = @account.courses.find_by_sis_source_id("test_2")
      course.name.should eql("Testing & Breaking 102")
    end

    it "should not rename courses that have had their names manually changed" do
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,,active"
      )
      course = @account.courses.find_by_sis_source_id("test_1")
      course.course_code.should eql("TC 101")
      course.name.should eql("Test Course 101")

      course.name = "Haha my course lol"
      course.course_code = "SUCKERS 101"
      course.save

      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 102,Test Course 102,,,active"
      )
      course = @account.courses.find_by_sis_source_id("test_1")
      course.course_code.should eql("SUCKERS 101")
      course.name.should eql("Haha my course lol")
    end

    it 'should override term dates if the start or end dates are set' do
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
        "test1,TC 101,Test Course 1,,,active,,",
        "test2,TC 102,Test Course 2,,,active,,2011-05-14 00:00:00",
        "test3,TC 103,Test Course 3,,,active,2011-04-14 00:00:00,",
        "test4,TC 104,Test Course 4,,,active,2011-04-14 00:00:00,2011-05-14 00:00:00"
      )
      @account.courses.find_by_sis_source_id("test1").restrict_enrollments_to_course_dates.should be_false
      @account.courses.find_by_sis_source_id("test2").restrict_enrollments_to_course_dates.should be_true
      @account.courses.find_by_sis_source_id("test3").restrict_enrollments_to_course_dates.should be_true
      @account.courses.find_by_sis_source_id("test4").restrict_enrollments_to_course_dates.should be_true
    end

    it 'should support start/end date and restriction stickiness' do
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
        "test4,TC 104,Test Course 4,,,active,2011-04-14 00:00:00,2011-05-14 00:00:00"
      )
      @account.courses.find_by_sis_source_id("test4").tap do |course|
        course.restrict_enrollments_to_course_dates.should be_true
        course.start_at.should == DateTime.parse("2011-04-14 00:00:00")
        course.conclude_at.should == DateTime.parse("2011-05-14 00:00:00")
        course.restrict_enrollments_to_course_dates = false
        course.start_at = DateTime.parse("2010-04-14 00:00:00")
        course.conclude_at = DateTime.parse("2010-05-14 00:00:00")
        course.save!
      end
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
        "test4,TC 104,Test Course 4,,,active,2011-04-14 00:00:00,2011-05-14 00:00:00"
      )
      @account.courses.find_by_sis_source_id("test4").tap do |course|
        course.restrict_enrollments_to_course_dates.should be_false
        course.start_at.should == DateTime.parse("2010-04-14 00:00:00")
        course.conclude_at.should == DateTime.parse("2010-05-14 00:00:00")
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
      ['c1', 'c2', 'c3'].map{|c| Course.find_by_sis_source_id(c)}.each do |c|
        c.account.should == Account.find_by_sis_source_id('A001')
        c.name.should == 'Test Course 1'
        c.course_code.should == 'TC 101'
        c.enrollment_term.should == EnrollmentTerm.find_by_sis_source_id('T001')
        c.start_at.should == DateTime.parse("2011-04-14 00:00:00")
        c.conclude_at.should == DateTime.parse("2011-05-14 00:00:00")
        c.restrict_enrollments_to_course_dates.should be_true
      end
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
        "c1,TC 102,Test Course 2,A002,T002,active,2011-04-12 00:00:00,2011-05-12 00:00:00"
      )
      ['c1', 'c2', 'c3'].map{|c| Course.find_by_sis_source_id(c)}.each do |c|
        c.account.should == Account.find_by_sis_source_id('A002')
        c.name.should == 'Test Course 2'
        c.course_code.should == 'TC 102'
        c.enrollment_term.should == EnrollmentTerm.find_by_sis_source_id('T002')
        c.start_at.should == DateTime.parse("2011-04-12 00:00:00")
        c.conclude_at.should == DateTime.parse("2011-05-12 00:00:00")
        c.restrict_enrollments_to_course_dates.should be_true
      end
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
        "c1,TC 102,Test Course 2,A002,T002,active,,"
      )
      ['c1', 'c2', 'c3'].map{|c| Course.find_by_sis_source_id(c)}.each do |c|
        c.account.should == Account.find_by_sis_source_id('A002')
        c.name.should == 'Test Course 2'
        c.course_code.should == 'TC 102'
        c.enrollment_term.should == EnrollmentTerm.find_by_sis_source_id('T002')
        c.start_at.should be_nil
        c.conclude_at.should be_nil
        c.restrict_enrollments_to_course_dates.should be_false
      end
      ['c1'].map{|c| Course.find_by_sis_source_id(c)}.each do |c|
        c.account = Account.find_by_sis_source_id('A003')
        c.name = 'Test Course 3'
        c.course_code = 'TC 103'
        c.enrollment_term = EnrollmentTerm.find_by_sis_source_id('T003')
        c.start_at = DateTime.parse("2011-04-13 00:00:00")
        c.conclude_at = DateTime.parse("2011-05-13 00:00:00")
        c.restrict_enrollments_to_course_dates = true
        c.save!
      end
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
        "c1,TC 104,Test Course 4,A004,T004,active,2011-04-16 00:00:00,2011-05-16 00:00:00"
      )
      ['c1'].map{|c| Course.find_by_sis_source_id(c)}.each do |c|
        c.account.should == Account.find_by_sis_source_id('A004')
        c.name.should == 'Test Course 3'
        c.course_code.should == 'TC 103'
        c.enrollment_term.should == EnrollmentTerm.find_by_sis_source_id('T003')
        c.start_at.should == DateTime.parse("2011-04-13 00:00:00")
        c.conclude_at.should == DateTime.parse("2011-05-13 00:00:00")
        c.restrict_enrollments_to_course_dates.should be_true
      end
      ['c2', 'c3'].map{|c| Course.find_by_sis_source_id(c)}.each do |c|
        c.account.should == Account.find_by_sis_source_id('A004')
        c.name.should == 'Test Course 2'
        c.course_code.should == 'TC 102'
        c.enrollment_term.should == EnrollmentTerm.find_by_sis_source_id('T002')
        c.start_at.should be_nil
        c.conclude_at.should be_nil
        c.restrict_enrollments_to_course_dates.should be_false
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
      ['c1', 'c2', 'c3'].map{|c| Course.find_by_sis_source_id(c)}.each do |c|
        c.account.should == Account.find_by_sis_source_id('A001')
        c.name.should == 'Test Course 1'
        c.course_code.should == 'TC 101'
        c.enrollment_term.should == EnrollmentTerm.find_by_sis_source_id('T001')
        c.start_at.should == DateTime.parse("2011-04-14 00:00:00")
        c.conclude_at.should == DateTime.parse("2011-05-14 00:00:00")
        c.restrict_enrollments_to_course_dates.should be_true
      end
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
        "c1,TC 102,Test Course 2,A002,T002,active,2011-04-12 00:00:00,2011-05-12 00:00:00"
      )
      ['c1', 'c2', 'c3'].map{|c| Course.find_by_sis_source_id(c)}.each do |c|
        c.account.should == Account.find_by_sis_source_id('A002')
        c.name.should == 'Test Course 2'
        c.course_code.should == 'TC 102'
        c.enrollment_term.should == EnrollmentTerm.find_by_sis_source_id('T002')
        c.start_at.should == DateTime.parse("2011-04-12 00:00:00")
        c.conclude_at.should == DateTime.parse("2011-05-12 00:00:00")
        c.restrict_enrollments_to_course_dates.should be_true
      end
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
        "c1,TC 102,Test Course 2,A002,T002,active,,"
      )
      ['c1', 'c2', 'c3'].map{|c| Course.find_by_sis_source_id(c)}.each do |c|
        c.account.should == Account.find_by_sis_source_id('A002')
        c.name.should == 'Test Course 2'
        c.course_code.should == 'TC 102'
        c.enrollment_term.should == EnrollmentTerm.find_by_sis_source_id('T002')
        c.start_at.should be_nil
        c.conclude_at.should be_nil
        c.restrict_enrollments_to_course_dates.should be_false
      end
      ['c2', 'c3'].map{|c| Course.find_by_sis_source_id(c)}.each do |c|
        c.account = Account.find_by_sis_source_id('A003')
        c.name = 'Test Course 3'
        c.course_code = 'TC 103'
        c.enrollment_term = EnrollmentTerm.find_by_sis_source_id('T003')
        c.start_at = DateTime.parse("2011-04-13 00:00:00")
        c.conclude_at = DateTime.parse("2011-05-13 00:00:00")
        c.restrict_enrollments_to_course_dates = true
        c.save!
      end
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
        "c1,TC 104,Test Course 4,A004,T004,active,2011-04-16 00:00:00,2011-05-16 00:00:00"
      )
      ['c2', 'c3'].map{|c| Course.find_by_sis_source_id(c)}.each do |c|
        c.account.should == Account.find_by_sis_source_id('A004')
        c.name.should == 'Test Course 3'
        c.course_code.should == 'TC 103'
        c.enrollment_term.should == EnrollmentTerm.find_by_sis_source_id('T003')
        c.start_at.should == DateTime.parse("2011-04-13 00:00:00")
        c.conclude_at.should == DateTime.parse("2011-05-13 00:00:00")
        c.restrict_enrollments_to_course_dates.should be_true
      end
      ['c1'].map{|c| Course.find_by_sis_source_id(c)}.each do |c|
        c.account.should == Account.find_by_sis_source_id('A004')
        c.name.should == 'Test Course 4'
        c.course_code.should == 'TC 104'
        c.enrollment_term.should == EnrollmentTerm.find_by_sis_source_id('T004')
        c.start_at.should == DateTime.parse("2011-04-16 00:00:00")
        c.conclude_at.should == DateTime.parse("2011-05-16 00:00:00")
        c.restrict_enrollments_to_course_dates.should be_true
      end
    end
  end

  context "user importing" do
    it "should create new users and update names" do
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user@example.com,active"
      )
      user = User.find_by_email('user@example.com')
      user.account.should eql(@account)
      user.name.should eql("User Uno")

      user.pseudonyms.count.should eql(1)
      pseudonym = user.pseudonyms.first
      pseudonym.unique_id.should eql('user1')

      user.communication_channels.count.should eql(1)
      cc = user.communication_channels.first
      cc.path.should eql("user@example.com")

      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno 2,user@example.com,active"
      )
      user = User.find_by_email('user@example.com')
      user.account.should eql(@account)
      user.name.should eql("User Uno 2")

      user.pseudonyms.count.should eql(1)
      pseudonym = user.pseudonyms.first
      pseudonym.unique_id.should eql('user1')

      user.communication_channels.count.should eql(1)

      user.name = "My Awesome Name"
      user.save

      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno 2,user@example.com,active"
      )
      user = User.find_by_email('user@example.com')
      user.account.should eql(@account)
      user.name.should eql("My Awesome Name")
    end

    it "should set passwords and not overwrite current passwords" do
      process_csv_data_cleanly(
        "user_id,login_id,password,first_name,last_name,email,status,ssha_password",
        "user_1,user1,badpassword,User,Uno 2,user@example.com,active,",
        "user_2,user2,,User,Uno 2,user2@example.com,active,#{gen_ssha_password("password")}"
      )
      user1 = User.find_by_email('user@example.com')
      p = user1.pseudonyms.first
      p.valid_arbitrary_credentials?('badpassword').should be_true

      p.password = 'lessbadpassword'
      p.password_confirmation = 'lessbadpassword'
      p.save

      user2 = User.find_by_email('user2@example.com')
      p = user2.pseudonyms.first
      p.valid_arbitrary_credentials?('password').should be_true

      p.password = 'newpassword'
      p.password_confirmation = 'newpassword'
      p.save

      p.valid_arbitrary_credentials?('password').should be_false
      p.valid_arbitrary_credentials?('newpassword').should be_true

      process_csv_data_cleanly(
        "user_id,login_id,password,first_name,last_name,email,status,ssha_password",
        "user_1,user1,badpassword2,User,Uno 2,user@example.com,active",
        "user_2,user2,,User,Uno 2,user2@example.com,active,#{gen_ssha_password("changedpassword")}"
      )

      user1.reload
      p = user1.pseudonyms.first
      p.valid_arbitrary_credentials?('badpassword').should be_false
      p.valid_arbitrary_credentials?('badpassword2').should be_false
      p.valid_arbitrary_credentials?('lessbadpassword').should be_true

      user2.reload
      p = user2.pseudonyms.first
      p.valid_arbitrary_credentials?('password').should be_false
      p.valid_arbitrary_credentials?('changedpassword').should be_false
      p.valid_arbitrary_credentials?('newpassword').should be_true
      p.valid_ssha?('changedpassword').should be_true
    end

    it "should allow setting and resetting of passwords" do
      User.find_by_email("user1@example.com").should be_nil
      User.find_by_email("user2@example.com").should be_nil

      process_csv_data_cleanly(
        "user_id,login_id,password,first_name,last_name,email,status,ssha_password",
        "user_1,user1,password1,User,Uno,user1@example.com,active,",
        "user_2,user2,,User,Dos,user2@example.com,active,#{gen_ssha_password("encpass1")}"
      )

      user1_persistence_token = nil
      user2_persistence_token = nil
      User.find_by_email('user1@example.com').pseudonyms.first.tap do |p|
        user1_persistence_token = p.persistence_token
        p.valid_arbitrary_credentials?('password1').should be_true
        p.valid_arbitrary_credentials?('password2').should be_false
        p.valid_arbitrary_credentials?('password3').should be_false
        p.valid_arbitrary_credentials?('password4').should be_false
      end

      user2_sis_ssha = nil
      User.find_by_email('user2@example.com').pseudonyms.first.tap do |p|
        user2_persistence_token = p.persistence_token
        user2_sis_ssha = p.sis_ssha
        p.valid_arbitrary_credentials?('encpass1').should be_true
        p.valid_arbitrary_credentials?('encpass2').should be_false
        p.valid_arbitrary_credentials?('encpass3').should be_false
        p.valid_arbitrary_credentials?('password4').should be_false
      end

      # passwords haven't changed, neither should persistence tokens
      process_csv_data_cleanly(
        "user_id,login_id,password,first_name,last_name,email,status,ssha_password",
        "user_1,user1,password1,User,Uno,user1@example.com,active,",
        "user_2,user2,,User,Dos,user2@example.com,active,#{user2_sis_ssha}"
      )

      User.find_by_email('user1@example.com').pseudonyms.first.tap do |p|
        user1_persistence_token.should == p.persistence_token
        p.valid_arbitrary_credentials?('password1').should be_true
        p.valid_arbitrary_credentials?('password2').should be_false
        p.valid_arbitrary_credentials?('password3').should be_false
        p.valid_arbitrary_credentials?('password4').should be_false
      end

      User.find_by_email('user2@example.com').pseudonyms.first.tap do |p|
        user2_persistence_token.should == p.persistence_token
        p.valid_arbitrary_credentials?('encpass1').should be_true
        p.valid_arbitrary_credentials?('encpass2').should be_false
        p.valid_arbitrary_credentials?('encpass3').should be_false
        p.valid_arbitrary_credentials?('password4').should be_false
      end

      # passwords change, persistence token should change
      process_csv_data_cleanly(
        "user_id,login_id,password,first_name,last_name,email,status,ssha_password",
        "user_1,user1,password2,User,Uno,user1@example.com,active,",
        "user_2,user2,,User,Dos,user2@example.com,active,#{gen_ssha_password("encpass2")}"
      )

      User.find_by_email('user1@example.com').pseudonyms.first.tap do |p|
        user1_persistence_token.should_not == p.persistence_token
        p.valid_arbitrary_credentials?('password1').should be_false
        p.valid_arbitrary_credentials?('password2').should be_true
        p.valid_arbitrary_credentials?('password3').should be_false
        p.valid_arbitrary_credentials?('password4').should be_false

        p.password_confirmation = p.password = 'password4'
        p.save
        user1_persistence_token = p.persistence_token
      end

      User.find_by_email('user2@example.com').pseudonyms.first.tap do |p|
        user2_persistence_token.should_not == p.persistence_token
        p.valid_arbitrary_credentials?('encpass1').should be_false
        p.valid_arbitrary_credentials?('encpass2').should be_true
        p.valid_arbitrary_credentials?('encpass3').should be_false
        p.valid_arbitrary_credentials?('password4').should be_false

        p.password_confirmation = p.password = 'password4'
        p.save
        user2_persistence_token = p.persistence_token
      end

      # user set password, persistence token should not change
      process_csv_data_cleanly(
        "user_id,login_id,password,first_name,last_name,email,status,ssha_password",
        "user_1,user1,password3,User,Uno,user1@example.com,active,",
        "user_2,user2,,User,Dos,user2@example.com,active,#{gen_ssha_password("encpass3")}"
      )

      User.find_by_email('user1@example.com').pseudonyms.first.tap do |p|
        user1_persistence_token.should == p.persistence_token
        p.valid_arbitrary_credentials?('password1').should be_false
        p.valid_arbitrary_credentials?('password2').should be_false
        p.valid_arbitrary_credentials?('password3').should be_false
        p.valid_arbitrary_credentials?('password4').should be_true
      end

      User.find_by_email('user2@example.com').pseudonyms.first.tap do |p|
        user2_persistence_token.should == p.persistence_token
        p.valid_arbitrary_credentials?('encpass1').should be_false
        p.valid_arbitrary_credentials?('encpass2').should be_false
        p.valid_arbitrary_credentials?('encpass3').should be_false
        p.valid_arbitrary_credentials?('password4').should be_true
      end

    end

    it "should catch active-record-level errors, like invalid unique_id" do
      before_user_count = User.count
      before_pseudo_count = Pseudonym.count
      importer = process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "U1,@,User,Uno,user@example.com,active"
      )
      user = User.find_by_email('user@example.com')
      user.should be_nil

      importer.errors.map(&:last).should == []
      importer.warnings.map(&:last).should == ["Failed saving user. Internal error: unique_id is invalid"]
      [User.count, Pseudonym.count].should == [before_user_count, before_pseudo_count]
    end

    it "should not allow a secondary user account with the same login id." do
      p_count = Pseudonym.count
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user@example.com,active"
      )
      user = User.find_by_email('user@example.com')
      user.pseudonyms.count.should == 1
      user.pseudonyms.find_by_unique_id('user1').sis_user_id.should == 'user_1'

      importer = process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_2,user1,User,Uno,user@example.com,active"
      )
      importer.errors.should == []
      importer.warnings.map{|r|r.last}.should == ["user user_1 has already claimed user_2's requested login information, skipping"]
      user = User.find_by_email('user@example.com')
      user.pseudonyms.count.should == 1
      user.pseudonyms.find_by_unique_id('user1').sis_user_id.should == 'user_1'
      Pseudonym.count.should == (p_count + 1)
    end

    it "should not allow a secondary user account to change its login id to some other registered login id" do
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active",
        "user_2,user2,User,Dos,user2@example.com,active"
      )

      importer = process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_2,user1,User,Dos,user2@example.com,active",
        "user_1,user3,User,Uno,user1@example.com,active"
      )
      importer.warnings.map{|r|r.last}.should == ["user user_1 has already claimed user_2's requested login information, skipping"]
      importer.errors.should == []
      Pseudonym.find_by_account_id_and_sis_user_id(@account.id, "user_1").unique_id.should == "user3"
      Pseudonym.find_by_account_id_and_sis_user_id(@account.id, "user_2").unique_id.should == "user2"
    end

    it "should allow a secondary user account to change its login id to some other registered login id if the other changes it first" do
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active",
        "user_2,user2,User,Dos,user2@example.com,active"
      )

      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user3,User,Uno,user1@example.com,active",
        "user_2,user1,User,Dos,user2@example.com,active"
      )
      Pseudonym.find_by_account_id_and_sis_user_id(@account.id, "user_1").unique_id.should == "user3"
      Pseudonym.find_by_account_id_and_sis_user_id(@account.id, "user_2").unique_id.should == "user1"
    end

    it "should allow a user to update information" do
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active"
      )

      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user2,User,Uno-Dos,user1@example.com,active"
      )

      Pseudonym.find_by_account_id_and_sis_user_id(@account.id, "user_1").user.last_name.should == "Uno-Dos"
    end

    it "should allow a user to update emails specifically" do
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active"
      )

      Pseudonym.find_by_account_id_and_sis_user_id(@account.id, "user_1").user.email.should == "user1@example.com"

      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user2@example.com,active"
      )

      Pseudonym.find_by_account_id_and_sis_user_id(@account.id, "user_1").user.email.should == "user2@example.com"
    end

    it "should add two users with different user_ids, login_ids, but the same email" do
      importer = process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user@example.com,active",
        "user_2,user2,User,Dos,user@example.com,active"
      )
      importer.errors.should == []
      importer.warnings.map(&:last).should == ['E-mail address user@example.com for user user2 is already claimed; ignoring']
      user1 = Pseudonym.find_by_unique_id('user1').user
      user2 = Pseudonym.find_by_unique_id('user2').user
      user1.should_not == user2
      user1.last_name.should == "Uno"
      user2.last_name.should == "Dos"
      user1.pseudonyms.count.should == 1
      user2.pseudonyms.count.should == 1
      user1.pseudonyms.first.communication_channel_id.should_not be_nil
      user2.pseudonyms.first.communication_channel_id.should be_nil
    end

    it "should not add a user with the same login id as another user" do
      importer = process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active",
        "user_2,user1,User,Dos,user2@example.com,active"
      )
      importer.errors.should == []
      importer.warnings.map{|x| x[1]}.should == ["user user_1 has already claimed user_2's requested login information, skipping"]
      Pseudonym.find_by_unique_id('user1').should_not be_nil
      Pseudonym.find_by_unique_id('user2').should be_nil
    end

    it "should use an existing pseudonym if it wasn't imported from sis and has the same login id" do
      u = User.create!
      u.register!
      p_count = Pseudonym.count
      p = u.pseudonyms.create!(:unique_id => "user2", :path => "user2", :password => "validpassword", :password_confirmation => "validpassword", :account => @account)
      Pseudonym.find_by_unique_id('user1').should be_nil
      Pseudonym.find_by_unique_id('user2').should_not be_nil
      p.sis_user_id.should be_nil
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active",
        "user_2,user2,User,Dos,user2@example.com,active"
      )
      p.reload
      Pseudonym.find_by_unique_id('user1').should_not be_nil
      Pseudonym.find_by_unique_id('user2').should_not be_nil
      Pseudonym.count.should == (p_count + 2)
      p.sis_user_id.should == "user_2"
    end

    it "should use an existing pseudonym if it wasn't imported from sis and has the same email address" do
      u = User.create!
      u.register!
      p_count = Pseudonym.count
      p = u.pseudonyms.create!(:unique_id => "user2@example.com", :path => "user2@example.com", :password => "validpassword", :password_confirmation => "validpassword", :account => @account)
      Pseudonym.find_by_unique_id('user1').should be_nil
      Pseudonym.find_by_unique_id('user2').should be_nil
      Pseudonym.find_by_unique_id('user2@example.com').should_not be_nil
      p.sis_user_id.should be_nil
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active",
        "user_2,user2,User,Dos,user2@example.com,active"
      )
      p.reload
      Pseudonym.find_by_unique_id('user1').should_not be_nil
      Pseudonym.find_by_unique_id('user2').should_not be_nil
      Pseudonym.find_by_unique_id('user2@example.com').should be_nil
      Pseudonym.count.should == (p_count + 2)
      p.sis_user_id.should == "user_2"
    end

    it "should strip white space on fields" do
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1  ,user1   ,User   ,Uno   ,user@example.com   ,active  ",
        "   user_2,   user2,   User,   Dos,   user2@example.com,  active"
      )
      user = User.find_by_email('user@example.com')
      user.should_not be_nil
      p = user.pseudonyms.first
      p.unique_id.should == "user1"
      user = User.find_by_email('user2@example.com')
      user.should_not be_nil
      p = user.pseudonyms.first
      p.unique_id.should == "user2"
    end

    it "should use an existing communication channel" do
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active"
      )
      p = Pseudonym.find_by_unique_id('user1')
      user1 = p.user
      user1.last_name.should == "Uno"
      user1.pseudonyms.count.should == 1
      p.communication_channel_id.should_not be_nil
      user1.communication_channels.count.should == 1
      user1.communication_channels.first.path.should == 'user1@example.com'
      p.sis_communication_channel_id.should == p.communication_channel_id
      user1.communication_channels.create!(:path => 'user2@example.com', :path_type => 'email') { |cc| cc.workflow_state = 'active' }

      # change to user2@example.com; because user1@example.com was sis created, it should disappear
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user2@example.com,active"
      )
      p.reload
      user1.reload
      user1.pseudonyms.count.should == 1
      user1.communication_channels.count.should == 2
      user1.communication_channels.unretired.count.should == 1
      p.communication_channel_id.should_not be_nil
      user1.communication_channels.unretired.first.path.should == 'user2@example.com'
      p.sis_communication_channel_id.should == p.communication_channel_id
      p.communication_channel_id.should == user1.communication_channels.unretired.first.id
    end

    it "should work when a communication channel already exists, but there's no sis_communication_channel" do
      importer = process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,,active"
      )
      p = Pseudonym.find_by_unique_id('user1')
      user1 = p.user
      user1.last_name.should == "Uno"
      user1.pseudonyms.count.should == 1
      p.communication_channel_id.should be_nil
      user1.communication_channels.count.should == 0
      p.sis_communication_channel_id.should be_nil
      user1.communication_channels.create!(:path => 'user2@example.com', :path_type => 'email') { |cc| cc.workflow_state = 'active' }

      importer = process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user2@example.com,active"
      )
      p.reload
      user1.reload
      user1.pseudonyms.count.should == 1
      user1.communication_channels.count.should == 1
      user1.communication_channels.unretired.count.should == 1
      p.communication_channel_id.should_not be_nil
      user1.communication_channels.unretired.first.path.should == 'user2@example.com'
      p.sis_communication_channel_id.should == p.communication_channel_id
      p.communication_channel_id.should == user1.communication_channels.unretired.first.id
    end

    it "should handle stickiness" do
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,,active"
      )
      p = Pseudonym.find_by_unique_id('user1')
      p.unique_id = 'user5'
      p.save!
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user3,User,Uno,,active"
      )
      p.reload
      p.unique_id.should == 'user5'
      Pseudonym.find_by_unique_id('user1').should be_nil
      Pseudonym.find_by_unique_id('user3').should be_nil
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user3,User,Uno,,active",
        {:override_sis_stickiness => true}
      )
      p.reload
      p.unique_id.should == 'user3'
      Pseudonym.find_by_unique_id('user1').should be_nil
      Pseudonym.find_by_unique_id('user5').should be_nil
    end
  end

  context 'enrollment importing' do
    it 'should skip bad content' do
      before_count = Enrollment.count
      importer = process_csv_data(
        "course_id,user_id,role,section_id,status",
        ",U001,student,,active",
        "C001,,student,1B,active",
        "C001,U001,cheater,1B,active",
        "C001,U001,student,1B,semi-active"
      )
      Enrollment.count.should == before_count

      importer.errors.should == []
      warnings = importer.warnings.map { |r| r.last }
      warnings.should == ["No course_id or section_id given for an enrollment",
                        "No user_id given for an enrollment",
                        "Improper role \"cheater\" for an enrollment",
                        "Improper status \"semi-active\" for an enrollment"]
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
      warnings.should == ["An enrollment referenced a non-existent course NONEXISTENT",
                          "An enrollment referenced a non-existent section NONEXISTENT",
                          "An enrollment listed a section and a course that are unrelated"]
      importer.errors.should == []
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
      course = @account.courses.find_by_sis_source_id("test_1")
      course.teachers.map(&:name).should be_include("User Uno")
      course.students.first.name.should == "User Dos"
      course.tas.first.name.should == "User Tres"
      course.observers.first.name.should == "User Quatro"
      course.observer_enrollments.first.associated_user_id.should == course.students.first.id
      course.designers.first.name.should == "User Cinco"
      siete = course.teacher_enrollments.detect { |e| e.user.name == "User Siete" }
      siete.should_not be_nil
      siete.start_at.should == DateTime.new(1985, 8, 24)
      siete.end_at.should == DateTime.new(2011, 8, 29)
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
      course = @account.courses.find_by_sis_source_id("test_1")
      course.teacher_enrollments.first.tap do |e|
        e.start_at.should == DateTime.parse("1985-08-24")
        e.end_at.should == DateTime.parse("2011-08-29")
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
        e.start_at.should == DateTime.parse("1985-05-24")
        e.end_at.should == DateTime.parse("2011-05-29")
      end
    end

    it "should not try looking up a section to enroll into if the section name is empty" do
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "test_1,TC 101,Test Course 101,,,active",
        "test_2,TC 102,Test Course 102,,,active"
      )
      bad_course = @account.courses.find_by_sis_source_id("test_1")
      bad_course.course_sections.length.should == 0
      good_course = @account.courses.find_by_sis_source_id("test_2")
      good_course.course_sections.length.should == 0
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user@example.com,active"
      )
      process_csv_data_cleanly(
        "course_id,user_id,role,section_id,status,associated_user_id",
        "test_2,user_1,teacher,,active,"
      )
      good_course.teachers.first.name.should == "User Uno"
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
      course1 = @account.courses.find_by_sis_source_id("test_1")
      course2 = @account.courses.find_by_sis_source_id("test_2")
      course1.default_section.users.first.name.should == "User Uno"
      section1_1 = course1.course_sections.find_by_sis_source_id("S101")
      section1_1.users.first.name.should == "User Dos"
      section1_2 = course1.course_sections.find_by_sis_source_id("S102")
      section1_2.users.first.name.should == "User Tres"
      section2_1 = course2.course_sections.find_by_sis_source_id("S201")
      section2_1.users.map(&:name).sort.should == ["User Cuatro", "User Cinco"].sort
      section2_2 = course2.course_sections.find_by_sis_source_id("S202")
      section2_2.users.first.name.should == "User Seis"

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
  end

  context 'account importing' do
    it 'should skip bad content' do
      before_count = Account.count
      importer = process_csv_data(
        "account_id,parent_account_id,name,status",
        "A001,,Humanities,active",
        ",,Humanities 3,active")

      errors = importer.errors.map { |r| r.last }
      warnings = importer.warnings.map { |r| r.last }
      warnings.should == ["No account_id given for an account"]
      errors.should == []

      importer = process_csv_data(
        "account_id,parent_account_id,name,status",
        "A002,A000,English,active",
        "A003,,English,inactive",
        "A004,,,active")
      Account.count.should == before_count + 1

      errors = importer.errors.map { |r| r.last }
      warnings = importer.warnings.map { |r| r.last }
      errors.should == []
      warnings.should == ["Parent account didn't exist for A002",
                          "Improper status \"inactive\" for account A003, skipping",
                          "No name given for account A004, skipping"]
    end

    it 'should create accounts' do
      before_count = Account.count
      process_csv_data_cleanly(
        "account_id,parent_account_id,name,status",
        "A001,,Humanities,active",
        "A002,A001,English,active",
        "A003,A002,English Literature,active",
        "A004,,Awesomeness,active"
      )
      Account.count.should == before_count + 4

      a1 = @account.sub_accounts.find_by_sis_source_id('A001')
      a1.should_not be_nil
      a1.parent_account_id.should == @account.id
      a1.root_account_id.should == @account.id
      a1.name.should == 'Humanities'

      a2 = a1.sub_accounts.find_by_sis_source_id('A002')
      a2.should_not be_nil
      a2.parent_account_id.should == a1.id
      a2.root_account_id.should == @account.id
      a2.name.should == 'English'

      a3 = a2.sub_accounts.find_by_sis_source_id('A003')
      a3.should_not be_nil
      a3.parent_account_id.should == a2.id
      a3.root_account_id.should == @account.id
      a3.name.should == 'English Literature'
    end

    it 'should update the hierarchies of existing accounts' do
      before_count = Account.count
      process_csv_data_cleanly(
        "account_id,parent_account_id,name,status",
        "A001,,Humanities,active",
        "A002,,English,deleted",
        "A003,,English Literature,active",
        "A004,,Awesomeness,active"
      )
      Account.count.should == before_count + 4

      ['A001', 'A002', 'A003', 'A004'].each do |id|
        Account.find_by_sis_source_id(id).parent_account.should == @account
      end
      Account.find_by_sis_source_id('A002').workflow_state.should == "deleted"
      Account.find_by_sis_source_id('A003').name.should == "English Literature"

      process_csv_data_cleanly(
        "account_id,parent_account_id,name,status",
        "A002,A001,,",
        "A003,A002,,",
        "A004,A002,,"
      )
      Account.count.should == before_count + 4

      a1 = Account.find_by_sis_source_id('A001')
      a2 = Account.find_by_sis_source_id('A002')
      a3 = Account.find_by_sis_source_id('A003')
      a4 = Account.find_by_sis_source_id('A004')
      a1.parent_account.should == @account
      a2.parent_account.should == a1
      a3.parent_account.should == a2
      a4.parent_account.should == a2

      Account.find_by_sis_source_id('A002').workflow_state.should == "deleted"
      Account.find_by_sis_source_id('A003').name.should == "English Literature"

    end

    it 'should support sticky fields' do
      process_csv_data_cleanly(
        "account_id,parent_account_id,name,status",
        "A001,,Humanities,active"
      )
      Account.find_by_sis_source_id('A001').name.should == "Humanities"
      process_csv_data_cleanly(
        "account_id,parent_account_id,name,status",
        "A001,,Math,active"
      )
      Account.find_by_sis_source_id('A001').tap do |a|
        a.name.should == "Math"
        a.name = "Science"
        a.save!
      end
      process_csv_data_cleanly(
        "account_id,parent_account_id,name,status",
        "A001,,History,active"
      )
      Account.find_by_sis_source_id('A001').name.should == "Science"
    end
  end

  context 'term importing' do
    it 'should skip bad content' do
      before_count = EnrollmentTerm.count
      importer = process_csv_data(
        "term_id,name,status,start_date,end_date",
        "T001,Winter11,active,,",
        ",Winter13,active,,",
        "T002,Winter10,inactive,,",
        "T003,,active,,"
      )
      EnrollmentTerm.count.should == before_count + 1

      importer.errors.should == []
      warnings = importer.warnings.map { |r| r.last }
      warnings.should == ["No term_id given for a term",
                        "Improper status \"inactive\" for term T002",
                        "No name given for term T003"]
    end

    it 'should create terms' do
      before_count = EnrollmentTerm.count
      importer = process_csv_data(
        "term_id,name,status,start_date,end_date",
        "T001,Winter11,active,2011-1-05 00:00:00,2011-4-14 00:00:00",
        "T002,Winter12,active,2012-13-05 00:00:00,2012-14-14 00:00:00",
        "T003,Winter13,active,,"
      )
      EnrollmentTerm.count.should == before_count + 3

      t1 = @account.enrollment_terms.find_by_sis_source_id('T001')
      t1.should_not be_nil
      t1.name.should == 'Winter11'
      t1.start_at.to_s(:db).should == '2011-01-05 00:00:00'
      t1.end_at.to_s(:db).should == '2011-04-14 00:00:00'

      t2 = @account.enrollment_terms.find_by_sis_source_id('T002')
      t2.should_not be_nil
      t2.name.should == 'Winter12'
      t2.start_at.should be_nil
      t2.end_at.should be_nil

      importer.warnings.map{|r|r.last}.should == ["Bad date format for term T002"]
      importer.errors.should == []
    end

    it 'should support stickiness' do
      before_count = EnrollmentTerm.count
      importer = process_csv_data(
        "term_id,name,status,start_date,end_date",
        "T001,Winter11,active,2011-1-05 00:00:00,2011-4-14 00:00:00")
      EnrollmentTerm.count.should == before_count + 1
      EnrollmentTerm.last.tap do |t|
        t.name.should == "Winter11"
        t.start_at.should == DateTime.parse("2011-1-05 00:00:00")
        t.end_at.should == DateTime.parse("2011-4-14 00:00:00")
      end
      importer = process_csv_data(
        "term_id,name,status,start_date,end_date",
        "T001,Winter12,active,2010-1-05 00:00:00,2010-4-14 00:00:00")
      EnrollmentTerm.count.should == before_count + 1
      EnrollmentTerm.last.tap do |t|
        t.name.should == "Winter12"
        t.start_at.should == DateTime.parse("2010-1-05 00:00:00")
        t.end_at.should == DateTime.parse("2010-4-14 00:00:00")
        t.name = "Fall11"
        t.start_at = DateTime.parse("2009-1-05 00:00:00")
        t.end_at = DateTime.parse("2009-4-14 00:00:00")
        t.save!
      end
      importer = process_csv_data(
        "term_id,name,status,start_date,end_date",
        "T001,Fall12,active,2011-1-05 00:00:00,2011-4-14 00:00:00")
      EnrollmentTerm.count.should == before_count + 1
      EnrollmentTerm.last.tap do |t|
        t.name.should == "Fall11"
        t.start_at.should == DateTime.parse("2009-1-05 00:00:00")
        t.end_at.should == DateTime.parse("2009-4-14 00:00:00")
      end
    end
  end

  context 'section importing' do
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
      CourseSection.count.should == before_count + 1

      importer.errors.should == []
      warnings = importer.warnings.map { |r| r.last }
      warnings.should == ["No course_id given for a section S002",
                        "No section_id given for a section in course C001",
                        "Improper status \"inactive\" for section S003 in course C002",
                        "No name given for section S004 in course C002",
                        "Section S005 references course C001 which doesn't exist"]
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
      CourseSection.count.should == before_count + 1
      CourseSection.last.name.should == "Sec1"
      process_csv_data_cleanly(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C001,Sec2,2011-1-05 00:00:00,2011-4-14 00:00:00,active")
      CourseSection.count.should == before_count + 1
      CourseSection.last.tap do |s|
        s.name.should == "Sec2"
        s.name = "Sec3"
        s.save!
      end
      process_csv_data_cleanly(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C001,Sec4,2011-1-05 00:00:00,2011-4-14 00:00:00,active")
      CourseSection.count.should == before_count + 1
      CourseSection.last.name.should == "Sec3"
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
      CourseSection.count.should == before_count + 2

      course = @account.courses.find_by_sis_source_id("C001")

      s1 = course.course_sections.find_by_sis_source_id('S001')
      s1.should_not be_nil
      s1.name.should == 'Sec1'
      s1.start_at.to_s(:db).should == '2011-01-05 00:00:00'
      s1.end_at.to_s(:db).should == '2011-04-14 00:00:00'

      s2 = course.course_sections.find_by_sis_source_id('S002')
      s2.should_not be_nil
      s2.name.should == 'Sec2'
      s2.start_at.should be_nil
      s2.end_at.should be_nil

      importer.warnings.map{|r|r.last}.should == ["Bad date format for section S002",
                                                  "Section S003 references course C002 which doesn't exist"]
      importer.errors.should == []
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
      course = @account.courses.find_by_sis_source_id('test1')
      course.course_sections.find_by_sis_source_id("sec1").restrict_enrollments_to_section_dates.should be_false
      course.course_sections.find_by_sis_source_id("sec2").restrict_enrollments_to_section_dates.should be_true
      course.course_sections.find_by_sis_source_id("sec3").restrict_enrollments_to_section_dates.should be_true
      course.course_sections.find_by_sis_source_id("sec4").restrict_enrollments_to_section_dates.should be_true
    end

    it 'should support start/end date and restriction stickiness' do
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
        "test1,TC 101,Test Course 1,,,active,,"
      )
      course = @account.courses.find_by_sis_source_id('test1')
      process_csv_data_cleanly(
        "section_id,course_id,name,status,start_date,end_date",
        "sec4,test1,Test Course 4,active,2011-04-14 00:00:00,2011-05-14 00:00:00"
      )
      course.course_sections.find_by_sis_source_id("sec4").tap do |section|
        section.restrict_enrollments_to_section_dates.should be_true
        section.start_at.should == DateTime.parse("2011-04-14 00:00:00")
        section.end_at.should == DateTime.parse("2011-05-14 00:00:00")
        section.restrict_enrollments_to_section_dates = false
        section.start_at = DateTime.parse("2010-04-14 00:00:00")
        section.end_at = DateTime.parse("2010-05-14 00:00:00")
        section.save!
      end
      process_csv_data_cleanly(
        "section_id,course_id,name,status,start_date,end_date",
        "sec4,test1,Test Course 4,active,2011-04-14 00:00:00,2011-05-14 00:00:00"
      )
      course.course_sections.find_by_sis_source_id("sec4").tap do |section|
        section.restrict_enrollments_to_section_dates.should be_false
        section.start_at.should == DateTime.parse("2010-04-14 00:00:00")
        section.end_at.should == DateTime.parse("2010-05-14 00:00:00")
      end
    end


    it 'should verify xlist files' do
      importer = process_csv_data(
        "xlist_course_id,section_id,status",
        ",S001,active"
      )
      importer.errors.should == []
      importer.warnings.map{|r|r.last}.should == ["No xlist_course_id given for a cross-listing"]
      importer = process_csv_data(
        "xlist_course_id,section_id,status",
        "X001,,active"
      )
      importer.errors.should == []
      importer.warnings.map{|r|r.last}.should == ["No section_id given for a cross-listing"]
      importer = process_csv_data(
        "xlist_course_id,section_id,status",
        "X001,S001,"
      )
      importer.errors.should == []
      importer.warnings.map{|r|r.last}.should == ['Improper status "" for a cross-listing']
      importer = process_csv_data(
        "xlist_course_id,section_id,status",
        "X001,S001,baleeted"
      )
      importer.errors.should == []
      importer.warnings.map{|r|r.last}.should == ['Improper status "baleeted" for a cross-listing']
      @account.courses.size.should == 0
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

      course = @account.courses.find_by_sis_source_id("C001")
      s1 = course.course_sections.find_by_sis_source_id("S001")
      s1.should_not be_nil
      s1.nonxlist_course.should be_nil
      s1.account.should be_nil
      course.course_sections.find_by_sis_source_id("S002").should_not be_nil
      course.associated_accounts.map(&:id).sort.should == [@account.id]
      @account.courses.find_by_sis_source_id("X001").should be_nil

      process_csv_data_cleanly(
        "xlist_course_id,section_id,status",
        "X001,S001,active"
      )

      xlist_course = @account.courses.find_by_sis_source_id("X001")
      xlist_course.associated_accounts.map(&:id).sort.should == [@account.id]
      course = @account.courses.find_by_sis_source_id("C001")
      course.associated_accounts.map(&:id).sort.should == [@account.id]
      s1 = xlist_course.course_sections.find_by_sis_source_id("S001")
      s1.should_not be_nil
      s1.nonxlist_course.should eql(course)
      s1.account.should be_nil
      course.course_sections.find_by_sis_source_id("S001").should be_nil
      course.course_sections.find_by_sis_source_id("S002").should_not be_nil

      process_csv_data_cleanly(
        "xlist_course_id,section_id,status",
        "X001,S001,deleted"
      )

      xlist_course = @account.courses.find_by_sis_source_id("X001")
      course = @account.courses.find_by_sis_source_id("C001")
      xlist_course.course_sections.find_by_sis_source_id("S001").should be_nil
      xlist_course.associated_accounts.map(&:id).sort.should == [@account.id]
      s1 = course.course_sections.find_by_sis_source_id("S001")
      s1.should_not be_nil
      s1.nonxlist_course.should be_nil
      s1.account.should be_nil
      course.course_sections.find_by_sis_source_id("S002").should_not be_nil
      course.associated_accounts.map(&:id).sort.should == [@account.id]

      xlist_course.name.should == "Test Course 101"
      xlist_course.short_name.should == "TC 101"
      xlist_course.sis_source_id.should == "X001"
      xlist_course.root_account_id.should == @account.id
      xlist_course.account_id.should == @account.id
      xlist_course.workflow_state.should == "claimed"
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
      @account.courses.find_by_sis_source_id("C001").deleted?.should be_false
      @account.courses.find_by_sis_source_id("C002").deleted?.should be_false
      process_csv_data_cleanly(
        "xlist_course_id,section_id,status",
        "X001,S001,active",
        "X001,S002,active",
        "X002,S004,active",
        "X002,S005,active"
      )
      @account.courses.find_by_sis_source_id("C001").deleted?.should be_false
      @account.courses.find_by_sis_source_id("C002").deleted?.should be_false
      @account.courses.find_by_sis_source_id("X001").deleted?.should be_false
      @account.courses.find_by_sis_source_id("X002").deleted?.should be_false
      @account.courses.find_by_sis_source_id("X001").name.should == "Test Course 101"
      @account.courses.find_by_sis_source_id("X002").name.should == "Test Course 102"
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "C001,TC 103,Test Course 103,,,active",
        "C002,TC 104,Test Course 104,,,active"
      )
      @account.courses.find_by_sis_source_id("C001").deleted?.should be_false
      @account.courses.find_by_sis_source_id("C002").deleted?.should be_false
      @account.courses.find_by_sis_source_id("X001").deleted?.should be_false
      @account.courses.find_by_sis_source_id("X002").deleted?.should be_false
      @account.courses.find_by_sis_source_id("X001").name.should == "Test Course 103"
      @account.courses.find_by_sis_source_id("X002").name.should == "Test Course 104"
      process_csv_data_cleanly(
        "xlist_course_id,section_id,status",
        "X001,S001,deleted",
        "X001,S002,deleted",
        "X002,S004,deleted",
        "X002,S005,deleted"
      )
      @account.courses.find_by_sis_source_id("C001").deleted?.should be_false
      @account.courses.find_by_sis_source_id("C002").deleted?.should be_false
      @account.courses.find_by_sis_source_id("X001").deleted?.should be_false
      @account.courses.find_by_sis_source_id("X002").deleted?.should be_false
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

      course = @account.courses.find_by_sis_source_id("C001")
      s1 = course.course_sections.find_by_sis_source_id("S001")
      s1.should_not be_nil
      s1.nonxlist_course.should be_nil
      s1.account.should be_nil
      course.course_sections.find_by_sis_source_id("S002").should_not be_nil
      @account.courses.find_by_sis_source_id("X001").should_not be_nil

      process_csv_data_cleanly(
        "xlist_course_id,section_id,status",
        "X001,S001,active"
      )

      xlist_course = @account.courses.find_by_sis_source_id("X001")
      course = @account.courses.find_by_sis_source_id("C001")
      s1 = xlist_course.course_sections.find_by_sis_source_id("S001")
      s1.should_not be_nil
      s1.nonxlist_course.should eql(course)
      s1.account.should be_nil
      course.course_sections.find_by_sis_source_id("S001").should be_nil
      course.course_sections.find_by_sis_source_id("S002").should_not be_nil

      process_csv_data_cleanly(
        "xlist_course_id,section_id,status",
        "X001,S001,deleted"
      )

      xlist_course = @account.courses.find_by_sis_source_id("X001")
      course = @account.courses.find_by_sis_source_id("C001")
      xlist_course.course_sections.find_by_sis_source_id("S001").should be_nil
      s1 = course.course_sections.find_by_sis_source_id("S001")
      s1.should_not be_nil
      s1.nonxlist_course.should be_nil
      s1.account.should be_nil
      course.course_sections.find_by_sis_source_id("S002").should_not be_nil

      xlist_course.name.should == "Test Course 102"
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

      xlist_course_1 = @account.courses.find_by_sis_source_id("X001")
      xlist_course_2 = @account.courses.find_by_sis_source_id("X002")
      xlist_course_1.course_sections.find_by_sis_source_id("S001").should_not be_nil
      xlist_course_1.course_sections.find_by_sis_source_id("S002").should_not be_nil
      xlist_course_1.course_sections.find_by_sis_source_id("S003").should_not be_nil
      xlist_course_2.course_sections.find_by_sis_source_id("S004").should_not be_nil
      xlist_course_1.course_sections.find_by_sis_source_id("S005").should_not be_nil
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

        xlist_course = @account.courses.find_by_sis_source_id("X001")
        course = @account.courses.find_by_sis_source_id("C001")
        s1 = xlist_course.course_sections.find_by_sis_source_id("S001")
        s1.should_not be_nil
        s1.nonxlist_course.should eql(course)
        s1.account.should be_nil
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

      xlist_course = @account.courses.find_by_sis_source_id("X001")
      course = @account.courses.find_by_sis_source_id("C001")
      s1 = xlist_course.course_sections.find_by_sis_source_id("S001")
      s1.should_not be_nil
      s1.nonxlist_course.should eql(course)
      s1.account.should be_nil

      3.times do
        process_csv_data_cleanly(
          "xlist_course_id,section_id,status",
          "X001,S001,deleted"
        )

        course = @account.courses.find_by_sis_source_id("C001")
        s1 = course.course_sections.find_by_sis_source_id("S001")
        s1.should_not be_nil
        s1.nonxlist_course.should be_nil
        s1.account.should be_nil
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

        xlist_course = @account.courses.find_by_sis_source_id("X00#{i}")
        course = @account.courses.find_by_sis_source_id("C001")
        s1 = xlist_course.course_sections.find_by_sis_source_id("S001")
        s1.should_not be_nil
        s1.nonxlist_course.should eql(course)
        s1.course.should eql(xlist_course)
        s1.account.should be_nil
        s1.crosslisted?.should be_true
      end
      process_csv_data_cleanly(
        "xlist_course_id,section_id,status",
        "X101,S001,deleted"
      )

      course = @account.courses.find_by_sis_source_id("C001")
      s1 = course.course_sections.find_by_sis_source_id("S001")
      s1.should_not be_nil
      s1.nonxlist_course.should be_nil
      s1.course.should eql(course)
      s1.account.should be_nil
      s1.crosslisted?.should be_false
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
      xlist_course = @account.courses.find_by_sis_source_id("X001")
      course = @account.courses.find_by_sis_source_id("C001")
      s1 = xlist_course.course_sections.find_by_sis_source_id("S001")
      s1.should_not be_nil
      s1.nonxlist_course.should eql(course)
      s1.course.should eql(xlist_course)
      s1.crosslisted?.should be_true
      s1.name.should == "Sec1"
      process_csv_data_cleanly(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C001,Sec2,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
      )
      xlist_course = @account.courses.find_by_sis_source_id("X001")
      course = @account.courses.find_by_sis_source_id("C001")
      s1 = xlist_course.course_sections.find_by_sis_source_id("S001")
      s1.should_not be_nil
      s1.nonxlist_course.should eql(course)
      s1.course.should eql(xlist_course)
      s1.crosslisted?.should be_true
      s1.name.should == "Sec2"
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
      course1 = @account.courses.find_by_sis_source_id("C001")
      course2 = @account.courses.find_by_sis_source_id("C002")
      s1 = course1.course_sections.find_by_sis_source_id("S001")
      s1.course.should eql(course1)
      process_csv_data_cleanly(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C002,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
      )
      course1.reload
      course2.reload
      s1.reload
      s1.course.should eql(course2)
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
      xlist_course = @account.courses.find_by_sis_source_id("X001")
      course1 = @account.courses.find_by_sis_source_id("C001")
      course2 = @account.courses.find_by_sis_source_id("C002")
      s1 = xlist_course.course_sections.find_by_sis_source_id("S001")
      s1.should_not be_nil
      s1.nonxlist_course.should eql(course1)
      s1.course.should eql(xlist_course)
      s1.account.should be_nil
      s1.crosslisted?.should be_true
      process_csv_data_cleanly(
        "section_id,course_id,name,start_date,end_date,status",
        "S001,C002,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
      )
      s1.reload
      s1.nonxlist_course.should be_nil
      s1.course.should eql(course2)
      s1.account.should be_nil
      s1.crosslisted?.should be_false
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
        CourseSection.find_by_root_account_id_and_sis_source_id(@account.id, 'S001').tap(&block)
      end
      def check_section_crosslisted(sis_id)
        with_section do |s|
          s.course.sis_source_id.should == sis_id
          s.nonxlist_course.sis_source_id.should == 'C001'
        end
      end
      def check_section_not_crosslisted
        with_section do |s|
          s.course.sis_source_id.should == 'C001'
          s.nonxlist_course.should be_nil
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
        s.crosslist_to_course(Course.find_by_root_account_id_and_sis_source_id(@account.id, 'C002'))
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
        CourseSection.find_by_root_account_id_and_sis_source_id(@account.id, 'S001').tap(&block)
      end
      def check_section_crosslisted(sis_id)
        with_section do |s|
          s.course.sis_source_id.should == sis_id
          s.nonxlist_course.sis_source_id.should == 'C001'
        end
      end
      def check_section_not_crosslisted
        with_section do |s|
          s.course.sis_source_id.should == 'C001'
          s.nonxlist_course.should be_nil
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

  end

  context 'grade publishing results importing' do
    it 'should skip bad content' do
      importer = process_csv_data(
        "enrollment_id,grade_publishing_status",
        ",published",
        "1,published",
        "2,asplode")

      importer.errors.should == []
      warnings = importer.warnings.map { |r| r.last }
      warnings.should == ["No enrollment_id given",
                        "Enrollment 1 doesn't exist",
                        "Improper grade_publishing_status \"asplode\" for enrollment 2"]
    end

    it 'should properly update the db' do
      course_with_student
      @course.account = @account;
      @course.save!

      @enrollment.grade_publishing_status = 'publishing';
      @enrollment.save!

      process_csv_data_cleanly(
        "enrollment_id,grade_publishing_status",
        "#{@enrollment.id},published")

      @enrollment.reload
      @enrollment.grade_publishing_status.should == 'published'
    end

    it 'should properly pass in messages' do
      course_with_student
      @course.account = @account;
      @course.save!

      @enrollment.grade_publishing_status = 'publishing';
      @enrollment.save!

      @course.grade_publishing_status.should == 'publishing'

      process_csv_data_cleanly(
        "enrollment_id,grade_publishing_status,message",
        "#{@enrollment.id},published,message1")

      @course.grade_publishing_status.should == 'published'
      @course.grade_publishing_messages.should == { "Published: message1" => 1 }

      @enrollment.reload
      @enrollment.grade_publishing_status.should == 'published'
    end
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

    context 'course' do
      it 'should change course account associations when a course account changes' do
        process_csv_data_cleanly(
          "course_id,short_name,long_name,account_id,term_id,status",
          "test_1,TC 101,Test Course 101,,,active"
        )
        Course.find_by_sis_source_id("test_1").associated_accounts.map(&:id).should == [@account.id]
        process_csv_data_cleanly(
          "course_id,short_name,long_name,account_id,term_id,status",
          "test_1,TC 101,Test Course 101,A001,,active"
        )
        Course.find_by_sis_source_id("test_1").associated_accounts.map(&:id).sort.should == [Account.find_by_sis_source_id('A001').id, @account.id].sort
        process_csv_data_cleanly(
          "course_id,short_name,long_name,account_id,term_id,status",
          "test_1,TC 101,Test Course 101,A004,,active"
        )
        Course.find_by_sis_source_id("test_1").associated_accounts.map(&:id).sort.should == [Account.find_by_sis_source_id('A004').id, @account.id].sort
        process_csv_data_cleanly(
          "course_id,short_name,long_name,account_id,term_id,status",
          "test_1,TC 101,Test Course 101,A003,,active"
        )
        Course.find_by_sis_source_id("test_1").associated_accounts.map(&:id).sort.should == [Account.find_by_sis_source_id('A003').id, Account.find_by_sis_source_id('A002').id, Account.find_by_sis_source_id('A001').id, @account.id].sort
        process_csv_data_cleanly(
          "course_id,short_name,long_name,account_id,term_id,status",
          "test_1,TC 101,Test Course 101,A001,,active"
        )
        Course.find_by_sis_source_id("test_1").associated_accounts.map(&:id).sort.should == [Account.find_by_sis_source_id('A001').id, @account.id].sort
      end
    end

    context 'section' do
      before(:each) do
        process_csv_data_cleanly(
          "course_id,short_name,long_name,account_id,term_id,status",
          "C001,TC 101,Test Course 101,,,active",
          "C002,TC 101,Test Course 101,A001,,active",
          "C003,TC 101,Test Course 101,A002,,active",
          "C004,TC 101,Test Course 101,A003,,active",
          "C005,TC 101,Test Course 101,A004,,active"
        )
      end

      it 'should change course account associations when a section account changes' do
        process_csv_data_cleanly(
          "section_id,course_id,name,start_date,end_date,status,account_id",
          "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active,"
        )
        Course.find_by_sis_source_id("C001").associated_accounts.map(&:id).should == [@account.id]
        process_csv_data_cleanly(
          "section_id,course_id,name,start_date,end_date,status,account_id",
          "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active,A001"
        )
        Course.find_by_sis_source_id("C001").associated_accounts.map(&:id).sort.should == [@account.id, Account.find_by_sis_source_id('A001').id].sort
        process_csv_data_cleanly(
          "section_id,course_id,name,start_date,end_date,status,account_id",
          "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active,A004"
        )
        Course.find_by_sis_source_id("C001").associated_accounts.map(&:id).sort.should == [@account.id, Account.find_by_sis_source_id('A004').id].sort
      end

      it 'should change course account associations when a section is not crosslisted and the original section\'s course changes via sis' do
        process_csv_data_cleanly(
          "section_id,course_id,name,start_date,end_date,status,account_id",
          "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active,A004"
        )
        Course.find_by_sis_source_id("C001").associated_accounts.map(&:id).sort.should == [@account.id, Account.find_by_sis_source_id('A004').id].sort
        Course.find_by_sis_source_id("C002").associated_accounts.map(&:id).sort.should == [Account.find_by_sis_source_id('A001').id, @account.id].sort
        process_csv_data_cleanly(
          "section_id,course_id,name,start_date,end_date,status,account_id",
          "S001,C002,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active,A004"
        )
        Course.find_by_sis_source_id("C001").associated_accounts.map(&:id).should == [@account.id]
        Course.find_by_sis_source_id("C002").associated_accounts.map(&:id).sort.should == [Account.find_by_sis_source_id('A001').id, Account.find_by_sis_source_id('A004').id, @account.id].sort
      end

      it 'should change course account associations when a section is crosslisted and the original section\'s course changes via sis' do
        process_csv_data_cleanly(
          "section_id,course_id,name,start_date,end_date,status,account_id",
          "S001,C002,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active,A004"
        )
        Course.find_by_sis_source_id("C001").associated_accounts.map(&:id).should == [@account.id]
        Course.find_by_sis_source_id("C002").associated_accounts.map(&:id).sort.should == [Account.find_by_sis_source_id('A001').id, Account.find_by_sis_source_id('A004').id, @account.id].sort
        process_csv_data_cleanly(
          "xlist_course_id,section_id,status",
          "X001,S001,active"
        )
        Course.find_by_sis_source_id("C001").associated_accounts.map(&:id).should == [@account.id]
        Course.find_by_sis_source_id("C002").associated_accounts.map(&:id).sort.should == [Account.find_by_sis_source_id('A001').id, @account.id].sort
        Course.find_by_sis_source_id("X001").associated_accounts.map(&:id).sort.should == [Account.find_by_sis_source_id('A001').id, Account.find_by_sis_source_id('A004').id, @account.id].sort
        process_csv_data_cleanly(
          "section_id,course_id,name,start_date,end_date,status,account_id",
          "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active,A004"
        )
        Course.find_by_sis_source_id("C001").associated_accounts.map(&:id).sort.should == [@account.id, Account.find_by_sis_source_id('A004').id].sort
        Course.find_by_sis_source_id("C002").associated_accounts.map(&:id).sort.should == [Account.find_by_sis_source_id('A001').id, @account.id].sort
        Course.find_by_sis_source_id("X001").associated_accounts.map(&:id).sort.should == [Account.find_by_sis_source_id('A001').id, @account.id].sort
      end
    end

    context 'crosslist course' do
      before(:each) do
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
          "section_id,course_id,name,start_date,end_date,status,account_id",
          "S001,C002,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active,A004"
        )
        process_csv_data_cleanly(
          "xlist_course_id,section_id,status",
          "X001,S001,active"
        )
        Course.find_by_sis_source_id("X001").associated_accounts.map(&:id).sort.should == [Account.find_by_sis_source_id('A001').id, Account.find_by_sis_source_id('A004').id, @account.id].sort
        process_csv_data_cleanly(
          "xlist_course_id,section_id,status",
          "X001,S001,deleted"
        )
        Course.find_by_sis_source_id("X001").associated_accounts.map(&:id).sort.should == [Account.find_by_sis_source_id('A001').id, @account.id].sort
      end

      it 'should have proper account associations when being undeleted' do
        process_csv_data_cleanly(
          "section_id,course_id,name,start_date,end_date,status,account_id",
          "S001,C002,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active,A004",
          "S002,C002,Sec2,2011-1-05 00:00:00,2011-4-14 00:00:00,active,A004"
        )
        process_csv_data_cleanly(
          "xlist_course_id,section_id,status",
          "X001,S001,active"
        )
        Course.find_by_sis_source_id("X001").deleted?.should be_false
        process_csv_data_cleanly(
          "course_id,short_name,long_name,account_id,term_id,status",
          "X001,TC 101,Test Course 101,,,deleted"
        )
        Course.find_by_sis_source_id("X001").deleted?.should be_true
        process_csv_data_cleanly(
          "xlist_course_id,section_id,status",
          "X001,S002,active"
        )
        Course.find_by_sis_source_id("X001").deleted?.should be_false
        Course.find_by_sis_source_id("X001").associated_accounts.map(&:id).sort.should == [Account.find_by_sis_source_id('A001').id, Account.find_by_sis_source_id('A004').id, @account.id].sort
      end

      it 'should have proper account associations when a section is added and then removed' do
        process_csv_data_cleanly(
          "section_id,course_id,name,start_date,end_date,status,account_id",
          "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active,A004"
        )
        Course.find_by_sis_source_id("C001").associated_accounts.map(&:id).sort.should == [@account.id, Account.find_by_sis_source_id('A004').id].sort
        Course.find_by_sis_source_id("C002").associated_accounts.map(&:id).sort.should == [Account.find_by_sis_source_id('A001').id, @account.id].sort
        process_csv_data_cleanly(
          "xlist_course_id,section_id,status",
          "C002,S001,active"
        )
        Course.find_by_sis_source_id("C001").associated_accounts.map(&:id).should == [@account.id]
        Course.find_by_sis_source_id("C002").associated_accounts.map(&:id).sort.should == [Account.find_by_sis_source_id('A001').id, Account.find_by_sis_source_id('A004').id, @account.id].sort
        process_csv_data_cleanly(
          "xlist_course_id,section_id,status",
          "C002,S001,deleted"
        )
        Course.find_by_sis_source_id("C001").associated_accounts.map(&:id).sort.should == [@account.id, Account.find_by_sis_source_id('A004').id].sort
        Course.find_by_sis_source_id("C002").associated_accounts.map(&:id).sort.should == [Account.find_by_sis_source_id('A001').id, @account.id].sort
      end

      it 'should get account associations updated when the template course is updated' do
        process_csv_data_cleanly(
          "section_id,course_id,name,start_date,end_date,status,account_id",
          "S001,C001,Sec1,2011-1-05 00:00:00,2011-4-14 00:00:00,active"
        )
        process_csv_data_cleanly(
          "xlist_course_id,section_id,status",
          "X001,S001,active"
        )
        Course.find_by_sis_source_id("C001").associated_accounts.map(&:id).should == [@account.id]
        Course.find_by_sis_source_id("X001").associated_accounts.map(&:id).should == [@account.id]
        process_csv_data_cleanly(
          "course_id,short_name,long_name,account_id,term_id,status",
          "C001,TC 101,Test Course 101,A004,,active"
        )
        Course.find_by_sis_source_id("C001").associated_accounts.map(&:id).sort.should == [Account.find_by_sis_source_id('A004').id, @account.id].sort
        Course.find_by_sis_source_id("X001").associated_accounts.map(&:id).sort.should == [Account.find_by_sis_source_id('A004').id, @account.id].sort
        process_csv_data_cleanly(
          "course_id,short_name,long_name,account_id,term_id,status",
          "C001,TC 101,Test Course 101,A001,,active"
        )
        Course.find_by_sis_source_id("C001").associated_accounts.map(&:id).sort.should == [Account.find_by_sis_source_id('A001').id, @account.id].sort
        Course.find_by_sis_source_id("X001").associated_accounts.map(&:id).sort.should == [Account.find_by_sis_source_id('A001').id, @account.id].sort
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
        course = Course.find_by_sis_source_id("C001")
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
        @account.courses.find_by_sis_source_id("C001").students.first.name.should == "User Uno"
        @account.courses.find_by_sis_source_id("X001").should be_nil
        process_csv_data_cleanly(
          "xlist_course_id,section_id,status",
          "X001,S001,active"
        )
        process_csv_data_cleanly(
          "course_id,user_id,role,section_id,status,associated_user_id",
          "C001,user_1,student,S001,active,"
        )
        @account.courses.find_by_sis_source_id("C001").students.size.should == 0
        @account.courses.find_by_sis_source_id("X001").students.first.name.should == "User Uno"
      end
    end

    it "user" do
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active",
        "user_2,user2,User,Dos,user2@example.com,deleted"
      )
      user1 = @account.pseudonyms.find_by_sis_user_id('user_1')
      user2 = @account.pseudonyms.find_by_sis_user_id('user_2')
      user1.user.user_account_associations.map { |uaa| [uaa.account_id, uaa.depth] }.should == [[@account.id, 0]]
      user2.user.user_account_associations.should be_empty

      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,deleted"
      )
      user1.reload
      user1.user.user_account_associations.should be_empty
    end
  end

  describe "group importing" do

    it "should skip bad content" do
      process_csv_data_cleanly(
        "account_id,parent_account_id,name,status",
        "A001,,TestAccount,active"
      )
      before_count = Group.count
      importer = process_csv_data(
        "group_id,account_id,name,status",
        "G001,A001,Group 1,available",
        "G002,A001,Group 1,blerged",
        "G003,A001,,available",
        "G004,A004,Group 4,available",
        ",A001,G1,available")
      importer.errors.should == []
      importer.warnings.map(&:last).should ==
        ["Improper status \"blerged\" for group G002, skipping",
         "No name given for group G003, skipping",
         "Parent account didn't exist for A004",
         "No group_id given for a group"]
      Group.count.should == before_count + 1
    end

    it "should create groups" do
      account_model
      @sub = @account.all_accounts.create!(:name => 'sub')
      @sub.update_attribute('sis_source_id', 'A002')
      process_csv_data_cleanly(
        "group_id,account_id,name,status",
        "G001,,Group 1,available",
        "G002,A002,Group 2,deleted")
      groups = Group.all(:order => :id)
      groups.map(&:account_id).should == [@account.id, @sub.id]
      groups.map(&:sis_source_id).should == %w(G001 G002)
      groups.map(&:name).should == ["Group 1", "Group 2"]
      groups.map(&:workflow_state).should == %w(available deleted)
    end

    it "should update group attributes" do
      @sub = @account.sub_accounts.create!(:name => 'sub')
      @sub.update_attribute('sis_source_id', 'A002')
      process_csv_data_cleanly(
        "group_id,account_id,name,status",
        "G001,,Group 1,available",
        "G002,,Group 2,available")
      Group.count.should == 2
      Group.find_by_sis_source_id('G001').update_attribute(:name, 'Group 1-1')
      process_csv_data_cleanly(
        "group_id,account_id,name,status",
        "G001,,Group 1-b,available",
        "G002,A002,Group 2-b,deleted")
      # group 1's name won't change because it was manually changed
      groups = Group.all(:order => :id)
      groups.map(&:name).should == ["Group 1-1", "Group 2-b"]
      groups.map(&:root_account).should == [@account, @account]
      groups.map(&:workflow_state).should == %w(available deleted)
      groups.map(&:account).should == [@account, @sub]
    end
  end

  describe "group membership importing" do
    before do
      group_model(:context => @account, :sis_source_id => "G001")
      @user1 = user_with_pseudonym(:username => 'u1@example.com')
      @user1.pseudonym.update_attribute(:sis_user_id, 'U001')
      @user1.pseudonym.update_attribute(:account, @account)
      @user2 = user_with_pseudonym(:username => 'u2@example.com')
      @user2.pseudonym.update_attribute(:sis_user_id, 'U002')
      @user2.pseudonym.update_attribute(:account, @account)
      @user3 = user_with_pseudonym(:username => 'u3@example.com')
      @user3.pseudonym.update_attribute(:sis_user_id, 'U003')
      @user3.pseudonym.update_attribute(:account, @account)
    end

    it "should skip bad content" do
      importer = process_csv_data(
        "group_id,user_id,status",
        ",U001,accepted",
        "G001,,accepted",
        "G001,U001,bogus")
      GroupMembership.count.should == 0
      importer.warnings.map(&:last).should ==
        ["No group_id given for a group user",
         "No user_id given for a group user",
         "Improper status \"bogus\" for a group user"]
      importer.errors.should == []
    end

    it "should add users to groups" do
      process_csv_data_cleanly(
        "group_id,user_id,status",
        "G001,U001,accepted",
        "G001,U003,deleted")
      ms = GroupMembership.all(:order => :id)
      ms.map(&:user_id).should == [@user1.id, @user3.id]
      ms.map(&:group_id).should == [@group.id, @group.id]
      ms.map(&:workflow_state).should == %w(accepted deleted)

      process_csv_data_cleanly(
        "group_id,user_id,status",
        "G001,U001,deleted",
        "G001,U003,deleted")
      ms = GroupMembership.all(:order => :id)
      ms.map(&:user_id).should == [@user1.id, @user3.id]
      ms.map(&:group_id).should == [@group.id, @group.id]
      ms.map(&:workflow_state).should == %w(deleted deleted)
    end
  end
end
