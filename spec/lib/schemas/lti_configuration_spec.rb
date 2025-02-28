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

require_relative "../../lti_1_3_tool_configuration_spec_helper"

describe Schemas::LtiConfiguration do
  # introduces `canvas_lti_configuration` (hard-coded JSON LtiConfiguration)
  # and `internal_lti_configuration` (hard-coded JSON InternalLtiConfiguration)
  include_context "lti_1_3_tool_configuration_spec_helper"

  describe "#validate" do
    subject { Schemas::LtiConfiguration.validate(json).to_a }

    let(:json) { nil }
    let(:error_details) { subject.first["details"] }

    context "with minimal valid configuration" do
      let(:json) do
        { title: "Hello World!", description: "hello there", target_link_uri: "url", oidc_initiation_url: "url" }
      end

      it "returns no errors" do
        expect(subject).to be_empty
      end
    end

    context "with minimal invalid configuration" do
      let(:json) do
        { title: "Hello World!", description: "hello there", target_link_uri: "url" }
      end

      it "returns errors" do
        expect(subject).not_to be_empty
      end

      it "includes specific errors" do
        expect(error_details["missing_keys"]).to eq ["oidc_initiation_url"]
      end
    end

    context "with full valid configuration" do
      let(:json) { canvas_lti_configuration }

      it "returns no errors" do
        expect(subject).to be_empty
      end
    end

    context "with submission_type_selection" do
      let(:json) do
        canvas_lti_configuration.tap do |s|
          s["extensions"].first["settings"]["placements"] << {
            placement: "submission_type_selection",
            description:,
            require_resource_selection:
          }.deep_stringify_keys
        end
      end
      let(:description) { "Select a submission type" }
      let(:require_resource_selection) { true }

      context "when parameters are valid" do
        it "returns no errors" do
          expect(subject).to be_empty
        end
      end

      context "when description is invalid" do
        let(:description) { "a" * 256 }

        it "returns errors" do
          expect(subject).not_to be_empty
        end
      end

      context "when require_resource_selection is invalid" do
        let(:require_resource_selection) { "ruh roh" }

        it "returns errors" do
          expect(subject).not_to be_empty
        end
      end
    end
  end

  describe ".from_internal_lti_configuration" do
    subject { Schemas::LtiConfiguration.from_internal_lti_configuration(internal_lti_configuration) }

    it "returns a valid LtiConfiguration" do
      expect(Schemas::LtiConfiguration.validate(subject).to_a).to be_empty
    end

    it "returns a LtiConfiguration with the same values as the InternalLtiConfiguration" do
      expect(subject).to eq(canvas_lti_configuration.deep_symbolize_keys)
    end
  end
end
