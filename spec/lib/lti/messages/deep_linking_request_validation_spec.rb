# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "lti_advantage_shared_examples"

describe Lti::Messages::DeepLinkingRequest do
  include_context "lti_advantage_shared_examples"

  let(:opts) { { resource_type: "editor_button" } }

  let(:jwt_message) do
    Lti::Messages::DeepLinkingRequest.new(
      tool:,
      context: course,
      user:,
      expander:,
      return_url:,
      opts:
    )
  end

  describe "nested model validation" do
    it "validates deep_linking_settings and propagates errors when nested model is invalid" do
      message = jwt_message.instance_variable_get(:@message)

      message.deep_linking_settings.accept_types = ["ltiResourceLink"]
      message.deep_linking_settings.accept_presentation_document_targets = ["iframe"]

      expect(message.valid?).to be false
      expect(message.errors[:deep_linking_settings]).to eq(
        [
          { deep_link_return_url: [{ attribute: :deep_link_return_url, message: "can't be blank", type: :blank }] }
        ]
      )
    end

    it "validates successfully when deep_linking_settings are valid" do
      message = jwt_message.instance_variable_get(:@message)

      message.deep_linking_settings.accept_types = ["ltiResourceLink"]
      message.deep_linking_settings.accept_presentation_document_targets = ["iframe"]
      message.deep_linking_settings.deep_link_return_url = "http://test.com/return"

      expect(message.deep_linking_settings.valid?).to be true
    end
  end
end
