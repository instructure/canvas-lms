# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative "../../lti_1_3_spec_helper"

RSpec.describe Lti::ToolConfigurationsApiController do
  subject { response }

  include_context "lti_1_3_spec_helper"

  let_once(:sub_account) { account_model(root_account: account) }
  let_once(:admin) { account_admin_user(account:) }
  let_once(:student) do
    student_in_course
    @student
  end
  let(:config_from_response) do
    Lti::ToolConfiguration.find(json_parse.dig("tool_configuration", "id"))
  end
  let_once(:account) { Account.default }
  let(:dev_key_params) do
    {
      name: "Test Dev Key",
      email: "test@test.com",
      notes: "Some cool notes",
      test_cluster_only: true,
      scopes: ["https://purl.imsglobal.org/spec/lti-ags/scope/lineitem"],
      require_scopes: true,
      redirect_uris: "http://www.test.com\r\nhttp://www.anothertest.com",
      public_jwk_url: "https://www.test.com"
    }
  end
  let(:new_url) { "https://www.new-url.com/test" }
  let(:dev_key_id) { developer_key.id }
  let(:privacy_level) { "public" }
  let(:params) do
    {
      developer_key: dev_key_params,
      account_id: sub_account.id,
      developer_key_id: dev_key_id,
      tool_configuration: {
        privacy_level:,
        settings:
      }
    }.compact
  end

  before do
    user_session(admin)
    settings["extensions"][0]["privacy_level"] = privacy_level
  end

  shared_examples_for "an action that requires manage developer keys" do |skip_404|
    context "when the user has manage_developer_keys" do
      it { is_expected.to be_successful }
    end

    context "when the user is not an admin" do
      before { user_session(student) }

      it { is_expected.to be_unauthorized }
    end

    unless skip_404
      context "when the developer key does not exist" do
        before { developer_key.destroy! }

        it { is_expected.to be_not_found }
      end
    end
  end

  shared_examples_for "an endpoint that requires an existing tool configuration" do
    context "when the tool configuration does not exist" do
      it { is_expected.to be_not_found }
    end
  end

  shared_examples_for "an endpoint that accepts a settings_url" do
    let(:ok_response) do
      double(
        :body => settings.to_json,
        :is_a? => true,
        "[]" => "application/json"
      )
    end
    let(:url) { "https://www.mytool.com/config/json" }
    let(:privacy_level) { "public" }
    let(:params) do
      {
        developer_key: dev_key_params,
        account_id: sub_account.id,
        developer_key_id: developer_key.id,
        tool_configuration: {
          settings_url: url,
          disabled_placements: ["course_navigation", "account_navigation"],
          custom_fields: "foo=bar\r\nkey=value",
          privacy_level:
        }
      }
    end
    let(:make_request) { raise "Override in spec" }

    context "when the request does not time out" do
      before do
        allow(CanvasHttp).to receive(:get).and_return(ok_response)
      end

      it "uses the tool configuration JSON from the settings_url" do
        subject
        expect(config_from_response.settings["target_link_uri"]).to eq settings["target_link_uri"]
      end

      it 'sets the "disabled_placements"' do
        subject
        expect(config_from_response.disabled_placements).to match_array(
          params.dig(:tool_configuration, :disabled_placements)
        )
      end

      it 'sets the "custom_fields"' do
        subject
        expect(config_from_response.settings["custom_fields"]).to eq(
          "foo" => "bar",
          "key" => "value",
          "has_expansion" => "$Canvas.user.id",
          "no_expansion" => "foo"
        )
      end

      context "and `redirect_uris` is not sent at developer key parameter" do
        it "set `target_link_uri` to developer_key.redirect_uris" do
          dev_key_params.delete(:redirect_uris)

          subject

          expect(config_from_response.developer_key.redirect_uris).to eq [settings["target_link_uri"]]
        end
      end

      context "and `redirect_uris` is sent at developer key parameter" do
        let(:redirect_uris) { dev_key_params[:redirect_uris].split(/[\r\n]+/) }

        it "set redirect_uris parameter to developer_key.redirect_uris" do
          subject

          expect(config_from_response.developer_key.redirect_uris).to eq redirect_uris
        end
      end
    end

    context "when the request times out" do
      before do
        allow(CanvasHttp).to receive(:get).and_raise(Timeout::Error)
      end

      it { is_expected.to have_http_status :unprocessable_entity }

      it "responds with helpful error message" do
        subject
        expect(json_parse["errors"].first["message"]).to eq "Could not retrieve settings, the server response timed out."
      end
    end

    context "when the response is not a success" do
      subject { json_parse["errors"].first["message"] }

      let(:stubbed_response) { double }

      before do
        allow(stubbed_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return false
        allow(stubbed_response).to receive("[]").and_return("application/json")
        allow(CanvasHttp).to receive(:get).and_return(stubbed_response)
      end

      context 'when the response is "not found"' do
        before do
          allow(stubbed_response).to receive_messages(message: "Not found", code: "404")
          make_request
        end

        it { is_expected.to eq "Not found" }
      end

      context 'when the response is "unauthorized"' do
        before do
          allow(stubbed_response).to receive_messages(message: "Unauthorized", code: "401")
          make_request
        end

        it { is_expected.to eq "Unauthorized" }
      end

      context 'when the response is "internal server error"' do
        before do
          allow(stubbed_response).to receive_messages(message: "Internal server error", code: "500")
          make_request
        end

        it { is_expected.to eq "Internal server error" }
      end

      context "when the response is not JSON" do
        before do
          allow(stubbed_response).to receive("[]").and_return("text/html")
          allow(stubbed_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return true
          make_request
        end

        it { is_expected.to eq 'Content type must be "application/json"' }
      end
    end
  end

  shared_examples_for "an endpoint that accepts developer key parameters" do
    subject do
      make_request
      DeveloperKey.find(json_parse.dig("developer_key", "id"))
    end

    let(:make_request) { raise "set in example" }
    let(:bad_scope_request) { raise "set in example" }

    it "sets the developer key name" do
      expect(subject.name).to eq dev_key_params[:name]
    end

    it "sets the developer key email" do
      expect(subject.email).to eq dev_key_params[:email]
    end

    it "sets the developer key notes" do
      expect(subject.notes).to eq dev_key_params[:notes]
    end

    it "sets the developer key test_cluster_only" do
      expect(subject.test_cluster_only).to eq dev_key_params[:test_cluster_only]
    end

    it "sets the developer key scopes" do
      expect(subject.scopes).to eq dev_key_params[:scopes]
    end

    it "sets the developer key require_scopes" do
      expect(subject.require_scopes).to eq dev_key_params[:require_scopes]
    end

    it "sets the developer key redirect_uris" do
      expect(subject.redirect_uris).to eq dev_key_params[:redirect_uris].split
    end

    it "sets the developer key oidc_initiation_url" do
      expect(subject.oidc_initiation_url).to eq oidc_initiation_url
    end

    context "when scopes are invalid" do
      subject do
        bad_scope_request
        json_parse["errors"].first["message"]
      end

      it { is_expected.to eq "cannot contain invalid scope" }
    end
  end

  shared_examples_for "an endpoint that validates public_jwk and public_jwk_url" do
    subject do
      make_request
      return nil if json_parse["errors"].blank?

      json_parse["errors"].first["message"]
    end

    let(:make_request) { raise "set in examples" }
    let(:tool_config_public_jwk) do
      {
        "kty" => "RSA",
        "e" => "AQAB",
        "n" => "2YGluUtCi62Ww_TWB38OE6wTaN...",
        "kid" => "2018-09-18T21:55:18Z",
        "alg" => "RS256",
        "use" => "sig"
      }
    end
    let(:settings) do
      s = super()
      s["public_jwk_url"] = "https://test.com"
      s
    end

    context "when the public jwk is missing" do
      let(:public_jwk) { nil }

      it { is_expected.to be_nil }
    end

    context "when the public jwk url is missing" do
      let(:settings) do
        s = super()
        s.delete("public_jwk_url")
        s
      end

      it { is_expected.to be_nil }
    end

    context "when both the public jwk and public jwk url are missing" do
      let(:public_jwk) { nil }
      let(:settings) do
        s = super()
        s.delete("public_jwk_url")
        s
      end

      it { is_expected.to be_present }
    end

    context "when the public jwk is missing keys" do
      let(:public_jwk) do
        {
          "e" => "AQAB",
          "n" => "2YGluUtCi62Ww_TWB38OE6wTaN...",
          "kid" => "2018-09-18T21:55:18Z"
        }
      end

      it { is_expected.to be_present }
    end

    context "when the public jwk has an invalid alg" do
      let(:public_jwk) do
        {
          "kty" => "RSA",
          "e" => "AQAB",
          "n" => "2YGluUtCi62Ww_TWB38OE6wTaN...",
          "kid" => "2018-09-18T21:55:18Z",
          "alg" => "invalid",
          "use" => "sig"
        }
      end

      it { is_expected.to be_present }
    end

    context "when the public jwk has an invalid kty" do
      let(:public_jwk) do
        {
          "kty" => "invalid",
          "e" => "AQAB",
          "n" => "2YGluUtCi62Ww_TWB38OE6wTaN...",
          "kid" => "2018-09-18T21:55:18Z",
          "alg" => "RS256",
          "use" => "sig"
        }
      end

      it { is_expected.to be_present }
    end
  end

  describe "#create" do
    subject { post :create, params: }

    let(:dev_key_id) { nil }

    it_behaves_like "an action that requires manage developer keys", true

    context "when the tool configuration does not exist" do
      let(:dev_key_id) { developer_key.id }

      it { is_expected.to be_ok }

      it "creates a developer key on the correct account" do
        subject
        key = DeveloperKey.find(json_parse.dig("tool_configuration", "developer_key_id"))
        expect(key.account).to eq sub_account
      end
    end

    it_behaves_like "an endpoint that accepts a settings_url" do
      let(:make_request) { post :create, params: }
    end

    it_behaves_like "an endpoint that validates public_jwk and public_jwk_url" do
      let(:make_request) { post :create, params: }
    end

    it_behaves_like "an endpoint that accepts developer key parameters" do
      let(:bad_scope_params) { { account_id: sub_account.id, developer_key: dev_key_params.merge(scopes: ["invalid scope"]) } }
      let(:make_request) { post :create, params: params.merge({ developer_key: dev_key_params }) }
      let(:bad_scope_request) { post :create, params: params.merge(bad_scope_params) }
    end

    context "without a redirect_uri present" do
      let(:dev_key_params) { super().merge(redirect_uris: nil) }

      it "returns a 400" do
        expect(post(:create, params:)).to have_http_status :bad_request
      end
    end
  end

  describe "#update" do
    subject { put :update, params: }

    let(:target_link_uri) { new_url }

    before do
      tool_configuration
    end

    context do
      it { is_expected.to be_ok }

      it "updates the tool configuration" do
        subject
        new_settings = config_from_response.settings
        expect(new_settings["target_link_uri"]).to eq new_url
      end

      it "sets the privacy level" do
        subject
        expect(config_from_response.privacy_level).to eq "public"
      end
    end

    context "when there are associated tools" do
      shared_examples_for "an action that updates installed tools" do
        subject { installed_tool.reload.workflow_state }

        let(:installed_tool) do
          t = tool_configuration.new_external_tool(context)
          t.save!
          t
        end
        let(:context) { raise "set in examples" }
        let(:privacy_level) { "anonymous" }

        before do
          installed_tool
          put(:update, params:)
          run_jobs
        end

        it { is_expected.to eq privacy_level }
      end

      context "when tool in an account" do
        it_behaves_like "an action that updates installed tools" do
          let(:context) { tool_configuration.developer_key.account }
        end
      end

      context "when tool is in a course" do
        it_behaves_like "an action that updates installed tools" do
          let(:context) { course_model }
        end
      end
    end

    it_behaves_like "an endpoint that validates public_jwk and public_jwk_url" do
      let(:make_request) { put :update, params: }
    end

    it_behaves_like "an action that requires manage developer keys"

    it_behaves_like "an endpoint that accepts developer key parameters" do
      let(:bad_scope_params) { { developer_key: dev_key_params.merge(scopes: ["invalid scope"]) } }
      let(:make_request) { put :update, params: params.merge({ developer_key: dev_key_params }) }
      let(:bad_scope_request) { put :update, params: params.merge(bad_scope_params) }
    end
  end

  describe "#show" do
    subject { get :show, params: params.except(:tool_configuration) }

    before do
      tool_configuration
      account.developer_key_account_bindings
             .find_by(developer_key:)
             .update!(workflow_state: "on")
    end

    context "when tool configuration does not exist" do
      let(:tool_configuration) { nil }

      it_behaves_like "an endpoint that requires an existing tool configuration"
    end

    context "when the requested key is not enable in the context" do
      let(:disabled_key) { DeveloperKey.create!(account: sub_account) }
      let(:dev_key_id) { disabled_key.id }

      it 'responds with "unauthorized"' do
        subject
        expect(response).to be_unauthorized
      end
    end

    context 'when the current user does not have "lti_add_edit"' do
      let(:student) { student_in_course(active_all: true).user }

      before { user_session(student) }

      it 'responds with "unauthorized"' do
        subject
        expect(response).to be_unauthorized
      end
    end

    context "when the tool configuration exists and key is enabled" do
      it "renders the tool configuration" do
        subject
        expect(config_from_response).to eq tool_configuration
      end
    end
  end

  describe "#destroy" do
    subject { delete :destroy, params: params.except(:tool_configuration) }

    before do
      tool_configuration
    end

    it_behaves_like "an action that requires manage developer keys"

    context do
      let(:tool_configuration) { nil }

      it_behaves_like "an endpoint that requires an existing tool configuration"
    end

    context "when the tool configuration exists" do
      it "destroys the tool configuration" do
        subject
        expect(Lti::ToolConfiguration.find_by(id: tool_configuration.id)).to be_nil
      end

      it { is_expected.to be_no_content }
    end
  end
end
