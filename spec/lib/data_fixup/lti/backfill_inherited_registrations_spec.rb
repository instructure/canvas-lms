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

RSpec.describe DataFixup::Lti::BackfillInheritedRegistrations do
  specs_require_sharding

  subject { execute_fixup }

  let(:operation_shard) { @shard1 }

  around do |example|
    operation_shard.activate do
      example.run
    end
  end

  let_once(:user) { user_model }
  let_once(:template) do
    lti_registration_with_tool(
      account: Account.site_admin,
      created_by: user
    )
  end

  before do
    # Prevent actual sleeps when testing
    allow_any_instance_of(described_class).to receive(:wait_between_jobs)
    allow_any_instance_of(described_class).to receive(:wait_between_processing)
  end

  def execute_fixup
    operation_shard.activate { described_class.new }.run
    run_jobs
  end

  # ─── Same-shard topology (OSS / default shard == site admin shard) ──────────

  context "on the site admin shard" do
    let(:operation_shard) { Account.site_admin.shard }

    let_once(:root_account) { operation_shard.activate { account_model } }
    let_once(:binding) do
      operation_shard.activate do
        Lti::AccountBindingService.call(
          registration: template,
          account: root_account,
          user:,
          workflow_state: :on
        )[:lti_registration_account_binding]
      end
    end

    it "creates a local copy of the template registration for the binding's account" do
      expect { subject }.to change { Lti::Registration.where(template_registration: template, account: root_account).count }.from(0).to(1)

      local_copy = Lti::Registration.find_by(template_registration: template, account: root_account)
      expect(local_copy.template_registration).to eq(template)
      expect(local_copy.account).to eq(root_account)
    end

    it "is idempotent — only creates one local copy across multiple runs" do
      described_class.new.run
      described_class.new.run

      expect(Lti::Registration.where(template_registration: template, account: root_account).count).to eq(1)
    end

    it "skips dynamic registrations" do
      lti_ims_registration_model(lti_registration: template)

      expect { subject }.not_to change { Lti::Registration.where(template_registration: template).count }
    end

    it "skips deleted registrations" do
      template.update!(workflow_state: "deleted")

      expect { subject }.not_to change { Lti::Registration.count }
    end

    it "skips deleted bindings" do
      binding.update!(workflow_state: "deleted")

      expect { subject }.not_to change { Lti::Registration.where(template_registration: template).count }
    end

    it "skips site admin account bindings" do
      expect(
        Lti::RegistrationAccountBinding.where(registration: template, account: Account.site_admin).exists?
      ).to be(true)

      expect { subject }.not_to(
        change { Lti::Registration.where(template_registration: template, account: Account.site_admin).count }
      )
    end

    it "doesn't create a local copy for an 'off' binding" do
      binding.update!(workflow_state: "off")

      expect { subject }.not_to change { Lti::Registration.where(template_registration: template, account: root_account).count }
    end

    it "does not create a RegistrationAccountBinding for the local copy" do
      subject

      local_copy = Lti::Registration.find_by(template_registration: template, account: root_account)
      expect(Lti::RegistrationAccountBinding.find_by(registration: local_copy, account: root_account)).to be_nil
    end

    it "does not create a ContextExternalTool for the local copy" do
      expect { subject }.not_to change { ContextExternalTool.count }
    end

    it "does not create a local copy when the template registration is inactive" do
      Lti::AccountBindingService.call(
        account: root_account,
        registration: template,
        user: site_admin_user,
        workflow_state: :off
      )
      subject

      expect(Lti::Registration.where(template_registration: template, account: root_account).count).to eq(0)
    end

    it "creates a fresh local copy when the existing one is deleted" do
      subject
      local_copy = Lti::Registration.find_by(template_registration: template, account: root_account)
      local_copy.update!(workflow_state: "deleted")

      described_class.new.run

      active_copies = Lti::Registration.active.where(template_registration: template, account: root_account)
      expect(active_copies.count).to eq(1)
      expect(active_copies.first).not_to eq(local_copy)
    end

    it "isolates errors — captures via Sentry and continues processing other bindings" do
      root_account2 = account_model
      Lti::AccountBindingService.call(
        registration: template,
        account: root_account2,
        user:,
        workflow_state: :on
      )

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

  context "on a non-default shard" do
    specs_require_sharding

    def run_fixup_on(shard)
      shard.activate do
        described_class.new(switchman_shard: shard).run
      end
    end

    it "creates a local copy on the non-default shard" do
      template

      @shard2.activate do
        root_account2 = account_model
        user2 = user_model

        Lti::AccountBindingService.call(
          registration: template,
          account: root_account2,
          user: user2,
          workflow_state: :on
        )

        run_fixup_on(@shard2)

        local_copy = Lti::Registration.find_by(template_registration: template, account: root_account2)
        expect(local_copy).to be_present
        expect(local_copy.template_registration).to eq(template)
        expect(local_copy.account).to eq(root_account2)
      end
    end

    it "local copy lives on the correct (non-default) shard" do
      template

      @shard2.activate do
        root_account2 = account_model
        user2 = user_model

        Lti::AccountBindingService.call(
          registration: template,
          account: root_account2,
          user: user2,
          workflow_state: :on
        )

        run_fixup_on(@shard2)

        local_copy = Lti::Registration.find_by(template_registration: template, account: root_account2)
        expect(local_copy.shard).to eq(@shard2)
      end
    end

    it "stores template_registration_id as the global ID for cross-shard lookup" do
      template

      @shard2.activate do
        root_account2 = account_model
        user2 = user_model

        Lti::AccountBindingService.call(
          registration: template,
          account: root_account2,
          user: user2,
          workflow_state: :on
        )

        run_fixup_on(@shard2)

        local_copy = Lti::Registration.find_by(template_registration: template, account: root_account2)
        expect(local_copy.template_registration_id).to eq(template.global_id)
      end
    end

    it "is idempotent — only creates one local copy across multiple runs" do
      template

      @shard2.activate do
        root_account2 = account_model
        user2 = user_model

        Lti::AccountBindingService.call(
          registration: template,
          account: root_account2,
          user: user2,
          workflow_state: :on
        )

        run_fixup_on(@shard2)
        run_fixup_on(@shard2)

        expect(Lti::Registration.where(template_registration: template, account: root_account2).count).to eq(1)
      end
    end

    it "skips dynamic registrations" do
      Account.site_admin.shard.activate { lti_ims_registration_model(lti_registration: template) }

      @shard2.activate do
        root_account2 = account_model
        user2 = user_model

        Lti::AccountBindingService.call(
          registration: template,
          account: root_account2,
          user: user2,
          workflow_state: :on
        )

        expect { run_fixup_on(@shard2) }.not_to change { Lti::Registration.where(template_registration: template).count }
      end
    end

    it "excludes bindings referencing non-site-admin-shard registrations" do
      template

      @shard2.activate do
        root_account2 = account_model
        # lti_registration_with_tool creates a registration + binding on @shard2;
        # its registration_id is local to @shard2, outside the site admin shard ID range.
        other_reg = lti_registration_with_tool(account: root_account2)

        expect { run_fixup_on(@shard2) }.not_to change { Lti::Registration.where(template_registration: other_reg).count }
      end
    end

    it "does not create a RegistrationAccountBinding for the local copy" do
      template

      @shard2.activate do
        root_account2 = account_model
        user2 = user_model

        Lti::AccountBindingService.call(
          registration: template,
          account: root_account2,
          user: user2,
          workflow_state: :on
        )

        run_fixup_on(@shard2)

        local_copy = Lti::Registration.find_by(template_registration: template, account: root_account2)
        expect(Lti::RegistrationAccountBinding.find_by(registration: local_copy, account: root_account2)).to be_nil
      end
    end

    it "does not create a ContextExternalTool for the local copy" do
      template

      @shard2.activate do
        root_account2 = account_model
        user2 = user_model

        Lti::AccountBindingService.call(
          registration: template,
          account: root_account2,
          user: user2,
          workflow_state: :on
        )

        expect { run_fixup_on(@shard2) }.not_to change { ContextExternalTool.count }
      end
    end

    it "doesn't create a local copy for an 'off' binding" do
      template

      @shard2.activate do
        root_account2 = account_model
        user2 = user_model

        Lti::AccountBindingService.call(
          registration: template,
          account: root_account2,
          user: user2,
          workflow_state: :off
        )

        run_fixup_on(@shard2)

        expect(Lti::Registration.find_by(template_registration: template, account: root_account2)).not_to be_present
      end
    end

    it "doesn't create a local copy when the template registration is inactive" do
      template
      Account.site_admin.shard.activate do
        Lti::AccountBindingService.call(
          account: Account.site_admin,
          user: site_admin_user,
          registration: template,
          workflow_state: :off
        )
      end

      @shard2.activate do
        root_account2 = account_model
        user2 = user_model

        Lti::AccountBindingService.call(
          registration: template,
          account: root_account2,
          user: user2,
          workflow_state: :on
        )

        run_fixup_on(@shard2)

        local_copy = Lti::Registration.find_by(template_registration: template, account: root_account2)
        expect(local_copy).not_to be_present
      end
    end

    it "does not process bindings from a different non-default shard" do
      template

      @shard1.activate do
        root_account1 = account_model
        user1 = user_model
        Lti::AccountBindingService.call(
          registration: template,
          account: root_account1,
          user: user1,
          workflow_state: :on
        )
      end

      @shard2.activate do
        root_account2 = account_model
        user2 = user_model
        Lti::AccountBindingService.call(
          registration: template,
          account: root_account2,
          user: user2,
          workflow_state: :on
        )
        run_fixup_on(@shard2)
      end

      @shard1.activate do
        expect(Lti::Registration.where(template_registration: template)).to be_empty
      end
    end

    it "isolates errors — captures via Sentry and continues" do
      template

      @shard2.activate do
        root_account2 = account_model
        root_account3 = account_model
        user2 = user_model

        Lti::AccountBindingService.call(
          registration: template,
          account: root_account2,
          user: user2,
          workflow_state: :on
        )
        Lti::AccountBindingService.call(
          registration: template,
          account: root_account3,
          user: user2,
          workflow_state: :on
        )

        allow(Lti::InstallTemplateRegistrationService).to receive(:call).and_wrap_original do |original, **kwargs|
          raise "boom" if kwargs[:account] == root_account2

          original.call(**kwargs)
        end

        expect(Sentry).to receive(:capture_exception).once

        expect { run_fixup_on(@shard2) }.not_to raise_error
        expect(Lti::Registration.find_by(template_registration: template, account: root_account3)).to be_present
      end
    end
  end
end
