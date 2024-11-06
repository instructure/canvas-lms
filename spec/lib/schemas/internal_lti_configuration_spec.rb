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

describe Schemas::InternalLtiConfiguration do
  # introduces `settings` (hard-coded JSON LtiConfiguration)
  # and `internal_configuration` (hard-coded JSON InternalLtiConfiguration)
  include_context "lti_1_3_tool_configuration_spec_helper"

  describe "#validate" do
    subject { Schemas::InternalLtiConfiguration.new.validate(json).to_a }

    let(:json) { internal_configuration }
    let(:error_details) { subject.first["details"] }
    let(:error_message) { subject.first["error"] }

    context "with minimal invalid configuration" do
      let(:json) do
        { title: "Hello World!", description: "hello there", target_link_uri: "url", scopes: [], redirect_uris: ["url"] }
      end

      it "returns errors" do
        expect(subject).not_to be_empty
      end

      it "includes specific errors" do
        expect(error_details["missing_keys"]).to include "oidc_initiation_url"
      end
    end

    context "with full valid configuration" do
      it "returns no errors" do
        expect(subject).to be_empty
      end
    end

    context "public_jwk" do
      let(:jwk) { nil }
      let(:json) do
        internal_configuration.tap do |c|
          c[:public_jwk] = jwk
        end
      end

      context "when not set" do
        before do
          json.delete(:public_jwk)
        end

        it "is valid" do
          expect(subject).to be_empty
        end
      end

      context "when object" do
        let(:jwk) { { kty: "RSA" } }

        it "is valid" do
          expect(subject).to be_empty
        end
      end

      context "when array" do
        let(:jwk) { [] }

        it "is valid" do
          expect(subject).to be_empty
        end
      end
    end

    context "windowTarget" do
      let(:window_target) { nil }
      let(:json) do
        internal_configuration.tap do |c|
          c[:launch_settings][:windowTarget] = window_target
        end
      end

      context "when not set" do
        before do
          json[:launch_settings].delete(:windowTarget)
        end

        it "is valid" do
          expect(subject).to be_empty
        end
      end

      context "when _blank" do
        let(:window_target) { "_blank" }

        it "is valid" do
          expect(subject).to be_empty
        end
      end

      context "when another value" do
        let(:window_target) { "_self" }

        it "is valid" do
          expect(subject).to be_empty
        end
      end

      context "when null" do
        let(:window_target) { nil }

        it "is valid" do
          expect(subject).to be_empty
        end
      end
    end

    context "default" do
      let(:default) { nil }
      let(:json) do
        internal_configuration.tap do |c|
          c[:launch_settings][:default] = default
        end
      end

      context "when not set" do
        before do
          json[:launch_settings].delete(:default)
        end

        it "is valid" do
          expect(subject).to be_empty
        end
      end

      %w[disabled enabled].each do |value|
        context "when #{value}" do
          let(:default) { value }

          it "is valid" do
            expect(subject).to be_empty
          end
        end
      end

      context "when another value" do
        let(:default) { "invalid" }

        it "is valid" do
          expect(subject).to be_empty
        end
      end
    end

    context "visibility" do
      let(:visibility) { nil }
      let(:json) do
        internal_configuration.tap do |c|
          c[:launch_settings][:visibility] = visibility
        end
      end

      context "when not set" do
        before do
          json[:launch_settings].delete(:visibility)
        end

        it "is valid" do
          expect(subject).to be_empty
        end
      end

      %w[admins members public].each do |value|
        context "when #{value}" do
          let(:visibility) { value }

          it "is valid" do
            expect(subject).to be_empty
          end
        end
      end

      context "when another value" do
        let(:visibility) { "invalid" }

        it "is invalid" do
          expect(error_message).to include "visibility"
        end
      end
    end

    context "privacy_level" do
      let(:privacy_level) { nil }
      let(:json) do
        internal_configuration.tap do |c|
          c[:privacy_level] = privacy_level
        end
      end

      context "when not set" do
        before do
          json.delete(:privacy_level)
        end

        it "is valid" do
          expect(subject).to be_empty
        end
      end

      %w[anonymous name_only email_only public].each do |value|
        context "when #{value}" do
          let(:privacy_level) { value }

          it "is valid" do
            expect(subject).to be_empty
          end
        end
      end

      context "when another value" do
        let(:privacy_level) { "invalid" }

        it "is invalid" do
          expect(error_message).to include "privacy_level"
        end
      end
    end

    context "selection_height" do
      let(:selection_height) { nil }
      let(:json) do
        internal_configuration.tap do |c|
          c[:launch_settings][:selection_height] = selection_height
        end
      end

      context "when not set" do
        before do
          json[:launch_settings].delete(:selection_height)
        end

        it "is valid" do
          expect(subject).to be_empty
        end
      end

      context "when number" do
        let(:selection_height) { 100 }

        it "is valid" do
          expect(subject).to be_empty
        end
      end

      context "when string" do
        let(:selection_height) { "100" }

        it "is valid" do
          expect(subject).to be_empty
        end
      end
    end

    context "placements" do
      context "when invalid" do
        let(:json) do
          internal_configuration.tap do |c|
            c[:placements] << { placement: "invalid" }
          end
        end

        it "is invalid" do
          expect(error_message).to include "placements"
        end
      end

      context "enabled" do
        let(:enabled) { nil }
        let(:json) do
          internal_configuration.tap do |c|
            c[:placements] << { placement: "course_navigation", enabled: }
          end
        end

        context "when not set" do
          before do
            json[:placements].last.delete(:enabled)
          end

          it "is valid" do
            expect(subject).to be_empty
          end
        end

        context "when boolean" do
          let(:enabled) { true }

          it "is valid" do
            expect(subject).to be_empty
          end
        end

        context "when string" do
          let(:enabled) { "true" }

          it "is valid" do
            expect(subject).to be_empty
          end
        end
      end
    end

    context "scopes" do
      context "when invalid" do
        let(:json) do
          internal_configuration.tap do |c|
            c[:scopes] << "invalid"
          end
        end

        it "is invalid" do
          expect(error_message).to include "scopes"
        end
      end

      context "when empty" do
        let(:json) do
          internal_configuration.tap do |c|
            c[:scopes] = []
          end
        end

        it "is valid" do
          expect(subject).to be_empty
        end
      end

      context "when not present" do
        let(:json) do
          internal_configuration.tap do |c|
            c.delete(:scopes)
          end
        end

        it "is invalid" do
          expect(error_message).to include "scopes"
        end
      end
    end

    context "root_account_only" do
      context "in launch_settings" do
        let(:json) do
          internal_configuration.tap do |c|
            c[:launch_settings][:root_account_only] = true
          end
        end

        it "returns no errors" do
          expect(subject).to be_empty
        end
      end

      context "in account_navigation" do
        let(:json) do
          super().merge(
            {
              placements: [
                { placement: "account_navigation", root_account_only: true }
              ]
            }
          )
        end

        it "returns no errors" do
          expect(subject).to be_empty
        end
      end

      context "in other placement" do
        let(:json) do
          super().merge(
            {
              placements: [
                { placement: "course_navigation", root_account_only: true }
              ]
            }
          )
        end

        it "returns no errors" do
          expect(subject).to be_empty
        end
      end
    end
  end

  describe ".from_lti_configuration" do
    subject { Schemas::InternalLtiConfiguration.from_lti_configuration(settings) }

    # make tweaks to transformed config to match validations
    let(:internal_lti_config) do
      subject.tap do |config|
        config.delete(:vendor_extensions)
        config[:redirect_uris] = [config[:target_link_uri]]
      end
    end

    it "returns a valid InternalLtiConfiguration" do
      expect(Schemas::InternalLtiConfiguration.new.validate(internal_lti_config).to_a).to be_empty
    end

    it "returns an InternalLtiConfiguration with the same values as the LtiConfiguration" do
      expect(internal_lti_config).to eq(internal_configuration)
    end

    context "with no scopes" do
      let(:settings) do
        super().except("scopes", :scopes)
      end

      it "defaults scopes to empty array" do
        expect(subject[:scopes]).to eq([])
      end
    end

    context "with no canvas extension" do
      before do
        settings[:extensions] = []
      end

      it "does not error" do
        expect { subject }.not_to raise_error
      end
    end
  end
end
