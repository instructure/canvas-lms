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
  describe NewQuizzes do
    before do
      # Reset the cached config before each test
      NewQuizzes.instance_variable_set(:@config, nil)

      allow(DynamicSettings).to receive(:find).with(any_args).and_call_original
      allow(DynamicSettings).to receive(:find)
        .with(tree: :private)
        .and_return(DynamicSettings::FallbackProxy.new({
                                                         "new_quizzes.yml" => {
                                                           NewQuizzes::NEW_QUIZZES_CLOUDFRONT_HOST_PRODUCTION_KEY => "https://example.cloudfront.net"
                                                         }.to_yaml
                                                       }))
      allow(ApplicationController).to receive(:region).and_return("us-west-2")
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("CANVAS_ENVIRONMENT").and_return("prod")
    end

    describe ".launch_url" do
      context "in development environment" do
        it "returns edge_cloudfront_host/none/remoteEntry.js" do
          allow(Rails.env).to receive(:development?).and_return(true)
          allow(DynamicSettings).to receive(:find)
            .with(tree: :private)
            .and_return(DynamicSettings::FallbackProxy.new({
                                                             "new_quizzes.yml" => {
                                                               NewQuizzes::NEW_QUIZZES_CLOUDFRONT_HOST_EDGE_KEY => "https://edge.cloudfront.net"
                                                             }.to_yaml
                                                           }))
          expect(NewQuizzes.launch_url).to eq("https://edge.cloudfront.net/none/remoteEntry.js")
        end
      end

      context "in non-development environment" do
        before do
          allow(Rails.env).to receive(:development?).and_return(false)
        end

        it "constructs URL with region and environment" do
          expect(NewQuizzes.launch_url).to eq("https://example.cloudfront.net/us-west-2/prod/remoteEntry.js")
        end

        it "returns nil cloudfront host when config is blank" do
          NewQuizzes.instance_variable_set(:@config, nil)
          allow(DynamicSettings).to receive(:find)
            .with(tree: :private)
            .and_return(DynamicSettings::FallbackProxy.new({
                                                             "new_quizzes.yml" => {}.to_yaml
                                                           }))
          expect(NewQuizzes.launch_url).to eq("/us-west-2/prod/remoteEntry.js")
        end

        it "defaults to edge and warns when CANVAS_ENVIRONMENT is not set" do
          allow(ENV).to receive(:fetch).with("CANVAS_ENVIRONMENT").and_yield
          expect(Rails.logger).to receive(:warn).with(/CANVAS_ENVIRONMENT is not set/).at_least(:once)
          expect(NewQuizzes.launch_url).to eq("https://example.cloudfront.net/us-west-2/edge/remoteEntry.js")
        end

        it "defaults to us-east-1 and warns when region is nil" do
          allow(ApplicationController).to receive(:region).and_return(nil)
          expect(Rails.logger).to receive(:warn).with(/ApplicationController.region is not set/)
          expect(NewQuizzes.launch_url).to eq("https://example.cloudfront.net/us-east-1/prod/remoteEntry.js")
        end

        it "maps cd environment to edge" do
          allow(ENV).to receive(:fetch).with("CANVAS_ENVIRONMENT").and_return("cd")
          expect(NewQuizzes.launch_url).to eq("https://example.cloudfront.net/us-west-2/edge/remoteEntry.js")
        end

        it "uses custom CANVAS_ENVIRONMENT value" do
          allow(ENV).to receive(:fetch).with("CANVAS_ENVIRONMENT").and_return("beta")
          expect(NewQuizzes.launch_url).to eq("https://example.cloudfront.net/us-west-2/beta/remoteEntry.js")
        end
      end

      it "caches the config" do
        allow(Rails.env).to receive(:development?).and_return(false)
        # Call once to cache
        NewQuizzes.launch_url

        # Verify the second call uses the cached value
        expect(DynamicSettings).not_to receive(:find)
        NewQuizzes.launch_url
      end
    end

    describe ".ui_version" do
      it "returns region/environment" do
        expect(NewQuizzes.ui_version).to eq("us-west-2/prod")
      end

      it "returns none in development" do
        allow(Rails.env).to receive(:development?).and_return(true)
        expect(NewQuizzes.ui_version).to eq("none")
      end
    end
  end
end
