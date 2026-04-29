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
#

describe JsonUtilsHelper do
  describe "safe_parse_json_array" do
    context "when response is a valid JSON array" do
      it "returns the parsed array" do
        json = [
          { "rubric_category" => "Content", "criterion" => "Meets requirements", "reasoning" => "Clear" }
        ].to_json

        result = JsonUtilsHelper.safe_parse_json_array(json)
        expect(result).to be_a(Array)
        expect(result.first["rubric_category"]).to eq("Content")
      end
    end

    context "when response is blank" do
      it "returns an empty array" do
        expect(JsonUtilsHelper.safe_parse_json_array("")).to eq([])
        expect(JsonUtilsHelper.safe_parse_json_array(nil)).to eq([])
      end
    end

    context "when response is not valid JSON" do
      it "raises CedarAi::Errors::GraderError if JSON can't be parsed and no array fragment can be repaired" do
        expect do
          JsonUtilsHelper.safe_parse_json_array("not-json")
        end.to raise_error(CedarAi::Errors::GraderError, /Invalid JSON response/)
      end
    end

    context "when response is not an array" do
      it "returns empty array if parsed JSON is not an array" do
        json = { foo: "bar" }.to_json
        expect(JsonUtilsHelper.safe_parse_json_array(json)).to eq([])
      end
    end

    context "when response contains extra text around a valid array" do
      it "extracts and parses the array" do
        response = "Here is the response: [{\"rubric_category\": \"Content\", \"criterion\": \"Meets requirements\", \"reasoning\": \"Clear\"}]"
        result = JsonUtilsHelper.safe_parse_json_array(response)
        expect(result).to be_a(Array)
        expect(result.first["rubric_category"]).to eq("Content")
      end
    end

    context "when extracted portion is not a JSON array" do
      it "raises CedarAi::Errors::GraderError if the extracted JSON is not an array" do
        bad_response = <<~TEXT
          Some output:
          {"rubric_category": "Content", "criterion": "Meets requirements"}
        TEXT

        expect do
          JsonUtilsHelper.safe_parse_json_array(bad_response)
        end.to raise_error(CedarAi::Errors::GraderError, /Invalid JSON response/)
      end
    end

    context "when response contains unescaped inner quotes within a value" do
      it "repairs inner quotes and returns parsed array" do
        broken = <<~JSON
          [
            {
              "rubric_category": "Research",
              "reasoning": "The essay mentions the "dog breath sniffer" reference from Business Insider.",
              "criterion": "Excellent"
            }
          ]
        JSON

        result = JsonUtilsHelper.safe_parse_json_array(broken)
        expect(result).to be_a(Array)
        expect(result.first["rubric_category"]).to eq("Research")
        expect(result.first["reasoning"]).to include("dog breath sniffer")
      end
    end
  end

  describe "escape_inner_quotes" do
    it "escapes unescaped inner quotes but leaves already escaped quotes alone" do
      raw = %q({"k":"This has an "inner" quote and an escaped \"quote\" already."})
      fixed = JsonUtilsHelper.escape_inner_quotes(raw)
      expect(fixed).to include('\"inner\"')
      expect(fixed).to include('\"quote\"')
      expect(fixed).not_to include('\\\\\"quote\"')
    end

    it "does not modify keys" do
      raw = %q({"key_with_\"quote\"": "value with "inner" quote"})
      fixed = JsonUtilsHelper.escape_inner_quotes(raw)
      expect(fixed).to include('"key_with_\"quote\""').or include('"key_with_\\\"quote\\\""')
    end
  end
end
