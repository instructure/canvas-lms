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

RSpec.describe DataFixup::Lti::BackfillForcedOnRegistrations do
  specs_require_sharding

  subject { execute_fixup }

  around do |example|
    operation_shard.activate do
      example.run
    end
  end

  let(:operation_shard) { @shard1 }
  let(:sa_shard) { Account.site_admin.shard }

  let_once(:user) { sa_shard.activate { user_model } }
  let_once(:template) do
    sa_shard.activate do
      lti_registration_with_tool(
        account: Account.site_admin,
        created_by: user
      )
    end
  end

  let_once(:sa_binding) do
    sa_shard.activate do
      Lti::AccountBindingService.call(
        registration: template,
        account: Account.site_admin,
        user:,
        workflow_state: :on
      )
    end
  end

  before do
    allow_any_instance_of(described_class).to receive(:wait_between_jobs)
    allow_any_instance_of(described_class).to receive(:wait_between_processing)
  end

  def execute_fixup
    operation_shard.activate { described_class.new }.run
    run_jobs
  end

  # ─── Same-shard topology (OSS / default shard == site admin shard) ──────────

  context "on the site admin shard" do
    let(:operation_shard) { sa_shard }

    let_once(:root_account) { account_model }

    it "creates a local copy for every active root account" do
      expect { subject }.to change {
        Lti::Registration.where(template_registration: template, account: root_account).count
      }.from(0).to(1)

      local_copy = Lti::Registration.find_by(template_registration: template, account: root_account)
      expect(local_copy.template_registration).to eq(template)
      expect(local_copy.account).to eq(root_account)
    end

    it "is idempotent — only creates one local copy across multiple runs" do
      execute_fixup
      execute_fixup

      expect(Lti::Registration.where(template_registration: template, account: root_account).count).to eq(1)
    end

    it "handles multiple forced-on registrations" do
      template2 = lti_registration_with_tool(account: Account.site_admin, created_by: user)
      Lti::AccountBindingService.call(
        registration: template2,
        account: Account.site_admin,
        user:,
        workflow_state: :on
      )

      subject

      expect(Lti::Registration.find_by(template_registration: template, account: root_account)).to be_present
      expect(Lti::Registration.find_by(template_registration: template2, account: root_account)).to be_present
    end

    it "creates copies for all root accounts" do
      root_account2 = account_model

      subject

      expect(Lti::Registration.find_by(template_registration: template, account: root_account)).to be_present
      expect(Lti::Registration.find_by(template_registration: template, account: root_account2)).to be_present
    end

    it "skips dynamic registrations" do
      lti_ims_registration_model(lti_registration: template, account: Account.site_admin)

      expect { subject }.not_to change { Lti::Registration.where(template_registration: template).count }
    end

    it "skips deleted template registrations" do
      template.destroy

      expect { subject }.not_to change { Lti::Registration.count }
    end

    it "skips the site admin account itself" do
      expect { subject }.not_to(
        change { Lti::Registration.where(template_registration: template, account: Account.site_admin).count }
      )
    end

    it "does not create a local copy for an 'allow' binding" do
      Lti::AccountBindingService.call(
        registration: template,
        account: Account.site_admin,
        user:,
        workflow_state: :allow
      )

      expect { subject }.not_to change { Lti::Registration.where(template_registration: template).count }
    end

    it "does not create a local copy for an 'off' binding" do
      Lti::AccountBindingService.call(
        registration: template,
        account: Account.site_admin,
        user:,
        workflow_state: :off
      )

      expect { subject }.not_to change { Lti::Registration.where(template_registration: template).count }
    end

    it "does not create a RegistrationAccountBinding for the local copy" do
      subject

      local_copy = Lti::Registration.find_by(template_registration: template, account: root_account)
      expect(Lti::RegistrationAccountBinding.find_by(registration: local_copy, account: root_account)).to be_nil
    end

    it "does not create a ContextExternalTool" do
      expect { subject }.not_to change { ContextExternalTool.count }
    end

    it "creates a fresh local copy when the existing one is deleted" do
      subject
      local_copy = Lti::Registration.find_by(template_registration: template, account: root_account)
      local_copy.destroy

      described_class.new.run

      active_copies = Lti::Registration.active.where(template_registration: template, account: root_account)
      expect(active_copies.count).to eq(1)
      expect(active_copies.first).not_to eq(local_copy)
    end

    it "isolates errors — captures via Sentry and continues processing other accounts" do
      root_account2 = account_model

      allow(Lti::InstallTemplateRegistrationService).to receive(:call).and_wrap_original do |original, **kwargs|
        raise "boom" if kwargs[:account] == root_account

        original.call(**kwargs)
      end

      expect(Sentry).to receive(:capture_exception).once

      expect { subject }.not_to raise_error
      expect(Lti::Registration.find_by(template_registration: template, account: root_account2)).to be_present
    end
  end

  # ─── Cross-shard topology (production / site admin on a different shard) ─────

  context "on a different shard" do
    specs_require_sharding

    let(:operation_shard) { @shard2 }

    it "creates a local copy on the non-default shard" do
      root_account2 = account_model

      subject

      expect(Lti::Registration.find_by(template_registration: template, account: root_account2)).to be_present
    end

    it "stores template_registration_id as the global ID for cross-shard lookup" do
      root_account2 = account_model

      subject

      local_copy = Lti::Registration.find_by(template_registration: template, account: root_account2)
      expect(local_copy.template_registration_id).to eq(template.global_id)
    end

    it "is idempotent" do
      root_account2 = account_model

      execute_fixup
      execute_fixup

      expect(Lti::Registration.where(template_registration: template, account: root_account2).count).to eq(1)
    end

    it "skips dynamic registrations" do
      sa_shard.activate { lti_ims_registration_model(lti_registration: template) }

      account_model

      expect { execute_fixup }.not_to change {
        Lti::Registration.where(template_registration: template).count
      }
    end

    it "does not process bindings from a different non-default shard" do
      @shard1.activate { account_model }

      account_model
      subject

      @shard1.activate do
        expect(Lti::Registration.where(template_registration: template)).to be_empty
      end
    end

    it "isolates errors — captures via Sentry and continues" do
      root_account2 = account_model
      root_account3 = account_model

      allow(Lti::InstallTemplateRegistrationService).to receive(:call).and_wrap_original do |original, **kwargs|
        raise "boom" if kwargs[:account] == root_account2

        original.call(**kwargs)
      end

      expect(Sentry).to receive(:capture_exception).once

      expect { subject }.not_to raise_error
      expect(Lti::Registration.find_by(template_registration: template, account: root_account3)).to be_present
    end
  end
end
