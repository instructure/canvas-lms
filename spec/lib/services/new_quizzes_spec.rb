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
                                                           "launch_url" => "https://test.instructure.com/quizzes"
                                                         }.to_yaml
                                                       }))
    end

    describe ".launch_url" do
      it "returns the launch URL from the dynamic settings" do
        expect(NewQuizzes.launch_url).to eq("https://test.instructure.com/quizzes")
      end

      it "caches the config" do
        # Call once to cache
        NewQuizzes.launch_url

        # Verify the second call uses the cached value
        expect(DynamicSettings).not_to receive(:find)
        NewQuizzes.launch_url
      end
    end

    context "when dynamic settings are not available" do
      before do
        # Reset the cached config for this context
        NewQuizzes.instance_variable_set(:@config, nil)

        allow(DynamicSettings).to receive(:find)
          .with(tree: :private)
          .and_return(DynamicSettings::FallbackProxy.new({
                                                           "new_quizzes.yml" => nil
                                                         }))
      end

      it "returns nil for launch_url" do
        expect(NewQuizzes.launch_url).to be_nil
      end
    end

    describe ".ui_version" do
      context "when launch URL contains a version" do
        it "extracts the version from the URL" do
          allow(NewQuizzes).to receive(:launch_url).and_return("https://example.com/abc123/remoteEntry.js")
          expect(NewQuizzes.ui_version).to eq("abc123")
        end

        it "handles URLs with multiple path segments" do
          allow(NewQuizzes).to receive(:launch_url).and_return("https://example.com/path/to/abc123/remoteEntry.js")
          expect(NewQuizzes.ui_version).to eq("abc123")
        end

        it "returns 'none' for local development placeholder" do
          allow(NewQuizzes).to receive(:launch_url).and_return("http://example.com:8082/none/remoteEntry.js")
          expect(NewQuizzes.ui_version).to eq("none")
        end
      end

      context "when launch URL is missing" do
        it "returns nil when launch_url is nil" do
          allow(NewQuizzes).to receive(:launch_url).and_return(nil)
          expect(NewQuizzes.ui_version).to be_nil
        end

        it "returns nil when launch_url is empty string" do
          allow(NewQuizzes).to receive(:launch_url).and_return("")
          expect(NewQuizzes.ui_version).to be_nil
        end
      end

      context "when launch URL has unexpected format" do
        it "returns nil and logs error for URL without remoteEntry.js" do
          allow(NewQuizzes).to receive(:launch_url).and_return("https://example.com/abc123/index.js")
          expect(Rails.logger).to receive(:error).with(/Failed to parse New Quizzes launch URL/)
          expect(NewQuizzes.ui_version).to be_nil
        end

        it "returns nil and logs error for URL with only remoteEntry.js" do
          allow(NewQuizzes).to receive(:launch_url).and_return("https://example.com/remoteEntry.js")
          expect(Rails.logger).to receive(:error).with(/Failed to parse New Quizzes launch URL/)
          expect(NewQuizzes.ui_version).to be_nil
        end

        it "returns nil and logs error for invalid URL" do
          allow(NewQuizzes).to receive(:launch_url).and_return("not a valid url")
          expect(Rails.logger).to receive(:error).with(/Failed to parse New Quizzes launch URL/)
          expect(NewQuizzes.ui_version).to be_nil
        end
      end
    end
  end
end
