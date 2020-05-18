#
# Copyright (C) 2013 - present Instructure, Inc.
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
  let(:user) { User.create }
  let(:account_report) { AccountReport.new(report_type: 'test_report', account: account, user: user) }
  let(:report) { AccountReports::TestReport.new(account_report) }

  it 'should handle basic math' do
    # default min
    expect(report.number_of_items_per_runner(1)).to eq 25
    # divided by 99 to make for 100 jobs except for when exactly divisible by 99
    expect(report.number_of_items_per_runner(13001)).to eq 131
    # default max
    expect(report.number_of_items_per_runner(1801308213)).to eq 1000
    # override min
    expect(report.number_of_items_per_runner(100, min: 10)).to eq 10
    # override max
    expect(report.number_of_items_per_runner(109213081, max: 100)).to eq 100
  end

  it 'should create report runners with a single trip' do
    account_report.save!
    expect(AccountReport).to receive(:bulk_insert_objects).once.and_call_original
    report.create_report_runners((1..50).to_a, 50)
    expect(account_report.account_report_runners.count).to eq 2
  end

  it 'should create report runners with few trips to the db' do
    account_report.save!
    # lower the setting so we can do more than one trip with less data
    Setting.set("ids_per_report_runner_batch", 1_000)
    # once with 1_008 ids and 84 runners and then once with 200 ids and the
    # other runners
    expect(AccountReport).to receive(:bulk_insert_objects).twice.and_call_original
    # also got to pass min so that we get runners with 12 ids instead of 25
    report.create_report_runners((1..1_200).to_a, 1_201, min: 10)
    expect(account_report.account_report_runners.count).to eq 100
  end

  it 'should fail when no csv' do
    AccountReports.message_recipient(account_report, 'hi', nil)
    expect(account_report.parameters["extra_text"]).to eq "Failed, the report failed to generate a file. Please try again."
  end

  describe "load pseudonyms" do
    before(:once) do
      @user = user_with_pseudonym(active_all: true, account: account, user: user)
      course = account.courses.create!(name: 'reports')
      role = Enrollment.get_built_in_role_for_type('StudentEnrollment')
      @enrollmnent = course.enrollments.create!(user: @user,
                                                workflow_state: 'active',
                                                sis_pseudonym: @pseudonym,
                                                type: 'StudentEnrollment',
                                                role: role)
    end

    it 'should do one query for pseudonyms' do
      report.preload_logins_for_users([@user])
      expect(SisPseudonym).to receive(:for).never
      report.loaded_pseudonym({@user.id => [@pseudonym]}, @user, enrollment: @enrollmnent)
    end

    it 'should ignore deleted pseudonyms' do
      @pseudonym.destroy
      report.preload_logins_for_users([@user])
      expect(SisPseudonym).to receive(:for).once.and_call_original
      pseudonym = report.loaded_pseudonym({@user.id => [@pseudonym]}, @user, enrollment: @enrollmnent)
      expect(pseudonym).to be_nil
    end

    it 'should use deleted pseudonyms when passed' do
      @pseudonym.destroy
      report.preload_logins_for_users([@user])
      expect(SisPseudonym).to receive(:for).never
      pseudonym = report.loaded_pseudonym({@user.id => [@pseudonym]}, @user, include_deleted: true, enrollment: @enrollmnent)
      expect(pseudonym).to eq @pseudonym
    end
  end

  describe "#send_report" do
    before do
      allow(AccountReports).to receive(:available_reports).and_return(account_report.report_type => {title: 'test_report'})
      allow(report).to receive(:report_title).and_return('TitleReport')
    end

    it "Should not break for nil parameters" do
      expect(AccountReports).to receive(:message_recipient)
      report.send_report
    end

    it "Should allow aborting" do
      account_report.workflow_state = 'deleted'
      account_report.save!
      expect{report.write_report(['header']) { |csv| csv << 'hi' }}.to raise_error(/aborted/)
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

    it 'should parse time' do
      og_time = 1.day.ago.iso8601
      account_report.parameters = {'start_at' => og_time }
      time = report.restricted_datetime_from_param('start_at')
      expect(time).to eq og_time
    end

    it 'should parse and restrict time' do
      og_time = 2.days.ago.iso8601
      account_report.parameters = {'start_at' => og_time}
      restricted_time = 1.day.ago.iso8601
      time = report.restricted_datetime_from_param('start_at', earliest: restricted_time)
      expect(time).to eq restricted_time
    end

    it 'should parse and not change to restrict time' do
      og_time = 2.days.ago.iso8601
      account_report.parameters = {'start_at' => og_time}
      restricted_time = 3.days.ago.iso8601
      time = report.restricted_datetime_from_param('start_at', earliest: restricted_time)
      expect(time).to eq og_time
    end

    it 'should parse and restrict latest times' do
      og_time = 2.days.ago.iso8601
      account_report.parameters = {'end_at' => og_time}
      restricted_time = 3.days.ago.iso8601
      time = report.restricted_datetime_from_param('end_at', latest: restricted_time)
      expect(time).to eq restricted_time
    end

    it 'should fallback to a time' do
      og_time = 1.day.ago.iso8601
      account_report.parameters = {}
      time = report.restricted_datetime_from_param('start_at', fallback: og_time)
      expect(time).to eq og_time
    end

    it 'should only fallback to a time when one is not provided' do
      og_time = 1.day.ago.iso8601
      account_report.parameters = {'start_at' => og_time}
      other_time = 3.days.ago.iso8601
      time = report.restricted_datetime_from_param('start_at', fallback: other_time)
      expect(time).to eq og_time
    end
  end

  describe "#generate_and_run_report" do
    context 'i18n' do
      before do
        account_report.save!
        user.enable_feature!(:include_byte_order_mark_in_gradebook_exports)
        user.enable_feature!(:use_semi_colon_field_separators_in_gradebook_exports)
      end

      it "Should not have byte order mark and semicolons when i18n compatibility disabled" do
        file = report.generate_and_run_report(['h1', 'h2']) do |csv|
          csv << ['val1', 'val2']
        end
        contents = File.read(file)
        expect(contents).to eq "h1,h2\nval1,val2\n"
      end

      it "Should use i18n compatibility when enabled" do
        file = report.generate_and_run_report(['h1', 'h2'], 'csv', true) do |csv|
          csv << ['val1', 'val2']
        end
        contents = File.read(file)
        expect(contents).to eq "\xEF\xBB\xBFh1;h2\nval1;val2\n"
      end
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

        allow(report).to receive(:course).and_return(@course3)
        courses = report.add_course_scope(courses)
        expect(courses.count(:all)).to eq(1)
      end

      it 'should not add course scope if course is not set' do
        courses = Course.all

        allow(report).to receive(:course).and_return(nil)
        courses = report.add_course_scope(courses)
        expect(courses.count(:all)).to eq(3)
      end

    end

    describe '#add_term_scope' do
      it 'should add term scope if term is set' do
        courses = Course.all

        allow(report).to receive(:term).and_return(@enrollment_term)
        courses = report.add_term_scope(courses)
        expect(courses.count(:all)).to eq(2)
      end

      it 'should not add term scope if term is not set' do
        courses = Course.all

        allow(report).to receive(:term).and_return(nil)
        courses = report.add_term_scope(courses)
        expect(courses.count(:all)).to eq(3)
      end

    end

  end

end
