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

describe LLMConfig do
  describe "#initialize" do
    context "with valid attributes" do
      it "initializes successfully" do
        config = LLMConfig.new(name: "TestConfig", model_id: "model123", template: "template")
        expect(config.name).to eq("TestConfig")
        expect(config.model_id).to eq("model123")
        expect(config.template).to eq("template")
        expect(config.options).to eq({})
      end
    end

    context "with invalid attributes" do
      it "raises an error if name is not a string" do
        expect { LLMConfig.new(name: nil, model_id: "model123", template: "template") }.to raise_error(ArgumentError, "Name must be a string")
      end

      it "raises an error if model_id is not a string" do
        expect { LLMConfig.new(name: "TestConfig", model_id: nil, template: "template") }.to raise_error(ArgumentError, "Model ID must be a string")
      end

      it "raises an error if template is neither string nor nil" do
        expect { LLMConfig.new(name: "TestConfig", model_id: "model123", template: 123) }.to raise_error(ArgumentError, "Template must be a string")
      end

      it "raises an error if options is not a hash" do
        expect { LLMConfig.new(name: "TestConfig", model_id: "model123", template: "template", options: "invalid") }.to raise_error(ArgumentError, "Options must be a hash")
      end
    end
  end

  describe "#generate_prompt_and_options" do
    let(:config) { LLMConfig.new(name: "TestConfig", model_id: "model123", template: "Hello <TEMPLATE_PLACEHOLDER>", options: { max_tokens: 100, system: "Hello <OPTIONS_PLACEHOLDER>" }) }

    it "replaces the placeholders with content in both prompt and options" do
      prompt, options = config.generate_prompt_and_options(substitutions: { TEMPLATE: "Template", OPTIONS: "Options" })
      expect(prompt).to eq("Hello Template")
      expect(options).to eq({ max_tokens: 100, system: "Hello Options" })
    end

    it "raises an error if prompt still contains placeholders" do
      expect { config.generate_prompt_and_options(substitutions: {}) }.to raise_error(ArgumentError, "Template still contains placeholder: <TEMPLATE_PLACEHOLDER>")
    end

    it "raises an error if options still contain placeholders" do
      expect { config.generate_prompt_and_options(substitutions: { TEMPLATE: "Template" }) }.to raise_error(ArgumentError, "Options still contain placeholder: <OPTIONS_PLACEHOLDER>")
    end

    it "returns the prompt and options when no placeholders are present" do
      config = LLMConfig.new(name: "TestConfig", model_id: "model123", template: "Hello", options: { max_tokens: 100, system: "Hello" })
      prompt, options = config.generate_prompt_and_options(substitutions: {})
      expect(prompt).to eq("Hello")
      expect(options).to eq({ max_tokens: 100, system: "Hello" })
    end
  end
end
