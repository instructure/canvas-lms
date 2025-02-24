# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative "../../spec_helper"

describe MicrosoftSync::LoginService do
  include WebMock::API

  describe ".new_token" do
    before { WebMock.disable_net_connect! }

    after { WebMock.enable_net_connect! }

    context "when not configured" do
      before do
        allow(Rails.application.credentials).to receive(:microsoft_sync).and_return(nil)
      end

      it 'returns an error "MicrosoftSync not configured"' do
        expect do
          described_class.new_token("abc")
        end.to raise_error(/MicrosoftSync not configured/)
      end
    end

    context "when configured" do
      subject { described_class.new_token("mytenant") }

      before do
        allow(InstStatsd::Statsd).to receive(:increment)
        allow(Rails.application.credentials).to receive(:microsoft_sync).and_return({
                                                                                      client_id: "theclientid",
                                                                                      client_secret: "thesecret"
                                                                                    })
      end

      context "when Microsoft returns a response" do
        before do
          WebMock.stub_request(
            :post, "https://login.microsoftonline.com/mytenant/oauth2/v2.0/token"
          ).with(
            body: {
              scope: "https://graph.microsoft.com/.default",
              grant_type: "client_credentials",
              client_id: "theclientid",
              client_secret: "thesecret"
            }
          ).and_return(
            status: response_status,
            body: response_body.to_json,
            headers: { "Content-type" => "application/json" }
          )
        end

        context "(200 status code)" do
          let(:response_status) { 200 }
          let(:response_body) do
            { "token_type" => "Bearer", "expires_in" => 3599, "access_token" => "themagicaltoken" }
          end

          it { is_expected.to eq(response_body) }

          it "increments a statsd metric" do
            subject
            expect(InstStatsd::Statsd).to have_received(:increment).with(
              "microsoft_sync.login_service",
              tags: { status_code: "200" }
            )
          end
        end

        context "(401 status code)" do
          let(:response_status) { 401 }
          let(:response_body) { {} }

          it "increments a statsd metric and raises an HTTPInvalidStatus" do
            expect { subject }.to raise_error(
              MicrosoftSync::Errors::HTTPInvalidStatus,
              /Login service returned 401 for tenant mytenant/
            )
            expect(InstStatsd::Statsd).to have_received(:increment).with(
              "microsoft_sync.login_service",
              tags: { status_code: "401" }
            )
          end
        end

        context "(400 status code, Tenant not found)" do
          let(:response_status) { 400 }
          let(:response_body) do
            {
              "error" => "invalid_request",
              "error_description" =>
                 "AADSTS90002: Tenant 'a.b.c' not found. This may happen if there are no active subscriptions for the tenant. Check to make sure you have the correct tenant ID. Check with your subscription administrator.\r\nTrace ID: etc.",
              "error_codes" => [90_002],
              "timestamp" => "2021-04-28 23:20:12Z",
              "error_uri" => "https://login.microsoftonline.com/error?code=90002"
            }
          end

          it "raises a TenantDoesNotExist (graceful cancel error)" do
            klass = MicrosoftSync::LoginService::TenantDoesNotExist
            msg = /tenant does not exist/
            expect { subject }.to raise_microsoft_sync_graceful_cancel_error(klass, msg)
          end
        end

        context "(400 status code, Tenant not valid domain)" do
          let(:response_status) { 400 }
          let(:response_body) do
            { "error_description" => "AADSTS900023: Specified tenant identifier '---' is neither a valid DNS name, nor a valid external domain.\r\nTrace ID: etc", "error_codes" => [900_023], "timestamp" => "2021-04-28 23:20:23Z", "error_uri" => "https://login.microsoftonline.com/error?code=900023" }
          end

          it "raises a TenantDoesNotExist (graceful cancel error)" do
            klass = MicrosoftSync::LoginService::TenantDoesNotExist
            msg = /tenant does not exist/
            expect { subject }.to raise_microsoft_sync_graceful_cancel_error(klass, msg)
          end
        end

        context "(400 status code, other error message)" do
          let(:response_status) { 400 }
          let(:response_body) { { "error_description" => "foo" } }

          it "raises an HTTPInvalidStatus" do
            expect { subject }.to raise_error(
              MicrosoftSync::Errors::HTTPBadRequest,
              /Login service returned 400 for tenant mytenant/
            )
          end
        end
      end

      context "when an error occurs" do
        it "increments a statsd metric and bubbles up the error" do
          error = SocketError.new
          expect(HTTParty).to receive(:post).and_raise error
          expect { subject }.to raise_error(error)
          expect(InstStatsd::Statsd).to have_received(:increment).with(
            "microsoft_sync.login_service",
            tags: { status_code: "error" }
          )
        end
      end
    end
  end

  describe ".token" do
    shared_examples_for "a cache that uses the specified expiry" do
      it "caches the token until the expiry specified by Microsoft, minus a buffer time" do
        enable_cache do
          expect(described_class).to receive(:new_token).once.with("some_tenant").and_return({
                                                                                               "expires_in" => specified_expiry, "access_token" => "firsttoken"
                                                                                             })

          expect(described_class.token("some_tenant")).to eq("firsttoken")
          Timecop.freeze((specified_expiry - 16).seconds.from_now) do
            expect(described_class.token("some_tenant")).to eq("firsttoken")
          end

          expect(described_class).to receive(:new_token).once.with("some_tenant").and_return({
                                                                                               "expires_in" => specified_expiry, "access_token" => "secondtoken"
                                                                                             })

          Timecop.freeze((specified_expiry - 1).seconds.from_now) do
            expect(described_class.token("some_tenant")).to eq("secondtoken")
          end
        end
      end
    end

    context "when Microsoft uses the default expiry" do
      let(:specified_expiry) { described_class::CACHE_DEFAULT_EXPIRY.to_i }

      it_behaves_like "a cache that uses the specified expiry"
    end

    context "when Microsoft uses a different expiry" do
      let(:specified_expiry) { 123 }

      it_behaves_like "a cache that uses the specified expiry"
    end

    it "caches per tenant" do
      enable_cache do
        expect(described_class).to receive(:new_token).once.with("some_tenant").and_return({
                                                                                             "expires_in" => 123, "access_token" => "firsttoken"
                                                                                           })
        expect(described_class).to receive(:new_token).once.with("another_tenant").and_return({
                                                                                                "expires_in" => 123, "access_token" => "secondtoken"
                                                                                              })
        expect(described_class.token("some_tenant")).to eq("firsttoken")
        expect(described_class.token("some_tenant")).to eq("firsttoken")
        expect(described_class.token("another_tenant")).to eq("secondtoken")
        expect(described_class.token("some_tenant")).to eq("firsttoken")
      end
    end
  end
end
