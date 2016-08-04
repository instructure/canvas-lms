require_relative '../../../spec_helper.rb'

class SisAssignmentHarness
  include Api::V1::SisAssignment
end

describe Api::V1::SisAssignment do
  subject { SisAssignmentHarness.new }

  context "#sis_assignments_json" do
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
      assignment_1.stubs(:locked_for?).returns(false)

      assignment_with_context.stubs(:locked_for?).returns(false)
      assignment_with_context.stubs(:context).returns(course_sections)
      assignment_with_context.stubs(:association).with(:context).returns(course_sections)
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
  end
end

