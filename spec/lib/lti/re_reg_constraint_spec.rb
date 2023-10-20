# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe Lti::ReRegConstraint do
  describe "#matches?" do
    it "returns true if the header VND-IMS-CONFIRM-URL is present" do
      mock_request = double("mock_request")
      allow(mock_request).to receive_messages(
        headers: { "VND-IMS-CONFIRM-URL" => "http://i-am-a-place-on-the-internet.dev/" },
        format: "json"
      )
      expect(subject.matches?(mock_request)).to be_truthy
    end

    it "returns failse if the format is not json" do
      mock_request = double("mock_request")
      allow(mock_request).to receive_messages(
        headers: { "VND-IMS-CONFIRM-URL" => "http://i-am-a-place-on-the-internet.dev/" },
        format: "xml"
      )
      expect(subject.matches?(mock_request)).to be_falsey
    end
  end
end
