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
    let(:tool) { external_tool_1_3_model(context: account, opts: { url: "https://account.quiz-lti-dub-prod.instructure.com/lti/launch" }) }
    let(:request) { double("request", host: "canvas.instructure.com", host_with_port: "canvas.instructure.com", params: {}) }
    let(:controller) do
      double("controller",
             request:,
             lti_grade_passback_api_url: "https://canvas.instructure.com/api/lti/v1/tools/grade_passback",
             blti_legacy_grade_passback_api_url: "https://canvas.instructure.com/api/lti/v1/tools/legacy_grade_passback",
             lti_turnitin_outcomes_placement_url: "https://canvas.instructure.com/api/lti/v1/turnitin/outcomes_placement",
             named_context_url: "https://canvas.instructure.com/courses/#{course.id}/external_content/success/external_tool_redirect")
    end
    let(:variable_expander) { Lti::VariableExpander.new(account, course, controller, current_user: user, tool:) }
    let(:tag) do
      assignment.external_tool_tag || assignment.create_external_tool_tag(
        url: tool&.url || "https://example.com/lti",
        content: tool
      )
    end

    subject(:builder) do
      described_class.new(
        context: course,
        assignment:,
        tool:,
        tag:,
        current_user: user,
        controller:,
        request:,
        variable_expander:
      )
    end

    # Helper to create canonical string matching the builder's implementation
    def canonical_string_for_params(params)
      normalized_params = params.map do |k, v|
        value = case v
                when Float
                  (v == v.to_i) ? v.to_i.to_s : v.to_s
                when Array, Hash
                  v.to_json
                else
                  v.to_s
                end
        [k.to_s, value]
      end
      URI.encode_www_form(normalized_params.sort_by { |k, _v| k })
    end

    describe "#build" do
      it "includes backend_url extracted from tool launch_url" do
        result = builder.build
        expect(result[:backend_url]).to eq("https://account.quiz-lti-dub-prod.instructure.com")
      end

      context "when tool has domain instead of URL" do
        let(:tool) { external_tool_1_3_model(context: account, opts: { url: nil, domain: "account.quiz-lti-dub-beta.instructure.com" }) }

        it "extracts backend_url from domain" do
          result = builder.build
          expect(result[:backend_url]).to eq("https://account.quiz-lti-dub-beta.instructure.com")
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

        it "raises an error when building" do
          expect { builder.build }.to raise_error("Tool is required for resource_link_id")
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

      context "locale parameter" do
        it "includes locale in the build output" do
          result = builder.build
          expect(result["launch_presentation_locale"]).to be_present
        end

        it "returns current I18n locale" do
          I18n.with_locale(:es) do
            result = builder.build
            expect(result["launch_presentation_locale"]).to eq(:es)
          end
        end

        it "returns default locale when I18n.locale is nil" do
          allow(I18n).to receive(:locale).and_return(nil)
          result = builder.build
          expect(result["launch_presentation_locale"]).to eq(I18n.default_locale)
        end
      end

      context "roles parameter" do
        it "includes roles in the build output" do
          course.enroll_teacher(user, enrollment_state: "active")
          result = builder.build
          expect(result[:roles]).to eq("Instructor")
        end

        it "returns Learner for StudentEnrollment" do
          course.enroll_student(user, enrollment_state: "active")
          result = builder.build
          expect(result[:roles]).to eq("Learner")
        end

        it "returns TA role for TaEnrollment" do
          course.enroll_ta(user, enrollment_state: "active")
          result = builder.build
          expect(result[:roles]).to include("TeachingAssistant")
        end

        it "returns comma-separated roles for multiple enrollments" do
          course.enroll_teacher(user, enrollment_state: "active")
          course.enroll_student(user, enrollment_state: "active")
          result = builder.build
          expect(result[:roles]).to include("Instructor")
          expect(result[:roles]).to include("Learner")
          expect(result[:roles]).to include(",")
        end

        it "ignores inactive enrollments" do
          course.enroll_teacher(user, enrollment_state: "deleted")
          result = builder.build
          expect(result[:roles]).to eq("urn:lti:sysrole:ims/lis/None")
        end

        it "returns NONE when user has no roles" do
          result = builder.build
          expect(result[:roles]).to eq("urn:lti:sysrole:ims/lis/None")
        end

        context "with account admin" do
          it "includes Administrator role for account admin" do
            account_admin_user_with_role_changes(user:, account:, role: admin_role)
            result = builder.build
            expect(result[:roles]).to eq("urn:lti:instrole:ims/lis/Administrator")
          end

          it "includes both course role and account admin role" do
            course.enroll_teacher(user, enrollment_state: "active")
            account_admin_user_with_role_changes(user:, account:, role: admin_role)
            result = builder.build
            roles = result[:roles].split(",")
            expect(roles).to include("Instructor")
            expect(roles).to include("urn:lti:instrole:ims/lis/Administrator")
          end

          it "deduplicates account admin role if user is admin in multiple accounts in chain" do
            sub_account = account.sub_accounts.create!
            course.update!(account: sub_account)
            account_admin_user_with_role_changes(user:, account:, role: admin_role)
            account_admin_user_with_role_changes(user:, account: sub_account, role: admin_role)
            result = builder.build
            # Should only have one Administrator role despite being admin in 2 accounts
            expect(result[:roles].scan("Administrator").count).to eq(1)
          end
        end

        context "with site admin" do
          before do
            # Create site admin role for user
            Account.site_admin.account_users.create!(user:)
          end

          it "includes SysAdmin role for site admin" do
            result = builder.build
            expect(result[:roles]).to eq("urn:lti:sysrole:ims/lis/SysAdmin")
          end

          it "includes both course role and site admin role" do
            course.enroll_teacher(user, enrollment_state: "active")
            result = builder.build
            roles = result[:roles].split(",")
            expect(roles).to include("Instructor")
            expect(roles).to include("urn:lti:sysrole:ims/lis/SysAdmin")
          end

          it "includes site admin, account admin, and course roles" do
            course.enroll_teacher(user, enrollment_state: "active")
            account_admin_user_with_role_changes(user:, account:, role: admin_role)
            result = builder.build
            roles = result[:roles].split(",")
            expect(roles).to include("Instructor")
            expect(roles).to include("urn:lti:instrole:ims/lis/Administrator")
            expect(roles).to include("urn:lti:sysrole:ims/lis/SysAdmin")
          end
        end

        context "with role deduplication" do
          it "deduplicates multiple enrollments of same type" do
            # Create two sections and enroll in both
            section1 = course.course_sections.create!(name: "Section 1")
            section2 = course.course_sections.create!(name: "Section 2")
            course.enroll_teacher(user, enrollment_state: "active", section: section1)
            course.enroll_teacher(user, enrollment_state: "active", section: section2)
            result = builder.build
            # Should only have one Instructor role despite 2 teacher enrollments
            expect(result[:roles]).to eq("Instructor")
          end
        end
      end

      context "ext_roles parameter" do
        it "includes ext_roles in the build output" do
          course.enroll_teacher(user, enrollment_state: "active")
          result = builder.build
          expect(result[:ext_roles]).to be_present
          expect(result[:ext_roles]).to include("urn:lti:role:ims/lis/Instructor")
        end

        it "includes institution roles from all_roles" do
          account_admin_user_with_role_changes(user:, account:, role: admin_role)
          result = builder.build
          expect(result[:ext_roles]).to include("urn:lti:instrole:ims/lis/Administrator")
        end

        it "includes site admin role in ext_roles" do
          Account.site_admin.account_users.create!(user:)
          result = builder.build
          expect(result[:ext_roles]).to include("urn:lti:sysrole:ims/lis/SysAdmin")
        end

        it "returns deduplicated and sorted roles" do
          course.enroll_teacher(user, enrollment_state: "active")
          account_admin_user_with_role_changes(user:, account:, role: admin_role)
          Account.site_admin.account_users.create!(user:)
          result = builder.build
          ext_roles = result[:ext_roles].split(",")
          # Check that roles are unique
          expect(ext_roles.uniq).to eq(ext_roles)
          # Check that roles are sorted
          expect(ext_roles).to eq(ext_roles.sort)
        end

        it "returns User role when user has no enrollments" do
          result = builder.build
          # Users with no enrollments still get the "User" system role from all_roles
          expect(result[:ext_roles]).to eq("urn:lti:sysrole:ims/lis/User")
        end
      end
    end

    describe "#build_with_signature" do
      let(:tool) do
        external_tool_1_3_model(
          context: account,
          opts: {
            url: "https://account.quiz-lti-dub-prod.instructure.com/lti/launch",
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
          backend_url: "https://account.quiz-lti-dub-prod.instructure.com"
        )
        expect(params["launch_presentation_locale"]).to eq(I18n.locale)
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
        canonical_string = canonical_string_for_params(params)

        # Verify the signature
        expected_signature = OpenSSL::HMAC.digest("sha256", tool.shared_secret, canonical_string)
        expect(signature).to eq(expected_signature)
      end

      it "produces different signatures for different params" do
        result1 = builder.build_with_signature
        params1 = result1[:params]

        # Modify params to simulate different data
        params1_modified = params1.dup
        params1_modified[:backend_url] = "https://different.example.com"

        # Generate a new signature for the modified params
        canonical_string = canonical_string_for_params(params1_modified)
        modified_signature = OpenSSL::HMAC.digest("sha256", tool.shared_secret, canonical_string)
        modified_signature_base64 = Base64.strict_encode64(modified_signature)

        # The signature should be different for different params
        expect(modified_signature_base64).not_to eq(result1[:signature])
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
            opts: { url: "https://account.quiz-lti-dub-prod.instructure.com/lti/launch" }
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

        it "raises an error about missing tool" do
          expect { builder.build_with_signature }.to raise_error("Tool is required for resource_link_id")
        end
      end

      describe "signature verification (cross-check)" do
        it "can be verified using ActiveSupport::SecurityUtils.secure_compare" do
          result = builder.build_with_signature
          params = result[:params]
          provided_signature = Base64.strict_decode64(result[:signature])

          # Simulate verification (what Quiz LTI will do)
          canonical_string = canonical_string_for_params(params)
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
          canonical_string = canonical_string_for_params(params)
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
          canonical_string = canonical_string_for_params(params)
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
          canonical_string = canonical_string_for_params(params)
          expected_signature = OpenSSL::HMAC.digest("sha256", tool.shared_secret, canonical_string)

          is_valid = ActiveSupport::SecurityUtils.secure_compare(provided_signature, expected_signature)
          expect(is_valid).to be true
        end
      end
    end
  end
end
