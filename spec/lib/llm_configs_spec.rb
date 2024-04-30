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

describe LlmConfigs do
  before { LlmConfigs.instance_variable_set(:@configs, nil) }

  describe ".configs" do
    before do
      allow(Dir).to receive(:[]).and_return(["config/llm_configs/test.yml"])
      allow(YAML).to receive(:load_file).with("config/llm_configs/test.yml").and_return({
                                                                                          "name" => "test",
                                                                                          "model_id" => "model123",
                                                                                          "template" => "template123",
                                                                                          "options" => { "option1" => "value1" }
                                                                                        })
    end

    it "loads configuration from YAML files" do
      expect(LlmConfigs.configs["test"].name).to eq("test")
      expect(LlmConfigs.configs["test"].model_id).to eq("model123")
      expect(LlmConfigs.configs["test"].template).to eq("template123")
      expect(LlmConfigs.configs["test"].options).to eq({ "option1" => "value1" })
    end

    context "when there is an ArgumentError" do
      before do
        allow(YAML).to receive(:load_file).with("config/llm_configs/test.yml").and_return({
                                                                                            "model_id" => "model123",
                                                                                            "template" => "template123",
                                                                                            "options" => { "option1" => "value1" }
                                                                                          })
      end

      it "raises an error with a descriptive message" do
        expect { LlmConfigs.configs }.to raise_error(ArgumentError, /Error in LLM config test: Name must be a string/)
      end
    end
  end

  describe ".config_for" do
    before do
      allow(LlmConfigs).to receive(:configs).and_return({
                                                          "test" => LlmConfig.new(
                                                            name: "test",
                                                            model_id: "model123",
                                                            template: "template123",
                                                            options: { "option1" => "value1" }
                                                          )
                                                        })
    end

    it "returns the correct LlmConfig object for a given prompt type" do
      config = LlmConfigs.config_for(:test)
      expect(config.name).to eq("test")
      expect(config.model_id).to eq("model123")
      expect(config.template).to eq("template123")
      expect(config.options).to eq({ "option1" => "value1" })
    end

    it "returns nil if the config does not exist" do
      expect(LlmConfigs.config_for(:nonexistent)).to be_nil
    end
  end
end
