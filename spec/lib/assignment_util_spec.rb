require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe AssignmentUtil do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true, user_name: 'a student')
  end

  let(:assignment) do
    @course.assignments.create!(assignment_valid_attributes)
  end

  describe "due_date_required?" do
    it "returns true when all 3 are set to true" do
      assignment.post_to_sis = true
      assignment.context.account.stubs(:sis_require_assignment_due_date).returns({value: true})
      assignment.context.account.stubs(:feature_enabled?).with('new_sis_integrations').returns(true)
      expect(described_class.due_date_required?(assignment)).to eq(true)
    end

    it "returns false when post_to_sis is false" do
      assignment.post_to_sis = false
      assignment.context.account.stubs(:sis_require_assignment_due_date).returns({value: true})
      assignment.context.account.stubs(:feature_enabled?).with('new_sis_integrations').returns(true)
      expect(described_class.due_date_required?(assignment)).to eq(false)
    end

    it "returns false when sis_require_assignment_due_date is false" do
      assignment.post_to_sis = true
      assignment.context.account.stubs(:sis_require_assignment_due_date).returns({value: false})
      assignment.context.account.stubs(:feature_enabled?).with('new_sis_integrations').returns(true)
      expect(described_class.due_date_required?(assignment)).to eq(false)
    end

    it "returns false when new_sis_integrations is false" do
      assignment.post_to_sis = true
      assignment.context.account.stubs(:sis_require_assignment_due_date).returns({value: true})
      assignment.context.account.stubs(:feature_enabled?).with('new_sis_integrations').returns(false)
      expect(described_class.due_date_required?(assignment)).to eq(false)
    end
  end

  describe "due_date_ok?" do
    it "returns false when due_at is blank and due_date_required? is true" do
      assignment.due_at = nil
      described_class.stubs(:due_date_required?).with(assignment).returns(true)
      expect(described_class.due_date_ok?(assignment)).to eq(false)
    end

    it "returns true when due_at is present and due_date_required? is true" do
      assignment.due_at = Time.zone.now
      described_class.stubs(:due_date_required?).with(assignment).returns(true)
      expect(described_class.due_date_ok?(assignment)).to eq(true)
    end

    it "returns true when due_at is present and due_date_required? is false" do
      assignment.due_at = Time.zone.now
      described_class.stubs(:due_date_required?).with(assignment).returns(false)
      expect(described_class.due_date_ok?(assignment)).to eq(true)
    end

    it "returns true when due_at is present and due_date_required? is false" do
      assignment.due_at = nil
      described_class.stubs(:due_date_required?).with(assignment).returns(false)
      expect(described_class.due_date_ok?(assignment)).to eq(true)
    end
  end
end

