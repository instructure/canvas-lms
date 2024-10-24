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
require "lti_1_3_spec_helper"

RSpec.describe DataFixup::Lti::FixToolConfigurationPrivacyLevel do
  subject { described_class.run }

  include_context "lti_1_3_spec_helper"

  let(:account) { Account.default }

  before do
    tool_configuration.untransform!
    tool_configuration.settings["extensions"][0]["privacy_level"] = extension_privacy_level
    tool_configuration.save!
    tool_configuration.update_column("privacy_level", root_privacy_level)
  end

  context "tool_configuration with inconsistent privacy_level values" do
    context "when settings->extensions->canvas_platform->privacy_level present" do
      let(:extension_privacy_level) { "email_only" }

      context "when root privacy_level is nil" do
        let(:root_privacy_level) { nil }

        it "updates the privacy_level with the value of extension_privacy_level" do
          expect { subject }.to change { tool_configuration.reload["privacy_level"] }.from(nil).to("email_only")
        end
      end

      context "when root privacy_level is present and different" do
        let(:root_privacy_level) { "public" }

        it "updates the privacy_level with the value of extension_privacy_level" do
          expect { subject }.to change { tool_configuration.reload["privacy_level"] }.from(root_privacy_level).to(extension_privacy_level)
        end
      end

      context "when root privacy_level is present and same" do
        let(:root_privacy_level) { "email_only" }

        it "does not modify the tool_configuration model" do
          expect { subject }.not_to change { tool_configuration.configuration }
        end
      end
    end

    context "when settings->extensions->canvas_platform->privacy_level is not presen" do
      before do
        setting = tool_configuration.settings
        setting["extensions"].first.delete("privacy_level")
        tool_configuration.update_column("settings", setting)
      end

      let(:root_privacy_level) { "anonymous" }

      it "does not modify the tool_configuration model" do
        expect { subject }.not_to change { tool_configuration.configuration }
      end
    end
  end
end
