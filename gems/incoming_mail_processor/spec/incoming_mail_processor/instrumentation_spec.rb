require 'spec_helper'

describe IncomingMailProcessor::Instrumentation do
  let(:mailbox) do
    obj = double()
    allow(obj).to receive(:unprocessed_message_count).and_return(4,nil,0,50)
    obj
  end

  let(:single_config) do
    { 'imap' => {
        'address' => "fake@fake.fake"
      }
    }
  end

  let(:multi_config) do
    { 'imap' => {
        'accounts' => [
          { 'username' => 'user1@fake.fake' },
          { 'username' => 'user2@fake.fake' },
          { 'username' => 'user3@fake.fake' },
          { 'username' => 'user4@fake.fake' },
        ],
      },
    }
  end

  describe ".process" do
    before do
      allow(IncomingMailProcessor::IncomingMessageProcessor).to receive(:create_mailbox).and_return(mailbox)
    end

    it 'should push to statsd for one mailbox' do
      IncomingMailProcessor::IncomingMessageProcessor.configure(single_config)

      expect(CanvasStatsd::Statsd).to receive(:gauge).with("incoming_mail_processor.mailbox_queue_size.fake@fake_fake",4)

      IncomingMailProcessor::Instrumentation.process
    end

    it 'should push to statsd for multiple mailboxes' do
      IncomingMailProcessor::IncomingMessageProcessor.configure(multi_config)

      expect(CanvasStatsd::Statsd).to receive(:gauge).with("incoming_mail_processor.mailbox_queue_size.user1@fake_fake", 4)
      expect(CanvasStatsd::Statsd).to receive(:gauge).with("incoming_mail_processor.mailbox_queue_size.user3@fake_fake", 0)
      expect(CanvasStatsd::Statsd).to receive(:gauge).with("incoming_mail_processor.mailbox_queue_size.user4@fake_fake", 50)

      IncomingMailProcessor::Instrumentation.process
    end
  end
end
