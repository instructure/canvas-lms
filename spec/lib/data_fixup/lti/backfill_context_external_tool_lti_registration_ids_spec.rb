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

RSpec.describe DataFixup::Lti::BackfillContextExternalToolLtiRegistrationIds do
  subject { DataFixup::Lti::BackfillContextExternalToolLtiRegistrationIds.run }

  let(:developer_key) { lti_developer_key_model }
  let!(:context_external_tool) do
    ContextExternalTool.create!(
      context: course_model,
      consumer_key: "key",
      shared_secret: "secret",
      name: "test tool",
      url: "http://www.tool.com/launch",
      developer_key:,
      lti_version: "1.3",
      root_account: Account.default
    )
  end

  before do
    # Create a dynamic registration just to make sure that it doesn't somehow affect
    # things
    lti_ims_registration_model
  end

  it "associates the lti_registration with the context_external_tool" do
    expect(context_external_tool.lti_registration_id).to be_nil
    subject
    expect(context_external_tool.reload.lti_registration_id).to eq(developer_key.lti_registration.id)
  end

  it "does not affect context external tools that already have an lti_registration_id" do
    another_developer_key = lti_developer_key_model
    cet_with_registration = ContextExternalTool.create!(
      context: course_model,
      consumer_key: "key",
      shared_secret: "secret",
      name: "test tool",
      url: "http://www.tool.com/launch",
      developer_key: lti_developer_key_model,
      lti_version: "1.3",
      root_account: Account.default,
      lti_registration: another_developer_key.lti_registration
    )

    original_lti_registration_id = another_developer_key.lti_registration.id
    subject
    expect(cet_with_registration.lti_registration_id).to eq(original_lti_registration_id)
  end

  context "CETs that shouldn't get a registration_id" do
    let!(:cet) do
      ContextExternalTool.create!(
        context: account_model,
        name: "1.1 tool, no dev key",
        consumer_key: "key",
        shared_secret: "secret",
        domain: "example.com",
        settings: {
          global_navigation: {
            text: "Global Navigation",
            url: "https://example.com"
          }
        }
      )
    end

    it "does not affect tools without a developer key" do
      subject
      expect(cet.lti_registration_id).to be_nil
    end

    it "does not affect tools that have a developer key but no registration" do
      cet.developer_key_id = developer_key_model.id

      subject
      expect(cet.lti_registration_id).to be_nil
    end

    it "rescues errors and continues" do
      # Create some additional CETs to make sure they finish
      2.times do
        ContextExternalTool.create!(
          context: course_model,
          consumer_key: "key",
          shared_secret: "secret",
          name: "test tool",
          url: "http://www.tool.com/launch",
          developer_key: lti_developer_key_model,
          lti_version: "1.3",
          root_account: Account.default
        )
      end

      sentry_scope = double(Sentry::Scope)

      expect(sentry_scope).to receive(:set_tags).with(tool_id: context_external_tool.global_id)
      expect(sentry_scope).to receive(:set_context).with("exception", { name: "ArgumentError", message: "ArgumentError" })
      expect(Sentry).to receive(:with_scope).and_yield(sentry_scope)

      allow_any_instance_of(ContextExternalTool).to receive(:update_column).with(any_args).and_call_original
      allow_any_instance_of(ContextExternalTool).to receive(:update_column).with(:lti_registration_id, developer_key.lti_registration_id).and_raise(ArgumentError)

      expect { subject }.not_to raise_error
      # 1 should still be empty from earlier when the DK had no registration;
      # another 1 should be empty because it failed.
      # The other two created above should have a registration assigned to them,
      # leaving just two without an lti_registration_id.
      expect(ContextExternalTool.where(lti_registration_id: nil).count).to eq(2)
    end
  end
end
