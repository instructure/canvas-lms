require_relative '../../../spec_helper.rb'
include Api::V1::Json

class SisAssignmentHarness
  include Api::V1::SisAssignment
end

describe Api::V1::SisAssignment do
  subject { SisAssignmentHarness.new }

  let(:course_1) { course }
  let(:assignment_1) { assignment_model(course: course) }
  let(:assignment_with_context) { Assignment.new }

  let(:assignment_override_1) do
    assignment_override_model(assignment: assignment_1)
  end

  let(:assignment_override_2) do
    assignment_override_model(assignment: assignment_1)
  end

  let(:assignment_overrides) do
    assignment_override_1.stubs(:set_type).returns("CourseSection")
    assignment_override_1.stubs(:set_id).returns(1)

    assignment_override_2.stubs(:set_type).returns("CourseSection")
    assignment_override_2.stubs(:set_id).returns(2)

    [
      assignment_override_1,
      assignment_override_2
    ]
  end

  let(:course_section_1) { CourseSection.new }
  let(:course_section_2) { CourseSection.new }
  let(:course_section_3) { CourseSection.new }

  let(:course_sections) do
    [
      course_section_1,
      course_section_2,
      course_section_3
    ]
  end

  before do
    assignment_override_model(:assignment => @assignment)
    assignment_model(:course => @course)
    @student = student_in_course(:course => @course, :user => user_with_pseudonym).user
    @override = @assignment.assignment_overrides(true).first
    assignment_1.stubs(:locked_for?).returns(false)

    assignment_with_context.stubs(:locked_for?).returns(false)
    assignment_with_context.stubs(:context).returns(course_sections)
    assignment_with_context.stubs(:association).with(:context).returns(course_sections)
    assignment_with_context.stubs(:association).with(:assignment_override_students).returns(@override)
    assignment_with_context.stubs(:assignment_override_students).returns(@override)
    assignment_with_context.stubs(:association).with(:assignment_group).returns(
      OpenStruct.new(:loaded? => false))
    assignment_with_context.stubs(:association).with(:active_assignment_overrides).returns(
      OpenStruct.new(:loaded? => true))
    assignment_with_context.stubs(:active_assignment_overrides).returns(assignment_overrides)
    assignment_with_context.stubs(:only_visible_to_overrides).returns(true)

    assignment_with_context.stubs(:unlock_at).returns(10.days.ago)
    assignment_with_context.stubs(:lock_at).returns(10.days.from_now)

    assignment_overrides.stubs(:loaded?).returns(true)
    assignment_overrides.stubs(:unlock_at).returns(15.days.ago)
    assignment_overrides.stubs(:lock_at).returns(2.days.from_now)

    course_section_1.stubs(:id).returns(1)
    course_section_2.stubs(:id).returns(2)
    course_section_3.stubs(:id).returns(3)

    course_sections.each do |course_section|
      course_section.stubs(:nonxlist_course).returns(course_1)
      course_section.stubs(:crosslisted?).returns(false)
    end

    course_sections.stubs(:loaded?).returns(true)
    course_sections.stubs(:active_course_sections).returns(course_sections)
    course_sections.stubs(:association).returns(OpenStruct.new(:loaded? => true))
  end

  context "#sis_assignments_json" do
    it "assignment groups have name and sis_source_id" do
      ag_name = 'chumba choo choo'
      sis_source_id = "my super unique goo-id"
      assignment_group = AssignmentGroup.new(name: ag_name, sis_source_id: sis_source_id, group_weight: 8.7)
      assignment_1.stubs(:assignment_group).returns(assignment_group)
      result = subject.sis_assignments_json([assignment_1])
      expect(result[0]["assignment_group"]["name"]).to eq(ag_name)
      expect(result[0]["assignment_group"]["sis_source_id"]).to eq(sis_source_id)
      expect(result[0]["assignment_group"]["group_weight"]).to eq(8.7)
    end

    it "returns false for include_in_final_grade when omit_from_final_grade is true" do
      assignment_1[:omit_from_final_grade] = true
      assignment_1[:grading_type] = 'points'
      assignments = [assignment_1]
      result = subject.sis_assignments_json(assignments)
      expect(result[0]['include_in_final_grade']).to eq(false)
    end

    it "returns false for include_in_final_grade when grading_type is not_graded" do
      assignment_1[:omit_from_final_grade] = false
      assignment_1[:grading_type] = 'not_graded'
      assignments = [assignment_1]
      result = subject.sis_assignments_json(assignments)
      expect(result[0]['include_in_final_grade']).to eq(false)
    end

    it "returns true for include_in_final_grade when appropriate" do
      assignment_1[:omit_from_final_grade] = false
      assignment_1[:grading_type] = 'points'
      assignments = [assignment_1]
      result = subject.sis_assignments_json(assignments)
      expect(result[0]['include_in_final_grade']).to eq(true)
    end

    it "returns an empty hash for 0 assignments" do
      assignments = []
      expect(subject.sis_assignments_json(assignments)).to eq([])
    end

    context "returns hash when there are no courses" do
      let(:assignments) { [assignment_1] }
      let(:results) { subject.sis_assignments_json(assignments) }
      it { expect(results.size).to eq(1) }
      it { expect(results.first["id"]).to eq(assignment_1.id) }
    end

    it "sis assignments handle only visible to overrides" do
      assignments = [assignment_with_context]
      result = subject.sis_assignments_json(assignments)
      expect(result[0]['sections'].size).to eq(2)
      expect(result[0]['sections'][0]["id"]).to eq(1)
      expect(result[0]['sections'][1]["id"]).to eq(2)
    end

    it "includes unlock_at and lock_at attributes" do
      assignments = [assignment_with_context]
      result = subject.sis_assignments_json(assignments)
      expect(result[0].key?('unlock_at')).to eq(true)
      expect(result[0].key?('lock_at')).to eq(true)
    end

    it "includes unlock_at and lock_at attributes in section overrides" do
      assignments = [assignment_with_context]
      result = subject.sis_assignments_json(assignments)
      expect(result[0]['sections'][0]['override'].key?('unlock_at')).to eq(true)
      expect(result[0]['sections'][0]['override'].key?('lock_at')).to eq(true)
    end

    context "user level assignment differentiation" do
      before :once do
        course_with_teacher(:active_all => true)
        assignment_model(:course => @course, :group_category => 'category')
        assignment_override_model(:assignment => @assignment)
        @override.set = @course.default_section
        @override.save!
      end

      it "sis assignments handle only visible user_overrides" do
        student_in_course({:course => @course, :workflow_state => 'active'})
        @override.set = nil
        @override.set_type = 'ADHOC'
        @override.save!

        @override_student = @override.assignment_override_students.build
        @override_student.user = @student
        @override_student.user.pseudonym = pseudonym(@override_student.user)
        @override_student.save!

        @assignment.stubs(:assignment_override_students).returns([@override_student])

        result = subject.sis_assignments_json([@assignment])
        user_overrides = result[0]['user_overrides'][0]

        expect(user_overrides['id']).to eq(@override_student.user.pseudonym['id'])
        expect(user_overrides['name']).to eq(@override_student.user['name'])
        expect(user_overrides['sis_user_id']).to eq(nil)
      end

      it "returns proper json for multiple students with the same override" do
        student_1_name = "Student 1"
        student_2_name = "Student 2"
        student_1_sis_id = "student-1-sis-id"
        student_2_sis_id = "student-2-sis-id"
        student_in_course({
                              :course => @course,
                              :workflow_state => 'active',
                              :name => student_1_name
                          })

        @override.set = nil
        @override.set_type = 'ADHOC'
        @override.save!

        @override_student = @override.assignment_override_students.build
        @override_student.user = @student
        @override_student.user.pseudonym = managed_pseudonym(@override_student.user, sis_user_id: student_1_sis_id)
        @override_student.save!

        # This overrides @student
        student_in_course({
                              :course => @course,
                              :workflow_state => 'active',
                              :name => student_2_name
                          })

        @override_student_2 = @override.assignment_override_students.build
        @override_student_2.user = @student
        @override_student_2.user.pseudonym = managed_pseudonym(@override_student_2.user, sis_user_id: student_2_sis_id)
        @override_student_2.save!

        result = subject.sis_assignments_json([@assignment])

        override = result[0]
        user_overrides = override["user_overrides"]
        user_override = user_overrides[0]

        expect(result.length).to be(1)
        expect(override["course_id"]).to be(@course.id)
        expect(override["points_possible"]).to be(@assignment.points_possible)
        expect(user_overrides.length).to be(1)

        expect(user_override["id"][0]["name"]).to eq(student_1_name)
        expect(user_override["id"][0]["sis_user_id"]).to eq(student_1_sis_id)

        expect(user_override["id"][1]["name"]).to eq(student_2_name)
        expect(user_override["id"][1]["sis_user_id"]).to eq(student_2_sis_id)
      end
      it "returns proper json for multiple students with individual overrides" do
        student_1_name = "Student 1"
        student_2_name = "Student 2"
        student_1_sis_id = "student-1-sis-id"
        student_2_sis_id = "student-2-sis-id"
        student_in_course({
                              :course => @course,
                              :workflow_state => 'active',
                              :name => student_1_name
                          })

        @override.set = nil
        @override.set_type = 'ADHOC'
        @override.save!

        @override_student = @override.assignment_override_students.build
        @override_student.user = @student
        @override_student.user.pseudonym = managed_pseudonym(@override_student.user, sis_user_id: student_1_sis_id)
        @override_student.save!

        # This overrides @override
        assignment_override_model(:assignment => @assignment)
        @override.set = nil
        @override.set_type = 'ADHOC'
        @override.save!

        # This overrides @student
        student_in_course({
                              :course => @course,
                              :workflow_state => 'active',
                              :name => student_2_name
                          })

        @override_student_2 = @override.assignment_override_students.build
        @override_student_2.user = @student
        @override_student_2.user.pseudonym = managed_pseudonym(@override_student_2.user, sis_user_id: student_2_sis_id)
        @override_student_2.save!

        result = subject.sis_assignments_json([@assignment])
        override = result[0]
        user_overrides = override["user_overrides"]

        expect(result.length).to be(1)
        expect(override["course_id"]).to be(@course.id)
        expect(override["points_possible"]).to be(@assignment.points_possible)
        expect(user_overrides.length).to be(2)

        expect(user_overrides[0]["name"]).to eq(student_1_name)
        expect(user_overrides[0]["sis_user_id"]).to eq(student_1_sis_id)

        expect(user_overrides[1]["name"]).to eq(student_2_name)
        expect(user_overrides[1]["sis_user_id"]).to eq(student_2_sis_id)
      end
    end
  end
end
