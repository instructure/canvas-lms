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

describe TokenScopes do
  before do
    # We want to force the usage of the fallback scope mapper here, not the generated version
    stub_const("ApiScopeMapper", ApiScopeMapperFallback)
  end

  describe ".named_scopes" do
    let!(:user_info_scope) { TokenScopes.named_scopes.find { |s| s[:scope] == TokenScopes::USER_INFO_SCOPE[:scope] } }
    let(:new_quizzes_scopes) { TokenScopes.named_scopes.filter { |s| s[:path]&.include? "api/quiz/v1" } }

    it "includes the resource_name" do
      expect(user_info_scope[:resource_name].to_s).to eq "oauth2"
    end

    it "includes the resource" do
      expect(user_info_scope[:resource].to_s).to eq "oauth2"
    end

    it "includes a CD2 Peer Services scope" do
      scope = TokenScopes.named_scopes.find { |s| s[:scope] == TokenScopes::CD2_SCOPE[:scope] }
      expect(scope).not_to be_nil
      expect(scope[:resource_name].to_s).to eq "peer_services"
    end

    it "doesn't include scopes without a name" do
      TokenScopes.instance_variable_set(:@_named_scopes, nil) # we need to make sure that we generate a new list
      allow(ApiScopeMapper).to receive(:name_for_resource).and_return(nil)
      expect(TokenScopes.named_scopes).to eq []
      TokenScopes.instance_variable_set(:@_named_scopes, nil) # we don't want to have this version stored
    end

    it "includes new quizzes API scopes" do
      expect(new_quizzes_scopes).not_to be_empty
    end
  end

  describe ".all_scopes" do
    it "includes the userinfo scope" do
      expect(TokenScopes.all_scopes).to include TokenScopes::USER_INFO_SCOPE[:scope]
    end

    it "includes the hidden scope" do
      expect(TokenScopes.all_scopes).to include(*TokenScopes::LTI_HIDDEN_SCOPES.keys)
    end

    it "includes the lti scopes" do
      expect(TokenScopes.all_scopes).to include(*TokenScopes::LTI_SCOPES.keys)
    end

    it "includes the postMessage scopes" do
      expect(TokenScopes.all_scopes).to include(*TokenScopes::LTI_POSTMESSAGE_SCOPES)
    end

    describe "generated_scopes" do
      let!(:generated_scopes) do
        TokenScopes.all_scopes - [
          TokenScopes::USER_INFO_SCOPE[:scope],
          TokenScopes::CD2_SCOPE[:scope],
          *TokenScopes::LTI_SCOPES.keys,
          *TokenScopes::LTI_HIDDEN_SCOPES.keys
        ]
      end

      it "formats the scopes with url:http_verb|api_path" do
        generated_scopes.each do |scope|
          expect(%r{^url:(?:GET|OPTIONS|POST|PUT|PATCH|DELETE)\|/api/.+} =~ scope).not_to be_nil
        end
      end

      it "does not include the optional format part of the route path" do
        generated_scopes.each do |scope|
          expect(scope.include?("(.:format)")).to be false
        end
      end
    end
  end

  describe "testing scopes in sync with documentation and typescript scopes (via YAML file)" do
    let(:tools_intro_md_content) { Rails.root.join("doc/api/tools_intro.md").read }

    let(:scopes_from_yaml_file) do
      arr = YAML.load_file(Rails.root.join("spec/fixtures/lti/lti_scopes.yml"))
      arr.to_h { |scope| [scope["scope"], scope.except("scope")] }
    end

    let(:documented_scopes_and_descs) do
      scopes_from_yaml_file
        .reject { |_scope, obj| obj["undocumented"] }
        .transform_values { it["description"] }
    end

    let(:undocumented_hidden_scopes_and_descs) do
      scopes_from_yaml_file
        .select { |_scope, obj| obj["undocumented"] }
        .transform_values { it["description"] }
    end

    describe "LTI_SCOPES" do
      it "contains exactly the documented scopes in the YAML file" do
        expect(TokenScopes::LTI_SCOPES.keys).to match_array(documented_scopes_and_descs.keys)
      end

      it "matches the descriptions of the scopes in the YAML file (except the Ruby descriptions have a trailing period)" do
        TokenScopes::LTI_SCOPES.each do |scope, description|
          expect(description).to eq(documented_scopes_and_descs[scope] + ".")
        end
      end

      it "matches the list and documentation in tools_intro.md" do
        TokenScopes::LTI_SCOPES.each do |scope, description|
          expect(tools_intro_md_content).to include(scope)
          desc_without_period = description.gsub(/\.$/, "")
          expect(tools_intro_md_content).to include(desc_without_period)
        end
      end
    end

    describe "LTI_HIDDEN_SCOPES" do
      it "contains exactly the undocumented hidden scopes in the YAML file" do
        expect(TokenScopes::LTI_HIDDEN_SCOPES.keys).to match_array(undocumented_hidden_scopes_and_descs.keys)
      end

      it "matches the descriptions of the undocumented hidden scopes in the YAML file (except the Ruby descriptions have a trailing period)" do
        TokenScopes::LTI_HIDDEN_SCOPES.each do |scope, description|
          expect(description).to eq(undocumented_hidden_scopes_and_descs[scope] + ".")
        end
      end

      it "contains only scopes that are not documented in tools_intro.md" do
        TokenScopes::LTI_HIDDEN_SCOPES.each do |scope, description|
          expect(tools_intro_md_content).not_to include(scope)
          desc_without_period = description.gsub(/\.$/, "")
          expect(tools_intro_md_content).not_to include(desc_without_period)
        end
      end
    end

    describe "ALL_LTI_SCOPES" do
      it "consists of LTI_SCOPES and LTI_HIDDEN_SCOPES keys" do
        expect(TokenScopes::ALL_LTI_SCOPES).to match_array(TokenScopes::LTI_SCOPES.keys + TokenScopes::LTI_HIDDEN_SCOPES.keys)
      end
    end
  end

  describe "public scopes" do
    let(:account) { instance_double(Account, feature_enabled?: true) }
    let(:scopes_hash) { TokenScopes.public_lti_scopes_hash_for_account(account) }
    let(:scopes_list) { TokenScopes.public_lti_scopes_urls_for_account(account) }

    def mock_ff_off(flag)
      allow(account).to receive(:feature_enabled?).with(flag).and_return(false)
    end

    context "with all flags on" do
      it "returns all scopes" do
        expect(scopes_hash).to eq TokenScopes::LTI_SCOPES
        expect(scopes_list).to eq TokenScopes::LTI_SCOPES.keys
      end
    end

    context "with the lti_asset_processor flag off" do
      before { mock_ff_off(:lti_asset_processor) }

      it "is missing the asset scopes" do
        asset_scopes = [
          TokenScopes::LTI_ASSET_READ_ONLY_SCOPE,
          TokenScopes::LTI_ASSET_REPORT_SCOPE,
          TokenScopes::LTI_EULA_USER_SCOPE,
          TokenScopes::LTI_EULA_DEPLOYMENT_SCOPE
        ]
        expect(scopes_hash).to eq TokenScopes::LTI_SCOPES.except(*asset_scopes)
        expect(scopes_list).to eq TokenScopes::LTI_SCOPES.keys - asset_scopes
      end
    end
  end
end
