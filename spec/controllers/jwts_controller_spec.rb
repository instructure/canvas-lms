require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe JwtsController do
  describe "#generate" do
    include_context "JWT setup"

    it "requires being logged in" do
      get 'generate'
      expect(response).to be_redirect
      expect(response.status).to eq(302)
    end

    it "generates a base64 encoded token for a user session with env var secrets" do
      token_user = user(active_user: true)
      user_session(token_user)
      get 'generate', format: 'json'
      un_csrfd_body = response.body.gsub("while(1);", "")
      utf8_token_string = JSON.parse(un_csrfd_body)['token']
      decoded_crypted_token = Canvas::Security.base64_decode(utf8_token_string)
      decrypted_token_body = Canvas::Security.decrypt_services_jwt(decoded_crypted_token)
      expect(decrypted_token_body[:sub]).to eq(token_user.global_id)
    end

    it "doesn't allow using a token to gen a token" do
      token_user = user(active_user: true)
      token = Canvas::Security.create_services_jwt(token_user.global_id)
      utf8_crypted_token = Canvas::Security.base64_encode(token)
      get 'generate', {format: 'json'}, {'Authorization' => "Bearer #{utf8_crypted_token}"}
      expect(response.status).to_not eq(200)
    end
  end
end
