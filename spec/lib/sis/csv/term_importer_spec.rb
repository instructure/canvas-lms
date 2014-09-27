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

describe SIS::CSV::TermImporter do

  before { account_model }

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

    t1 = @account.enrollment_terms.where(sis_source_id: 'T001').first
    t1.should_not be_nil
    t1.name.should == 'Winter11'
    t1.start_at.to_s(:db).should == '2011-01-05 00:00:00'
    t1.end_at.to_s(:db).should == '2011-04-14 00:00:00'

    t2 = @account.enrollment_terms.where(sis_source_id: 'T002').first
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
