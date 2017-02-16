require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe AssignmentUtil do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true, user_name: 'a student')
  end

  let(:assignment) do
    @course.assignments.create!(assignment_valid_attributes)
  end

  let(:assignment_name_length_value){ 15 }

  def account_stub_helper(assignment, require_due_date, sis_syncing, new_sis_integrations)
    assignment.context.account.stubs(:sis_require_assignment_due_date).returns({value: require_due_date})
    assignment.context.account.stubs(:sis_syncing).returns({value: sis_syncing})
    assignment.context.account.stubs(:feature_enabled?).with('new_sis_integrations').returns(new_sis_integrations)
  end

  def due_date_required_helper(assignment, post_to_sis, require_due_date, sis_syncing, new_sis_integrations)
    assignment.post_to_sis = post_to_sis
    account_stub_helper(assignment, require_due_date, sis_syncing, new_sis_integrations)
  end

  describe "due_date_required?" do
    it "returns true when all 4 are set to true" do
      due_date_required_helper(assignment, true, true, true, true)
      expect(described_class.due_date_required?(assignment)).to eq(true)
    end

    it "returns false when post_to_sis is false" do
      due_date_required_helper(assignment, false, true, true, true)
      expect(described_class.due_date_required?(assignment)).to eq(false)
    end

    it "returns false when sis_require_assignment_due_date is false" do
      due_date_required_helper(assignment, true, false, true, true)
      expect(described_class.due_date_required?(assignment)).to eq(false)
    end

    it "returns false when sis_syncing is false" do
      due_date_required_helper(assignment, true, true, false, true)
      expect(described_class.due_date_required?(assignment)).to eq(false)
    end

    it "returns false when new_sis_integrations is false" do
      due_date_required_helper(assignment, true, true, true, false)
      expect(described_class.due_date_required?(assignment)).to eq(false)
    end
  end

  describe "due_date_required_for_account?" do
    it "returns true when all 3 are set to true" do
      account_stub_helper(assignment, true, true, true)
      expect(described_class.due_date_required_for_account?(assignment)).to eq(true)
    end

    it "returns false when sis_require_assignment_due_date is false" do
      account_stub_helper(assignment, false, true, true)
      expect(described_class.due_date_required_for_account?(assignment)).to eq(false)
    end

    it "returns false when sis_syncing is false" do
      account_stub_helper(assignment, true, false, true)
      expect(described_class.due_date_required_for_account?(assignment)).to eq(false)
    end

    it "returns false when new_sis_integrations is false" do
      account_stub_helper(assignment, true, true, false)
      expect(described_class.due_date_required_for_account?(assignment)).to eq(false)
    end
  end

  describe "assignment_max_name_length" do
    it "returns 15 when the account setting sis_assignment_name_length_input is 15" do
      assignment.context.account.stubs(:sis_assignment_name_length_input).returns({value: 15})
      expect(described_class.assignment_max_name_length(assignment)).to eq(15)
    end
  end

  describe "post_to_sis_friendly_name" do
    it "returns custom friendly name when the account setting sis_name is custom" do
      assignment.context.account.root_account.settings[:sis_name] = 'Foo Bar'
      expect(described_class.post_to_sis_friendly_name(assignment)).to eq('Foo Bar')
    end

    it "returns SIS when the account setting sis_name is not custom" do
      expect(described_class.post_to_sis_friendly_name(assignment)).to eq('SIS')
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

  describe "assignment_name_length_required?" do
    it "returns true when all 4 are set to true" do
      assignment.post_to_sis = true
      assignment.context.account.stubs(:sis_syncing).returns({value: true})
      assignment.context.account.stubs(:sis_assignment_name_length).returns({value: true})
      assignment.context.account.stubs(:feature_enabled?).with('new_sis_integrations').returns(true)
      expect(described_class.assignment_name_length_required?(assignment)).to eq(true)
    end

    it "returns false when sis_sycning is set to false" do
      assignment.post_to_sis = true
      assignment.context.account.stubs(:sis_syncing).returns({value: false})
      assignment.context.account.stubs(:sis_assignment_name_length).returns({value: true})
      assignment.context.account.stubs(:feature_enabled?).with('new_sis_integrations').returns(true)
      expect(described_class.assignment_name_length_required?(assignment)).to eq(false)
    end

    it "returns false when post_to_sis is false" do
      assignment.post_to_sis = false
      assignment.context.account.stubs(:sis_syncing).returns({value: true})
      assignment.context.account.stubs(:sis_assignment_name_length).returns({value: true})
      assignment.context.account.stubs(:feature_enabled?).with('new_sis_integrations').returns(true)
      expect(described_class.assignment_name_length_required?(assignment)).to eq(false)
    end

    it "returns false when sis_assignment_name_length is false" do
      assignment.post_to_sis = true
      assignment.context.account.stubs(:sis_syncing).returns({value: false})
      assignment.context.account.stubs(:sis_assignment_name_length).returns({value: false})
      assignment.context.account.stubs(:feature_enabled?).with('new_sis_integrations').returns(true)
      expect(described_class.assignment_name_length_required?(assignment)).to eq(false)
    end

    it "returns false when new_sis_integrations is false" do
      assignment.post_to_sis = true
      assignment.context.account.stubs(:sis_syncing).returns({value: false})
      assignment.context.account.stubs(:sis_assignment_name_length).returns({value: true})
      assignment.context.account.stubs(:feature_enabled?).with('new_sis_integrations').returns(false)
      expect(described_class.assignment_name_length_required?(assignment)).to eq(false)
    end
  end
end
