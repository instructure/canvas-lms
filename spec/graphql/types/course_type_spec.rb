require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/graphql_type_tester')

describe Types::CourseType do
  let_once(:course) { course_with_student(active_all: true); @course }
  let(:course_type) { GraphQLTypeTester.new(Types::CourseType, course) }

  it "works" do
    expect(course_type._id).to eq course.id
    expect(course_type.name).to eq course.name
  end

  describe "assignmentsConnection" do
    let_once(:assignment) {
      course.assignments.create! name: "asdf", workflow_state: "unpublished"
    }

    it "only returns visible assignments" do
      expect(course_type.assignmentsConnection(current_user: @teacher).size).to eq 1
      expect(course_type.assignmentsConnection(current_user: @student).size).to eq 0
    end
  end

  describe "sectionsConnection" do
    it "only includes active sections" do
      section1 = course.course_sections.create!(name: "Delete Me")
      expect(course_type.sectionsConnection.size).to eq 2

      section1.destroy
      expect(course_type.sectionsConnection.size).to eq 1
    end
  end

  context "submissionsConnection" do
    before(:once) do
      a1 = course.assignments.create! name: "one", points_possible: 10
      a2 = course.assignments.create! name: "two", points_possible: 10

      @student1 = @student
      student_in_course(active_all: true)
      @student2 = @student

      @student1a1_submission, _ = a1.grade_student(@student1, grade: 1, grader: @teacher)
      @student1a2_submission, _ = a2.grade_student(@student1, grade: 9, grader: @teacher)
      @student2a1_submission, _ = a1.grade_student(@student2, grade: 5, grader: @teacher)

      @student1a1_submission.update_attribute :graded_at, 4.days.ago
      @student1a2_submission.update_attribute :graded_at, 2.days.ago
      @student2a1_submission.update_attribute :graded_at, 3.days.ago
    end

    it "returns submissions for specified students" do
      expect(
        course_type.submissionsConnection(
          current_user: @teacher,
          args: {
            studentIds: [@student1.id.to_s, @student2.id.to_s],
            orderBy: [{field: "id", direction: "asc"}],
          }
        )
      ).to eq [
        @student1a1_submission,
        @student1a2_submission,
        @student2a1_submission
      ].sort_by(&:id)
    end

    it "doesn't let students see other student's submissions" do
      expect(
        course_type.submissionsConnection(
          current_user: @student2,
          args: {
            studentIds: [@student1.id.to_s, @student2.id.to_s],
          }
        )
      ).to eq [@student2a1_submission]
    end

    it "takes sorting criteria" do
      expect(
        course_type.submissionsConnection(
          current_user: @teacher,
          args: {
            studentIds: [@student1.id.to_s, @student2.id.to_s],
            orderBy: [{field: "graded_at", direction: "desc"}],
          }
        )
      ).to eq [
        @student1a2_submission,
        @student2a1_submission,
        @student1a1_submission,
      ]
    end
  end

  describe "usersConnection" do
    before(:once) do
      @student1 = @student
      @student2 = student_in_course(active_all: true).user
    end

    it "returns all visible users" do
      expect(
        course_type.usersConnection(current_user: @teacher)
      ).to eq [@teacher, @student1, @student2]
    end

    it "returns only the specified users" do
      expect(
        course_type.usersConnection(
          current_user: @teacher,
          args: {userIds: @student1}
        )
      ).to eq [@student1]
    end

    it "doesn't return users that aren't visible to you" do
      other_teacher = teacher_in_course(active_all: true,
                                        course: Course.create!).user
      expect(
        course_type.usersConnection(current_user: other_teacher)
      ).to be_nil
    end
  end

  describe "AssignmentGroupConnection" do
    it "returns groups" do
      c = Course.find(course.id)
      c.assignment_groups.create!(name: 'a group')
      expect(c.assignment_groups.size).to be 1
      expect(course_type.assignmentGroupsConnection.length).to be 1
    end
  end
end
