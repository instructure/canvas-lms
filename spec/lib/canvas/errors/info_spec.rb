require 'spec_helper'
require_dependency "canvas/errors/info"
module Canvas
  class Errors
    describe Info do
      let(:request) do
        stub(env: {}, remote_ip: "", query_parameters: {},
             request_parameters: {}, path_parameters: {}, url: '',
             request_method_symbol: '', format: 'HTML', headers: {}, authorization: nil)
      end

      let(:request_context_id){ 'abcdefg1234567'}
      let(:auth_header){ "OAuth oauth_body_hash=\"2jmj7l5rSw0yVb%2FvlWAYkK%2FYBwk%3D\", oauth_consumer_key=\"test_key\", oauth_nonce=\"QFOhAwKHz0UATQSdycHdNkMZYpkhkzU1lYpwvIF3Q8\", oauth_signature=\"QUfER7WBKsq0nzIjJ8Y7iTcDaq0%3D\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"1445980405\", oauth_version=\"1.0\"" }
      let(:account){ stub(global_id: 1122334455) }
      let(:user) { stub(global_id: 5544332211)}
      let(:opts) { { request_context_id: request_context_id, type: 'core_meltdown' }}

      describe 'initialization' do
        it "grabs the request context id if not provided" do
          RequestContextGenerator.stubs(:request_id).returns("zzzzzzz")
          info = described_class.new(request, account, user, {})
          expect(info.rci).to eq("zzzzzzz")
        end
      end

      describe "#to_h" do
        let(:output) do
          info = described_class.new(request, account, user, opts)
          info.to_h
        end

        it 'digests request information' do
          request.stubs(:remote_ip).returns("123.456")
          expect(output[:tags][:account_id]).to eq(1122334455)
          expect(output[:tags][:type]).to eq('core_meltdown')
          expect(output[:extra][:request_context_id]).to eq(request_context_id)
          expect(output[:extra]['REMOTE_ADDR']).to eq("123.456")
        end

        it "pulls in the request method" do
          request.stubs(:request_method_symbol).returns("POST")
          expect(output[:extra][:request_method]).to eq('POST')
        end

        it 'passes format through' do
          request.stubs(:format).returns("JSON")
          expect(output[:extra][:format]).to eq('JSON')
        end

        it 'includes user information' do
          expect(output[:tags][:user_id]).to eq(5544332211)
        end

        it 'passes important headers' do
          request.stubs(:headers).returns({'User-Agent'=>'the-agent'})
          expect(output[:extra][:user_agent]).to eq('the-agent')
        end

        it 'passes oauth header info' do
          request.stubs(:authorization).returns(auth_header)
          check_oauth(output[:extra])
        end
      end

      describe ".useful_http_env_stuff_from_request" do
        it "duplicates to get away from frozen strings out of the request.env" do
          dangerous_hash = {
            "QUERY_STRING".force_encoding(Encoding::ASCII_8BIT).freeze =>
              "somestuff=blah".force_encoding(Encoding::ASCII_8BIT).freeze,
            "HTTP_HOST".force_encoding(Encoding::ASCII_8BIT).freeze =>
              "somehost.com".force_encoding(Encoding::ASCII_8BIT).freeze,
          }
          req = stub(env: dangerous_hash, remote_ip: "", url: "",
                     path_parameters: {}, query_parameters: {}, request_parameters: {})
          env_stuff = described_class.useful_http_env_stuff_from_request(req)
          expect do
            Utf8Cleaner.recursively_strip_invalid_utf8!(env_stuff, true)
          end.not_to raise_error
        end

        it "has a max limit on the request_parameters data size" do
          req = stub(env: {}, remote_ip: "", url: "",
                     path_parameters: {}, query_parameters: {}, request_parameters: {"body" => ("a"*(described_class::MAX_DATA_SIZE*2))})
          env_stuff = described_class.useful_http_env_stuff_from_request(req)
          expect(env_stuff['request_parameters'].size).to eq(described_class::MAX_DATA_SIZE)
        end
      end

      describe ".useful_http_headers" do
        it "returns some oauth header info" do
          req = stub(authorization: auth_header, headers: {})
          oauth_info = described_class.useful_http_headers(req)
          check_oauth(oauth_info)
        end

        it "returns user agent" do
          req = stub(headers: {'User-Agent'=>'the-agent'}, authorization: nil)
          output = described_class.useful_http_headers(req)

          expect(output[:user_agent]).to eq('the-agent')
        end
      end

      def check_oauth(oauth_info)
        expected_info = {
          "oauth_body_hash"=>"2jmj7l5rSw0yVb/vlWAYkK/YBwk=",
          "oauth_consumer_key"=>"test_key",
          "oauth_nonce"=>"QFOhAwKHz0UATQSdycHdNkMZYpkhkzU1lYpwvIF3Q8",
          "oauth_signature"=>"QUfER7WBKsq0nzIjJ8Y7iTcDaq0=",
          "oauth_signature_method"=>"HMAC-SHA1",
          "oauth_timestamp"=>"1445980405",
          "oauth_version"=>"1.0"
        }
        assert_hash_contains(oauth_info, expected_info)
      end
    end
  end
end
