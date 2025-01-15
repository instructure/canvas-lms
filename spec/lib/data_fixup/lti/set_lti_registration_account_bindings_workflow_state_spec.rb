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

RSpec.describe DataFixup::Lti::SetLtiRegistrationAccountBindingsWorkflowState do
  let(:account) { account_model }

  let(:dkab) do
    dev_key = dev_key_model_1_3(account:)
    dev_key.developer_key_account_bindings.first
  end

  let(:lrab) { dkab.lti_registration_account_binding }

  context "when the LRAB and DKAB have a different workflow_state" do
    before do
      dkab.update_column(:workflow_state, "on")
      lrab.update_column(:workflow_state, "off")
    end

    it "changes the workflow_state of the lti_registration_account_binding" do
      DataFixup::Lti::SetLtiRegistrationAccountBindingsWorkflowState.run
      expect(lrab.reload.workflow_state).to eq("on")
    end

    context "and one of them fails" do
      let(:lrab_to_fail) do
        lrab = Lti::RegistrationAccountBinding.third

        allow_any_instance_of(Lti::RegistrationAccountBinding)
          .to receive(:update_column).and_wrap_original do |m, *args|
            if m.receiver == lrab_to_fail
              raise ArgumentError
            else
              m.call(*args)
            end
          end

        lrab
      end

      before do
        5.times do
          dev_key = dev_key_model_1_3(account:)
          dkab = dev_key.developer_key_account_bindings.first
          dkab.update_column(:workflow_state, "off")
          dkab.lti_registration_account_binding.update_column(:workflow_state, "on")
        end
      end

      it "still finishes the other records" do
        DataFixup::Lti::SetLtiRegistrationAccountBindingsWorkflowState.run

        # All LRABs should match their DKAB's workflow_state, except the one that
        # was supposed to fail. So, the list below should be empty.
        lrabs_with_on_workflow_state = Lti::RegistrationAccountBinding.all.select do |lrab|
          lrab != lrab_to_fail && lrab.workflow_state != lrab.developer_key_account_binding.workflow_state
        end

        expect(lrabs_with_on_workflow_state).to eq([])
      end

      it "logs the error to Sentry" do
        fake_scope = double(Sentry::Scope)
        expect(fake_scope).to receive(:set_tags).with(developer_key_account_binding_id: lrab_to_fail.developer_key_account_binding.global_id)
        expect(fake_scope).to receive(:set_context).with("exception", { name: "ArgumentError", message: "ArgumentError" })
        expect(Sentry).to receive(:with_scope).and_yield(fake_scope)

        expect { DataFixup::Lti::SetLtiRegistrationAccountBindingsWorkflowState.run }
          .not_to raise_error
      end
    end
  end
end
