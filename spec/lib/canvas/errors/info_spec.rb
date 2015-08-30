require 'spec_helper'
module Canvas
  class Errors
    describe Info do
      let(:request) do
        stub(env: {}, remote_ip: "", query_parameters: {},
             request_parameters: {}, path_parameters: {}, url: '',
             request_method_symbol: '', format: 'HTML', headers: {})
      end

      let(:request_context_id){ 'abcdefg1234567'}
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
          expect(output[:extra][:user_id]).to eq(5544332211)
        end

        it 'passes important headers' do
          request.stubs(:headers).returns({'User-Agent'=>'the-agent'})
          expect(output[:extra][:user_agent]).to eq('the-agent')
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
      end

    end
  end
end
