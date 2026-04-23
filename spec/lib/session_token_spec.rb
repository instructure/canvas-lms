# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

describe SessionToken do
  it "is valid after serialization and parsing" do
    token = SessionToken.new(1)
    token_string = token.to_s
    new_token = SessionToken.parse(token_string)
    expect(new_token).to be_valid

    # there was an error with the padding of the base64 encoding for a different sized token
    token = SessionToken.new(1_145_874)
    token_string = token.to_s
    new_token = SessionToken.parse(token_string)
    expect(new_token).to be_valid
  end

  it "preserves pseudonym_id" do
    token = SessionToken.new(1)
    expect(SessionToken.parse(token.to_s).pseudonym_id).to eq token.pseudonym_id
  end

  it "preserves nil current_user_id" do
    token = SessionToken.new(1)
    expect(SessionToken.parse(token.to_s).current_user_id).to be_nil
  end

  it "preserves non-nil current_user_id" do
    token = SessionToken.new(1, current_user_id: 2)
    expect(SessionToken.parse(token.to_s).current_user_id).to eq token.current_user_id
  end

  it "preserves nil used_remember_me_token" do
    token = SessionToken.new(1)
    expect(SessionToken.parse(token.to_s).used_remember_me_token).to be_nil
  end

  it "preserves non-nil used_remember_me_token" do
    token = SessionToken.new(1, used_remember_me_token: true)
    expect(SessionToken.parse(token.to_s).used_remember_me_token).to eq token.used_remember_me_token
  end

  it "preserves non-nil consent_from_mobile" do
    token = SessionToken.new(1, consent_from_mobile: true)
    expect(SessionToken.parse(token.to_s).consent_from_mobile).to eq token.consent_from_mobile
  end

  it "validates tokens generated before consent_from_mobile was added to the signature" do
    token = SessionToken.new(1)
    legacy_signature_string = [
      token.created_at.to_i.to_s,
      token.pseudonym_id.to_s,
      token.current_user_id.to_s,
      token.used_remember_me_token.to_s
    ].join("::")
    token.signature = Canvas::Security.hmac_sha1(legacy_signature_string)
    expect(SessionToken.parse(token.to_s)).to be_valid
  end

  it "is not valid after tampering" do
    token = SessionToken.new(1)
    token.to_s # cache the signature
    token.pseudonym_id = 2
    expect(SessionToken.parse(token.to_s)).not_to be_valid
  end

  it "is not valid with out of bounds created_at" do
    token = SessionToken.new(1)
    token.created_at -= (SessionToken::VALIDITY_PERIOD + 5).seconds
    expect(SessionToken.parse(token.to_s)).not_to be_valid

    token = SessionToken.new(1)
    token.created_at += (SessionToken::VALIDITY_PERIOD + 5).seconds
    expect(SessionToken.parse(token.to_s)).not_to be_valid

    token = SessionToken.new(1)
    token.created_at += 5.seconds
    expect(SessionToken.parse(token.to_s)).to be_valid
  end

  it "does not parse with invalid syntax or contents" do
    # bad base64
    expect(SessionToken.parse("{}")).to be_nil

    # good base64, bad json
    bad_token = Base64.encode64("[[]").tr("+/", "-_").gsub(/=|\n/, "")
    expect(SessionToken.parse(bad_token)).to be_nil

    # good json, wrong data structure
    expect(SessionToken.parse(JSONToken.encode([]))).to be_nil

    # good json, extra field
    token = SessionToken.new(1)
    data = token.as_json.merge(extra: 1)
    expect(SessionToken.parse(JSONToken.encode(data))).to be_nil

    # good json, missing field
    data = token.as_json.slice(:created_at, :pseudonym_id, :current_user_id, :signature)
    expect(SessionToken.parse(JSONToken.encode(data))).to be_nil

    # good json, wrong data types
    data = token.as_json.merge(created_at: "invalid")
    expect(SessionToken.parse(JSONToken.encode(data))).to be_nil

    data = token.as_json.merge(pseudonym_id: "invalid")
    expect(SessionToken.parse(JSONToken.encode(data))).to be_nil

    data = token.as_json.merge(current_user_id: "invalid")
    expect(SessionToken.parse(JSONToken.encode(data))).to be_nil

    data = token.as_json.merge(used_remember_me_token: "invalid")
    expect(SessionToken.parse(JSONToken.encode(data))).to be_nil

    data = token.as_json.merge(consent_from_mobile: "invalid")
    expect(SessionToken.parse(JSONToken.encode(data))).to be_nil

    data = token.as_json.merge(signature: 1)
    expect(SessionToken.parse(JSONToken.encode(data))).to be_nil
  end

  describe ".parse" do
    context "when given malformed input that raises a parse error" do
      it "logs the error before returning nil" do
        bad_token = Base64.encode64("[[]").tr("+/", "-_").gsub(/=|\n/, "")
        expect(Rails.logger).to receive(:error).with(/\[SessionToken\]/)
        expect(SessionToken.parse(bad_token)).to be_nil
      end
    end
  end

  describe ".report_error" do
    context "when the feature flag is disabled" do
      before { allow(Account.site_admin).to receive(:feature_enabled?).with(:log_session_token_failures).and_return(false) }

      it "does not emit a DataDog event" do
        expect(InstStatsd::Statsd).not_to receive(:event)
        SessionToken.report_error(reason: :parsing_error)
      end
    end

    context "when the feature flag is enabled" do
      before { allow(Account.site_admin).to receive(:feature_enabled?).with(:log_session_token_failures).and_return(true) }

      it "emits a parsing_error event with the correct title and message" do
        expect(InstStatsd::Statsd).to receive(:event).with(
          "SessionToken: Parsing Error",
          a_string_starting_with("SessionToken failed to parse session token"),
          hash_including(type: "SessionToken", alert_type: :error)
        )
        SessionToken.report_error(reason: :parsing_error)
      end

      it "emits a token_invalid event with the correct title and message" do
        expect(InstStatsd::Statsd).to receive(:event).with(
          "SessionToken: Invalid Token",
          a_string_starting_with("SessionToken session token failed validation"),
          hash_including(type: "SessionToken", alert_type: :error)
        )
        SessionToken.report_error(reason: :token_invalid)
      end

      it "falls back to reason.to_s for unknown reasons" do
        expect(InstStatsd::Statsd).to receive(:event).with(
          "SessionToken: some_unknown_reason",
          a_string_starting_with("SessionToken some_unknown_reason"),
          hash_including(type: "SessionToken", alert_type: :error)
        )
        SessionToken.report_error(reason: :some_unknown_reason)
      end
    end
  end

  describe "#valid?" do
    context "when the token's created_at is outside the validity window" do
      it "logs an expired token error" do
        token = SessionToken.new(1)
        token.created_at -= (SessionToken::VALIDITY_PERIOD + 5).seconds
        parsed = SessionToken.parse(token.to_s)
        expect(Rails.logger).to receive(:error).with(/Expired token/)
        parsed.valid?
      end
    end

    context "when the token has been tampered with and HMAC verification fails" do
      it "logs an HMAC validation error" do
        token = SessionToken.new(1)
        token.to_s # cache the signature
        token.pseudonym_id = 2
        parsed = SessionToken.parse(token.to_s)
        expect(Rails.logger).to receive(:error).with(/HMAC validation failed/)
        parsed.valid?
      end
    end

    context "when the token is well-formed and within the validity window" do
      it "does not log any errors" do
        token = SessionToken.new(1)
        parsed = SessionToken.parse(token.to_s)
        expect(Rails.logger).not_to receive(:error)
        parsed.valid?
      end
    end
  end
end
