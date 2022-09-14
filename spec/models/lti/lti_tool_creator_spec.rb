# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

describe(Lti::LtiToolCreator) do
  let(:settings) { { url: "/some/url" }.with_indifferent_access }
  let(:context_external_tool) do
    ContextExternalTool.new.tap do |tool|
      tool.name = "tool"
      tool.consumer_key = "12345"
      tool.shared_secret = "secret"
      tool.settings = settings
    end
  end

  it "converts a ContextExternalTool to an LTITool" do
    lti_tool = Lti::LtiToolCreator.new(context_external_tool).convert
    expect(lti_tool.name).to eq "tool"
    expect(lti_tool.consumer_key).to eq "12345"
    expect(lti_tool.shared_secret).to eq "secret"
    expect(lti_tool.settings).to eq(settings)
  end

  describe "privacy level" do
    it "defaults to anonymous" do
      lti_tool = Lti::LtiToolCreator.new(context_external_tool).convert
      expect(lti_tool.privacy_level).to eq LtiOutbound::LTITool::PRIVACY_LEVEL_ANONYMOUS
    end

    it "maps public privacy" do
      context_external_tool.privacy_level = "public"
      lti_tool = Lti::LtiToolCreator.new(context_external_tool).convert
      expect(lti_tool.privacy_level).to eq LtiOutbound::LTITool::PRIVACY_LEVEL_PUBLIC
    end

    it "maps name only privacy" do
      context_external_tool.privacy_level = "name_only"
      lti_tool = Lti::LtiToolCreator.new(context_external_tool).convert
      expect(lti_tool.privacy_level).to eq LtiOutbound::LTITool::PRIVACY_LEVEL_NAME_ONLY
    end

    it "maps email only privacy" do
      context_external_tool.privacy_level = "email_only"
      lti_tool = Lti::LtiToolCreator.new(context_external_tool).convert
      expect(lti_tool.privacy_level).to eq LtiOutbound::LTITool::PRIVACY_LEVEL_EMAIL_ONLY
    end

    it "maps anynomous privacy" do
      context_external_tool.privacy_level = "anonymous"
      lti_tool = Lti::LtiToolCreator.new(context_external_tool).convert
      expect(lti_tool.privacy_level).to eq LtiOutbound::LTITool::PRIVACY_LEVEL_ANONYMOUS
    end
  end
end
