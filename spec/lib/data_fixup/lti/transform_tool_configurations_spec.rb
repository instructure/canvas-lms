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
require "lti_1_3_tool_configuration_spec_helper"

RSpec.describe DataFixup::Lti::TransformToolConfigurations do
  subject { described_class.run }

  # introduces `settings` (hard-coded JSON LtiConfiguration)
  include_context "lti_1_3_tool_configuration_spec_helper"

  let(:account) { Account.default }
  let(:developer_key) { dev_key_model_1_3(account:) }
  let(:tool_configuration) do
    developer_key.tool_configuration.delete
    # needs to be not transformed yet
    Lti::ToolConfiguration.create!(
      developer_key:,
      settings: settings.merge(public_jwk: tool_config_public_jwk),
      privacy_level: "public"
    )
  end
  let(:second_tool_configuration) do
    tool_configuration.dup.tap do |tc|
      dk = dev_key_model_1_3(account:)
      dk.tool_configuration.delete
      tc.developer_key = dk
      tc.save!
    end
  end

  before do
    tool_configuration
  end

  it "populates new columns with settings data" do
    expect(tool_configuration.target_link_uri).to be_nil
    subject
    expect(tool_configuration.reload.target_link_uri).to eq(settings["target_link_uri"])
  end

  it "removes data from settings" do
    subject
    expect(tool_configuration.reload[:settings]).to be_blank
  end

  context "when transformation errors" do
    let(:scope) { double("scope") }

    before do
      second_tool_configuration

      tool_configuration.settings["target_link_uri"] = "a" * 6000
      tool_configuration.save!

      allow(Sentry).to receive(:with_scope).and_yield(scope)
      allow(Sentry).to receive(:capture_message)
      allow(scope).to receive(:set_tags)
      allow(scope).to receive(:set_context)
    end

    it "captures and reports the error" do
      subject
      expect(Sentry).to have_received(:capture_message).with("DataFixup::Lti#transform_tool_configurations", level: :warning)
      expect(scope).to have_received(:set_tags).with(tool_configuration_id: tool_configuration.global_id)
      expect(scope).to have_received(:set_context).with("exception", { name: "ActiveRecord::ValueTooLong", message: a_string_matching(/too long/) })
      expect(tool_configuration.reload.target_link_uri).to be_nil
    end

    it "still migrates other tool configurations" do
      subject
      expect(second_tool_configuration.reload.target_link_uri).to eq(settings["target_link_uri"])
    end
  end

  context "with invalid data" do
    before do
      tool_configuration.settings["public_jwk"] = []
    end

    it "still populates new columns" do
      subject
      expect(tool_configuration.reload.target_link_uri).to eq(settings["target_link_uri"])
    end

    it "still removes data from settings" do
      subject
      expect(tool_configuration.reload[:settings]).to be_blank
    end
  end
end
