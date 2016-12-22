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

describe "Default Account Reports" do
  include ReportSpecHelper

  before(:once) do
    Notification.where(name: "Report Generated").first_or_create
    Notification.where(name: "Report Generation Failed").first_or_create
    @account = Account.create(name: 'New Account', default_time_zone: 'UTC')
    @default_term = @account.default_enrollment_term

    @term1 = EnrollmentTerm.create(:name => 'Fall', :start_at => 6.months.ago, :end_at => 1.year.from_now)
    @term1.root_account = @account
    @term1.sis_source_id = 'fall12'
    @term1.save!
    @user1 = user_with_managed_pseudonym(:active_all => true, :account => @account, :name => "John St. Clair",
                                         :sortable_name => "St. Clair, John", :username => 'john@stclair.com',
                                         :sis_user_id => "user_sis_id_01")
    @user2 = user_with_managed_pseudonym(:active_all => true, :username => 'micheal@michaelbolton.com',
                                         :name => 'Michael Bolton', :account => @account,
                                         :sis_user_id => "user_sis_id_02")
    @user3 = user_with_managed_pseudonym(:active_all => true, :account => @account, :name => "Rick Astley",
                                         :sortable_name => "Astley, Rick", :username => 'rick@roll.com',
                                         :sis_user_id => "user_sis_id_03")
    @user4 = user_with_managed_pseudonym(:active_all => true, :username => 'jason@donovan.com',
                                         :name => 'Jason Donovan', :account => @account,
                                         :sis_user_id => "user_sis_id_04")
    @user5 = user_with_managed_pseudonym(:active_all => true, :username => 'john@smith.com',
                                         :name => 'John Smith', :sis_user_id => "user_sis_id_05",
                                         :account => @account)

    @course1 = Course.new(:name => 'English 101', :course_code => 'ENG101', :account => @account)
    @course1.workflow_state = 'available'
    @course1.enrollment_term_id = @term1.id
    @course1.sis_source_id = "SIS_COURSE_ID_1"
    @course1.save!
    @course2 = course(:course_name => 'Math 101', :account => @account, :active_course => true)

    @enrollment1 = @course1.enroll_user(@user1, 'StudentEnrollment', :enrollment_state => :active)
    @enrollment2 = @course1.enroll_user(@user2, 'StudentEnrollment', :enrollment_state => :completed)
    @enrollment3 = @course2.enroll_user(@user2, 'StudentEnrollment', :enrollment_state => :active)
    @enrollment4 = @course1.enroll_user(@user3, 'StudentEnrollment', :enrollment_state => :active)
    @enrollment5 = @course2.enroll_user(@user4, 'StudentEnrollment', :enrollment_state => :active)
    @enrollment6 = @course1.enroll_user(@user5, 'TeacherEnrollment', :enrollment_state => :active)
    @enrollment7 = @course2.enroll_user(@user5, 'TaEnrollment', :enrollment_state => :active)
  end

  # The report should get all the grades for the term provided
  # create 2 courses each with students
  # have a student in both courses
  # have sis id's and not sis ids
  describe "Grade Export report" do
    before(:once) do
      @enrollment1.update_attribute :computed_final_score, 88
      @enrollment2.update_attribute :computed_final_score, 90
      @enrollment3.update_attribute :computed_final_score, 93
      @enrollment4.update_attribute :computed_final_score, 97
      @enrollment5.update_attribute :computed_final_score, 99
    end

    it "should run grade export for a term" do
      parameters = {}
      parameters["enrollment_term"] = @term1.id
      parsed = read_report('grade_export_csv', {order: 13, params: parameters})
      expect(parsed.length).to eq 3

      expect(parsed[0]).to eq ["John St. Clair", @user1.id.to_s, "user_sis_id_01", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "88.0", "active"]
      expect(parsed[1]).to eq ["Michael Bolton", @user2.id.to_s, "user_sis_id_02", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "90.0", "concluded"]
      expect(parsed[2]).to eq ["Rick Astley", @user3.id.to_s, "user_sis_id_03", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "97.0", "active"]
    end

    it "should run grade export for a term using sis_id" do

      parameters = {}
      parameters["enrollment_term"] = "sis_term_id:fall12"
      parsed = read_report('grade_export_csv', {order: 13, params: parameters})

      expect(parsed[0]).to eq ["John St. Clair", @user1.id.to_s, "user_sis_id_01", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "88.0", "active"]
      expect(parsed[1]).to eq ["Michael Bolton", @user2.id.to_s, "user_sis_id_02", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "90.0", "concluded"]
      expect(parsed[2]).to eq ["Rick Astley", @user3.id.to_s, "user_sis_id_03", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "97.0", "active"]
    end

    it "should run grade export with no parameters" do

      parsed = read_report('grade_export_csv', {order: 13})
      expect(parsed.length).to eq 5

      expect(parsed[0]).to eq ["John St. Clair", @user1.id.to_s, "user_sis_id_01", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "88.0", "active"]
      expect(parsed[1]).to eq ["Michael Bolton", @user2.id.to_s, "user_sis_id_02", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "90.0", "concluded"]
      expect(parsed[2]).to eq ["Michael Bolton", @user2.id.to_s, "user_sis_id_02", "Math 101", @course2.id.to_s,
                           nil, "Math 101", @course2.course_sections.first.id.to_s, nil, "Default Term",
                           @default_term.id.to_s, nil, nil, "93.0", "active"]
      expect(parsed[3]).to eq ["Rick Astley", @user3.id.to_s, "user_sis_id_03", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "97.0", "active"]
      expect(parsed[4]).to eq ["Jason Donovan", @user4.id.to_s, "user_sis_id_04", "Math 101", @course2.id.to_s,
                           nil, "Math 101", @course2.course_sections.first.id.to_s, nil, "Default Term",
                           @default_term.id.to_s, nil, nil, "99.0", "active"]
    end

    it "should run grade export with empty string parameter" do

      parameters = {}
      parameters["enrollment_term"] = ""
      parsed = read_report('grade_export_csv', {order: 13, params: parameters})
      expect(parsed.length).to eq 5

      expect(parsed[0]).to eq ["John St. Clair", @user1.id.to_s, "user_sis_id_01", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "88.0", "active"]
      expect(parsed[1]).to eq ["Michael Bolton", @user2.id.to_s, "user_sis_id_02", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "90.0", "concluded"]
      expect(parsed[2]).to eq ["Michael Bolton", @user2.id.to_s, "user_sis_id_02", "Math 101", @course2.id.to_s,
                           nil, "Math 101", @course2.course_sections.first.id.to_s, nil, "Default Term",
                           @default_term.id.to_s, nil, nil, "93.0", "active"]
      expect(parsed[3]).to eq ["Rick Astley", @user3.id.to_s, "user_sis_id_03", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "97.0", "active"]
      expect(parsed[4]).to eq ["Jason Donovan", @user4.id.to_s, "user_sis_id_04", "Math 101", @course2.id.to_s,
                           nil, "Math 101", @course2.course_sections.first.id.to_s, nil, "Default Term",
                           @default_term.id.to_s, nil, nil, "99.0", "active"]
    end

    it "should run grade export with deleted users" do

      @course2.destroy
      @enrollment1.destroy

      parameters = {}
      parameters["include_deleted"] = true
      parsed = read_report('grade_export_csv', {order: 13, params: parameters})
      expect(parsed.length).to eq 5

      expect(parsed[0]).to eq ["John St. Clair", @user1.id.to_s, "user_sis_id_01", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "88.0", "deleted"]
      expect(parsed[1]).to eq ["Michael Bolton", @user2.id.to_s, "user_sis_id_02", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "90.0", "concluded"]
      expect(parsed[2]).to eq ["Michael Bolton", @user2.id.to_s, "user_sis_id_02", "Math 101", @course2.id.to_s,
                           nil, "Math 101", @course2.course_sections.first.id.to_s, nil, "Default Term",
                           @default_term.id.to_s, nil, nil, "93.0", "deleted"]
      expect(parsed[3]).to eq ["Rick Astley", @user3.id.to_s, "user_sis_id_03", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "97.0", "active"]
      expect(parsed[4]).to eq ["Jason Donovan", @user4.id.to_s, "user_sis_id_04", "Math 101", @course2.id.to_s,
                           nil, "Math 101", @course2.course_sections.first.id.to_s, nil, "Default Term",
                           @default_term.id.to_s, nil, nil, "99.0", "deleted"]
    end

    it "should run grade export on a sub account" do
      sub_account = Account.create(:parent_account => @account, :name => 'English')
      @course2.account = sub_account
      @course2.save!

      parameters = {}
      parsed = read_report('grade_export_csv', {order: 13, account: sub_account, params: parameters})
      expect(parsed.length).to eq 2

      expect(parsed[0]).to eq ["Michael Bolton", @user2.id.to_s, "user_sis_id_02", "Math 101", @course2.id.to_s,
                           nil, "Math 101", @course2.course_sections.first.id.to_s, nil, "Default Term",
                           @default_term.id.to_s, nil, nil, "93.0", "active"]
      expect(parsed[1]).to eq ["Jason Donovan", @user4.id.to_s, "user_sis_id_04", "Math 101", @course2.id.to_s,
                           nil, "Math 101", @course2.course_sections.first.id.to_s, nil, "Default Term",
                           @default_term.id.to_s, nil, nil, "99.0", "active"]
    end

    it "should run a grade export on concluded courses with an limiting period given" do
      @course1.complete!
      @enrollment1.conclude
      @enrollment1.save!

      parameters = {}
      parameters["include_deleted"] = true
      parameters["limiting_period"] = "2"
      parsed = read_report('grade_export_csv', {order: 13, params: parameters})
      expect(parsed.length).to eq 5

      expect(parsed[0]).to eq ["John St. Clair", @user1.id.to_s, "user_sis_id_01",
                           "English 101", @course1.id.to_s, "SIS_COURSE_ID_1",
                           "English 101", @course1.course_sections.first.id.to_s,
                           nil, "Fall", @term1.id.to_s, "fall12", nil, "88.0", "concluded"]
      expect(parsed[1]).to eq ["Michael Bolton", @user2.id.to_s, "user_sis_id_02",
                           "English 101", @course1.id.to_s, "SIS_COURSE_ID_1",
                           "English 101", @course1.course_sections.first.id.to_s,
                           nil, "Fall", @term1.id.to_s, 'fall12', nil, "90.0", "concluded"]
      expect(parsed[2]).to eq ["Michael Bolton", @user2.id.to_s, "user_sis_id_02",
                           "Math 101", @course2.id.to_s, nil, "Math 101",
                           @course2.course_sections.first.id.to_s, nil, "Default Term",
                           @default_term.id.to_s, nil, nil, "93.0", "active"]
      expect(parsed[3]).to eq ["Rick Astley", @user3.id.to_s, "user_sis_id_03",
                           "English 101", @course1.id.to_s, "SIS_COURSE_ID_1",
                           "English 101", @course1.course_sections.first.id.to_s,
                           nil, "Fall", @term1.id.to_s, "fall12", nil, "97.0", "concluded"]
      expect(parsed[4]).to eq ["Jason Donovan", @user4.id.to_s, "user_sis_id_04",
                           "Math 101", @course2.id.to_s, nil, "Math 101",
                           @course2.course_sections.first.id.to_s, nil, "Default Term",
                           @default_term.id.to_s, nil, nil, "99.0", "active"]

    end

    it "should not return results that don't fall within the limiting period" do
      @course1.complete!
      @course1.conclude_at = Date.today - 3.days
      @course1.save!

      parameters = {}
      parameters["include_deleted"] = true
      parameters["limiting_period"] = "2"
      parsed = read_report('grade_export_csv', {order: 13, params: parameters})
      expect(parsed.length).to eq 2
      expect(parsed[0]).to eq ["Michael Bolton", @user2.id.to_s, "user_sis_id_02",
                           "Math 101", @course2.id.to_s, nil, "Math 101",
                           @course2.course_sections.first.id.to_s, nil, "Default Term",
                           @default_term.id.to_s, nil, nil, "93.0", "active"]
      expect(parsed[1]).to eq ["Jason Donovan", @user4.id.to_s, "user_sis_id_04",
                           "Math 101", @course2.id.to_s, nil, "Math 101",
                           @course2.course_sections.first.id.to_s, nil, "Default Term",
                           @default_term.id.to_s, nil, nil, "99.0", "active"]
    end

    it "should return a deleted courses within an limiting period" do
      @enrollment3.destroy
      parameters = {}
      parameters["include_deleted"] = true
      parameters["limiting_period"] = "2"
      parsed = read_report('grade_export_csv', {order: 13, params: parameters})
      expect(parsed.length).to eq 4

      expect(parsed[0]).to eq ["John St. Clair", @user1.id.to_s, "user_sis_id_01", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "88.0", "active"]
      expect(parsed[1]).to eq ["Michael Bolton", @user2.id.to_s, "user_sis_id_02", "Math 101", @course2.id.to_s,
                           nil, "Math 101", @course2.course_sections.first.id.to_s, nil, "Default Term",
                           @default_term.id.to_s, nil, nil, "93.0", "deleted"]
      expect(parsed[2]).to eq ["Rick Astley", @user3.id.to_s, "user_sis_id_03", "English 101", @course1.id.to_s,
                           "SIS_COURSE_ID_1", "English 101", @course1.course_sections.first.id.to_s, nil, "Fall",
                           @term1.id.to_s, "fall12", nil, "97.0", "active"]
      expect(parsed[3]).to eq ["Jason Donovan", @user4.id.to_s, "user_sis_id_04", "Math 101", @course2.id.to_s,
                           nil, "Math 101", @course2.course_sections.first.id.to_s, nil, "Default Term",
                           @default_term.id.to_s, nil, nil, "99.0", "active"]
    end

  end

  describe "MGP Grade Export" do
    describe "#mgp_grade_export" do
      it "makes csvs for all terms" do
        reports = read_report("mgp_grade_export_csv")
        expect(reports).to include "Default Term.csv"
        expect(reports).to include "Fall.csv"
      end

      it "can return csv for a single term" do
        reports = read_report("mgp_grade_export_csv",
                              params: {enrollment_term_id: @term1.id})
        expect(reports).to include "Fall.csv"
        expect(reports).not_to include "Default Term.csv"
      end
    end

    describe "#mgp_term_csv" do
      before(:once) do
        # set up grading periods
        gpg = GradingPeriodGroup.new title: "Grading Periods"
        gpg.root_account = @course2.root_account
        gpg.enrollment_terms << @default_term
        gpg.save!
        past   = gpg.grading_periods.create! title: "Past", start_date: 1.week.ago, end_date: 1.day.ago
        future = gpg.grading_periods.create! title: "Future", start_date: 1.day.from_now, end_date: 1.week.from_now

        @course3 = course(:course_name => 'Fun 404', :account => @account, :active_course => true)
        @course3.enroll_user(@user2, 'StudentEnrollment', :enrollment_state => :active)
        @course3.enroll_user(@user4, 'StudentEnrollment', :enrollment_state => :active)

        teacher = User.create!
        @course2.enroll_teacher(teacher)
        @course3.enroll_teacher(teacher)

        # set up assignments
        past_assignment = @course2.assignments.create! points_possible: 100, due_at: 3.days.ago
        future_assignment = @course2.assignments.create! points_possible: 100, due_at: 3.days.from_now

        Timecop.freeze(past.end_date - 1.day) do
          past_assignment.grade_student(@user2, grade: 25, grader: teacher)
          past_assignment.grade_student(@user4, grade: 75, grader: teacher)
        end
        future_assignment.grade_student(@user2, grade: 75, grader: teacher)
        future_assignment.grade_student(@user4, grade: 25, grader: teacher)

        past_assignment = @course3.assignments.create! points_possible: 100, due_at: 3.days.ago
        future_assignment = @course3.assignments.create! points_possible: 100, due_at: 3.days.from_now

        Timecop.freeze(past.end_date - 1.day) do
          past_assignment.grade_student(@user2, grade: 75, grader: teacher)
          past_assignment.grade_student(@user4, grade: 25, grader: teacher)
        end
        future_assignment.grade_student(@user2, grade: 25, grader: teacher)
        future_assignment.grade_student(@user4, grade: 75, grader: teacher)
      end

      it "reports mgp grades" do
        reports = read_report("mgp_grade_export_csv",
                              params: {enrollment_term_id: @default_term.id},
                              parse_header: true,
                              order: ["student name", "course"])
        csv = reports["Default Term.csv"]
        expect(csv.size).to eq 4
        expect(
          csv.all? { |student|
            ["Math 101", "Fun 404"].include?(student["course"])
            student["grading period set"] == "Grading Periods"
          }
        ).to eq true

        jason1, jason2, mike1, mike2 = csv

        expect(jason1["student name"]).to eq "Jason Donovan"
        expect(jason1["course"]).to eq "Fun 404"
        expect(jason1["Past current score"].to_f).to eq 25
        expect(jason1["Future current score"].to_f).to eq 75

        expect(jason2["student name"]).to eq "Jason Donovan"
        expect(jason2["course"]).to eq "Math 101"
        expect(jason2["Past current score"].to_f).to eq 75
        expect(jason2["Future current score"].to_f).to eq 25

        expect(mike1["student name"]).to eq "Michael Bolton"
        expect(mike1["course"]).to eq "Fun 404"
        expect(mike1["Past final score"].to_f).to eq 75
        expect(mike1["Future final score"].to_f).to eq 25

        expect(mike2["student name"]).to eq "Michael Bolton"
        expect(mike2["course"]).to eq "Math 101"
        expect(mike2["Past final score"].to_f).to eq 25
        expect(mike2["Future final score"].to_f).to eq 75
      end

      it "works with students in multiple sections" do
        section2 = @course2.course_sections.create! name: "section 2"
        @course2.enroll_student(@user2, section: section2,
          workflow_state: "active",
          allow_multiple_enrollments: true).tap { |e| e.accept }

        reports = read_report("mgp_grade_export_csv",
                              params: {enrollment_term_id: @default_term.id},
                              parse_header: true,
                              order: ["student name", "section id"])
        csv = reports["Default Term.csv"]

        # Just look at the course2 enrollments
        jason, mike1, mike2 = csv[0], csv[2], csv[4]

        expect(jason["student name"]).to eq "Jason Donovan"
        expect(mike1["student name"]).to eq "Michael Bolton"
        expect(mike2["student name"]).to eq "Michael Bolton"
        expect(mike1["section"]).to eq "Math 101"
        expect(mike2["section"]).to eq "section 2"
        expect(mike1["Past final score"].to_f).to eq 25
        expect(mike2["Past final score"].to_f).to eq 25
      end

      it "returns nothing for terms without grading periods" do
        reports = read_report("mgp_grade_export_csv",
                              params: {enrollment_term_id: @term1.id},
                              header: true,
                              order: "skip")
        csv = reports["Fall.csv"]
        expect(csv.size).to eq 1
        expect(csv.first).to eq ["no grading periods configured for this term"]
      end
    end
  end
end
