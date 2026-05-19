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

# Integration tests covering the interaction between the two LTI registration
# backfill fixups:
#   - DataFixup::Lti::BackfillInheritedRegistrations  (opt-in / explicit bindings)
#   - DataFixup::Lti::BackfillForcedOnRegistrations   (forced-on / no per-account binding)
RSpec.describe "LTI registration backfill integration" do
  specs_require_sharding

  subject { execute_fixup }

  let(:operation_shard) { @shard1 }
  let(:sa_shard) { Account.site_admin.shard }

  around do |example|
    operation_shard.activate do
      example.run
    end
  end

  let_once(:user) { operation_shard.activate { user_model } }
  let_once(:root_account) { operation_shard.activate { account_model } }
  let_once(:sa_binding) do
    sa_shard.activate do
      Lti::AccountBindingService.call(
        registration: template,
        account: Account.site_admin,
        user:,
        workflow_state: :allow
      )[:lti_registration_account_binding]
    end
  end
  let_once(:template) do
    sa_shard.activate do
      lti_registration_with_tool(
        account: Account.site_admin,
        created_by: user
      )
    end
  end

  before do
    allow_any_instance_of(DataFixup::Lti::BackfillForcedOnRegistrations).to receive(:wait_between_jobs)
    allow_any_instance_of(DataFixup::Lti::BackfillInheritedRegistrations).to receive(:wait_between_jobs)
    allow_any_instance_of(DataFixup::Lti::BackfillForcedOnRegistrations).to receive(:wait_between_processing)
    allow_any_instance_of(DataFixup::Lti::BackfillInheritedRegistrations).to receive(:wait_between_processing)
  end

  def execute_fixup
    operation_shard.activate do
      DataFixup::Lti::BackfillInheritedRegistrations.new.run
      DataFixup::Lti::BackfillForcedOnRegistrations.new.run
    end
    run_jobs
  end

  # Scenario:
  #   1. Site admin creates a registration and sets its binding to "allow"
  #      (opt-in: root accounts can choose to enable it).
  #   2. A root account opts in by creating its own binding with state "on".
  #   3. BackfillInheritedRegistrations runs and creates one local copy.
  #   4. Site admin later promotes the binding to "on" (forced-on for all).
  #   5. BackfillForcedOnRegistrations runs.
  #   6. The root account must still have exactly ONE local copy — not two.
  context "when a root account opted in before the site admin set the binding to 'on'" do
    it "results in exactly one local copy after both fixups run" do
      expect(sa_binding.workflow_state).to eq("allow")

      Lti::AccountBindingService.call(
        registration: template,
        account: root_account,
        user:,
        workflow_state: :on
      )

      sa_shard.activate do
        Lti::AccountBindingService.call(
          registration: template,
          account: Account.site_admin,
          user:,
          workflow_state: :on
        )
      end

      subject

      expect(
        Lti::Registration.where(template_registration: template, account: root_account).count
      ).to eq(1)
    end
  end
end
