# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe UsersController do
  describe "#fetch_courses_with_grades" do
    before :once do
      @account = Account.default
      @student = user_factory(active_all: true)
    end

    before do
      user_session(@student)
      controller.instance_variable_set(:@current_user, @student)
      controller.instance_variable_set(:@domain_root_account, @account)
    end

    context "course limit" do
      it "returns up to 50 courses" do
        # Create 60 courses with enrollments
        courses = (1..60).map do |i|
          course = course_factory(active_all: true, account: @account)
          course.update!(name: "Course #{i.to_s.rjust(2, "0")}")
          course.enroll_student(@student, enrollment_state: "active")
          course
        end

        # Call the private method via send
        result = controller.send(:fetch_courses_with_grades)

        # menu_courses returns up to 50 courses based on enrollment rank and date
        # We just verify the limit is respected, not the specific courses
        expect(result.length).to eq(50)
        course_ids_str = courses.map { |c| c.id.to_s }
        expect(result.all? { |c| course_ids_str.include?(c[:courseId]) }).to be true
      end

      it "returns all courses when less than 50" do
        # Create 10 courses
        courses = (1..10).map do |_i|
          course = course_factory(active_all: true, account: @account)
          course.enroll_student(@student, enrollment_state: "active")
          course
        end

        result = controller.send(:fetch_courses_with_grades)

        expect(result.length).to eq(10)
        expect(result.pluck(:courseId)).to match_array(courses.map { |c| c.id.to_s })
      end
    end

    context "courses without grades" do
      it "includes courses with null grade when grades are hidden" do
        course = course_factory(active_all: true, account: @account)
        course.enroll_student(@student, enrollment_state: "active")
        course.update!(hide_final_grades: true)

        result = controller.send(:fetch_courses_with_grades)

        expect(result.length).to eq(1)
        expect(result.first[:courseId]).to eq(course.id.to_s)
        expect(result.first[:currentGrade]).to be_nil
      end

      it "includes courses with null grade when no score exists" do
        course = course_factory(active_all: true, account: @account)
        course.enroll_student(@student, enrollment_state: "active")

        result = controller.send(:fetch_courses_with_grades)

        expect(result.length).to eq(1)
        expect(result.first[:courseId]).to eq(course.id.to_s)
        expect(result.first[:currentGrade]).to be_nil
      end

      it "includes grade when available and visible" do
        course = course_factory(active_all: true, account: @account)
        enrollment = course.enroll_student(@student, enrollment_state: "active")

        # Create a score for the enrollment
        enrollment.scores.create!(
          course_score: true,
          current_score: 85.5,
          workflow_state: "active"
        )

        result = controller.send(:fetch_courses_with_grades)

        expect(result.length).to eq(1)
        expect(result.first[:courseId]).to eq(course.id.to_s)
        expect(result.first[:currentGrade]).to eq(85.5)
      end

      it "includes course even when grade exists but is hidden (key change from old behavior)" do
        course = course_factory(active_all: true, account: @account)
        enrollment = course.enroll_student(@student, enrollment_state: "active")

        # Create a score but hide final grades
        enrollment.scores.create!(
          course_score: true,
          current_score: 90.0,
          workflow_state: "active"
        )
        course.update!(hide_final_grades: true)

        result = controller.send(:fetch_courses_with_grades)

        # KEY ASSERTION: Old code would have excluded this course entirely (result.length == 0)
        # New code includes the course but with null grade
        expect(result.length).to eq(1)
        expect(result.first[:courseId]).to eq(course.id.to_s)
        expect(result.first[:courseName]).to eq(course.name)
        expect(result.first[:currentGrade]).to be_nil # Grade is hidden, not shown
      end

      it "includes mix of courses with visible and hidden grades (demonstrates grade visibility is no longer required)" do
        # Course 1: Has visible grade
        course1 = course_factory(active_all: true, account: @account)
        course1.update!(name: "Course With Visible Grade")
        enrollment1 = course1.enroll_student(@student, enrollment_state: "active")
        enrollment1.scores.create!(
          course_score: true,
          current_score: 88.0,
          workflow_state: "active"
        )

        # Course 2: Has grade but it's hidden
        course2 = course_factory(active_all: true, account: @account)
        course2.update!(name: "Course With Hidden Grade", hide_final_grades: true)
        enrollment2 = course2.enroll_student(@student, enrollment_state: "active")
        enrollment2.scores.create!(
          course_score: true,
          current_score: 95.0,
          workflow_state: "active"
        )

        # Course 3: No grade at all
        course3 = course_factory(active_all: true, account: @account)
        course3.update!(name: "Course Without Grade")
        course3.enroll_student(@student, enrollment_state: "active")

        result = controller.send(:fetch_courses_with_grades)

        # OLD BEHAVIOR: Would only return course1 (result.length == 1)
        # NEW BEHAVIOR: Returns all 3 courses regardless of grade visibility
        expect(result.length).to eq(3)

        course1_data = result.find { |c| c[:courseId] == course1.id.to_s }
        course2_data = result.find { |c| c[:courseId] == course2.id.to_s }
        course3_data = result.find { |c| c[:courseId] == course3.id.to_s }

        # Course 1: Grade is visible
        expect(course1_data[:currentGrade]).to eq(88.0)

        # Course 2: Grade exists but is hidden (null)
        expect(course2_data[:currentGrade]).to be_nil

        # Course 3: No grade (null)
        expect(course3_data[:currentGrade]).to be_nil
      end
    end

    context "course types" do
      it "excludes invited enrollments from grade display" do
        course = course_factory(active_all: true, account: @account)
        course.enroll_student(@student, enrollment_state: "invited")

        result = controller.send(:fetch_courses_with_grades)

        # Invited enrollments are filtered out for grade widget
        # (menu_courses includes them for navigation, but grades widget only shows active)
        expect(result.length).to eq(0)
      end

      it "includes active enrollments" do
        course = course_factory(active_all: true, account: @account)
        course.enroll_student(@student, enrollment_state: "active")

        result = controller.send(:fetch_courses_with_grades)

        expect(result.length).to eq(1)
        expect(result.first[:courseId]).to eq(course.id.to_s)
      end
    end

    context "observer mode" do
      before :once do
        @observer = user_factory(active_all: true)
        @observed_student = user_factory(active_all: true)
      end

      before do
        user_session(@observer)
        controller.instance_variable_set(:@current_user, @observer)
        controller.instance_variable_set(:@domain_root_account, @account)
      end

      it "returns observed user courses with 50 limit" do
        # Create 60 courses for observed student
        courses = (1..60).map do |i|
          course = course_factory(active_all: true, account: @account)
          course.update!(name: "Course #{i.to_s.rjust(2, "0")}")
          course.enroll_student(@observed_student, enrollment_state: "active")

          # Enroll observer
          course.enroll_user(
            @observer,
            "ObserverEnrollment",
            associated_user_id: @observed_student.id,
            enrollment_state: "active"
          )
          course
        end

        result = controller.send(:fetch_courses_with_grades, @observed_student)

        # menu_courses returns up to 50 courses based on enrollment rank and date
        expect(result.length).to eq(50)
        course_ids_str = courses.map { |c| c.id.to_s }
        expect(result.all? { |c| course_ids_str.include?(c[:courseId]) }).to be true
      end

      it "returns courses for observed user (grade visibility depends on permissions)" do
        course = course_factory(active_all: true, account: @account)
        enrollment = course.enroll_student(@observed_student, enrollment_state: "active")

        # Create observer enrollment
        course.enroll_user(
          @observer,
          "ObserverEnrollment",
          associated_user_id: @observed_student.id,
          enrollment_state: "active"
        )

        # Create a score
        enrollment.scores.create!(
          course_score: true,
          current_score: 92.0,
          workflow_state: "active"
        )

        result = controller.send(:fetch_courses_with_grades, @observed_student)

        # Course appears in result (grade visibility is secondary concern for this test)
        expect(result.length).to eq(1)
        expect(result.first[:courseId]).to eq(course.id.to_s)
        # Grade visibility depends on observer enrollment permissions (tested elsewhere)
      end
    end

    context "favorites" do
      it "returns favorited courses when favorites exist" do
        # Create 20 courses
        all_courses = (1..20).map do |i|
          course = course_factory(active_all: true, account: @account)
          course.update!(name: "Course #{i.to_s.rjust(2, "0")}")
          course.enroll_student(@student, enrollment_state: "active")
          course
        end

        # Favorite 10 courses
        favorite_courses = all_courses.first(10)
        favorite_courses.each do |course|
          @student.favorites.create!(context: course)
        end

        result = controller.send(:fetch_courses_with_grades)

        # menu_courses returns favorites when they exist (for favoritable courses)
        # Since all courses are favoritable, only favorites are returned
        expect(result.length).to eq(10)
        # All favorites should be included
        favorite_ids = favorite_courses.map { |c| c.id.to_s }
        result_ids = result.pluck(:courseId)
        expect(result_ids).to match_array(favorite_ids)
      end
    end

    context "grading schemes" do
      it "returns percentage as default grading scheme" do
        course = course_factory(active_all: true, account: @account)
        course.enroll_student(@student, enrollment_state: "active")

        result = controller.send(:fetch_courses_with_grades)

        expect(result.first[:gradingScheme]).to eq("percentage")
      end

      it "returns grading standard data when enabled" do
        course = course_factory(active_all: true, account: @account)
        course.enroll_student(@student, enrollment_state: "active")

        # Enable grading standard
        grading_standard = course.grading_standards.create!(
          title: "Custom Grading",
          data: [["A", 0.9], ["B", 0.8], ["C", 0.7], ["D", 0.6], ["F", 0.0]]
        )
        course.update!(
          grading_standard_enabled: true,
          grading_standard_id: grading_standard.id
        )

        result = controller.send(:fetch_courses_with_grades)

        expect(result.first[:gradingScheme]).to eq([["A", 0.9], ["B", 0.8], ["C", 0.7], ["D", 0.6], ["F", 0.0]])
      end
    end

    context "data structure" do
      it "returns correct data structure" do
        course = course_factory(active_all: true, account: @account)
        course.update!(name: "Test Course", course_code: "TEST 101")
        enrollment = course.enroll_student(@student, enrollment_state: "active")

        Score.create!(
          enrollment:,
          grading_period: nil,
          current_score: 85.0,
          workflow_state: "active"
        )

        result = controller.send(:fetch_courses_with_grades)

        expect(result.first).to include(
          courseId: course.id.to_s,
          courseCode: "TEST 101",
          courseName: "Test Course",
          currentGrade: 85.0,
          gradingScheme: "percentage"
        )
        expect(result.first[:lastUpdated]).to be_present
      end
    end
  end
end
