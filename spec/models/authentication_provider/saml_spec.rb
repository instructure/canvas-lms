# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe AuthenticationProvider::SAML do
  include AccountDomainSpecHelper

  before do
    skip("requires SAML extension") unless AuthenticationProvider::SAML.enabled?
    stub_host_for_environment_specific_domain("test.host")
    @account = Account.create!(name: "account")
    @file_that_exists = File.expand_path(__FILE__)
  end

  it "sets the entity_id with the current domain" do
    allow(HostUrl).to receive(:default_host).and_return("bob.cody.instructure.com")
    stub_host_for_environment_specific_domain("bob.cody.instructure.com")
    @aac = @account.authentication_providers.create!(auth_type: "saml")
    expect(@aac.entity_id).to eq "http://bob.cody.instructure.com/saml2"
    @account.reload
    expect(@account.settings[:saml_entity_id]).to eq "http://bob.cody.instructure.com/saml2"
  end

  it "uses the entity id set on the account" do
    @account.settings[:saml_entity_id] = "my_entity"
    @account.save!
    @aac = @account.authentication_providers.create!(auth_type: "saml")
    expect(@aac.entity_id).to eq "my_entity"
  end

  it "unsets the entity id when it gets deleted" do
    @account.settings[:saml_entity_id] = "my_entity"
    @account.save!
    @aac = @account.authentication_providers.create!(auth_type: "saml")
    @aac.destroy
    expect(@account.settings).not_to have_key(:saml_entity_id)
  end

  it "does not unset the entity id when it gets deleted if another config exists" do
    @account.settings[:saml_entity_id] = "my_entity"
    @account.save!
    @aac = @account.authentication_providers.create!(auth_type: "saml")
    @aac2 = @account.authentication_providers.create!(auth_type: "saml")
    @aac.destroy
    expect(@account.settings[:saml_entity_id]).to eq "my_entity"
  end

  it "sets requested_authn_context to nil if empty string" do
    @aac = @account.authentication_providers.create!(auth_type: "saml", requested_authn_context: "")
    expect(@aac.requested_authn_context).to be_nil
  end

  it "allows requested_authn_context to be set to anything" do
    @aac = @account.authentication_providers.create!(auth_type: "saml", requested_authn_context: "anything")
    expect(@aac.requested_authn_context).to eq "anything"
  end

  describe "validation" do
    it "validates log_out_url if provided" do
      ap = Account.default.authentication_providers.new(auth_type: "saml")
      ap.log_out_url = "https:// your.adfserverurl.com /adfs/ls/"
      expect(ap).not_to be_valid
      expect(ap.errors.attribute_names).to eq [:log_out_url]
    end
  end

  describe "download_metadata" do
    it "requires an entity id for InCommon" do
      saml = Account.default.authentication_providers.new(auth_type: "saml",
                                                          metadata_uri: AuthenticationProvider::SAML::InCommon::URN)
      expect(saml).not_to be_valid
      expect(saml.errors.attribute_names).to eq [:idp_entity_id]
      expect(saml.errors.full_messages).to eq ["IdP Entity ID can't be blank"]
    end

    it "changes InCommon URI to the URN for it" do
      saml = Account.default.authentication_providers.new(auth_type: "saml",
                                                          metadata_uri: AuthenticationProvider::SAML::InCommon.endpoint)
      expect(saml).not_to be_valid
      expect(saml.metadata_uri).to eq AuthenticationProvider::SAML::InCommon::URN
    end

    it "populates InCommon metadata from MDQ-constructed URI" do
      saml = Account.default.authentication_providers.new(auth_type: "saml",
                                                          metadata_uri: AuthenticationProvider::SAML::InCommon::URN,
                                                          idp_entity_id: "urn:mace:incommon:myschool.edu")
      expect(saml).to receive(:populate_from_metadata_url).with("https://mdq.incommon.org/entities/urn%3Amace%3Aincommon%3Amyschool.edu")
      saml.save!
    end

    it "overwrite sig_alg field as appropriate" do
      # defaults to RSA-SHA256
      saml = AuthenticationProvider::SAML.new
      expect(saml.sig_alg).to eq SAML2::Bindings::HTTPRedirect::SigAlgs::RSA_SHA256

      entity = SAML2::Entity.new
      idp = SAML2::IdentityProvider.new
      entity.roles << idp

      # not specified; ignore
      saml.populate_from_metadata(entity)
      expect(saml.sig_alg).to eq SAML2::Bindings::HTTPRedirect::SigAlgs::RSA_SHA256

      # don't overwrite when requested
      idp.want_authn_requests_signed = true
      saml.populate_from_metadata(entity)
      expect(saml.sig_alg).to eq SAML2::Bindings::HTTPRedirect::SigAlgs::RSA_SHA256

      # always sets to nil if they don't want them signed
      idp.want_authn_requests_signed = false
      saml.populate_from_metadata(entity)
      expect(saml.sig_alg).to be_nil

      # defaults to RSA-SHA1 when we don't have a value
      idp.want_authn_requests_signed = true
      saml.populate_from_metadata(entity)
      expect(saml.sig_alg).to eq SAML2::Bindings::HTTPRedirect::SigAlgs::RSA_SHA1
    end

    context "identifier format" do
      let(:saml) { AuthenticationProvider::SAML.new }
      let(:entity) { SAML2::Entity.new }
      let(:idp) { SAML2::IdentityProvider.new }

      before { entity.roles << idp }

      it "overwrites if metadata only has one" do
        idp.name_id_formats << SAML2::NameID::Format::EMAIL_ADDRESS
        expect(saml.identifier_format).to eq(SAML2::NameID::Format::UNSPECIFIED)
        saml.populate_from_metadata(entity)
        expect(saml.identifier_format).to eq(SAML2::NameID::Format::EMAIL_ADDRESS)
      end

      it "does not overwrite if there are multiple and we're set to unspecified" do
        idp.name_id_formats << SAML2::NameID::Format::EMAIL_ADDRESS
        idp.name_id_formats << SAML2::NameID::Format::TRANSIENT
        saml.identifier_format = SAML2::NameID::Format::UNSPECIFIED
        saml.populate_from_metadata(entity)
        expect(saml.identifier_format).to eq(SAML2::NameID::Format::UNSPECIFIED)
      end

      it "sets to unspecified if there are multiple and we're set to something else" do
        idp.name_id_formats << SAML2::NameID::Format::EMAIL_ADDRESS
        idp.name_id_formats << SAML2::NameID::Format::TRANSIENT
        saml.identifier_format = SAML2::NameID::Format::PERSISTENT
        saml.populate_from_metadata(entity)
        expect(saml.identifier_format).to eq(SAML2::NameID::Format::UNSPECIFIED)
      end

      it "does not overwrite if there are multiple and we're set to one of the valid ones" do
        idp.name_id_formats << SAML2::NameID::Format::EMAIL_ADDRESS
        idp.name_id_formats << SAML2::NameID::Format::TRANSIENT
        saml.identifier_format = SAML2::NameID::Format::TRANSIENT
        saml.populate_from_metadata(entity)
        expect(saml.identifier_format).to eq(SAML2::NameID::Format::TRANSIENT)
      end
    end
  end

  describe ".resolve_saml_key_path" do
    it "returns nil for nil" do
      expect(AuthenticationProvider::SAML.resolve_saml_key_path(nil)).to be_nil
    end

    it "returns nil for nonexistent paths" do
      expect(AuthenticationProvider::SAML.resolve_saml_key_path("/tmp/does_not_exist")).to be_nil
    end

    it "returns abolute paths unmodified when the file exists" do
      Tempfile.open("samlkey") do |samlkey|
        expect(AuthenticationProvider::SAML.resolve_saml_key_path(samlkey.path)).to eq samlkey.path
      end
    end

    it "interprets relative paths from the config dir" do
      expect(AuthenticationProvider::SAML.resolve_saml_key_path("initializers")).to eq Rails.root.join("config/initializers").to_s
    end
  end

  describe "#user_logout_redirect" do
    it "sends you to the logout landing page if the IdP doesn't support SLO" do
      controller = double
      allow(controller).to receive(:session).and_return({})
      expect(controller).to receive(:logout_url).and_return("bananas")

      aac = @account.authentication_providers.create!(auth_type: "saml")
      @account.authentication_providers.first.destroy
      expect(aac.user_logout_redirect(controller, nil)).to eq "bananas"
    end

    it "sends you to the login page if the IdP doesn't support SLO, but Canvas auth is default" do
      controller = double
      allow(controller).to receive(:session).and_return({})
      expect(controller).to receive(:login_url).and_return("bananas")

      aac = @account.authentication_providers.create!(auth_type: "saml")
      expect(aac.user_logout_redirect(controller, nil)).to eq "bananas"
    end
  end

  describe ".sp_metadata_for_account" do
    it "includes federated attributes" do
      ap = @account.authentication_providers.build(auth_type: "saml")
      ap.federated_attributes = { "display_name" => { "attribute" => "name" } }
      ap.save!
      # ignore invalid saml key configuration in specs
      allow(AuthenticationProvider::SAML).to receive(:private_keys).and_return({})
      entity = AuthenticationProvider::SAML.sp_metadata_for_account(@account)
      expect(entity.roles.last.attribute_consuming_services.length).to eq 1
      expect(entity.roles.last.attribute_consuming_services.first.requested_attributes.length).to eq 1
      expect(entity.roles.last.attribute_consuming_services.first.requested_attributes.first.name).to eq "name"
    end

    it "signals if requests will be signed" do
      ap = @account.authentication_providers.new(auth_type: "saml")
      ap.sig_alg = "rsa-sha1"
      ap.save!
      # ignore invalid saml key configuration in specs
      allow(AuthenticationProvider::SAML).to receive(:private_keys).and_return({})
      entity = AuthenticationProvider::SAML.sp_metadata_for_account(@account)
      expect(entity.roles.last.authn_requests_signed?).to be true
    end

    it "signals if requests will not be signed" do
      ap = @account.authentication_providers.new(auth_type: "saml")
      ap.sig_alg = nil
      ap.save!
      # ignore invalid saml key configuration in specs
      allow(AuthenticationProvider::SAML).to receive(:private_keys).and_return({})
      entity = AuthenticationProvider::SAML.sp_metadata_for_account(@account)
      expect(entity.roles.last.authn_requests_signed?).to be false
    end

    it "does not signals if requests will be signed with mixed providers" do
      ap = @account.authentication_providers.new(auth_type: "saml")
      ap.sig_alg = "rsa-sha1"
      ap.save!
      ap = @account.authentication_providers.new(auth_type: "saml")
      ap.sig_alg = nil
      ap.save!
      # ignore invalid saml key configuration in specs
      allow(AuthenticationProvider::SAML).to receive(:private_keys).and_return({})
      entity = AuthenticationProvider::SAML.sp_metadata_for_account(@account)
      expect(entity.roles.last.authn_requests_signed?).to be_nil
    end
  end

  describe "#persist_metadata" do
    it "generates metadata on save when none exists" do
      aac = @account.authentication_providers.create!(auth_type: "saml")
      expect(aac.settings["metadata"]).to be_present
      expect(aac.settings["metadata_source"]).to eq("generated")
    end

    it "regenerates auto-generated metadata on save" do
      aac = @account.authentication_providers.create!(auth_type: "saml", idp_entity_id: "https://original.example.com")
      expect(aac.settings["metadata"]).to include("https://original.example.com")

      aac.update!(idp_entity_id: "https://updated.example.com")
      expect(aac.settings["metadata"]).to be_present
      expect(aac.settings["metadata_source"]).to eq("generated")
      expect(aac.settings["metadata"]).to include("https://updated.example.com")
    end

    it "regenerates synthetic metadata when metadata_uri is removed" do
      aac = @account.authentication_providers.create!(auth_type: "saml", idp_entity_id: "https://example.com")
      # simulate having previously downloaded real metadata from a metadata_uri
      real_metadata = aac.idp_metadata.to_xml.to_s
      aac.update_columns(settings: aac.settings.merge("metadata" => real_metadata, "metadata_source" => "url", "metadata_uri" => "https://metadata.example.com"))

      aac.reload
      expect(aac.settings["metadata_source"]).to eq("url")

      aac.update!(metadata_uri: "")
      expect(aac.settings["metadata_source"]).to eq("generated")
    end

    it "does not overwrite user-provided metadata" do
      aac = @account.authentication_providers.create!(auth_type: "saml")
      user_metadata = aac.idp_metadata.to_xml.to_s
      aac.settings["metadata"] = user_metadata
      aac.settings["metadata_source"] = "manual"
      aac.save!

      expect(aac.settings["metadata"]).to eq(user_metadata)
      expect(aac.settings["metadata_source"]).to eq("manual")
    end
  end

  describe "#validate_metadata" do
    it "rejects invalid XML metadata" do
      aac = @account.authentication_providers.create!(auth_type: "saml")
      aac.settings["metadata"] = "not valid xml"
      aac.settings["metadata_source"] = "manual"
      expect(aac).not_to be_valid
      expect(aac.errors[:metadata]).to be_present
    end

    it "accepts valid SAML entity metadata" do
      aac = @account.authentication_providers.create!(auth_type: "saml")
      expect(aac.settings["metadata"]).to be_present
      expect(aac).to be_valid
    end
  end

  describe "#idp_metadata" do
    it "returns parsed metadata from settings when present" do
      aac = @account.authentication_providers.create!(auth_type: "saml")
      # After save, settings["metadata"] should be populated
      result = aac.idp_metadata
      expect(result).to be_a(SAML2::Entity)
    end

    it "falls back to synthetic metadata when settings metadata is blank" do
      aac = @account.authentication_providers.create!(auth_type: "saml")
      aac.settings.delete("metadata")
      result = aac.idp_metadata
      expect(result).to be_a(SAML2::Entity)
    end
  end

  describe "#populate_from_metadata_xml" do
    let(:entity) do
      entity = SAML2::Entity.new
      entity.entity_id = "https://idp.example.com"
      idp = SAML2::IdentityProvider.new
      idp.single_sign_on_services << SAML2::Endpoint.new("https://idp.example.com/sso",
                                                         SAML2::Bindings::HTTPRedirect::URN)
      entity.roles << idp
      entity
    end

    it "stores the raw XML in settings with manual source" do
      aac = @account.authentication_providers.create!(auth_type: "saml")
      aac.populate_from_metadata_xml(entity.to_xml.to_s)
      expect(aac.settings["metadata"]).to be_present
      expect(aac.settings["metadata_source"]).to eq("manual")
    end

    it "stores the source as url when specified" do
      aac = @account.authentication_providers.create!(auth_type: "saml")
      aac.populate_from_metadata_xml(entity.to_xml.to_s, source: "url")
      expect(aac.settings["metadata_source"]).to eq("url")
    end
  end

  context "response collection" do
    skip "requires Redis" unless CanvasCache::Redis.enabled?

    let(:ap) { @account.authentication_providers.create!(auth_type: "saml") }
    let(:response) { instance_double(SAML2::Response, errors: []) }

    before do
      ap.settings["collect_responses"] = true
    end

    it "does nothing if not enabled" do
      ap.settings.delete("collect_responses")

      ap.collect_response(response, "<xml>")
      expect(ap.collected_responses).to eql []
    end

    it "stores and retrieves SAML responses" do
      responses = Array.new(12) { |i| "<xml#{i}>" }
      responses.each do |resp|
        ap.collect_response(response, resp)
      end
      # defaults to keeping 10
      expect(ap.collected_responses).to eql(responses[2..].map { |r| { "xml" => r, "errors" => "" } })
    end

    it "limits it if configured" do
      ap.settings["collect_responses"] = 3
      responses = Array.new(5) { |i| "<xml#{i}>" }
      responses.each do |resp|
        ap.collect_response(response, resp)
      end
      expect(ap.collected_responses).to eql(responses[2..].map { |r| { "xml" => r, "errors" => "" } })
    end

    it "collects a response with errors" do
      allow(response).to receive(:errors).and_return(["bad signature"])
      ap.collect_response(response, "<xml_with_errors>")
      expect(ap.collected_responses).to eql([{ "xml" => "<xml_with_errors>", "errors" => "bad signature" }])
    end

    it "collects a response with additional fields" do
      ap.collect_response(response, "<xml>", more: "data")
      expect(ap.collected_responses).to eql([{ "xml" => "<xml>", "errors" => "", "more" => "data" }])
    end
  end
end
