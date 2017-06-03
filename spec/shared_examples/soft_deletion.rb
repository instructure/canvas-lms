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
    it "calls save! if destroy_permanently! was called"

    it "triggers destroy callbacks"
  end
end
