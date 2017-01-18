require_relative '../../../spec_helper.rb'

describe "Api::V1::Pseudonym" do
  class Harness
    include Api::V1::Pseudonym
  end

  describe "#pseudonym_json" do
    let(:pseudonym){ Pseudonym.new(account: Account.default) }
    let(:session) { {} }
    let(:user) { User.new }
    let(:api) { Harness.new }

    it "includes the authentication_provider_type if there is one" do
      aac = AccountAuthorizationConfig.new(auth_type: "ldap")
      pseudonym.authentication_provider = aac
      json = api.pseudonym_json(pseudonym, user, session)
      expect(json[:authentication_provider_type]).to eq("ldap")
    end

    it "ignores the authentication_provider_type if it's absent" do
      json = api.pseudonym_json(pseudonym, user, session)
      expect(json[:authentication_provider_type]).to be_nil
    end
  end
end
