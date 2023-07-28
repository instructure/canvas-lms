# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

describe Lti::Helpers::JwtMessageHelper do
  # This set of tests uses data directly from the spec, to ensure our signature generation algorithm
  # follows it precisely
  describe "generate_oauth_consumer_key_sign" do
    subject { Lti::Helpers::JwtMessageHelper.generate_oauth_consumer_key_sign(associated_1_1_tool, message) }

    let(:associated_1_1_tool) do
      t = double("associated_1_1_tool")
      allow(t).to receive_messages(consumer_key: "179248902", shared_secret: "my-lti11-secret")
      t
    end
    let(:message) do
      m = double("message")
      allow(m).to receive_messages(deployment_id: "689302",
                                   iss: "https://lmsvendor.com",
                                   aud: "PM48OJSfGDTAzAo",
                                   exp: 1_551_290_856,
                                   nonce: "172we8671fd8z")
      m
    end

    it "generates the appropriate signature according to the IMS spec" do
      expect(subject).to eq("lWd54kFo5qU7xshAna6v8BwoBm6tmUjc6GTax6+12ps=")
    end
  end
end
