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

require_relative "../../api_spec_helper"

describe Api::V1::Lti::Registration do
  let(:tester) { Class.new { include Api::V1::Lti::Registration }.new }

  describe "#lti_registrations_json" do
    subject { tester.lti_registrations_json(registrations, user, session, context) }

    let(:registrations) { [lti_registration_model, lti_registration_model] }
    let(:user) { user_model }
    let(:session) { {} }
    let(:context) { account_model }

    it "includes the canvas id for each" do
      expect(subject.pluck(:id)).to include(*registrations.map(&:id))
    end
  end

  describe "#lti_registration_json" do
    subject { tester.lti_registration_json(registration, user, session, context, includes:) }

    let(:registration) { lti_registration_model(admin_nickname: "Test", vendor: "Test Company", account: context) }
    let(:user) { user_model }
    let(:session) { {} }
    let(:context) { account_model }
    let(:includes) { [] }

    it "includes all expected base attributes" do
      expect(subject).to include({
                                   id: registration.id,
                                   internal_service: false,
                                   account_id: registration.account_id,
                                   name: registration.name,
                                   admin_nickname: registration.admin_nickname,
                                   vendor: registration.vendor,
                                   workflow_state: registration.workflow_state,
                                   created_at: registration.created_at,
                                   updated_at: registration.updated_at,
                                   root_account_id: registration.root_account_id,
                                   lti_version: registration.lti_version
                                 })
    end

    it "includes a basic user object for created_by" do
      expect(subject[:created_by]).to include({
                                                id: registration.created_by.id,
                                              })
    end

    it "includes a basic user object for updated_by" do
      expect(subject[:updated_by]).to include({
                                                id: registration.updated_by.id,
                                              })
    end

    it "includes nil icon_url by default" do
      expect(subject).to have_key(:icon_url)
      expect(subject[:icon_url]).to be_nil
    end

    it "does not include account binding by default" do
      expect(subject).not_to include(:account_binding)
    end

    it "does not include configuration by default" do
      expect(subject).not_to include(:configuration)
    end

    it "does not include dynamic_registration by default" do
      expect(subject).not_to include(:dynamic_registration)
    end

    context "with an account binding" do
      let(:includes) { [:account_binding] }
      let(:account_binding) { lti_registration_account_binding_model(registration:, account: context) }

      before do
        account_binding # instantiate before test runs
      end

      it "includes the account binding" do
        expect(subject[:account_binding]).to include({
                                                       id: account_binding.id,
                                                     })
      end

      it "includes inherited as false" do
        expect(subject[:inherited]).to be(false)
      end

      context "when registration is from different account" do
        before do
          registration.account = account_model
          registration.save!
        end

        it "includes inherited as true" do
          expect(subject[:inherited]).to be(true)
        end
      end
    end

    context "without an account binding" do
      let(:includes) { [:account_binding] }

      it "does not include the account binding" do
        expect(subject).not_to include(:account_binding)
      end
    end

    context "of dynamic registration type" do
      let(:includes) { [:configuration] }
      let(:ims_registration) { lti_ims_registration_model(lti_registration: registration) }
      let(:icon_url) { "https://example.com/icon.png" }

      before do
        ims_registration.logo_uri = icon_url
        ims_registration.save!
      end

      it "includes the icon_url from configuration" do
        expect(subject[:icon_url]).to eq(icon_url)
      end

      it "includes the tool configuration" do
        expect(subject["configuration"]).to eq(ims_registration.registration_configuration)
      end

      it "includes dynamic_registration as true" do
        expect(subject[:dynamic_registration]).to be(true)
      end
    end
  end
end
