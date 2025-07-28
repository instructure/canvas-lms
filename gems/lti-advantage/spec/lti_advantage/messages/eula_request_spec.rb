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
  RSpec.describe EulaRequest do
    let(:valid_params) do
      {
        eulaservice: LtiAdvantage::Claims::Eulaservice.new(url: "eula_url", scope: ["scope"]),
        aud: "aud",
        azp: "azp",
        deployment_id: "deployment_id",
        exp: "exp",
        iat: "iat",
        iss: "iss",
        nonce: "nonce",
        version: "version",
        context: LtiAdvantage::Claims::Context.new(id: "id"),
        roles: ["role"],
        target_link_uri: "target_link_uri"
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

    it "does not override superclass memoized methods with attr_accessors" do
      subject.instance_variable_set(:@eulaservice, nil)
      expect(subject.eulaservice).to be_a(LtiAdvantage::Claims::Eulaservice)
      subject.instance_variable_set(:@roles, nil)
      expect(subject.roles).to be_a(Array)
    end

    describe "#initialize" do
      it "sets fields correctly" do
        valid_params.each do |key, value|
          expect(subject.send(key)).to eq(value)
        end
        expect(subject.message_type).to eq("LtiEulaRequest")
      end
    end
  end
end
