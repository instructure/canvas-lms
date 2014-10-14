require 'spec_helper'

describe Mailer do

  describe 'create_message' do

    it 'passes through to address' do
      message = message_model(to: "someemail@example.com")
      mail = Mailer.create_message(message)
      expect(mail.to).to eq ["someemail@example.com"]
    end

    it 'has defaults for critical fields' do
      message = message_model()
      mail = Mailer.create_message(message)
      expect(mail.header['From'].to_s).to eq "#{HostUrl.outgoing_email_default_name} <#{HostUrl.outgoing_email_address}>"
      expect(mail.header['Reply-To'].to_s).to eq IncomingMail::ReplyToAddress.new(message).address
    end

    it 'allows overrides for critical fields' do
      message = message_model()
      message.from_name = "Handy Randy"
      message.reply_to_name = "Stan Theman"
      mail = Mailer.create_message(message)
      expect(mail.header['Reply-To'].to_s).to eq "Stan Theman <#{IncomingMail::ReplyToAddress.new(message).address}>"
      expect(mail.header['From'].to_s).to eq "Handy Randy <#{HostUrl.outgoing_email_address}>"
    end

    it 'omits reply_to for sms' do
      message = message_model(path_type: 'sms')
      message.from_name = "Handy Randy"
      message.reply_to_name = "Stan Theman"
      mail = Mailer.create_message(message)
      expect(mail.header['Reply-To']).to be_nil
      expect(mail.header['From'].to_s).to eq "Handy Randy <#{HostUrl.outgoing_email_address}>"
    end
  end
end
