
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe 'Canvas::Twilio' do
  def stub_twilio(available_phone_numbers)
    phone_number_objects = available_phone_numbers.map do |number|
      stub(phone_number: number)
    end

    phone_number_objects.stubs(:next_page).returns([])

    Canvas::Twilio.stubs(:client).returns(
      stub(
        account: stub(messages: stub),
        incoming_phone_numbers: stub(
          list: phone_number_objects,
        )
      )
    )
  end

  def test_hrw(number_map)
    stub_twilio(number_map.keys.shuffle)

    number_map.each do |sender, recipients|
      recipients.each do |recipient|
        Canvas::Twilio.client.account.messages.expects(:create).with(from: sender, to: recipient, body: 'message text')

        Canvas::Twilio.deliver(recipient, 'message text')
      end
    end
  end

  describe '.deliver' do
    it 'sends messages' do
      stub_twilio(['+18015550100'])
      Canvas::Twilio.client.account.messages.expects(:create).with(from: '+18015550100', to: '+18015550101', body: 'message text')

      Canvas::Twilio.deliver('+18015550101', 'message text')
    end

    it 'uses HRW hashing to choose which numbers to send from' do
      test_hrw(
        '+18015550100' => ['+18015550110', '+18015550111', '+18015550113', '+18015550115', '+18015550119', '+18015550122'],
        '+18015550101' => ['+18015550112', '+18015550117', '+18015550118', '+18015550120'],
        '+18015550102' => ['+18015550114', '+18015550116', '+18015550121'],
      )

      test_hrw(
        '+18015550100' => ['+18015550110', '+18015550111', '+18015550113', '+18015550119'],
        '+18015550101' => ['+18015550117', '+18015550118', '+18015550120'],
        '+18015550102' => ['+18015550114', '+18015550116', '+18015550121'],
        '+18015550103' => ['+18015550112', '+18015550115', '+18015550122']
      )

      test_hrw(
        '+18015550100' => ['+18015550110', '+18015550111', '+18015550113'],
        '+18015550101' => ['+18015550118'],
        '+18015550102' => ['+18015550114', '+18015550116', '+18015550121'],
        '+18015550103' => ['+18015550112', '+18015550115'],
        '+18015550104' => ['+18015550117', '+18015550119', '+18015550120', '+18015550122']
      )
    end

    it 'handles Twilio pagination' do
      stub_twilio(['+18015550100', '+18015550102'])
      page = [stub(phone_number: '+18015550101')]
      page.stubs(:next_page).returns([])
      Canvas::Twilio.client.incoming_phone_numbers.list.stubs(:next_page).returns(page)

      {
        '+18015550100' => '+18015550110',
        '+18015550101' => '+18015550112',
        '+18015550102' => '+18015550114'
      }.each do |sender, recipient|
        Canvas::Twilio.client.account.messages.expects(:create).with(from: sender, to: recipient, body: 'message text')

        Canvas::Twilio.deliver(recipient, 'message text')
      end
    end

    it 'raises an exception when attempting to deliver without a config file' do
      Canvas::Twilio.stubs(:config).returns({})

      expect { Canvas::Twilio.deliver('+18015550100', 'message text') }.to raise_exception
    end

    it 'pings StatsD about outgoing messages' do
      stub_twilio(['+18015550100'])
      Canvas::Twilio.client.account.messages.expects(:create)

      CanvasStatsd::Statsd.expects(:increment).with('notifications.twilio.message_sent_from_number.+18015550100')

      Canvas::Twilio.deliver('+18015550101', 'message text')
    end
  end
end