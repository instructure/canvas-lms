# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "../../../lti_1_3_spec_helper"

describe DataFixup::Lti::FillToolConfigurationLtiRegistrationIds do
  include_context "lti_1_3_spec_helper"

  let(:account) { account_model }

  context "when there are developer keys with tool configurations" do
    let(:registration) { Lti::Registration.last }

    before do
      dev_key_model_1_3(account:)
      registration.manual_configuration.lti_registration = nil
    end

    it "puts the tool_configuration_id as the registration's manual_configuration_id" do
      expect(registration.manual_configuration).to be_nil
      described_class.run
      expect(registration.reload.manual_configuration)
        .to eq(registration.developer_key.tool_configuration)
    end
  end

  context "when there are developer keys without tool configurations" do
    let!(:developer_key) do
      dk = dev_key_model_1_3
      dk.tool_configuration.delete
      dk.reload
    end

    it "skips developer keys that don't have a tool configuration" do
      described_class.run
      expect(developer_key.lti_registration.manual_configuration).to be_nil
    end
  end

  context "when there are developer keys without lti_registrations" do
    let(:developer_key) do
      dk = dev_key_model_1_3
      dk.lti_registration.destroy!
      dk.reload
    end

    it "skips developer keys that don't have lti_registrations" do
      expect(developer_key).not_to receive(:lti_registration) # this would be called by the data fixup if it ran on this model
      described_class.run
    end
  end
end
