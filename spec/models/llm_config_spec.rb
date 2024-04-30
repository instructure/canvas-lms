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

describe LlmConfig do
  describe "#initialize" do
    context "with valid attributes" do
      it "initializes successfully" do
        config = LlmConfig.new(name: "TestConfig", model_id: "model123")
        expect(config.name).to eq("TestConfig")
        expect(config.model_id).to eq("model123")
        expect(config.template).to be_nil
        expect(config.options).to eq({})
      end
    end

    context "with invalid attributes" do
      it "raises an error if name is not a string" do
        expect { LlmConfig.new(name: nil, model_id: "model123") }.to raise_error(ArgumentError, "Name must be a string")
      end

      it "raises an error if model_id is not a string" do
        expect { LlmConfig.new(name: "TestConfig", model_id: nil) }.to raise_error(ArgumentError, "Model ID must be a string")
      end

      it "raises an error if template is neither string nor nil" do
        expect { LlmConfig.new(name: "TestConfig", model_id: "model123", template: 123) }.to raise_error(ArgumentError, "Template must be a string or nil")
      end

      it "raises an error if options is not a hash" do
        expect { LlmConfig.new(name: "TestConfig", model_id: "model123", options: "invalid") }.to raise_error(ArgumentError, "Options must be a hash")
      end
    end
  end

  describe "#generate_prompt" do
    let(:config) { LlmConfig.new(name: "TestConfig", model_id: "model123", template: "Hello <PLACEHOLDER>") }

    context "when template is not nil" do
      it "replaces the placeholder with dynamic content" do
        expect(config.generate_prompt(dynamic_content: "World")).to eq("Hello World")
      end
    end

    context "when template is nil" do
      let(:config) { LlmConfig.new(name: "TestConfig", model_id: "model123") }

      it "returns the dynamic content" do
        expect(config.generate_prompt(dynamic_content: "Hello")).to eq("Hello")
      end
    end
  end
end
