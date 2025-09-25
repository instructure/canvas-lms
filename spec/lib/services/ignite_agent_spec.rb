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

require_relative "../../spec_helper"

module Services
  describe IgniteAgent do
    before do
      # Reset the cached config before each test
      IgniteAgent.instance_variable_set(:@config, nil)

      allow(DynamicSettings).to receive(:find).with(any_args).and_call_original
      allow(DynamicSettings).to receive(:find)
        .with(tree: :private)
        .and_return(DynamicSettings::FallbackProxy.new({
                                                         "ignite_agent.yml" => {
                                                           "launch_url" => "https://test.instructure.com/agent/remoteEntry.js",
                                                           "backend_url" => "https://api.test.instructure.com/agent"
                                                         }.to_yaml
                                                       }))
    end

    describe ".launch_url" do
      it "returns the launch URL from the dynamic settings" do
        expect(IgniteAgent.launch_url).to eq("https://test.instructure.com/agent/remoteEntry.js")
      end

      it "caches the config" do
        # Call once to cache
        IgniteAgent.launch_url

        # Verify the second call uses the cached value
        expect(DynamicSettings).not_to receive(:find)
        IgniteAgent.launch_url
      end
    end

    describe ".backend_url" do
      it "returns the backend URL from the dynamic settings" do
        expect(IgniteAgent.backend_url).to eq("https://api.test.instructure.com/agent")
      end
    end

    context "when dynamic settings are not available" do
      before do
        # Reset the cached config for this context
        IgniteAgent.instance_variable_set(:@config, nil)

        allow(DynamicSettings).to receive(:find)
          .with(tree: :private)
          .and_return(DynamicSettings::FallbackProxy.new({
                                                           "ignite_agent.yml" => nil
                                                         }))
      end

      it "returns nil for launch_url" do
        expect(IgniteAgent.launch_url).to be_nil
      end

      it "returns nil for backend_url" do
        expect(IgniteAgent.backend_url).to be_nil
      end
    end
  end
end
