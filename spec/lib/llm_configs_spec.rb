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

describe LLMConfigs do
  before { LLMConfigs.instance_variable_set(:@configs, nil) }

  describe ".configs" do
    before do
      allow(Dir).to receive(:[]).and_return(["config/llm_configs/test.yml"])
      allow(YAML).to receive(:load_file).with("config/llm_configs/test.yml").and_return({
                                                                                          "name" => "test",
                                                                                          "model_id" => "model123",
                                                                                          "rate_limit" => { "limit" => 10, "period" => "day" },
                                                                                          "template" => "template123",
                                                                                          "options" => { "option1" => "value1" }
                                                                                        })
    end

    it "loads configuration from YAML files" do
      expect(LLMConfigs.configs["test"].name).to eq("test")
      expect(LLMConfigs.configs["test"].model_id).to eq("model123")
      expect(LLMConfigs.configs["test"].rate_limit).to eq({ limit: 10, period: "day" })
      expect(LLMConfigs.configs["test"].template).to eq("template123")
      expect(LLMConfigs.configs["test"].options).to eq({ "option1" => "value1" })
    end

    context "when there is an ArgumentError" do
      before do
        expect(YAML).to receive(:load_file).with("config/llm_configs/test.yml").and_return({
                                                                                             "model_id" => "model123",
                                                                                             "template" => "template123",
                                                                                             "options" => { "option1" => "value1" }
                                                                                           })
      end

      it "raises an error with a descriptive message" do
        expect { LLMConfigs.configs }.to raise_error(ArgumentError, /Error in LLM config test: Name must be a string/)
      end
    end
  end

  describe ".config_for" do
    before do
      expect(LLMConfigs).to receive(:configs).and_return({
                                                           "test" => LLMConfig.new(
                                                             name: "test",
                                                             model_id: "model123",
                                                             rate_limit: { limit: 10, period: "day" },
                                                             template: "template123",
                                                             options: { "option1" => "value1" }
                                                           )
                                                         })
    end

    it "returns the correct LlmConfig object for a given prompt type" do
      config = LLMConfigs.config_for(:test)
      expect(config.name).to eq("test")
      expect(config.model_id).to eq("model123")
      expect(config.rate_limit).to eq({ limit: 10, period: "day" })
      expect(config.template).to eq("template123")
      expect(config.options).to eq({ "option1" => "value1" })
    end

    it "returns nil if the config does not exist" do
      expect(LLMConfigs.config_for(:nonexistent)).to be_nil
    end
  end
end
