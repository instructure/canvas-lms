# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe DataFixup::Lti::SetRegistrationInactiveForOffBindings do
  describe "#run" do
    subject { described_class.new.run }

    let(:account) { account_model }

    it "sets an active registration to inactive when its binding is off" do
      registration = lti_registration_with_tool(account:)
      registration.lti_registration_account_bindings.first.update!(workflow_state: "off")

      expect { subject }
        .to change { registration.reload.workflow_state }
        .from("active").to("inactive")
    end

    it "does not update a registration that is already inactive" do
      # registration_params workflow_state: "inactive" also sets the binding to "off"
      # via CreateRegistrationService's resolve_workflow_state logic.
      registration = lti_registration_with_tool(
        account:,
        registration_params: { workflow_state: "inactive" }
      )

      subject

      expect(registration.reload.workflow_state).to eq("inactive")
    end

    it "does not update an active registration whose binding is on" do
      # lti_registration_with_tool creates a default LRAB with workflow_state = on.
      registration = lti_registration_with_tool(account:)

      subject

      expect(registration.reload.workflow_state).to eq("active")
    end

    it "does not update an active registration with no bindings" do
      registration = lti_registration_model(account:)

      subject

      expect(registration.reload.workflow_state).to eq("active")
    end

    context "with audit logging" do
      include_context "data fixup auditing"

      it "logs the IDs of updated registrations" do
        reg1 = lti_registration_with_tool(account:)
        reg1.lti_registration_account_bindings.first.update!(workflow_state: "off")
        reg2 = lti_registration_with_tool(account:)
        reg2.lti_registration_account_bindings.first.update!(workflow_state: "off")
        # Active registration with an "on" binding — should not be updated or logged
        unaffected = lti_registration_with_tool(account:)

        subject

        log = data_fixup_audit_logs(Shard.current.id)
        expect(log).to include("#{reg1.id}\n")
        expect(log).to include("#{reg2.id}\n")
        expect(log).not_to include(unaffected.id.to_s)
      end
    end

    context "when update_all raises an error" do
      let(:scope) { instance_double(Sentry::Scope) }
      let(:error) { ActiveRecord::StatementInvalid.new("PG::Error") }
      let!(:registration) do
        reg = lti_registration_with_tool(account:)
        reg.lti_registration_account_bindings.first.update!(workflow_state: "off")
        reg
      end

      before do
        allow(Lti::Registration).to receive(:where).and_wrap_original do |original, *args|
          relation = original.call(*args)
          allow(relation).to receive(:update_all).and_raise(error)
          relation
        end
      end

      it "sends an error to Sentry with the batch's first and last IDs" do
        expect(Sentry).to receive(:with_scope).and_yield(scope)
        expect(Sentry).to receive(:capture_message)
          .with("DataFixup::Lti::SetRegistrationInactiveForOffBindings#process_batch", { level: :warning })
        expect(scope).to receive(:set_tags).with(first_id: registration.id, last_id: registration.id)
        expect(scope).to receive(:set_context)
          .with("exception", { name: "ActiveRecord::StatementInvalid", message: "PG::Error" })
        subject
      end
    end

    it "does not update a deleted registration with an off binding" do
      # registration = lti_registration_model(account:, workflow_state: "deleted")
      registration = lti_registration_model(account:, workflow_state: "deleted")
      registration.update(workflow_state: "deleted")
      lti_registration_account_binding_model(registration:, workflow_state: "off")

      subject

      expect(registration.reload.workflow_state).to eq("deleted")
    end

    it "works on multiple registrations at once" do
      expected_results = {
        active: [],
        inactive: [],
        deleted: [],
      }

      3.times do
        # Three registrations that are inactive with an "off" binding; these
        # should remain inactive.
        reg = lti_registration_with_tool(
          account:,
          registration_params: { workflow_state: "inactive" }
        )
        expected_results[:inactive] << reg.id

        # Three registrations that are active with an "off" account binding.
        # These should be made inactive by the data fixup.
        reg = lti_registration_with_tool(account:)
        reg.lti_registration_account_bindings.first.update!(workflow_state: "off")
        expected_results[:inactive] << reg.id

        # Three registrations that are active and their LRAB is on. These should
        # remain active.
        reg = lti_registration_with_tool(account:)
        expected_results[:active] << reg.id

        # Three registrations that are deleted with an off LRAB; these should
        # not be touched.
        reg = lti_registration_with_tool(account:)
        reg.lti_registration_account_bindings.first.update!(workflow_state: "off")
        reg.update(workflow_state: "deleted")
        expected_results[:deleted] << reg.id

        # Three registrations that are deleted with an on LRAB; these should
        # not be touched.
        reg = lti_registration_with_tool(account:)
        reg.update(workflow_state: "deleted")
        expected_results[:deleted] << reg.id

        # Three active registrations with no account bindings; these should be unaffected
        reg = lti_registration_model(account:)
        expected_results[:active] << reg.id

        # Three inactive registrations with no account bindings; these should be unaffected
        reg = lti_registration_model(account:, workflow_state: :inactive)
        expected_results[:inactive] << reg.id
      end

      subject

      expected_results.each_pair do |workflow_state, ids|
        expect(Lti::Registration.where(id: ids).pluck(:workflow_state)).to all(eq(workflow_state.to_s))
      end
    end
  end
end
