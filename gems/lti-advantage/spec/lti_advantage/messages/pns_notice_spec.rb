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

require "lti_advantage"

require_relative "message_claims_examples"

module LtiAdvantage::Messages
  RSpec.describe PnsNotice do
    let(:valid_params) do
      {
        notice: LtiAdvantage::Models::PnsNoticeClaim.new(id: "id", timestamp: "timestamp", type: "type"),
        aud: "aud",
        azp: "azp",
        deployment_id: "deployment_id",
        exp: "exp",
        iat: "iat",
        iss: "iss",
        nonce: "nonce",
        version: "version"
      }
    end

    subject { described_class.new(valid_params) }

    describe "validations" do
      it "is valid with valid params" do
        expect(subject).to be_valid
      end

      it "is invalid without required claims" do
        required_claims = described_class::REQUIRED_CLAIMS
        required_claims.each do |claim|
          subject.send(:"#{claim}=", nil)
          expect(subject).not_to be_valid
          subject.send(:"#{claim}=", valid_params[claim])
        end
      end
    end

    describe "#initialize" do
      it "sets fields correctly" do
        expect(subject.version).to eq("version")
        expect(subject.notice.timestamp).to eq("timestamp")
        expect(subject.aud).to eq("aud")
        expect(subject.azp).to eq("azp")
        expect(subject.deployment_id).to eq("deployment_id")
        expect(subject.exp).to eq("exp")
        expect(subject.iat).to eq("iat")
        expect(subject.iss).to eq("iss")
        expect(subject.nonce).to eq("nonce")
        expect(subject.notice.type).to eq("type")
        expect(subject.notice.id).to eq("id")
        expect(subject.notice.timestamp).to eq("timestamp")
      end
    end
  end
end
