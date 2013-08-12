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
  before(:each) do

    Notification.find_or_create_by_name("Report Generated")
    Notification.find_or_create_by_name("Report Generation Failed")
    @account = Account.default
    @admin = account_admin_user(:account => @account)
    @default_term = @account.enrollment_terms.active.find_or_create_by_name(
      EnrollmentTerm::DEFAULT_TERM_NAME
    )

    @sub_account = Account.create(:parent_account => @account, :name => 'Math')
    @sub_account.sis_source_id = 'sub1'
    @sub_account.save!

    @term1 = EnrollmentTerm.create(:name => 'Fall',:start_at => 6.months.ago,
                                   :end_at => 1.year.from_now)
    @term1.root_account = @account
    @term1.sis_source_id = 'fall12'
    @term1.save!

    start_at = 1.day.ago
    end_at = 3.months.from_now
    @course1 = Course.new(:name => 'English 101',:course_code => 'ENG101',
                          :start_at => start_at,:conclude_at => end_at,
                          :account => @sub_account, :enrollment_term => @term1)
    @course1.sis_source_id = "SIS_COURSE_ID_1"
    @course1.restrict_enrollments_to_course_dates = true
    @course1.save!

    @course2 = Course.new(:name => 'Math 101', :course_code => 'MAT101',
                          :conclude_at => end_at,:account => @account)
    @course2.sis_source_id = "SIS_COURSE_ID_2"
    @course2.save!
    @course2.destroy

    @course3 = Course.new(:name => 'Science 101', :course_code => 'SCI101',
                          :account => @account)
    @course3.workflow_state = 'claimed'
    @course3.sis_source_id = "SIS_COURSE_ID_3"
    @course3.save!

    @course4 = Course.new(:name => 'self help',:course_code => 'self')
    @course4.workflow_state = 'available'
    @course4.save!

    @course5 = Course.new(:name => 'talking 101',:course_code => 'Tal101')
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
      parsed = ReportSpecHelper.run_report(@account, @report, parameters)

      parsed.length.should == 1

      parsed[0].should == [@course3.id.to_s, "SIS_COURSE_ID_3", "SCI101",
                           "Science 101", nil, nil]
    end

    it "should run unpublished courses report on sub account" do
      parsed = ReportSpecHelper.run_report(@sub_account, @report)
      parsed.length.should == 1

      parsed[0].should == [@course1.id.to_s, "SIS_COURSE_ID_1", "ENG101",
                           "English 101", @course1.start_at.iso8601,
                           @course1.conclude_at.iso8601]
    end

    it "should run unpublished courses report" do
      parsed = ReportSpecHelper.run_report(@account, @report)
      parsed.length.should == 2

      parsed[0].should == [@course1.id.to_s, "SIS_COURSE_ID_1", "ENG101",
                           "English 101", @course1.start_at.iso8601,
                           @course1.conclude_at.iso8601]
      parsed[1].should == [@course3.id.to_s, "SIS_COURSE_ID_3", "SCI101",
                           "Science 101", nil, nil]
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
      parsed = ReportSpecHelper.run_report(@account, @report, parameters)

      parsed.length.should == 1

      parsed[0].should == [@course2.id.to_s, "SIS_COURSE_ID_2", "MAT101",
                           "Math 101", nil, nil]
    end

    it "should run recently deleted courses report on sub account" do
      @course1.destroy
      parsed = ReportSpecHelper.run_report(@sub_account, @report)
      parsed.length.should == 1

      parsed[0].should == [@course1.id.to_s, "SIS_COURSE_ID_1", "ENG101",
                           "English 101", @course1.start_at.iso8601,
                           @course1.conclude_at.iso8601]
    end

    it "should run recently deleted courses report" do
      @course1.destroy
      parsed = ReportSpecHelper.run_report(@account, @report)
      parsed.length.should == 2

      parsed[0].should == [@course1.id.to_s, "SIS_COURSE_ID_1", "ENG101",
                           "English 101", @course1.start_at.iso8601,
                           @course1.conclude_at.iso8601]
      parsed[1].should == [@course2.id.to_s, "SIS_COURSE_ID_2", "MAT101",
                           "Math 101", nil, nil]
    end
  end
  describe "Unused Course report" do
    before(:each) do
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
      parsed = ReportSpecHelper.run_report(@account,@type,{},3)
      parsed.length.should == 2

      parsed[0].should == [@course1.id.to_s, "SIS_COURSE_ID_1", "ENG101",
                           "English 101", "unpublished",
                           @course1.created_at.iso8601]
      parsed[1].should == [@course6.id.to_s, nil, "THE01",
                           "Theology 101", "unpublished",
                           @course6.created_at.iso8601]
    end

    it "should not find courses with objects" do
      @wiki_page = @course6.wiki.wiki_pages.create(
        :title => "Some random wiki page",
        :body => "wiki page content")
      parsed = ReportSpecHelper.run_report(@account,@type,{},3)
      parsed.length.should == 0
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
      parsed = ReportSpecHelper.run_report(@account,@type,parameters,3)
      parsed.length.should == 1

      parsed[0].should == [@course6.id.to_s, nil, "THE01",
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
      parsed = ReportSpecHelper.run_report(sub_account,@type,{},3)
      parsed.length.should == 1

      parsed[0].should == [@course4.id.to_s, nil, "self",
                           "self help", "active",
                           @course4.created_at.iso8601]
    end
  end

end
