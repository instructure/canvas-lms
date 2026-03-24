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
      allow(ENV).to receive(:fetch).with("CANVAS_ENVIRONMENT").and_return("production")
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

        it "constructs URL with region" do
          expect(NewQuizzes.launch_url).to eq("https://example.cloudfront.net/us-west-2/remoteEntry.js")
        end

        it "returns nil cloudfront host when config is blank" do
          NewQuizzes.instance_variable_set(:@config, nil)
          allow(DynamicSettings).to receive(:find)
            .with(tree: :private)
            .and_return(DynamicSettings::FallbackProxy.new({
                                                             "new_quizzes.yml" => {}.to_yaml
                                                           }))
          expect(NewQuizzes.launch_url).to eq("/us-west-2/remoteEntry.js")
        end

        it "defaults to us-east-1 and warns when region is nil" do
          allow(ApplicationController).to receive(:region).and_return(nil)
          expect(Rails.logger).to receive(:warn).with(/ApplicationController.region is not set/)
          expect(NewQuizzes.launch_url).to eq("https://example.cloudfront.net/us-east-1/remoteEntry.js")
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

    describe ".importing_timeout_in_minutes" do
      context "when config has a valid integer value" do
        before do
          allow(DynamicSettings).to receive(:find)
            .with(tree: :private)
            .and_return(DynamicSettings::FallbackProxy.new({
                                                             "new_quizzes.yml" => {
                                                               NewQuizzes::NEW_QUIZZES_IMPORTING_TIMEOUT_IN_MINUTES_KEY => "120"
                                                             }.to_yaml
                                                           }))
        end

        it "returns the configured value as minutes" do
          expect(NewQuizzes.importing_timeout_in_minutes).to eq(120.minutes)
        end
      end

      context "when config value is nil (key not set)" do
        it "logs an error, captures to Sentry, and returns 30 minutes" do
          expect(Rails.logger).to receive(:error).twice
          expect(Sentry).to receive(:capture_exception)
          expect(NewQuizzes.importing_timeout_in_minutes).to eq(30.minutes)
        end
      end

      context "when config value is not a valid integer string" do
        before do
          allow(DynamicSettings).to receive(:find)
            .with(tree: :private)
            .and_return(DynamicSettings::FallbackProxy.new({
                                                             "new_quizzes.yml" => {
                                                               NewQuizzes::NEW_QUIZZES_IMPORTING_TIMEOUT_IN_MINUTES_KEY => "not_a_number"
                                                             }.to_yaml
                                                           }))
        end

        it "logs an error, captures to Sentry, and returns 30 minutes" do
          expect(Rails.logger).to receive(:error).twice
          expect(Sentry).to receive(:capture_exception)
          expect(NewQuizzes.importing_timeout_in_minutes).to eq(30.minutes)
        end
      end
    end

    describe ".ui_version" do
      it "returns region" do
        expect(NewQuizzes.ui_version).to eq("us-west-2")
      end

      it "returns none in development" do
        allow(Rails.env).to receive(:development?).and_return(true)
        expect(NewQuizzes.ui_version).to eq("none")
      end
    end
  end
end
