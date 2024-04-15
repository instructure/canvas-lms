# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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
#

shared_examples_for "types with enumerable workflow states" do
  let(:enum_class) { raise "set in examples" }
  let(:model_class) { raise "set in examples" }

  describe "workflow_state enumerable class" do
    subject { enum_class.values.keys }

    it "has values matching the workflow_state values of the model" do
      expect(subject).to match_array model_class.workflow_states.map(&:to_s)
    end
  end
end
