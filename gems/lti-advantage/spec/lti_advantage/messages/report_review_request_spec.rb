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

require "lti_advantage"

require_relative "message_claims_examples"

module LtiAdvantage::Messages
  RSpec.describe ReportReviewRequest do
    let(:valid_params) do
      {
        activity: LtiAdvantage::Claims::Activity.new(id: "id"),
        for_user: LtiAdvantage::Claims::ForUser.new(user_id: "user_id"),
        submission: LtiAdvantage::Claims::Submission.new(id: "id"),
        asset: LtiAdvantage::Claims::Asset.new(id: "id"),
        assetreport_type: "type",
        aud: "aud",
        azp: "azp",
        deployment_id: "deployment_id",
        exp: "exp",
        iat: "iat",
        iss: "iss",
        nonce: "nonce",
        version: "1.3.0",
        target_link_uri: "target_link_uri"
      }
    end

    subject { described_class.new(valid_params) }

    describe "validations" do
      it "is valid with valid params" do
        puts subject.valid?
        puts subject.errors.full_messages
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

    it "does not override superclass memoized methods with attr_accessors" do
      subject.instance_variable_set(:@activity, nil)
      expect(subject.activity).to be_a(LtiAdvantage::Claims::Activity)
    end

    describe "#initialize" do
      it "sets fields correctly" do
        expect(subject.version).to eq("1.3.0")
        expect(subject.activity.id).to eq("id")
        expect(subject.for_user.user_id).to eq("user_id")
        expect(subject.submission.id).to eq("id")
        expect(subject.asset.id).to eq("id")
        expect(subject.assetreport_type).to eq("type")
        expect(subject.aud).to eq("aud")
        expect(subject.azp).to eq("azp")
        expect(subject.deployment_id).to eq("deployment_id")
        expect(subject.exp).to eq("exp")
        expect(subject.iat).to eq("iat")
        expect(subject.iss).to eq("iss")
        expect(subject.nonce).to eq("nonce")
      end
    end
  end
end
