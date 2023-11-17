# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

require_relative "../../spec_helper"
require_relative "../../lti_1_3_spec_helper"

describe Lti::LaunchDebugLogger do
  subject do
    Lti::LaunchDebugLogger.new(
      tool:,
      request:,
      domain_root_account: account,
      pseudonym: pseudo,
      user: pseudo.user,
      cookies: nil,
      session: nil,
      context: course,
      context_enrollment: enrollment
    ).generate_debug_trace
  end

  let(:account) { Account.default }
  let(:tool) { external_tool_1_3_model(context: account) }
  let(:request) { ActionDispatch::Request.new({}) }
  let(:course) { course_model(account:) }
  let(:user) { user_with_pseudonym(account:) }
  let(:pseudo) { user.pseudonyms.first }
  let(:enrollment) { student_in_course(course:, active_enrollment: true, user:) }

  describe "#generate_debug_trace" do
    it "returns nil if not enabled" do
      described_class.disable!(account)
      expect(subject).to be_nil
    end

    context "when enabled" do
      before { described_class.enable!(account, 1) }
      after { described_class.disable!(account) }

      it "returns a URL-safe string" do
        expect(subject).to be_a(String)
        expect(subject).to match(/\A[A-Za-z0-9._-]+\z/)
      end

      it "doesn't crash when given a nil domain_root_account" do
        trace = Lti::LaunchDebugLogger.new(
          domain_root_account: nil,
          request: nil,
          cookies: nil,
          session: nil,
          pseudonym: nil,
          user: nil,
          context: nil,
          context_enrollment: nil,
          tool: nil
        )
        expect(trace.generate_debug_trace).to be_nil
      end

      it "doesn't crash when given other nil values" do
        trace = Lti::LaunchDebugLogger.new(
          domain_root_account: account,
          request: nil,
          cookies: nil,
          session: nil,
          pseudonym: nil,
          user: nil,
          context: nil,
          context_enrollment: nil,
          tool: nil
        )
        decoded = described_class.decode_debug_trace(trace.generate_debug_trace)
        expect(decoded).to be_a(Hash)
        expect(Time.parse(decoded["time"])).to be_within(60).of(Time.now)
      end

      it "can be read without regard to expiration" do
        decoded = described_class.decode_debug_trace(subject)

        Timecop.freeze(1.month.from_now) do
          expect(decoded["tool"]).to eq(tool.global_id)
        end
      end

      it "includes important canvas model-related fields" do
        decoded = described_class.decode_debug_trace(subject)

        expect(decoded["pseudonym"]).to eq(pseudo.global_id)
        expect(decoded["user"]).to eq(pseudo.user.global_id)
        expect(decoded["tool"]).to eq(tool.global_id)
        expect(decoded["dk"]).to eq(tool.developer_key.global_id)
        expect(decoded["domain_root_account"]).to eq(account.global_id)
        expect(decoded["context"]).to eq(course.global_id)
        expect(decoded["context_type"]).to eq("Course")
        expect(decoded["context_enrollment_type"]).to eq("StudentEnrollment")
      end

      context "when enrollment is an AccountUser" do
        let(:enrollment) do
          AccountUser.create!(user: account_admin_user(account:), account:)
        end

        # context_enrollment can apparently be this or an actual enrollment
        it "marks enrollment as simply AccountUser" do
          decoded = described_class.decode_debug_trace(subject)

          expect(decoded["context_enrollment_type"]).to eq("AccountUser")
        end
      end

      it "includes a timestamp" do
        decoded = described_class.decode_debug_trace(subject)

        expect(Time.parse(decoded["time"]).to_i).to be_within(60).of(Time.now.to_i)
      end
    end
  end
end
