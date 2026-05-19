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

describe "lti:local_vs_binding_diffs" do
  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task["lti:local_vs_binding_diffs"].reenable
  end

  context "when a local registration's workflow state doesn't match its account binding" do
    let_once(:account) { account_model }
    let_once(:template_registration) { lti_registration_with_tool(account: Account.site_admin) }

    # Local registration for the root account, with a mismatched binding.
    # Service creates inactive local reg + "off" binding; we then flip local to active.
    let_once(:local_registration) do
      Lti::InstallTemplateRegistrationService.call(
        account:,
        template: template_registration,
        binding_state: :off
      )[:local_copy].tap { |r| r.update!(workflow_state: "active") }
    end

    it "prints the mismatch count" do
      expect { Rake::Task["lti:local_vs_binding_diffs"].invoke }
        .to output(/Found 1 mismatches between account binding and local registration state/).to_stdout
    end

    it "prints CSV containing the mismatch data" do
      expect { Rake::Task["lti:local_vs_binding_diffs"].invoke }.to output(
        include(account.global_id.to_s)
          .and(include(account.name))
          .and(include(template_registration.global_id.to_s))
          .and(include(local_registration.global_id.to_s))
          .and(include("off"))
          .and(include("active"))
      ).to_stdout
    end

    context "plus additional mismatched registrations" do
      # Another account with binding "on" but local state "inactive" mismatch.
      # Service creates active local reg + "on" binding. Afterwards, flip local to inactive.
      let_once(:account2) { account_model }
      let_once(:local_registration2) do
        Lti::InstallTemplateRegistrationService.call(
          account: account2,
          template: template_registration,
          binding_state: :on
        )[:local_copy].tap { |r| r.update!(workflow_state: "inactive") }
      end

      # Another template registration where the binding is "off" but local is
      # "active" mismatch.
      # Service creates inactive local reg + "off" binding. Afterwards, flip local to active.
      let_once(:template_registration2) { lti_registration_with_tool(account: Account.site_admin) }
      let_once(:account3) { account_model }
      let_once(:local_registration3) do
        Lti::InstallTemplateRegistrationService.call(
          account: account3,
          template: template_registration2,
          binding_state: :off
        )[:local_copy].tap { |r| r.update!(workflow_state: "active") }
      end

      # A matching registration (binding "off", local "inactive") should not appear in CSV.
      let_once(:template_registration_match) { lti_registration_with_tool(account: Account.site_admin) }
      let_once(:account_match) { account_model }
      let_once(:local_registration_match) do
        Lti::InstallTemplateRegistrationService.call(
          account: account_match,
          template: template_registration_match,
          binding_state: :off
        )[:local_copy]
      end

      it "prints the correct mismatch count" do
        expect { Rake::Task["lti:local_vs_binding_diffs"].invoke }
          .to output(/Found 3 mismatches between account binding and local registration state/).to_stdout
      end

      it "prints CSV containing new mismatched registrations" do
        expect { Rake::Task["lti:local_vs_binding_diffs"].invoke }.to output(
          include(local_registration2.global_id.to_s)
            .and(include(local_registration3.global_id.to_s))
        ).to_stdout
      end

      it "does not include the matching registration in the CSV" do
        expect { Rake::Task["lti:local_vs_binding_diffs"].invoke }.not_to output(
          include(local_registration_match.global_id.to_s)
        ).to_stdout
      end
    end
  end

  context "when the template has a site admin binding that mismatches the local registration" do
    let_once(:account) { account_model }
    let_once(:template_registration) { lti_registration_with_tool(account: Account.site_admin) }

    # lti_registration_with_tool creates an "allow" binding in site admin.
    # Helper method here to set desired state so that this binding gets returned
    # by account_binding_for.
    def set_site_admin_binding(state)
      Lti::RegistrationAccountBinding.find_by!(
        registration: template_registration,
        account: Account.site_admin
      ).update!(workflow_state: state)
    end

    context "site admin binding is 'on' but local registration is inactive" do
      before { set_site_admin_binding("on") }

      # Service creates inactive local reg + "off" local binding.
      # account_binding_for returns the site admin "on" binding (mismatch).
      let_once(:local_registration) do
        Lti::InstallTemplateRegistrationService.call(
          account:,
          template: template_registration,
          binding_state: :off
        )[:local_copy]
      end

      it "detects the mismatch" do
        expect { Rake::Task["lti:local_vs_binding_diffs"].invoke }
          .to output(/Found 1 mismatches between account binding and local registration state/).to_stdout
      end
    end

    context "site admin binding is 'off' but local registration is active" do
      before { set_site_admin_binding("off") }

      # Service creates active local reg + "on" local binding.
      # account_binding_for returns the site admin "off" binding first (mismatch).
      let_once(:local_registration) do
        Lti::InstallTemplateRegistrationService.call(
          account:,
          template: template_registration,
          binding_state: :on
        )[:local_copy]
      end

      it "detects the mismatch" do
        expect { Rake::Task["lti:local_vs_binding_diffs"].invoke }
          .to output(/Found 1 mismatches between account binding and local registration state/).to_stdout
      end
    end
  end

  context "when a local registration's state matches its account binding" do
    let_once(:account) { account_model }
    let_once(:template_registration) { lti_registration_with_tool(account: Account.site_admin) }

    # Service creates active local reg + "on" binding. No mismatch.
    let_once(:local_registration) do
      Lti::InstallTemplateRegistrationService.call(
        account:,
        template: template_registration,
        binding_state: :on
      )[:local_copy]
    end

    it "prints a no mismatches message" do
      expect { Rake::Task["lti:local_vs_binding_diffs"].invoke }
        .to output(/No mismatches found between account bindings and local registration states/).to_stdout
    end
  end
end
