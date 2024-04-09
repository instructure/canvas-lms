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
  before do
    skip("requires SAML extension") unless AuthenticationProvider::SAML.enabled?
    @account = Account.create!(name: "account")
    @file_that_exists = File.expand_path(__FILE__)
  end

  it "sets the entity_id with the current domain" do
    allow(HostUrl).to receive(:default_host).and_return("bob.cody.instructure.com")
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
      expect(ap.errors.keys).to eq [:log_out_url]
    end
  end

  describe "download_metadata" do
    it "requires an entity id for InCommon" do
      saml = Account.default.authentication_providers.new(auth_type: "saml",
                                                          metadata_uri: AuthenticationProvider::SAML::InCommon::URN)
      expect(saml).not_to be_valid
      expect(saml.errors.first.first).to eq :idp_entity_id
    end

    it "changes InCommon URI to the URN for it" do
      saml = Account.default.authentication_providers.new(auth_type: "saml",
                                                          metadata_uri: AuthenticationProvider::SAML::InCommon.endpoint)
      expect(saml).not_to be_valid
      expect(saml.metadata_uri).to eq AuthenticationProvider::SAML::InCommon::URN
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
end
