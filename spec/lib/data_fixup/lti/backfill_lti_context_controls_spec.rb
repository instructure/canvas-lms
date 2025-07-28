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
#

describe DataFixup::Lti::BackfillLtiContextControls do
  subject { described_class.run }

  let_once(:account) { account_model }
  let_once(:tool) { external_tool_1_3_model(context: account, developer_key: dev_key) }
  let_once(:dev_key) do
    lti_developer_key_model(account:).tap do |key|
      key.lti_registration = lti_registration_model(account:)
    end
  end

  before do
    allow(Sentry).to receive(:with_scope)
    allow(Sentry).to receive(:capture_message)
  end

  it "shouldn't raise an error" do
    expect { subject }.not_to raise_error
  end

  it "should backfill Lti::ContextControls for all relevant tools" do
    old_tool = external_tool_model(context: account)
    expect { described_class.run }
      .to change { Lti::ContextControl.count }.by(1)
      .and not_change { old_tool.context_controls.reload.count }

    expect(Lti::ContextControl.last.path).to eq("a#{account.id}.")
  end

  it "should not backfill if no registration ID can be found" do
    tool.update_column(:lti_registration_id, nil)
    dev_key.update_column(:lti_registration_id, nil)

    scope = double("SentryScope")
    allow(scope).to receive(:set_context)
    allow(Sentry).to receive(:with_scope).and_yield(scope)
    expect(Sentry).to receive(:capture_message).with("Lti::ContextControl not backfilled because no registration ID found", level: :warning)
    expect { subject }.not_to change { Lti::ContextControl.count }
  end

  it "caches the path for each context" do
    allow(Lti::ContextControl).to receive(:calculate_path).and_call_original
    external_tool_1_3_model(context: account, developer_key: dev_key)
    expect { subject }.to change { Lti::ContextControl.count }.by(2)
    expect(Lti::ContextControl).to have_received(:calculate_path).once
  end

  context "some tools already have context controls" do
    let_once(:new_tool) { external_tool_1_3_model(context: account, developer_key: dev_key) }
    let_once(:dev_key) do
      developer_key_model(account:).tap do |key|
        key.lti_registration = lti_registration_model(account:)
      end
    end
    let_once(:context_control) do
      Lti::ContextControl.create!(
        registration: dev_key.lti_registration,
        available: true,
        deployment: new_tool,
        account:
      )
    end

    it "doesn't backfill Lti::ContextControls for tools that already have them" do
      expect { subject }
        .to not_change { new_tool.context_controls.reload.count }
        .and not_change { context_control.reload }
    end
  end
end
