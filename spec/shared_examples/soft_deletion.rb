shared_examples "soft deletion" do
  let(:first) do
    if creation_arguments.is_a? Array
      subject.create! creation_arguments.first
    else
      subject.create! creation_arguments
    end
  end

  let(:second) do
    if creation_arguments.is_a? Array
      subject.create! creation_arguments.last
    else
      subject.create! creation_arguments
    end
  end

  let(:active_scope)  { subject.active }

  describe "workflow" do
    it "defaults to active" do
      expect(first).to be_active
    end

    it "is deleted after destroy is called" do
      first.destroy
      expect(first).to be_deleted
    end
  end

  describe "#active" do
    let!(:destroy_the_second_active_object) { second.destroy }
    it "includes active grading_periods" do
      expect(active_scope).to include first
    end

    it "does not include inactive grading_periods" do
      expect(active_scope).to_not include second
    end
  end

  describe "#destroy" do
    it "marks deleted periods workflow_state as deleted" do
      first.destroy
      expect(first.workflow_state).to eq "deleted"
    end

    # Use Mocha to test this.
    it "calls save"
    it "calls save! if destroy! was called"

    it "triggers destroy callbacks"
  end
end
