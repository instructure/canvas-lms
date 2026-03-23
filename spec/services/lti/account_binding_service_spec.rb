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

describe Lti::AccountBindingService do
  subject do
    Lti::AccountBindingService.call(account:,
                                    registration:,
                                    user:,
                                    workflow_state:,
                                    overwrite_created_by:)
  end

  let_once(:account) { account_model }
  let_once(:developer_key) { lti_developer_key_model(account:) }
  let_once(:registration) { developer_key.lti_registration }
  let_once(:user) { user_model }
  let_once(:other_user) { user_model }
  # Developer key's create a default account binding upon creation, so we don't need to create one here.
  let_once(:developer_key_account_binding) { developer_key.account_binding_for(account) }
  let_once(:registration_account_binding) do
    Lti::RegistrationAccountBinding.create!(account:,
                                            registration:,
                                            developer_key_account_binding:,
                                            created_by: other_user,
                                            updated_by: other_user)
  end
  let_once(:workflow_state) { nil }
  let_once(:overwrite_created_by) { false }

  before do
    # bindings default to off, so match state
    registration.update!(workflow_state: "inactive")
  end

  it "returns a hash with the registration and developer key account bindings" do
    expect(subject).to eq(lti_registration_account_binding: registration_account_binding, developer_key_account_binding:)
  end

  context "something goes wrong updating a model" do
    let_once(:workflow_state) { "on" }
    before do
      allow(DeveloperKeyAccountBinding).to receive(:find_or_initialize_by).and_raise(StandardError)
    end

    it "rolls back the changes" do
      expect { subject }.to raise_error(StandardError)

      expect(registration_account_binding.workflow_state).to eq("off")
      expect(developer_key_account_binding.workflow_state).to eq("off")
      expect(registration.reload.workflow_state).to eq("inactive")
    end
  end

  # When we create a new registration and developer key (such as in Lti::RegistrationController#create),
  # due to being in a transaction, the aggressive caching of DeveloperKey.find_cached can cause some issues with validation,
  # (it returns nil as the secondary doesn't have the just created dev key), so we need to make sure
  # our code accounts for that.
  it "skips the developer key cache" do
    expect(DeveloperKey).not_to receive(:find_cached)
    expect { subject }.not_to raise_error
  end

  context "no registration is provided" do
    let_once(:registration) { nil }

    it "raises an error" do
      expect { subject }.to raise_error(ArgumentError, "registration must be provided")
    end
  end

  context "a binding already exists" do
    before do
      registration_account_binding
    end

    it "marks the binding as being updated by the user" do
      expect { subject }.to change { registration_account_binding.reload.updated_by }.to(user)
    end

    it "doesn't overwrite the created_by field if overwrite_created_by is false" do
      expect { subject }.not_to change { registration_account_binding.reload.created_by }.from(other_user)
    end

    it "associates the two bindings if they aren't already associated" do
      registration_account_binding.update!(developer_key_account_binding: nil)
      developer_key_account_binding.update!(lti_registration_account_binding: nil)
      expect { subject }
        .to change { registration_account_binding.reload.developer_key_account_binding }.to(developer_key_account_binding)
        .and change { developer_key_account_binding.reload.lti_registration_account_binding }.to(registration_account_binding)
    end

    context "overwrite_created_by is true" do
      let(:overwrite_created_by) { true }

      it "overwrites the created_by field" do
        expect { subject }.to change { registration_account_binding.reload.created_by }.to(user)
      end
    end

    context "workflow_state is provided" do
      let(:workflow_state) { "on" }

      it "updates workflow_state if provided" do
        expect { subject }
          .to change { registration_account_binding.reload.workflow_state }.to(workflow_state)
          .and change { developer_key_account_binding.reload.workflow_state }.to(workflow_state)
      end
    end
  end

  context "syncing registration workflow_state" do
    before do
      registration_account_binding
    end

    context "workflow_state is :on" do
      let(:workflow_state) { :on }

      it "sets registration workflow_state to active" do
        expect { subject }.to change { registration.reload.workflow_state }.to("active")
      end

      it "records the user as the updater on the registration" do
        expect { subject }.to change { registration.reload.updated_by }.to(user)
      end
    end

    context "workflow_state is :off" do
      let(:workflow_state) { :off }

      it "sets registration workflow_state to inactive" do
        registration.update!(workflow_state: "active")
        expect { subject }.to change { registration.reload.workflow_state }.to("inactive")
      end
    end

    context "workflow_state is :allow" do
      let_once(:sa_developer_key) { lti_developer_key_model(account: Account.site_admin) }
      let_once(:sa_registration) { sa_developer_key.lti_registration }
      let_once(:sa_binding) do
        Lti::RegistrationAccountBinding.create!(
          account: Account.site_admin,
          registration: sa_registration,
          created_by: other_user,
          updated_by: other_user
        )
      end

      subject do
        Lti::AccountBindingService.call(
          account: Account.site_admin,
          registration: sa_registration,
          user:,
          workflow_state: :allow,
          overwrite_created_by:
        )
      end

      before { sa_binding }

      it "sets registration workflow_state to active" do
        sa_registration.update!(workflow_state: "inactive")
        expect { subject }.to change { sa_registration.reload.workflow_state }.to("active")
      end
    end

    context "workflow_state is not mapped" do
      subject do
        Lti::AccountBindingService.call(
          account:,
          registration:,
          user:,
          workflow_state: :unmapped_state,
          overwrite_created_by:
        )
      end

      it "does not change registration workflow_state" do
        expect { subject }.not_to change { registration.reload.workflow_state }
      end
    end

    context "registration is already in the target state" do
      let(:workflow_state) { :off }

      it "does not save the registration" do
        expect { subject }.not_to change { registration.reload.updated_at }
      end
    end

    context "when the registration belongs to a different account (inherited)" do
      let_once(:sa_developer_key) { lti_developer_key_model(account: Account.site_admin) }
      let_once(:sa_registration) { sa_developer_key.lti_registration }
      let_once(:sa_root_account_binding) do
        Lti::RegistrationAccountBinding.create!(
          account:,
          registration: sa_registration,
          created_by: user,
          updated_by: user,
          workflow_state: :on
        )
      end

      subject do
        Lti::AccountBindingService.call(
          account:,
          registration: sa_registration,
          user:,
          workflow_state: :off,
          overwrite_created_by:
        )
      end

      before { sa_root_account_binding }

      it "does not change the registration workflow_state when a root account turns it off" do
        sa_registration.update!(workflow_state: "active")
        expect { subject }.not_to change { sa_registration.reload.workflow_state }
      end

      it "still updates the account binding workflow_state" do
        expect { subject }.to change { sa_root_account_binding.reload.workflow_state }.to("off")
      end
    end
  end

  context "no binding already exists" do
    before do
      # Ensure there really isn't a binding
      registration_account_binding.destroy_permanently!
    end

    it "creates a new registration account binding" do
      expect { subject }.to change { Lti::RegistrationAccountBinding.count }.by(1)
    end

    # Developer keys always have a default account binding created when they are created.
    it "doesn't create a new developer key account binding" do
      expect { subject }.not_to change { DeveloperKeyAccountBinding.count }
    end
  end
end
