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

require_relative "../../lti_1_3_tool_configuration_spec_helper"

describe Lti::CreateRegistrationService do
  # see also spec/controllers/lti/registrations_controller_spec.rb "POST create"
  # and spec/controllers/lti/tool_configurations_api_controller_spec.rb "POST create"
  subject do
    described_class.call(
      account:,
      created_by:,
      registration_params:,
      configuration_params:,
      unified_tool_id:,
      overlay_params:,
      binding_params:,
      developer_key_params:
    )
  end

  # brings in a valid internal lti configuration
  include_context "lti_1_3_tool_configuration_spec_helper"

  let_once(:account) { account_model }
  let_once(:created_by) { user_model }
  let(:registration_params) do
    {
      name: "Foo bar baz",
      admin_nickname: "who named this tool",
      vendor: "acme",
      description: "looney man"
    }
  end
  let(:configuration_params) do
    internal_lti_configuration.merge(scopes: [*TokenScopes::LTI_SCOPES.keys.slice(0..3)])
  end
  let(:unified_tool_id) { nil }
  let(:developer_key_params) { {} }
  let(:overlay_params) { {} }
  let(:binding_params) { {} }

  it "creates the expected objects with the expected values" do
    expect { subject }
      .to change { Lti::Registration.count }
      .by(1)
      .and change { DeveloperKey.count }
      .by(1)
      .and change { Lti::ToolConfiguration.count }
      .by(1)
      .and change { Lti::RegistrationAccountBinding.count }
      .by(1)
      .and change { ContextExternalTool.count }
      .by(1)

    expect(Lti::Registration.last.attributes.with_indifferent_access).to include(
      **registration_params
    )

    expect(Lti::ToolConfiguration.last.internal_lti_configuration.with_indifferent_access)
      .to eql(configuration_params.with_indifferent_access)
  end

  it "infers properties on the developer key from the tool configuration" do
    subject

    expect(DeveloperKey.last.scopes).to eql(configuration_params[:scopes])
    expect(DeveloperKey.last.redirect_uris).to eql([configuration_params[:target_link_uri]])
  end

  context "creating a site admin registration" do
    let(:account) { Account.site_admin }

    it "sets the developer key's account to nil and makes it invisible by default" do
      subject

      expect(DeveloperKey.last.visible).to be false
      expect(DeveloperKey.last.account).to be_nil
    end
  end

  context "with overlay params specified" do
    let(:overlay_params) { { disabled_scopes: [TokenScopes::LTI_SCOPES.keys[0]] } }

    it "creates a new overlay" do
      expect { subject }
        .to change { Lti::Overlay.count }
        .by(1)

      expect(Lti::Overlay.last.data.with_indifferent_access).to eql(overlay_params.with_indifferent_access)
    end

    it "uses the scopes from the overlay when creating the developer key" do
      subject
      puts overlay_params[:scopes]
      expect(DeveloperKey.last.scopes).not_to include(TokenScopes::LTI_SCOPES.keys[0])
    end
  end

  context "with developer_key_params defined" do
    let(:developer_key_params) do
      {
        # Explicitly different than the configuration_params scopes
        scopes: [TokenScopes::LTI_SCOPES.keys.last],
        test_cluster_only: true,
      }
    end

    it "uses the values from the parameters when creating the developer key" do
      subject
      expect(DeveloperKey.last.scopes).to eql(developer_key_params[:scopes])
      expect(DeveloperKey.last.test_cluster_only).to be true
    end

    context "with an disallowed param included" do
      let(:developer_key_params) do
        {
          oidc_initiation_url: "https://example.com/redirection"
        }
      end

      it "ignores the invalid param" do
        subject
        expect(DeveloperKey.last.oidc_initiation_url).not_to eql(developer_key_params[:oidc_initiation_url])
      end
    end
  end

  context "with binding_params defined" do
    let(:binding_params) { { workflow_state: :on } }

    it "sets the registration account binding to the specified state" do
      expect { subject }.to change { Lti::RegistrationAccountBinding.count }.by(1)

      expect(Lti::RegistrationAccountBinding.last.workflow_state).to eql("on")
    end
  end

  context "with a unified_tool_id" do
    let(:unified_tool_id) { "1234567890" }

    it "sets the unified_tool_id on the tool config" do
      expect { subject }.to change { Lti::ToolConfiguration.count }.by(1)

      expect(Lti::ToolConfiguration.last.unified_tool_id).to eql(unified_tool_id)
    end

    it "sets the unified_tool_id on the deployment" do
      subject
      expect(ContextExternalTool.last.unified_tool_id).to eql(unified_tool_id)
    end
  end

  context "with invalid configuration_params" do
    let(:configuration_params) do
      {
        not: :valid
      }
    end

    it "raises an error" do
      expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context "with invalid overlay params" do
    let(:overlay_params) do
      {
        disabled_scopes: "wrong!!"
      }
    end

    it "raises an error" do
      expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context "with a non-user passed in" do
    let(:created_by) { "foobarbaz" }

    it "raises an error" do
      expect { subject }.to raise_error(ArgumentError)
    end
  end

  context "with a non-account passed in" do
    let(:account) { "foobarbaz" }

    it "raises an error" do
      expect { subject }.to raise_error(ArgumentError)
    end
  end
end
