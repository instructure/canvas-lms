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
#
require_relative "../../lti_spec_helper"

describe Csp::Domain do
  include LtiSpecHelper

  describe "::domains_for_tool" do
    describe "when the tool has a domain" do
      let(:tool) do
        tool = external_tool_model(context: account_model)
        tool.update! url: nil, domain: "puppyhoff.me"
        tool
      end

      it "returns that domain and a wildcard for its subdomains" do
        expect(Csp::Domain.domains_for_tool(tool)).to eq [
          "puppyhoff.me", "*.puppyhoff.me"
        ]
      end
    end

    describe "when the tool has a domain property that is actually a URL" do
      let(:tool) do
        tool = external_tool_model(context: account_model)
        tool.update! url: nil, domain: "http://puppyhoff.me"
        tool
      end

      it "extracts a domain from the domain property" do
        expect(Csp::Domain.domains_for_tool(tool)).to eq [
          "puppyhoff.me", "*.puppyhoff.me"
        ]
      end
    end

    describe "when the tool has a url property but no domain" do
      let(:tool) do
        tool = external_tool_model(context: account_model)
        tool.update! url: "http://mac.puppyhoff.me/launch", domain: nil
        tool
      end

      it "extracts a domain from the URL" do
        expect(Csp::Domain.domains_for_tool(tool)).to eq [
          "mac.puppyhoff.me", "*.mac.puppyhoff.me"
        ]
      end
    end

    describe "when the tool has a domain property with beta override" do
      let(:tool) do
        tool = external_tool_model(context: account_model)
        tool.update! domain: "mac.puppyhoff.me", url: nil
        tool
      end

      it "extracts a domain from the environment settings" do
        tool.settings["environments"] = { "beta_domain" => "http://beta.example.com/launch" }
        tool.save!
        allow_beta_overrides(tool)
        expect(Csp::Domain.domains_for_tool(tool)).to eq [
          "beta.example.com", "*.beta.example.com"
        ]
      end

      it "extracts a domain from the environment settings without protocol" do
        tool.settings["environments"] = { "beta_domain" => "beta.example.com" }
        tool.save!
        allow_beta_overrides(tool)
        expect(Csp::Domain.domains_for_tool(tool)).to eq [
          "beta.example.com", "*.beta.example.com"
        ]
      end
    end

    describe "when the tool has an url property with beta override" do
      let(:tool) do
        tool = external_tool_model(context: account_model)
        tool.update! domain: nil, url: "http://mac.puppyhoff.me"
        tool.settings["environments"] = { "beta_launch_url" => "http://beta.example.com/launch" }
        tool.save!
        tool
      end

      it "extracts the URL from environment settings" do
        allow_beta_overrides(tool)
        expect(Csp::Domain.domains_for_tool(tool)).to eq [
          "beta.example.com", "*.beta.example.com"
        ]
      end
    end
  end
end
