require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/graphql_type_tester')

describe Types::CourseType do
  let_once(:course) { Course.create! name: "TEST" }
  let(:course_type) { GraphQLTypeTester.new(Types::CourseType, course) }

  it "works" do
    expect(course_type._id).to eq course.id
    expect(course_type.name).to eq course.name
  end

  describe "assignmentsConnection" do
    let_once(:teacher) {
      teacher_in_course(active_all: true, course: course)
      @teacher
    }
    let_once(:student) {
      student_in_course(active_all: true, course: course)
      @student
    }
    let_once(:assignment) {
      course.assignments.create! name: "asdf", workflow_state: "unpublished"
    }

    it "only returns visible assignments" do
      expect(course_type.assignmentsConnection(current_user: teacher).size).to eq 1
      expect(course_type.assignmentsConnection(current_user: student).size).to eq 0
    end
  end

  describe "sectionsConnection" do
    it "only includes active sections" do
      section1 = course.course_sections.create!(name: "Delete Me")
      section2 = course.course_sections.create!(name: "Keep Me")
      section1.destroy
      expect(course_type.sectionsConnection.size).to eq 1
    end
  end
end
