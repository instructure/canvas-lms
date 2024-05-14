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

describe Api::V1::Lti::RegistrationAccountBinding do
  let(:tester) { Class.new { include Api::V1::Lti::RegistrationAccountBinding }.new }

  describe "#registration_account_binding_json" do
    subject { tester.lti_registration_account_binding_json(account_binding, user, session, context) }

    let(:account_binding) { lti_registration_account_binding_model }
    let(:user) { user_model }
    let(:session) { {} }
    let(:context) { account_model }

    it "includes all expected base attributes" do
      expect(subject).to include({
                                   id: account_binding.id,
                                   account_id: account_binding.account_id,
                                   registration_id: account_binding.registration_id,
                                   workflow_state: account_binding.workflow_state,
                                   created_at: account_binding.created_at,
                                   updated_at: account_binding.updated_at,
                                   root_account_id: account_binding.root_account_id,
                                 })
    end

    it "includes a basic user object for created_by" do
      expect(subject[:created_by]).to include({
                                                id: account_binding.created_by.id,
                                              })
    end

    it "includes a basic user object for updated_by" do
      expect(subject[:updated_by]).to include({
                                                id: account_binding.updated_by.id,
                                              })
    end
  end
end
