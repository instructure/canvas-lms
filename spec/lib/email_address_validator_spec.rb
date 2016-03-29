
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe "EmailAddressValidator" do
  it "accepts good addresses with domains" do
    ['user@example.com', '"non\@triv"/ial@example.com'].each do |addr|
      expect(EmailAddressValidator.valid?(addr)).to eq true
    end
  end

  it "rejects bad, local, or multiple addresses" do
    ['None', '@example.com', 'user@', 'user1@example.com, user2@example.com'].each do |addr|
      expect(EmailAddressValidator.valid?(addr)).to eq false
    end
  end
end
