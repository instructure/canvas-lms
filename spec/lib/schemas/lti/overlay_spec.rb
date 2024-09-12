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

describe Schemas::Lti::Overlay do
  describe "#validate" do
    subject { Schemas::Lti::Overlay.validation_errors(json) }

    context "with minimal invalid configuration" do
      let(:json) do
        {
          title: 1234
        }
      end

      it "returns errors" do
        expect(subject).not_to be_empty
      end
    end

    context "with full valid configuration" do
      let(:json) do
        {
          title: "Hello World!",
          description: "hello there",
          custom_fields: { hello: "world" },
          target_link_uri: "url",
          oidc_initiation_url: "url",
          domain: "domain",
          privacy_level: "public",
          redirect_uris: ["url"],
          public_jwk: { hello: "world" },
          public_jwk_url: "url",
          disabled_scopes: [TokenScopes::LTI_AGS_LINE_ITEM_SCOPE],
          disabled_placements: ["course_navigation"],
          placements: {
            course_navigation: {
              text: "Course Navigation",
              target_link_uri: "url",
              message_type: "LtiDeepLinkingRequest",
              launch_height: 500,
              launch_width: 500
            }
          }
        }
      end

      it "returns no errors" do
        expect(subject).to be_empty
      end
    end

    context "with invalid privacy_level" do
      let(:json) do
        { privacy_level: "invalid" }
      end

      it "returns errors" do
        expect(subject).to include(/privacy_level.*is not one of/)
      end
    end

    context "with invalid disabled_scopes" do
      let(:json) do
        { disabled_scopes: ["invalid"] }
      end

      it "returns errors" do
        expect(subject).to include(/disabled_scopes.*is not one of/)
      end
    end

    context "with invalid disabled_placements" do
      let(:json) do
        { disabled_placements: ["invalid"] }
      end

      it "returns errors" do
        expect(subject).to include(/disabled_placements.*is not one of/)
      end
    end

    context "with invalid placement" do
      let(:json) do
        { placements: { invalid: { text: "Hello World!" } } }
      end

      it "returns errors" do
        expect(subject).to include(/placements.invalid.*disallowed/)
      end
    end

    context "with invalid placement message_type" do
      let(:json) do
        { placements: { course_navigation: { message_type: "invalid" } } }
      end

      it "returns errors" do
        expect(subject).to include(/placements.course_navigation.message_type.*is not one of/)
      end
    end
  end
end
