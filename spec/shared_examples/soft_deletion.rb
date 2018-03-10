#
# Copyright (C) 2015 - present Instructure, Inc.
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

# rubocop:disable RSpec/NamedSubject
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
  end

  describe "#active" do
    let!(:destroy_the_second_active_object) { second.destroy }
    it "includes active associations" do
      expect(active_scope).to include first
    end

    it "does not include inactive associations" do
      expect(active_scope).to_not include second
    end
  end

  describe "#destroy" do
    it "is deleted" do
      first.destroy
      expect(first).to be_deleted
    end

    it "marks deleted periods workflow_state as deleted" do
      first.destroy
      expect(first.workflow_state).to eq "deleted"
    end

    # Use Mocha to test this.
    it "calls save!" do
      expect(first).to receive(:save!).once
      first.destroy
    end

    it "triggers destroy callbacks" do
      expect(first).to receive(:run_callbacks).with(:destroy)
      first.destroy
    end
  end

  describe "#destroy_permanently" do
    it "frd destroys" do
      first.destroy_permanently!
      expect(first).to be_destroyed
    end
  end
end

shared_examples "has_one soft deletion" do
  describe "workflow" do
    it "defaults to active" do
      expect(subject).to be_active
    end

    it { is_expected.to be_active }
  end

  describe "#active" do
    it "includes active associations" do
      expect(subject.class.where(id: subject.id).active).to include subject
    end

    it "does not include inactive associations" do
      subject.destroy
      expect(subject.class.where(id: subject.id).active).not_to include subject
    end
  end

  describe "#destroy" do
    it "is deleted" do
      subject.destroy
      expect(subject).to be_deleted
    end

    it "marks deleted object workflow_state as deleted" do
      subject.destroy
      expect(subject.workflow_state).to eq 'deleted'
    end

    it "calls save!" do
      expect(subject).to receive(:save!).once
      subject.destroy
    end

    it "triggers destroy callbacks" do
      expect(subject).to receive(:run_callbacks).with(:destroy)
      subject.destroy
    end
  end

  describe "#destroy_permanently" do
    it "frd destroys" do
      subject.destroy_permanently!
      expect(subject).to be_destroyed
    end
  end
end
# rubocop:enable RSpec/NamedSubject
