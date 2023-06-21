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

module Canvas
  class Errors
    describe Info do
      let(:request) do
        double(env: {},
               remote_ip: "",
               query_parameters: {},
               request_parameters: {},
               path_parameters: {},
               url: "",
               request_method_symbol: "",
               format: "HTML",
               headers: {},
               authorization: nil)
      end

      let(:request_context_id) { "abcdefg1234567" }
      let(:auth_header) { "OAuth oauth_body_hash=\"2jmj7l5rSw0yVb%2FvlWAYkK%2FYBwk%3D\", oauth_consumer_key=\"test_key\", oauth_nonce=\"QFOhAwKHz0UATQSdycHdNkMZYpkhkzU1lYpwvIF3Q8\", oauth_signature=\"QUfER7WBKsq0nzIjJ8Y7iTcDaq0%3D\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"1445980405\", oauth_version=\"1.0\"" }
      let(:account) { double(global_id: 1_122_334_455) }
      let(:user) { double(global_id: 5_544_332_211) }
      let(:opts) { { request_context_id:, type: "core_meltdown" } }

      describe "initialization" do
        it "grabs the request context id if not provided" do
          allow(RequestContextGenerator).to receive(:request_id).and_return("zzzzzzz")
          info = described_class.new(request, account, user, {})
          expect(info.rci).to eq("zzzzzzz")
        end
      end

      describe "#to_h" do
        let(:output) do
          info = described_class.new(request, account, user, opts)
          info.to_h
        end

        it "digests request information" do
          allow(request).to receive(:remote_ip).and_return("123.456")
          expect(output[:tags][:account_id]).to eq(1_122_334_455)
          expect(output[:tags][:type]).to eq("core_meltdown")
          expect(output[:extra][:request_context_id]).to eq(request_context_id)
          expect(output[:extra]["REMOTE_ADDR"]).to eq("123.456")
        end

        it "pulls in the request method" do
          allow(request).to receive(:request_method_symbol).and_return("POST")
          expect(output[:extra][:request_method]).to eq("POST")
        end

        it "passes format through" do
          allow(request).to receive(:format).and_return("JSON")
          expect(output[:extra][:format]).to eq("JSON")
        end

        it "includes user information" do
          expect(output[:tags][:user_id]).to eq(5_544_332_211)
        end

        it "passes important headers" do
          allow(request).to receive(:headers).and_return({ "User-Agent" => "the-agent" })
          expect(output[:extra][:user_agent]).to eq("the-agent")
        end

        it "passes oauth header info" do
          allow(request).to receive(:authorization).and_return(auth_header)
          check_oauth(output[:extra])
        end
      end

      describe ".useful_http_env_stuff_from_request" do
        it "duplicates to get away from frozen strings out of the request.env" do
          dangerous_hash = {
            (+"QUERY_STRING").force_encoding(Encoding::ASCII_8BIT).freeze =>
              (+"somestuff=blah").force_encoding(Encoding::ASCII_8BIT).freeze,
            (+"HTTP_HOST").force_encoding(Encoding::ASCII_8BIT).freeze =>
              (+"somehost.com").force_encoding(Encoding::ASCII_8BIT).freeze,
          }
          req = double(env: dangerous_hash,
                       remote_ip: "",
                       url: "",
                       path_parameters: {},
                       query_parameters: {},
                       request_parameters: {})
          env_stuff = described_class.useful_http_env_stuff_from_request(req)
          expect do
            Utf8Cleaner.recursively_strip_invalid_utf8!(env_stuff, true)
          end.not_to raise_error
        end

        it "has a max limit on the request_parameters data size" do
          req = double(env: {},
                       remote_ip: "",
                       url: "",
                       path_parameters: {},
                       query_parameters: {},
                       request_parameters: { "body" => ("a" * (described_class::MAX_DATA_SIZE * 2)) })
          env_stuff = described_class.useful_http_env_stuff_from_request(req)
          expect(env_stuff["request_parameters"].size).to eq(described_class::MAX_DATA_SIZE)
        end
      end

      describe ".useful_http_headers" do
        it "returns some oauth header info" do
          req = double(authorization: auth_header, headers: {})
          oauth_info = described_class.useful_http_headers(req)
          check_oauth(oauth_info)
        end

        it "returns user agent" do
          req = double(headers: { "User-Agent" => "the-agent" }, authorization: nil)
          output = described_class.useful_http_headers(req)

          expect(output[:user_agent]).to eq("the-agent")
        end
      end

      def check_oauth(oauth_info)
        expected_info = {
          "oauth_body_hash" => "2jmj7l5rSw0yVb/vlWAYkK/YBwk=",
          "oauth_consumer_key" => "test_key",
          "oauth_nonce" => "QFOhAwKHz0UATQSdycHdNkMZYpkhkzU1lYpwvIF3Q8",
          "oauth_signature" => "QUfER7WBKsq0nzIjJ8Y7iTcDaq0=",
          "oauth_signature_method" => "HMAC-SHA1",
          "oauth_timestamp" => "1445980405",
          "oauth_version" => "1.0"
        }
        assert_hash_contains(oauth_info, expected_info)
      end
    end
  end
end
