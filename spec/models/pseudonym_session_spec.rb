# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe PseudonymSession do
  before do
    fake_controller_cls = Class.new do
      attr_reader :request

      def initialize
        request_cls = Class.new do
          def ip
            "127.0.0.1"
          end
        end
        @request = request_cls.new
      end

      def last_request_update_allowed?
        true
      end

      def params
        {}
      end

      def session
        {}
      end

      def cookies
        {}
      end

      def renew_session_id; end
    end
    Authlogic::Session::Base.controller = fake_controller_cls.new
  end

  after do
    Authlogic::Session::Base.controller = nil
  end

  let(:session) { described_class.new }

  describe "#validate_by_password" do
    before do
      allow(session).to receive(:super)
      allow(session).to receive(:attempted_record).and_return(attempted_record)
    end

    context "when audit_login returns :remaining_attempts_2" do
      let(:attempted_record) { double("AttemptedRecord", audit_login: :remaining_attempts_2) }

      it "adds a warning message to errors" do
        session.validate_by_password
        expect(session.errors.messages[:password]).to include("Please verify your username or password and try again. After 2 more attempt(s), your account will be locked.")
      end
    end

    context "when audit_login returns :remaining_attempts_1" do
      let(:attempted_record) { double("AttemptedRecord", audit_login: :remaining_attempts_1) }

      it "adds a warning message to errors" do
        session.validate_by_password
        expect(session.errors.messages[:password]).to include("Please verify your username or password and try again. After 1 more attempt(s), your account will be locked.")
      end
    end

    context "when audit_login returns :final_attempt" do
      let(:attempted_record) { double("AttemptedRecord", audit_login: :final_attempt) }

      it "adds a lock message to errors" do
        session.validate_by_password
        expect(session.errors.messages[:password]).to include("We've received several incorrect username or password entries. To protect your account, it has been locked. Please contact your system administrator.")
      end
    end

    context "when audit_login returns :too_many_attempts" do
      let(:attempted_record) { double("AttemptedRecord", audit_login: :too_many_attempts) }

      it "adds a max attempts message to errors" do
        session.validate_by_password
        expect(session.errors.messages[:password]).to include("Too many failed login attempts. Please try again later or contact your system administrator.")
      end
    end

    context "when audit_login returns :too_recent_login" do
      let(:attempted_record) { double("AttemptedRecord", audit_login: :too_recent_login) }

      it "adds a rapid attempts message to errors" do
        session.validate_by_password
        expect(session.errors.messages[:password]).to include("You have recently logged in multiple times too quickly. Please wait a few seconds and try again.")
      end
    end

    context "when audit_login returns an unexpected value" do
      let(:attempted_record) { double("AttemptedRecord", audit_login: :unexpected_value) }

      it "adds a generic error message to errors" do
        session.validate_by_password
        expect(session.errors.messages[:password]).to include("Login has been denied for security reasons. Please try again later or contact your system administrator.")
      end
    end
  end

  describe "save_record" do
    it "will not overwrite the last_request_at within the configured window" do
      pseud = pseudonym_model
      expected_timestamp = Time.now.utc
      pseud.last_request_at = 1.hour.ago
      pseud.save!
      pseud.last_request_at = expected_timestamp
      sess = PseudonymSession.new
      sess.record = pseud
      sess.save_record
      expect(pseud.reload.last_request_at).to eq(expected_timestamp)
      pseud.last_request_at = 1.second.from_now.utc
      sess.save_record
      expect(pseud.reload.last_request_at).to eq(expected_timestamp)
    end

    it "will update when other values also change" do
      pseud = pseudonym_model
      pseud.last_request_at = 1.hour.ago
      pseud.save!
      expected_timestamp = Time.now.utc
      pseud.last_request_at = expected_timestamp
      sess = PseudonymSession.new
      sess.record = pseud
      sess.save_record
      expect(pseud.reload.last_request_at).to eq(expected_timestamp)
      pseud.last_request_at = 1.second.from_now.utc
      pseud.unique_id = "some new value"
      sess.save_record
      expect(pseud.reload.last_request_at > expected_timestamp).to be_truthy
    end
  end
end
