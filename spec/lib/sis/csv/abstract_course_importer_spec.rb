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

describe SIS::CSV::AbstractCourseImporter do

  before { account_model }

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
      c.enrollment_term.should == EnrollmentTerm.where(sis_source_id: 'T001').first
    end
    process_csv_data_cleanly(
      "abstract_course_id,short_name,long_name,account_id,term_id,status",
      "C001,Math101,Mathematics,A001,T002,active"
    )
    AbstractCourse.count.should == before_count + 1
    AbstractCourse.last.tap do |c|
      c.name.should == "Mathematics"
      c.short_name.should == "Math101"
      c.enrollment_term.should == EnrollmentTerm.where(sis_source_id: 'T002').first
      c.name = "Physics"
      c.short_name = "Phys101"
      c.enrollment_term = EnrollmentTerm.where(sis_source_id: 'T003').first
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
      c.enrollment_term.should == EnrollmentTerm.where(sis_source_id: 'T003').first
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
