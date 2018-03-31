#
# Copyright (C) 2018 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe AssignmentOverrideInstrumenter do
  context '#needs_overriding?' do
    it "doesn't override when no overrideable attributes are requested" do
      expect(
        AssignmentOverrideInstrumenter.needs_overriding?("id" => true)
      ).to eq false
    end

    it "overrides when overrideable attributes are requested" do
      %w[dueAt unlockAt lockAt].each { |overrideable_attribute|
        expect(
          AssignmentOverrideInstrumenter.needs_overriding?(overrideable_attribute => true)
        ).to eq true
      }
    end

    it "doesn't override if assignment_overrides are requested" do
      expect(
        AssignmentOverrideInstrumenter.needs_overriding?(
          "dueAt" => true, "assignmentOverrides" => true
        )
      ).to eq false
    end
  end
end
