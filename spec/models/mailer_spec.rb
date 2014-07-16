require 'spec_helper'

describe Mailer do

  describe 'create_message' do

    # these specs only make sense in the rails 3 interface style
    # given that we're switching over soon, it doesn't seem worthwhile to
    # continue to evolve the rails2 adapters for the mailer interface to
    # accomodate this
    if CANVAS_RAILS3
      it 'passes through to address' do
        message = message_model(to: "someemail@example.com")
        mail = Mailer.create_message(message)
        mail.to.should == ["someemail@example.com"]
      end

      it 'has defaults for critical fields' do
        message = message_model()
        mail = Mailer.create_message(message)
        mail.header['From'].to_s.should == "#{HostUrl.outgoing_email_default_name} <#{HostUrl.outgoing_email_address}>"
        mail.header['Reply-To'].to_s.should == IncomingMail::ReplyToAddress.new(message).address
      end

      it 'allows overrides for critical fields' do
        message = message_model()
        message.from_name = "Handy Randy"
        message.reply_to_name = "Stan Theman"
        mail = Mailer.create_message(message)
        mail.header['Reply-To'].to_s.should == "Stan Theman <#{IncomingMail::ReplyToAddress.new(message).address}>"
        mail.header['From'].to_s.should== "Handy Randy <#{HostUrl.outgoing_email_address}>"
      end
    end

  end
end
