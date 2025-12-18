# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

describe SubmissionSearch do
  let_once(:course) { Course.create!(workflow_state: "available") }
  let_once(:jonah) { User.create!(name: "Jonah Jameson") }
  let_once(:amanda) { User.create!(name: "Amanda Jones") }
  let_once(:mandy) { User.create!(name: "Mandy Miller") }
  let_once(:james) { User.create!(name: "James Peterson") }
  let_once(:peter) { User.create!(name: "Peter Piper") }
  let_once(:students) { [jonah, amanda, mandy, james, peter] }
  let_once(:teacher) do
    teacher = User.create!(name: "Teacher Miller")
    TeacherEnrollment.create!(user: teacher, course:, workflow_state: "active")
    teacher
  end
  let_once(:observer) do
    observer = User.create!(name: "Observer")
    observer_enrollment = ObserverEnrollment.create!(user: observer, course:, workflow_state: "active")
    observer_enrollment.update_attribute(:associated_user_id, amanda.id)
    observer
  end
  let_once(:assignment) do
    Assignment.create!(
      course:,
      workflow_state: "active",
      submission_types: "online_text_entry",
      title: "an assignment",
      description: "the body"
    )
  end

  before :once do
    students.each do |student|
      StudentEnrollment.create!(user: student, course:, workflow_state: "active")
    end
  end

  it "finds all submissions" do
    results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "username" }]).search
    expect(results.preload(:user).map(&:user)).to eq students
  end

  it "excludes rejected students by default" do
    course.enrollments.find_by(user: jonah).reject
    results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "username" }]).search
    expect(results.where(user: jonah).exists?).to be false
  end

  it "excludes deactivated students by default" do
    course.enrollments.find_by(user: jonah).deactivate
    results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "username" }]).search
    expect(results.where(user: jonah).exists?).to be false
  end

  it "optionally includes deactivated students" do
    course.enrollments.find_by(user: jonah).deactivate
    results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "username" }], include_deactivated: true).search
    expect(results.where(user: jonah).exists?).to be true
  end

  it "excludes rejected students when including deactivated students" do
    course.enrollments.find_by(user: jonah).reject
    results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "username" }], include_deactivated: true).search
    expect(results.where(user: jonah).exists?).to be false
  end

  it "excludes concluded students by default" do
    course.enrollments.find_by(user: jonah).conclude
    results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "username" }]).search
    expect(results.where(user: jonah).exists?).to be false
  end

  it "optionally includes concluded students" do
    course.enrollments.find_by(user: jonah).conclude
    results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "username" }], include_concluded: true).search
    expect(results.where(user: jonah).exists?).to be true
  end

  it "excludes rejected students when including concluded students" do
    course.enrollments.find_by(user: jonah).reject
    results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "username" }], include_concluded: true).search
    expect(results.where(user: jonah).exists?).to be false
  end

  it "optionally includes deactivated students via gradebook settings" do
    course.enrollments.find_by(user: jonah).deactivate
    teacher.preferences[:gradebook_settings] = {
      course.global_id => {
        "show_inactive_enrollments" => "true"
      }
    }
    teacher.save!
    results = SubmissionSearch.new(
      assignment,
      teacher,
      nil,
      order_by: [{ field: "username" }],
      apply_gradebook_enrollment_filters: true
    ).search
    expect(results.where(user: jonah).exists?).to be true
  end

  it "optionally includes concluded students via gradebook settings" do
    course.enrollments.find_by(user: jonah).conclude
    teacher.preferences[:gradebook_settings] = {
      course.global_id => {
        "show_concluded_enrollments" => "true"
      }
    }
    teacher.save!
    results = SubmissionSearch.new(
      assignment,
      teacher,
      nil,
      order_by: [{ field: "username" }],
      apply_gradebook_enrollment_filters: true
    ).search
    expect(results.where(user: jonah).exists?).to be true
  end

  it "ignores include_concluded and include_deactivated when apply_gradebook_enrollment_filters is true" do
    course.enrollments.find_by(user: amanda).deactivate
    course.enrollments.find_by(user: jonah).conclude
    teacher.preferences[:gradebook_settings] = {
      course.global_id => {
        "show_concluded_enrollments" => "false",
        "show_inactive_enrollments" => "false"
      }
    }
    teacher.save!
    results = SubmissionSearch.new(
      assignment,
      teacher,
      nil,
      order_by: [{ field: "username" }],
      apply_gradebook_enrollment_filters: true,
      include_concluded: true,
      include_deactivated: true
    ).search

    aggregate_failures do
      expect(results.where(user: amanda).exists?).to be false
      expect(results.where(user: jonah).exists?).to be false
    end
  end

  it "finds submissions with user name search" do
    results = SubmissionSearch.new(assignment,
                                   teacher,
                                   nil,
                                   user_search: "man",
                                   order_by: [{ field: "username", direction: "descending" }]).search
    expect(results).to eq [
      Submission.find_by(user: mandy),
      Submission.find_by(user: amanda),
    ]
  end

  it "finds submissions with user id" do
    results = SubmissionSearch.new(assignment,
                                   teacher,
                                   nil,
                                   user_id: mandy.id,
                                   order_by: [{ field: "username", direction: "descending" }]).search
    expect(results).to eq [
      Submission.find_by(user: mandy)
    ]
  end

  it "filters for the specified workflow state" do
    assignment.submit_homework(amanda, submission_type: "online_text_entry", body: "submission")
    results = SubmissionSearch.new(assignment, teacher, nil, states: ["submitted"]).search
    expect(results).to eq [Submission.find_by(user: amanda)]
  end

  it "filters results to specified sections" do
    section = course.course_sections.create!
    StudentEnrollment.create!(user: amanda, course:, course_section: section, workflow_state: "active")
    results = SubmissionSearch.new(assignment, teacher, nil, section_ids: [section.id]).search
    expect(results).to eq [Submission.find_by(user: amanda)]
  end

  it "filters by the enrollment type" do
    fake_student = assignment.course.student_view_student
    results = SubmissionSearch.new(assignment, teacher, nil, enrollment_types: ["StudentEnrollment"]).search
    expect(results).not_to include Submission.find_by(user: fake_student)
  end

  it "filters by scored less than" do
    assignment.grade_student(amanda, score: 42, grader: teacher)
    assignment.grade_student(mandy, score: 10, grader: teacher)
    results = SubmissionSearch.new(assignment, teacher, nil, scored_less_than: 42).search
    expect(results).to eq [Submission.find_by(user: mandy)]
  end

  it "filters by scored greater than" do
    assignment.grade_student(amanda, score: 42, grader: teacher)
    assignment.grade_student(mandy, score: 10, grader: teacher)
    results = SubmissionSearch.new(assignment, teacher, nil, scored_more_than: 10).search
    expect(results).to eq [Submission.find_by(user: amanda)]
  end

  it "filters by late" do
    late_student = student_in_course(course:, active_all: true).user
    assignment = course.assignments.create!(name: "assignment", points_possible: 10, due_at: 2.days.ago)
    submission = assignment.submit_homework(late_student, body: "asdf", submitted_at: 1.day.ago)
    results = SubmissionSearch.new(assignment, teacher, nil, late: true).search
    expect(results).to eq [submission]
  end

  it "filters by needs_grading" do
    submission = assignment.submit_homework(amanda, body: "asdf")
    results = SubmissionSearch.new(assignment, teacher, nil, grading_status: "needs_grading").search
    expect(results).to eq [submission]
  end

  it "filters by excused" do
    submission = Submission.find_by(user: jonah)
    submission.excused = true
    submission.save!
    results = SubmissionSearch.new(assignment, teacher, nil, grading_status: "excused").search
    expect(results).to eq [submission]
  end

  it "filters by needs_review" do
    submission = Submission.find_by(user: peter)
    submission.workflow_state = "pending_review"
    submission.save!
    results = SubmissionSearch.new(assignment, teacher, nil, grading_status: "needs_review").search
    expect(results).to eq [submission]
  end

  it "filters by graded" do
    submission = Submission.find_by(user: mandy)
    submission.workflow_state = "graded"
    submission.save!
    results = SubmissionSearch.new(assignment, teacher, nil, grading_status: "graded").search
    expect(results).to eq [submission]
  end

  it "limits results to just associated student submissions if the user is an observer" do
    results = SubmissionSearch.new(assignment, observer, nil, {}).search
    expect(results).to eq [Submission.find_by(user: amanda)]
  end

  it "limits results to just the user's submission if the user is a student" do
    results = SubmissionSearch.new(assignment, amanda, nil, {}).search
    expect(results).to eq [Submission.find_by(user: amanda)]
  end

  it "returns nothing to randos" do
    rando = User.create!
    results = SubmissionSearch.new(assignment, rando, nil, {}).search
    expect(results).to eq []
  end

  describe "final sort criteria (or, default sort criteria if no sorts are provided)" do
    it "orders students by user id by default for non-anonymized assignments" do
      results = SubmissionSearch.new(assignment, teacher, nil, {}).search
      expect(results.map(&:user_id)).to eq assignment.submissions.pluck(:user_id).sort
    end

    it "orders students by submission anonymous name by default for anonymized assignments" do
      assignment.update!(anonymous_grading: true)
      results = SubmissionSearch.new(assignment, teacher, nil, {}).search
      anon_names = results.map { |sub| assignment.anonymous_student_identities.dig(sub.user_id, :name) }
      expect(anon_names).to eql ["Student 1", "Student 2", "Student 3", "Student 4", "Student 5"]
    end

    it "orders students by user id by default for assignments that are anonymous but have been posted" do
      assignment.update!(anonymous_grading: true)
      assignment.post_submissions
      results = SubmissionSearch.new(assignment, teacher, nil, {}).search
      expect(results.map(&:user_id)).to eq assignment.submissions.pluck(:user_id).sort
    end
  end

  describe "username ordering" do
    it "returns students ordered by their sortable name (case insensitive), ascending" do
      results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "username" }]).search
      # "Jameson, Jonah", "Jones, Amanda", "Miller, Mandy", "Peterson, James", "Piper, Peter"
      expect(results.extract_associated(:user)).to eq [jonah, amanda, mandy, james, peter]
    end

    it "returns students ordered by their sortable name (case insensitive), descending" do
      results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "username", direction: "descending" }]).search
      # "Piper, Peter", "Peterson, James", "Miller, Mandy", "Jones, Amanda", "Jameson, Jonah"
      expect(results.extract_associated(:user)).to eq [peter, james, mandy, amanda, jonah]
    end

    it "returns students ordered by their 'anonymous name' when the assignment is anonymized, ascending" do
      assignment.update!(anonymous_grading: true)
      results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "username" }]).search
      anon_names = results.map { |sub| assignment.anonymous_student_identities.dig(sub.user_id, :name) }
      expect(anon_names).to eql ["Student 1", "Student 2", "Student 3", "Student 4", "Student 5"]
    end

    it "returns students ordered by their 'anonymous name' when the assignment is anonymized, descending" do
      assignment.update!(anonymous_grading: true)
      results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "username", direction: "descending" }]).search
      anon_names = results.map { |sub| assignment.anonymous_student_identities.dig(sub.user_id, :name) }
      expect(anon_names).to eql ["Student 5", "Student 4", "Student 3", "Student 2", "Student 1"]
    end

    it "returns students ordered by their sortable name when the assignment is anonymous but posted, ascending" do
      assignment.update!(anonymous_grading: true)
      assignment.post_submissions

      results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "username" }]).search
      # "Jameson, Jonah", "Jones, Amanda", "Miller, Mandy", "Peterson, James", "Piper, Peter"
      expect(results.extract_associated(:user)).to eq [jonah, amanda, mandy, james, peter]
    end

    it "returns students ordered by their sortable name when the assignment is anonymous but posted, descending" do
      assignment.update!(anonymous_grading: true)
      assignment.post_submissions

      results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "username", direction: "descending" }]).search
      # "Piper, Peter", "Peterson, James", "Miller, Mandy", "Jones, Amanda", "Jameson, Jonah"
      expect(results.extract_associated(:user)).to eq [peter, james, mandy, amanda, jonah]
    end
  end

  describe "username_first_last ordering" do
    it "returns students ordered by first names (case insensitive), ascending" do
      results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "username_first_last" }]).search
      expect(results.extract_associated(:user)).to eq [amanda, james, jonah, mandy, peter]
    end

    it "returns students ordered by first names (case insensitive), descending" do
      results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "username_first_last", direction: "descending" }]).search
      expect(results.extract_associated(:user)).to eq [peter, mandy, jonah, james, amanda]
    end

    it "returns students ordered by their 'anonymous name' when the assignment is anonymized, ascending" do
      assignment.update!(anonymous_grading: true)

      results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "username_first_last" }]).search
      anon_names = results.map { |sub| assignment.anonymous_student_identities.dig(sub.user_id, :name) }
      expect(anon_names).to eql ["Student 1", "Student 2", "Student 3", "Student 4", "Student 5"]
    end

    it "returns students ordered by their 'anonymous name' when the assignment is anonymized, descending" do
      assignment.update!(anonymous_grading: true)

      results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "username_first_last", direction: "descending" }]).search
      anon_names = results.map { |sub| assignment.anonymous_student_identities.dig(sub.user_id, :name) }
      expect(anon_names).to eql ["Student 5", "Student 4", "Student 3", "Student 2", "Student 1"]
    end

    it "returns students ordered by first names when the assignment is anonymous but posted, ascending" do
      assignment.update!(anonymous_grading: true)
      assignment.post_submissions

      results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "username_first_last" }]).search
      expect(results.extract_associated(:user)).to eq [amanda, james, jonah, mandy, peter]
    end

    it "returns students ordered by first names when the assignment is anonymous but posted, descending" do
      assignment.update!(anonymous_grading: true)
      assignment.post_submissions

      results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "username_first_last", direction: "descending" }]).search
      expect(results.extract_associated(:user)).to eq [peter, mandy, jonah, james, amanda]
    end
  end

  describe "group name ordering" do
    before do
      @fruits = course.group_categories.create!(name: "Fruits")
      @apples = @fruits.groups.create!(name: "apples", context: course)
      @apples.add_user(jonah, "accepted")
      @apples.add_user(amanda, "accepted")
      bananas = @fruits.groups.create!(name: "Bananas", context: course)
      bananas.add_user(peter, "accepted")
      bananas.add_user(james, "accepted")
      assignment.update!(group_category: @fruits)
    end

    it "returns students ordered by their group name (case insensitive, students without group always last), ascending" do
      results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "group_name" }, { field: "username_first_last" }]).search
      # 'apples' members, then 'Bananas' members, then students without groups
      expect(results.extract_associated(:user)).to eq [amanda, jonah, james, peter, mandy]
    end

    it "returns students ordered by their group name (case insensitive, students without group always last), descending" do
      results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "group_name", direction: "descending" }, { field: "username_first_last" }]).search
      # 'Bananas' members, then 'apples' members, then students without groups
      expect(results.extract_associated(:user)).to eq [james, peter, amanda, jonah, mandy]
    end

    it "ignores group_name sort when the assignment is not a group assignment" do
      assignment.update!(group_category: nil)
      results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "group_name" }, { field: "username_first_last" }]).search
      expect(results.extract_associated(:user)).to eq [amanda, james, jonah, mandy, peter]
    end

    it "ignores group_name sort when the assignment's group category is soft-deleted" do
      @fruits.update!(deleted_at: Time.zone.now)
      results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "group_name" }, { field: "username_first_last" }]).search
      expect(results.extract_associated(:user)).to eq [amanda, james, jonah, mandy, peter]
    end

    it "ignores soft-deleted groups in group_name sort" do
      @apples.destroy # soft-deleted
      results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "group_name" }, { field: "username_first_last" }]).search
      expect(results.extract_associated(:user)).to eq [james, peter, amanda, jonah, mandy]
    end

    it "ignores soft-deleted group memberships in group_name sort" do
      @apples.group_memberships.find_by(user: amanda).destroy # soft-deleted
      results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "group_name" }, { field: "username_first_last" }]).search
      expect(results.extract_associated(:user)).to eq [jonah, james, peter, amanda, mandy]
    end
  end

  it "supports sorting submissions by whether the user is the test student, ascending" do
    test_student = assignment.course.student_view_student

    results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "test_student" }, { field: "username" }]).search
    expect(results.extract_associated(:user)).to eq [test_student, *students]
  end

  it "supports sorting submissions by whether the user is the test student, descending" do
    test_student = assignment.course.student_view_student

    results = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "test_student", direction: "descending" }, { field: "username" }]).search
    expect(results.extract_associated(:user)).to eq [*students, test_student]
  end

  it "returns a random-but-consistent order when given 'random' sort order" do
    first_result = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "random" }]).search.extract_associated(:user)
    second_result = SubmissionSearch.new(assignment, teacher, nil, order_by: [{ field: "random" }]).search.extract_associated(:user)
    expect(first_result).to eq second_result
  end

  it "ignores direction when given 'random' sort order" do
    asc_result = SubmissionSearch.new(
      assignment,
      teacher,
      nil,
      order_by: [{ field: "random", direction: "ascending" }]
    ).search.extract_associated(:user)
    desc_result = SubmissionSearch.new(
      assignment,
      teacher,
      nil,
      order_by: [{ field: "random", direction: "descending" }]
    ).search.extract_associated(:user)
    expect(asc_result).to eq desc_result
  end

  it "returns students ordered by who needs grading (secondary sort by user id)" do
    assignment.submit_homework(amanda, body: "homework")
    assignment.submit_homework(james, body: "homework")
    assignment.submit_homework(peter, body: "homework")
    users = SubmissionSearch.new(
      assignment,
      teacher,
      nil,
      order_by: [{ field: "needs_grading", direction: "ascending" }]
    ).search.extract_associated(:user)
    expect(users).to eq [amanda, james, peter, jonah, mandy]
  end

  it "orders students by submission status (not_graded, resubmitted, not_submitted, graded)" do
    assignment.submit_homework(james, body: "homework") # not_graded
    assignment.grade_student(amanda, score: 1, grader: teacher)
    assignment.submit_homework(amanda, body: "homework") # resubmitted
    assignment.grade_student(jonah, score: 1, grader: teacher) # graded
    users = SubmissionSearch.new(
      assignment,
      teacher,
      nil,
      order_by: [{ field: "submission_status", direction: "ascending" }, { field: "username_first_last" }]
    ).search.extract_associated(:user)
    expect(users).to eq [james, amanda, mandy, peter, jonah]
  end

  it "handles edge cases for submission status ordering (not_graded, resubmitted, not_submitted, graded)" do
    assignment.submit_homework(james, body: "homework")
    assignment.grade_student(james, score: 1, grader: teacher)
    # simulates a partially graded quiz, should be not_graded
    assignment.submissions.find_by(user: james).update_columns(workflow_state: "pending_review")
    assignment.grade_student(amanda, score: 5, grader: teacher)
    # not_submitted, since teacher initially graded then wiped it out later
    assignment.grade_student(amanda, score: nil, grader: teacher)
    assignment.grade_student(jonah, score: 1, grader: teacher)
    # nil should be treated as true for grade_matches_current_submission, meaning this should be considered graded, not resubmitted
    assignment.submissions.find_by(user: jonah).update_columns(grade_matches_current_submission: nil)
    users = SubmissionSearch.new(
      assignment,
      teacher,
      nil,
      order_by: [{ field: "submission_status", direction: "ascending" }, { field: "username_first_last" }]
    ).search.extract_associated(:user)
    expect(users).to eq [james, amanda, mandy, peter, jonah]
  end

  it "orders by submission score" do
    assignment.grade_student(peter, score: 1, grader: teacher)
    assignment.grade_student(amanda, score: 2, grader: teacher)
    assignment.grade_student(james, score: 3, grader: teacher)
    results = SubmissionSearch.new(assignment, teacher, nil, scored_more_than: 0, order_by: [{ field: "score" }]).search
    expect(results.preload(:user).map(&:user)).to eq [peter, amanda, james]
  end

  it "orders by submission date" do
    Timecop.freeze do
      assignment.submit_homework(peter, submission_type: "online_text_entry", body: "homework", submitted_at: Time.zone.now)
      assignment.submit_homework(amanda, submission_type: "online_text_entry", body: "homework", submitted_at: 1.hour.from_now)
      results = SubmissionSearch.new(assignment, teacher, nil, states: "submitted", order_by: [{ field: "submitted_at" }]).search
      expect(results.preload(:user).map(&:user)).to eq [peter, amanda]
    end
  end

  it "orders by multiple fields" do
    assignment.grade_student(peter, score: 1, grader: teacher)
    assignment.grade_student(amanda, score: 1, grader: teacher)
    assignment.grade_student(james, score: 3, grader: teacher)
    results = SubmissionSearch.new(assignment,
                                   teacher,
                                   nil,
                                   scored_more_than: 0,
                                   order_by: [
                                     { field: "score", direction: "descending" },
                                     { field: "username", direction: "ascending" }
                                   ]).search
    expect(results.preload(:user).map(&:user)).to eq [james, amanda, peter]
  end

  context "searchers with limited section visibility" do
    let(:limited_course) { Course.create!(workflow_state: "available") }
    let(:section1) { limited_course.course_sections.create!(name: "Section 1") }
    let(:section2) { limited_course.course_sections.create!(name: "Section 2") }
    let(:teacher_section2) { User.create!(name: "Teacher Section 2") }
    let(:section_assignment) do
      Assignment.create!(
        course: limited_course,
        workflow_state: "active",
        submission_types: "online_text_entry",
        title: "Section Assignment",
        only_visible_to_overrides: true
      )
    end

    before do
      TeacherEnrollment.create!(
        user: teacher_section2,
        course: limited_course,
        course_section: section2,
        workflow_state: "active",
        limit_privileges_to_course_section: true
      )

      section_assignment.assignment_overrides.create!(
        set_type: AssignmentOverride::SET_TYPE_COURSE_SECTION,
        set_id: section1.id
      )
    end

    it "includes student enrolled in both sections when searcher is in one section and assignment has override in the other" do
      student_both_sections = User.create!(name: "Student Both Sections")
      StudentEnrollment.create!(user: student_both_sections, course: limited_course, course_section: section1, workflow_state: "active")
      StudentEnrollment.create!(user: student_both_sections, course: limited_course, course_section: section2, workflow_state: "active")

      results = SubmissionSearch.new(
        section_assignment,
        teacher_section2,
        nil,
        apply_gradebook_enrollment_filters: true
      ).search

      expect(results.pluck(:user_id)).to include(student_both_sections.id)
    end

    it "excludes student enrolled only in assignment section when teacher is section-limited to a different section" do
      student_section1_only = User.create!(name: "Student Section 1 Only")
      StudentEnrollment.create!(user: student_section1_only, course: limited_course, course_section: section1, workflow_state: "active")

      results = SubmissionSearch.new(
        section_assignment,
        teacher_section2,
        nil,
        apply_gradebook_enrollment_filters: true
      ).search

      expect(results.pluck(:user_id)).not_to include(student_section1_only.id)
    end
  end

  context "group assignments" do
    before(:once) do
      group_category = course.group_categories.create!(name: "My Category")
      @group = group_category.groups.create!(name: "My Group", context: course)
      students.each { |student| @group.add_user(student) }
      assignment.update!(group_category:)
    end

    describe "user_id" do
      it "returns the group rep's submission when provided with the group rep's ID" do
        results = SubmissionSearch.new(assignment, teacher, nil, user_id: jonah.id).search
        aggregate_failures do
          expect(results.count).to eq 1
          expect(results.first.user_id).to eq jonah.id
        end
      end

      it "returns the group rep's submission when provided with a different group member's ID" do
        results = SubmissionSearch.new(assignment, teacher, nil, user_representative_id: amanda.id).search
        aggregate_failures do
          expect(results.count).to eq 1
          expect(results.first.user.id).to eq jonah.id
        end
      end

      it "returns empty submissions if the user is searching for another group member user_representative_id and cannot view all grades" do
        results = SubmissionSearch.new(assignment, amanda, nil, user_representative_id: jonah.id).search
        aggregate_failures do
          expect(results.count).to eq 0
          expect(results.first).to be_nil
        end
      end
    end

    describe "representatives_only" do
      it "returns a submission for each user in the group by default" do
        results = SubmissionSearch.new(assignment, teacher, nil, {}).search
        expect(results.count).to eq students.count
      end

      it "optionally returns only the group rep's submission" do
        results = SubmissionSearch.new(assignment, teacher, nil, representatives_only: true).search

        aggregate_failures do
          expect(results.count).to eq 1
          expect(results.first.user.id).to eq jonah.id
        end
      end

      it "includes concluded enrollments in representatives when gradebook settings specify" do
        course.enrollments.find_by(user: amanda).conclude
        teacher.preferences[:gradebook_settings] = {
          course.global_id => {
            "show_concluded_enrollments" => "true"
          }
        }
        teacher.save!

        results = SubmissionSearch.new(
          assignment,
          teacher,
          nil,
          apply_gradebook_enrollment_filters: true,
          representatives_only: true
        ).search

        aggregate_failures do
          expect(results.count).to eq 1
          expect(results.first.user.id).to eq jonah.id
        end
      end

      it "excludes concluded enrollments from representatives when gradebook settings do not include them" do
        course.enrollments.find_by(user: jonah).conclude
        teacher.preferences[:gradebook_settings] = {
          course.global_id => {
            "show_concluded_enrollments" => "false"
          }
        }
        teacher.save!

        results = SubmissionSearch.new(
          assignment,
          teacher,
          nil,
          apply_gradebook_enrollment_filters: true,
          representatives_only: true
        ).search

        aggregate_failures do
          expect(results.count).to eq 1
          expect(results.first.user.id).to eq amanda.id
        end
      end
    end
  end

  describe "#filter_section_enrollment_states" do
    let_once(:section1) { course.course_sections.create!(name: "Section 1") }
    let_once(:section2) { course.course_sections.create!(name: "Section 2") }
    let_once(:student_section1) { User.create!(name: "Student Section 1") }
    let_once(:student_section2) { User.create!(name: "Student Section 2") }

    before :once do
      StudentEnrollment.create!(user: student_section1, course:, course_section: section1, workflow_state: "active")
      StudentEnrollment.create!(user: student_section2, course:, course_section: section2, workflow_state: "active")
    end

    def create_section_override_for_assignment(assignment, section:)
      assignment.assignment_overrides.create!(
        set_type: AssignmentOverride::SET_TYPE_COURSE_SECTION,
        set_id: section.id
      )
    end

    it "returns user_scope unchanged when user_scope is empty" do
      assignment.only_visible_to_overrides = true
      assignment.save!

      search = SubmissionSearch.new(assignment, teacher, nil, apply_gradebook_enrollment_filters: true)
      user_scope = User.where(id: [])
      result = search.send(:filter_section_enrollment_states, user_scope)
      expect(result.pluck(:id)).to eq []
    end

    it "returns user_scope unchanged when apply_gradebook_enrollment_filters is false" do
      assignment.only_visible_to_overrides = true
      assignment.save!
      create_section_override_for_assignment(assignment, section: section1)

      search = SubmissionSearch.new(assignment, teacher, nil, {})
      user_scope = User.where(id: [student_section1.id])
      result = search.send(:filter_section_enrollment_states, user_scope)
      expect(result.pluck(:id)).to eq [student_section1.id]
    end

    it "returns user_scope unchanged when assignment is not only_visible_to_overrides" do
      assignment.only_visible_to_overrides = false
      assignment.save!

      search = SubmissionSearch.new(assignment, teacher, nil, apply_gradebook_enrollment_filters: true)
      user_scope = User.where(id: [student_section1.id])
      result = search.send(:filter_section_enrollment_states, user_scope)
      expect(result.pluck(:id)).to eq [student_section1.id]
    end

    it "returns user_scope unchanged when assignment has section overrides and non-section overrides (currently unintended bug)" do
      assignment.only_visible_to_overrides = true
      assignment.save!
      # Create an individual student override (non-section override)
      assignment.assignment_overrides.create!(set_type: "ADHOC")

      search = SubmissionSearch.new(assignment, teacher, nil, apply_gradebook_enrollment_filters: true)
      user_scope = User.where(id: [student_section1.id])
      result = search.send(:filter_section_enrollment_states, user_scope)
      expect(result.pluck(:id)).to eq [student_section1.id]
    end

    it "filters out users with inactive enrollments in assignment sections" do
      assignment.only_visible_to_overrides = true
      assignment.save!
      create_section_override_for_assignment(assignment, section: section1)

      # Deactivate student_section1's enrollment
      course.enrollments.find_by(user: student_section1).deactivate

      search = SubmissionSearch.new(assignment, teacher, nil, apply_gradebook_enrollment_filters: true)
      user_scope = User.where(id: [student_section1.id, student_section2.id])
      result = search.send(:filter_section_enrollment_states, user_scope)

      # student_section1 should be filtered out, student_section2 is not in assignment section
      expect(result.pluck(:id)).to eq []
    end

    it "filters out users with concluded enrollments when gradebook settings exclude them" do
      assignment.only_visible_to_overrides = true
      assignment.save!
      create_section_override_for_assignment(assignment, section: section1)

      # Conclude student_section1's enrollment
      course.enrollments.find_by(user: student_section1).conclude

      teacher.preferences[:gradebook_settings] = {
        course.global_id => {
          "show_concluded_enrollments" => "false"
        }
      }
      teacher.save!

      search = SubmissionSearch.new(assignment, teacher, nil, apply_gradebook_enrollment_filters: true)
      user_scope = User.where(id: [student_section1.id])
      result = search.send(:filter_section_enrollment_states, user_scope)
      expect(result.pluck(:id)).to eq []
    end

    it "keeps users with active enrollments in assignment sections" do
      assignment.only_visible_to_overrides = true
      assignment.save!
      create_section_override_for_assignment(assignment, section: section1)

      search = SubmissionSearch.new(assignment, teacher, nil, apply_gradebook_enrollment_filters: true)
      user_scope = User.where(id: [student_section1.id])
      result = search.send(:filter_section_enrollment_states, user_scope)
      expect(result.pluck(:id)).to eq [student_section1.id]
    end

    it "includes concluded users when gradebook settings allow them" do
      assignment.only_visible_to_overrides = true
      assignment.save!
      create_section_override_for_assignment(assignment, section: section1)

      # Conclude student_section1's enrollment
      course.enrollments.find_by(user: student_section1).conclude

      teacher.preferences[:gradebook_settings] = {
        course.global_id => {
          "show_concluded_enrollments" => "true"
        }
      }
      teacher.save!

      search = SubmissionSearch.new(assignment, teacher, nil, apply_gradebook_enrollment_filters: true)
      user_scope = User.where(id: [student_section1.id])
      result = search.send(:filter_section_enrollment_states, user_scope)
      expect(result.pluck(:id)).to eq [student_section1.id]
    end

    it "includes inactive users when gradebook settings allow them" do
      assignment.only_visible_to_overrides = true
      assignment.save!
      create_section_override_for_assignment(assignment, section: section1)

      # Deactivate student_section1's enrollment
      course.enrollments.find_by(user: student_section1).deactivate

      teacher.preferences[:gradebook_settings] = {
        course.global_id => {
          "show_inactive_enrollments" => "true"
        }
      }
      teacher.save!

      search = SubmissionSearch.new(assignment, teacher, nil, apply_gradebook_enrollment_filters: true)
      user_scope = User.where(id: [student_section1.id])
      result = search.send(:filter_section_enrollment_states, user_scope)
      expect(result.pluck(:id)).to eq [student_section1.id]
    end

    it "filters users by multiple assignment sections" do
      assignment.only_visible_to_overrides = true
      assignment.save!
      create_section_override_for_assignment(assignment, section: section1)
      create_section_override_for_assignment(assignment, section: section2)

      search = SubmissionSearch.new(assignment, teacher, nil, apply_gradebook_enrollment_filters: true)
      user_scope = User.where(id: [student_section1.id, student_section2.id])
      result = search.send(:filter_section_enrollment_states, user_scope)
      expect(result.pluck(:id)).to match_array([student_section1.id, student_section2.id])
    end

    it "filters out users not in any assignment section" do
      assignment.only_visible_to_overrides = true
      assignment.save!
      create_section_override_for_assignment(assignment, section: section1)

      # student_section2 is in section2, but assignment only has section1 override
      search = SubmissionSearch.new(assignment, teacher, nil, apply_gradebook_enrollment_filters: true)
      user_scope = User.where(id: [student_section1.id, student_section2.id])
      result = search.send(:filter_section_enrollment_states, user_scope)
      expect(result.pluck(:id)).to eq [student_section1.id]
    end
  end
end
