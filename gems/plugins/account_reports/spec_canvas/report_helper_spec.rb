#
# Copyright (C) 2013 - 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../../spec/spec_helper')

module AccountReports
  class TestReport
    include ReportHelper

    def initialize(account_report)
      @account_report = account_report
    end
  end
end

describe "report helper" do
  let(:account) { Account.default }
  let(:account_report) { AccountReport.new(:report_type => 'test_report', :account => account) }
  let(:report) { AccountReports::TestReport.new(account_report) }

  describe "#send_report" do
    before do
      AccountReports.stubs(available_reports: {account_report.report_type => {title: 'test_report'}})
      report.stubs(:report_title).returns('TitleReport')
    end

    it "Should not break for nil parameters" do
      AccountReports.expects(:message_recipient)
      report.send_report
    end
  end

  describe "timezone_strftime" do
    it "Should format DateTime" do
      date_time = DateTime.new(2003, 9, 13)
      formatted = report.timezone_strftime(date_time, '%d-%b')
      expect(formatted).to eq "13-Sep"
    end

    it "Should format Time" do
      time_zone = Time.use_zone('UTC') { Time.zone.parse('2013-09-13T00:00:00Z') }
      formatted = report.timezone_strftime(time_zone, '%d-%b')
      expect(formatted).to eq "13-Sep"
    end

    it "Should format String" do
      time_zone = Time.use_zone('UTC') { Time.zone.parse('2013-09-13T00:00:00Z') }
      formatted = report.timezone_strftime(time_zone.to_s, '%d-%b')
      expect(formatted).to eq "13-Sep"
    end
  end

  context 'Scopes' do

    before(:once) do
      @enrollment_term = EnrollmentTerm.new(workflow_state: 'active', name: 'Fall term', sis_source_id: 'fall14')
      @enrollment_term.root_account_id = account.id
      @enrollment_term.save!

      @enrollment_term2 = EnrollmentTerm.new(workflow_state: 'active', name: 'Summer term', sis_source_id: 'summer14')
      @enrollment_term2.root_account_id = account.id
      @enrollment_term2.save!

      @course1 = Course.new(:name => 'English 101', :course_code => 'ENG101',
                            :start_at => 1.day.ago, :conclude_at => 4.months.from_now,
                            :account => @sub_account1)
      @course1.enrollment_term = @enrollment_term
      @course1.sis_source_id = "SIS_COURSE_ID_1"
      @course1.save!

      @course2 = Course.new(:name => 'English 102', :course_code => 'ENG102',
                            :start_at => 1.day.ago, :conclude_at => 4.months.from_now,
                            :account => @sub_account1)
      @course2.enrollment_term = @enrollment_term
      @course2.sis_source_id = "SIS_COURSE_ID_2"
      @course2.save!

      @course3 = Course.new(:name => 'English 103', :course_code => 'ENG103',
                            :start_at => 1.day.ago, :conclude_at => 4.months.from_now,
                            :account => @sub_account2)
      @course3.enrollment_term = @enrollment_term2
      @course2.sis_source_id = "SIS_COURSE_ID_3"
      @course3.save!
    end

    describe '#add_course_scope' do

      it 'should add course scope if course is set' do
        courses = Course.all

        report.stubs(:course).returns(@course3)
        courses = report.add_course_scope(courses)
        expect(courses.count(:all)).to eq(1)
      end

      it 'should not add course scope if course is not set' do
        courses = Course.all

        report.stubs(:course).returns(nil)
        courses = report.add_course_scope(courses)
        expect(courses.count(:all)).to eq(3)
      end

    end

    describe '#add_term_scope' do
      it 'should add term scope if term is set' do
        courses = Course.all

        report.stubs(:term).returns(@enrollment_term)
        courses = report.add_term_scope(courses)
        expect(courses.count(:all)).to eq(2)
      end

      it 'should not add term scope if term is not set' do
        courses = Course.all

        report.stubs(:term).returns(nil)
        courses = report.add_term_scope(courses)
        expect(courses.count(:all)).to eq(3)
      end

    end

  end

end
