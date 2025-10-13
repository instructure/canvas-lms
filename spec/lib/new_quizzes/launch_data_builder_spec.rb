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

module NewQuizzes
  describe LaunchDataBuilder do
    let_once(:account) { Account.default }
    let_once(:course) { course_factory(account:) }
    let_once(:assignment) { assignment_model(course:) }
    let_once(:user) { user_model }
    let(:tool) { external_tool_1_3_model(context: account, opts: { url: "https://tenant.quiz-lti-iad-prod.instructure.com/lti/launch" }) }
    let(:request) { double("request", host: "canvas.instructure.com", host_with_port: "canvas.instructure.com", params: {}) }

    subject(:builder) do
      described_class.new(
        context: course,
        assignment:,
        tool:,
        current_user: user,
        request:
      )
    end

    describe "#build" do
      it "includes backend_url extracted from tool URL" do
        result = builder.build
        expect(result[:backend_url]).to eq("https://tenant.quiz-lti-iad-prod.instructure.com")
      end

      context "when tool has domain instead of URL" do
        let(:tool) { external_tool_1_3_model(context: account, opts: { url: nil, domain: "tenant.quiz-lti-iad-prod.instructure.com" }) }

        it "extracts backend_url from domain" do
          result = builder.build
          expect(result[:backend_url]).to eq("https://tenant.quiz-lti-iad-prod.instructure.com")
        end
      end

      context "when tool URL has non-standard port" do
        let(:tool) { external_tool_1_3_model(context: account, opts: { url: "http://localhost:3000/lti/launch" }) }

        it "includes the port in backend_url" do
          result = builder.build
          expect(result[:backend_url]).to eq("http://localhost:3000")
        end
      end

      context "when tool has no URL or domain" do
        let(:tool) { nil }

        it "returns nil for backend_url" do
          result = builder.build
          expect(result[:backend_url]).to be_nil
        end
      end

      context "when tool URL is invalid" do
        let(:tool) { external_tool_1_3_model(context: account, opts: { url: "not a valid url" }) }

        it "returns nil for backend_url and logs error" do
          expect(Rails.logger).to receive(:error).with(/Failed to parse tool URL/)
          result = builder.build
          expect(result[:backend_url]).to be_nil
        end
      end
    end

    describe "#build_with_signature" do
      let(:tool) do
        external_tool_1_3_model(
          context: account,
          opts: {
            url: "https://tenant.quiz-lti-iad-prod.instructure.com/lti/launch",
            shared_secret: "test-secret-key-123"
          }
        )
      end

      it "returns a hash with params and signature keys" do
        result = builder.build_with_signature
        expect(result).to have_key(:params)
        expect(result).to have_key(:signature)
      end

      it "includes all launch data in params" do
        result = builder.build_with_signature
        params = result[:params]

        expect(params).to include(
          custom_canvas_assignment_id: assignment.id,
          custom_canvas_course_id: course.id,
          custom_canvas_user_id: user.id,
          backend_url: "https://tenant.quiz-lti-iad-prod.instructure.com"
        )
      end

      it "generates a base64-encoded signature" do
        result = builder.build_with_signature
        signature = result[:signature]

        expect(signature).to be_a(String)
        expect { Base64.strict_decode64(signature) }.not_to raise_error
      end

      it "generates a valid HMAC-SHA256 signature" do
        result = builder.build_with_signature
        params = result[:params]
        signature = Base64.strict_decode64(result[:signature])

        # Recreate the canonical string the same way the builder does
        # Uses URL-encoded query-string format
        canonical_string = URI.encode_www_form(params.sort)

        # Verify the signature
        expected_signature = OpenSSL::HMAC.digest("sha256", tool.shared_secret, canonical_string)
        expect(signature).to eq(expected_signature)
      end

      it "produces different signatures for different params" do
        result1 = builder.build_with_signature

        # Modify the assignment to change params
        assignment.update!(title: "Modified Title")

        result2 = builder.build_with_signature

        expect(result1[:signature]).not_to eq(result2[:signature])
      end

      it "produces the same signature for the same params" do
        result1 = builder.build_with_signature
        result2 = builder.build_with_signature

        expect(result1[:signature]).to eq(result2[:signature])
      end

      context "when tool has no shared_secret" do
        let(:tool) do
          external_tool_1_3_model(
            context: account,
            opts: { url: "https://tenant.quiz-lti-iad-prod.instructure.com/lti/launch" }
          )
        end

        before do
          allow(tool).to receive(:shared_secret).and_return(nil)
        end

        it "raises an error" do
          expect { builder.build_with_signature }.to raise_error("Missing shared secret for tool")
        end

        it "logs an error message" do
          expect(Rails.logger).to receive(:error).with(/Cannot sign params: no shared secret available/)
          expect { builder.build_with_signature }.to raise_error(RuntimeError, "Missing shared secret for tool")
        end
      end

      context "when tool is nil" do
        let(:tool) { nil }

        it "raises an error" do
          expect { builder.build_with_signature }.to raise_error("Missing shared secret for tool")
        end
      end

      describe "signature verification (cross-check)" do
        it "can be verified using ActiveSupport::SecurityUtils.secure_compare" do
          result = builder.build_with_signature
          params = result[:params]
          provided_signature = Base64.strict_decode64(result[:signature])

          # Simulate verification (what Quiz LTI will do)
          # Uses URL-encoded query-string format
          canonical_string = URI.encode_www_form(params.sort)
          expected_signature = OpenSSL::HMAC.digest("sha256", tool.shared_secret, canonical_string)

          # Use secure_compare to prevent timing attacks
          is_valid = ActiveSupport::SecurityUtils.secure_compare(provided_signature, expected_signature)
          expect(is_valid).to be true
        end

        it "fails verification with tampered params" do
          result = builder.build_with_signature
          params = result[:params]
          provided_signature = Base64.strict_decode64(result[:signature])

          # Tamper with the params
          params[:custom_canvas_assignment_id] = 999_999

          # Try to verify with tampered params
          # Uses URL-encoded query-string format
          canonical_string = URI.encode_www_form(params.sort)
          expected_signature = OpenSSL::HMAC.digest("sha256", tool.shared_secret, canonical_string)

          is_valid = ActiveSupport::SecurityUtils.secure_compare(provided_signature, expected_signature)
          expect(is_valid).to be false
        end

        it "fails verification with wrong shared_secret" do
          result = builder.build_with_signature
          params = result[:params]
          provided_signature = Base64.strict_decode64(result[:signature])

          # Use wrong secret
          wrong_secret = "wrong-secret-key"
          # Uses URL-encoded query-string format
          canonical_string = URI.encode_www_form(params.sort)
          expected_signature = OpenSSL::HMAC.digest("sha256", wrong_secret, canonical_string)

          is_valid = ActiveSupport::SecurityUtils.secure_compare(provided_signature, expected_signature)
          expect(is_valid).to be false
        end

        it "correctly signs params with special characters requiring URL encoding" do
          # Update user with email containing special chars
          user.update!(email: "test+user@example.com", name: "John Doe Smith")

          result = builder.build_with_signature
          params = result[:params]
          provided_signature = Base64.strict_decode64(result[:signature])

          # Verify signature with URL encoding (what Quiz LTI will do)
          canonical_string = URI.encode_www_form(params.sort)
          expected_signature = OpenSSL::HMAC.digest("sha256", tool.shared_secret, canonical_string)

          is_valid = ActiveSupport::SecurityUtils.secure_compare(provided_signature, expected_signature)
          expect(is_valid).to be true
        end
      end
    end
  end
end
