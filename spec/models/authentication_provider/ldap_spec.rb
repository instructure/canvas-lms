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

describe AuthenticationProvider::LDAP do
  it "does not escape auth_filter" do
    @account = Account.new
    @account_config = @account.authentication_providers.build(
      auth_type: "ldap",
      ldap_filter: "(&(!(userAccountControl:1.2.840.113556.1.4.803:=2))(sAMAccountName={{login}}))"
    )

    @account_config.save
    expect(@account_config.auth_filter).to eql("(&(!(userAccountControl:1.2.840.113556.1.4.803:=2))(sAMAccountName={{login}}))")
  end

  describe "#test_ldap_search" do
    it "validates filter syntax" do
      aac = AuthenticationProvider::LDAP.new(account: Account.new)
      aac.auth_type = "ldap"
      aac.ldap_filter = "bob"
      expect(aac.test_ldap_search).to be_falsey
      expect(aac.errors.full_messages.join).to match(/Invalid filter syntax/)

      aac.errors.clear
      aac.ldap_filter = "(sAMAccountName={{login}})"
      expect(aac.test_ldap_search).to be_falsey
      expect(aac.errors.full_messages.join).not_to match(/Invalid filter syntax/)
    end
  end

  describe "#auth_over_tls" do
    let(:account) { Account.create }
    let(:auth_provider) { account.authentication_providers.create(auth_type: "ldap", auth_over_tls: "false") }

    context "when verify_ldap_certs is enabled" do
      before do
        account.set_feature_flag!(:verify_ldap_certs, "on")
      end

      it "returns simple_tls instead of a falsey value" do
        expect(auth_provider.auth_over_tls).to eq("simple_tls")
      end
    end
  end

  describe "#test_tls_cert_validity" do
    let(:account) { Account.create }
    let(:auth_provider) { account.authentication_providers.create(auth_type: "ldap", auth_filter: "") }

    context "when the connection fails even without verification" do
      it "returns nil" do
        allow_any_instance_of(Net::LDAP).to receive(:bind_as).and_raise(Net::LDAP::Error.new("Some error"))
        expect(auth_provider.test_tls_cert_validity).to be_nil
      end
    end

    context "when the connection fails only with verification" do
      it "returns false, with the exception message" do
        ldap = instance_double("Net::LDAP")
        allow(ldap).to receive_messages({ :host= => nil, :port= => nil, :base= => nil, :base => nil, :auth => nil })
        allow(ldap).to receive(:bind_as).and_invoke(->(_) { false }, ->(_) { raise Net::LDAP::Error, "Some error" })
        allow(Net::LDAP).to receive(:new).and_return(ldap)
        expect(auth_provider.test_tls_cert_validity).to eq([false, "Some error"])
      end
    end

    context "when the connection doesn't fail" do
      it "returns true, with no exception message" do
        ldap = instance_double("Net::LDAP")
        allow(ldap).to receive_messages({ :host= => nil, :port= => nil, :base= => nil, :base => nil, :auth => nil })
        allow(ldap).to receive(:bind_as).and_return(false).twice
        allow(Net::LDAP).to receive(:new).and_return(ldap)
        expect(auth_provider.test_tls_cert_validity).to eq([true, nil])
      end
    end
  end

  describe "#ldap_connection" do
    let(:account) { Account.create }
    let(:auth_provider) { account.authentication_providers.create(auth_type: "ldap") }

    context "when verify_ldap_certs is enabled" do
      before do
        account.set_feature_flag!(:verify_ldap_certs, "on")
      end

      it "uses default OpenSSL options" do
        encryption_args = auth_provider.ldap_connection.instance_variable_get(:@encryption)
        expect(encryption_args[:tls_options]).to eq(OpenSSL::SSL::SSLContext::DEFAULT_PARAMS)
      end

      context "and verify_tls_certs kwarg is false" do
        it "doesn't verify anything" do
          encryption_args = auth_provider.ldap_connection(verify_tls_certs: false).instance_variable_get(:@encryption)
          expect(encryption_args[:tls_options]).to eq({ verify_mode: OpenSSL::SSL::VERIFY_NONE, verify_hostname: false })
        end
      end
    end

    context "when verify_ldap_certs is disabled" do
      before do
        account.set_feature_flag!(:verify_ldap_certs, "off")
      end

      it "doesn't verify anything" do
        encryption_args = auth_provider.ldap_connection.instance_variable_get(:@encryption)
        expect(encryption_args[:tls_options]).to eq({ verify_mode: OpenSSL::SSL::VERIFY_NONE, verify_hostname: false })
      end

      context "and verify_tls_certs kwarg is true" do
        it "uses default OpenSSL options" do
          encryption_args = auth_provider.ldap_connection(verify_tls_certs: true).instance_variable_get(:@encryption)
          expect(encryption_args[:tls_options]).to eq(OpenSSL::SSL::SSLContext::DEFAULT_PARAMS)
        end
      end
    end
  end

  context "#ldap_bind_result" do
    before(:once) do
      @account = Account.new
      @account.save!
      @aac = AuthenticationProvider::LDAP.new(account: @account)
      @aac.auth_type = "ldap"
      @aac.ldap_filter = "bob"
      @aac.save!
    end

    it "does not attempt to bind with a blank password" do
      aac = AuthenticationProvider::LDAP.new
      aac.auth_type = "ldap"
      aac.ldap_filter = "bob"
      expect(aac).not_to receive(:ldap_connection)
      aac.ldap_bind_result("test", "")
    end

    context "statsd" do
      before do
        @ldap = double
        allow(@ldap).to receive(:base)
        allow(@aac).to receive_messages(ldap_connection: @ldap,
                                        ldap_filter: nil,
                                        account_id: 1,
                                        global_id: 2,
                                        should_send_to_statsd?: true)
        allow(InstStatsd::Statsd).to receive(:increment)
      end

      it "sends to statsd on success" do
        allow(@ldap).to receive(:bind_as).and_return(true)
        @aac.ldap_bind_result("user", "pass")
        expect(InstStatsd::Statsd).to have_received(:increment).with(
          "#{@aac.send(:statsd_prefix)}.ldap_success",
          short_stat: "ldap_success",
          tags: { account_id: Shard.global_id_for(@aac.account_id), auth_provider_id: @aac.global_id }
        )
      end

      it "sends to statsd on failure" do
        allow(@ldap).to receive(:bind_as).and_return(false)
        @aac.ldap_bind_result("user", "pass")
        expect(InstStatsd::Statsd).to have_received(:increment).with(
          "#{@aac.send(:statsd_prefix)}.ldap_failure",
          short_stat: "ldap_failure",
          tags: { account_id: Shard.global_id_for(@aac.account_id), auth_provider_id: @aac.global_id }
        )
      end

      it "sends to statsd on timeout" do
        allow(@ldap).to receive(:bind_as).and_raise(Timeout::Error)
        @aac.ldap_bind_result("user", "pass")
        expect(InstStatsd::Statsd).to have_received(:increment).with(
          "#{@aac.send(:statsd_prefix)}.ldap_timeout",
          short_stat: "ldap_timeout",
          tags: {
            account_id: Shard.global_id_for(@aac.account_id),
            auth_provider_id: @aac.global_id
          }
        )
      end

      it "sends to statsd on exception" do
        allow(@ldap).to receive(:bind_as).and_raise(StandardError)
        @aac.ldap_bind_result("user", "pass")
        expect(InstStatsd::Statsd).to have_received(:increment).with(
          "#{@aac.send(:statsd_prefix)}.ldap_error",
          short_stat: "ldap_error",
          tags: {
            account_id: Shard.global_id_for(@aac.account_id),
            auth_provider_id: @aac.global_id
          }
        )
      end
    end
  end
end
