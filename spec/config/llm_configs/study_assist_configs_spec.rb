# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe "study_assist LLM configs" do
  %w[study_assist_summarize study_assist_quiz study_assist_flashcards].each do |config_name|
    describe config_name do
      let(:data) { YAML.load_file(Rails.root.join("config/llm_configs/#{config_name}.yml")) }

      it "loads into an LLMConfig without errors" do
        expect do
          LLMConfig.new(
            name: data["name"],
            model_id: data["model_id"],
            rate_limit: data["rate_limit"],
            template: data["template"],
            options: data["options"]
          )
        end.not_to raise_error
      end

      it "declares a daily rate limit" do
        expect(data["rate_limit"]).to include("limit", "period")
        expect(data["rate_limit"]["period"]).to eq("day")
      end
    end
  end
end
