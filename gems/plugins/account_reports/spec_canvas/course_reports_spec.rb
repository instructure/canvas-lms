#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/report_spec_helper')

describe "Course Account Reports" do
  include ReportSpecHelper

  before(:once) do

    Notification.where(name: "Report Generated").first_or_create
    Notification.where(name: "Report Generation Failed").first_or_create
    @account = Account.create(name: 'New Account', default_time_zone: 'UTC')
    @admin = account_admin_user(:account => @account)
    @default_term = @account.default_enrollment_term

    @sub_account = Account.create(:parent_account => @account, :name => 'Math')
    @sub_account.sis_source_id = 'sub1'
    @sub_account.save!

    @term1 = EnrollmentTerm.create(:name => 'Fall', :start_at => 6.months.ago,
                                   :end_at => 1.year.from_now)
    @term1.root_account = @account
    @term1.sis_source_id = 'fall12'
    @term1.save!

    start_at = 1.day.ago
    end_at = 3.months.from_now
    @course1 = Course.create(:name => 'English 101', :course_code => 'ENG101',
                             :start_at => start_at, :conclude_at => end_at,
                             :account => @sub_account, :enrollment_term => @term1)
    @course1.sis_source_id = "SIS_COURSE_ID_1"
    @course1.restrict_enrollments_to_course_dates = true
    @course1.save!

    @course2 = Course.create(:name => 'Math 101', :course_code => 'MAT101',
                             :conclude_at => end_at, :account => @account)
    @course2.sis_source_id = "SIS_COURSE_ID_2"
    @course2.save!
    @course2.destroy

    @course3 = Course.create(:name => 'Science 101', :course_code => 'SCI101',
                             :account => @account)
    @course3.workflow_state = 'claimed'
    @course3.sis_source_id = "SIS_COURSE_ID_3"
    @course3.save!

    @course4 = Course.create(:name => 'self help', :course_code => 'self',
                             :account => @account)
    @course4.offer

    @course5 = Course.create(:name => 'talking 101', :course_code => 'Tal101',
                             :account => @account)
    @course5.workflow_state = 'completed'
    @course5.save!
  end

  describe "unpublished courses" do
    before(:each) do
      @report = 'unpublished_courses_csv'
    end

    it "should run unpublished courses report on a term" do
      parameters = {}
      parameters["enrollment_term_id"] = @default_term.id
      parsed = read_report(@report, {params: parameters})

      expect(parsed).to eq [[@course3.id.to_s, "SIS_COURSE_ID_3", "SCI101",
                         "Science 101", nil, nil]]
      expect(parsed.length).to eq 1

    end

    it "should run unpublished courses report on sub account" do
      parsed = read_report(@report, {account: @sub_account})

      expect(parsed).to eq [[@course1.id.to_s, "SIS_COURSE_ID_1", "ENG101",
                         "English 101", @course1.start_at.iso8601,
                         @course1.conclude_at.iso8601]]
      expect(parsed.length).to eq 1
    end

    it "should run unpublished courses report" do
      parsed = read_report(@report, {order: 1})
      expect(parsed).to eq [[@course1.id.to_s, "SIS_COURSE_ID_1", "ENG101",
                         "English 101", @course1.start_at.iso8601,
                         @course1.conclude_at.iso8601],
                        [@course3.id.to_s, "SIS_COURSE_ID_3", "SCI101",
                         "Science 101", nil, nil]]
      expect(parsed.length).to eq 2
    end
  end

  describe "deleted courses" do
    before(:each) do
      @report = 'recently_deleted_courses_csv'
    end

    it "should run recently deleted courses report on a term" do
      @course1.destroy
      parameters = {}
      parameters["enrollment_term_id"] = @default_term.id
      parsed = read_report(@report,{params: parameters})

      expect(parsed[0]).to eq [@course2.id.to_s, "SIS_COURSE_ID_2", "MAT101",
                           "Math 101", nil, nil]
      expect(parsed.length).to eq 1
    end

    it "should run recently deleted courses report on sub account" do
      @course1.destroy
      parsed = read_report(@report, {account: @sub_account})

      expect(parsed[0]).to eq [@course1.id.to_s, "SIS_COURSE_ID_1", "ENG101",
                           "English 101", @course1.start_at.iso8601,
                           @course1.conclude_at.iso8601]
      expect(parsed.length).to eq 1
    end

    it "should run recently deleted courses report" do
      @course1.destroy
      parsed = read_report(@report, {order: 1})
      expect(parsed.length).to eq 2

      expect(parsed[0]).to eq [@course1.id.to_s, "SIS_COURSE_ID_1", "ENG101",
                           "English 101", @course1.start_at.iso8601,
                           @course1.conclude_at.iso8601]
      expect(parsed[1]).to eq [@course2.id.to_s, "SIS_COURSE_ID_2", "MAT101",
                           "Math 101", nil, nil]
    end
  end
  describe "Unused Course report" do
    before(:once) do
      @type = 'unused_courses_csv'

      @course6 = Course.create(:name => 'Theology 101', :course_code => 'THE01',
                               :account => @account)

      @assignment = @course1.assignments.create(:title => "some assignment",
                                                :points_possible => "5")
      @discussion = @course2.discussion_topics.create!(:message => "hi")
      @attachment = attachment_model(:context => @course3)
      @module = @course4.context_modules.create!(:name => "some module")
      @quiz = @course5.quizzes.create!(:title => "new quiz")
    end

    it "should find courses with no active objects" do
      @assignment.destroy
      @attachment.destroy

      parsed = read_report(@type, {order: 3})
      expect(parsed.length).to eq 3

      expect(parsed[0]).to eq [@course1.id.to_s, "SIS_COURSE_ID_1", "ENG101",
                           "English 101", "unpublished",
                           @course1.created_at.iso8601]
      expect(parsed[1]).to eq [@course3.id.to_s, "SIS_COURSE_ID_3", "SCI101",
                           "Science 101", "unpublished",
                           @course3.created_at.iso8601]
      expect(parsed[2]).to eq [@course6.id.to_s, nil, "THE01",
                           "Theology 101", "unpublished",
                           @course6.created_at.iso8601]
    end

    it "should not find courses with objects" do
      @wiki_page = @course6.wiki.wiki_pages.create(
        :title => "Some random wiki page",
        :body => "wiki page content")
      report = run_report(@type)
      expect(report.parameters["extra_text"]).to eq "Term: All Terms;"
      parsed = parse_report(report)
      expect(parsed.length).to eq 0
    end

    it "should run unused courses report with a term" do
      @term1 = @account.enrollment_terms.create(:name => 'Fall')
      @assignment.destroy
      @course5.enrollment_term = @term1
      @course5.save
      @course6.enrollment_term = @term1
      @course6.save
      parameters = {}
      parameters["enrollment_term_id"] = @term1.id
      parsed = read_report(@type, {params: parameters})
      expect(parsed.length).to eq 1

      expect(parsed[0]).to eq [@course6.id.to_s, nil, "THE01",
                           "Theology 101", "unpublished",
                           @course6.created_at.iso8601]
    end

    it "should run unused courses report on a sub account" do
      sub_account = Account.create(:parent_account => @account,
                                   :name => 'English')
      @course3.account = sub_account
      @course3.save
      @course4.account = sub_account
      @course4.save
      @module.destroy
      parsed = read_report(@type, {account: sub_account})
      expect(parsed.length).to eq 1

      expect(parsed[0]).to eq [@course4.id.to_s, nil, "self",
                           "self help", "active",
                           @course4.created_at.iso8601]
    end
  end

  describe "course storage report" do
    before(:once) do
      @report = 'course_storage_csv'
      a = attachment_obj_with_context(@course1)
      a.update_attribute(:size, 1.226.megabyte)
      a = attachment_obj_with_context(@course2)
      a.update_attribute(:size, 3.megabyte)
      a = attachment_obj_with_context(@course5)
      a.update_attribute(:size, 11.megabyte)
      a = attachment_obj_with_context(@course5)
      a.update_attribute(:size, 1.megabyte)
      a = attachment_obj_with_context(@course4)
      a.update_attribute(:size, 4.6521.megabyte)
      a = attachment_obj_with_context(@course5)
      a.update_attribute(:size, 80.megabyte)
      child = attachment_obj_with_context(@course1)
      child.update_attribute(:size, 80.megabyte)
      child.root_attachment_id = a.id
      child.save!
    end

    it 'should add up storage for courses' do
      parsed = read_report(@report, {account: @account, order: "skip", header: true})
      expect(parsed.length).to eq 5
      headers = parsed.shift
      expect(headers.length).to eq parsed[0].length
      expect(parsed).to match_array [
                              [@course1.id.to_s, 'SIS_COURSE_ID_1', 'ENG101',
                               'English 101', @sub_account.id.to_s, 'sub1',
                               'Math', '1.23', '81.23'],
                              [@course3.id.to_s, 'SIS_COURSE_ID_3', 'SCI101',
                               'Science 101', @account.id.to_s, nil,
                               @account.name, '0.0', '0.0'],
                              [@course5.id.to_s, nil, 'Tal101', 'talking 101',
                               @account.id.to_s, nil, @account.name, '92.0', '92.0'],
                              [@course4.id.to_s, nil, 'self', 'self help',
                               @account.id.to_s, nil, @account.name, '4.65', '4.65']
      ]
    end

    it 'should add up storage for courses in sub account' do
      parsed = read_report(@report, {account: @sub_account})
      expect(parsed.length).to eq 1
      expect(parsed[0]).to eq [@course1.id.to_s, 'SIS_COURSE_ID_1', 'ENG101',
                               'English 101', @sub_account.id.to_s, 'sub1',
                               'Math', '1.23', '81.23']
    end
  end

end
