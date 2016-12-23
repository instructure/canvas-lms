
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe 'Canvas::Twilio' do
  def make_phone_number_stub(number, country_code)
    phone_number_stub = stub("Canvas::TWilio.lookups_client.phone_numbers.get(#{number})")
    phone_number_stub.stubs(:country_code).returns(country_code)
    phone_number_stub.stubs(:try).raises(Exception, "Rails 4 #try breaks Twilio lazy load logic. Don't use it.")
    phone_number_stub
  end

  def stub_twilio(available_phone_numbers, phone_number_countries = {})
    phone_number_objects = available_phone_numbers.map do |number|
      stub("Canvas::Twilio.client.incoming_phone_numbers.list/#{number}",
        phone_number: number
      )
    end

    phone_number_objects.stubs(:next_page).returns([])

    lookup_stub = stub('Canvas::Twilio.lookups_client.phone_numbers')
    # Expectations are matched last to first, so add our catch-all expectation before the number specific ones
    lookup_stub.stubs(:get).with(anything).returns(
      make_phone_number_stub('anything', Canvas::Twilio::DEFAULT_COUNTRY)
    )
    # Now add one expectation for each number+country mapping
    phone_number_countries.each do |number, country_code|
      lookup_stub.stubs(:get).with(number).returns(
        make_phone_number_stub(number.inspect, country_code)
      )
    end

    Canvas::Twilio.stubs(:client).returns(
      stub('Canvas::Twilio.client',
        account: stub('Canvas::Twilio.client.account', messages: stub),
        incoming_phone_numbers: stub('Canvas::Twilio.client.incoming_phone_numbers',
          list: phone_number_objects,
        )
      )
    )

    Canvas::Twilio.stubs(:lookups_client).returns(
      stub('Canvas::Twilio.lookups_client',
        phone_numbers: lookup_stub
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

    it "delivers to a phone number in the recipient's country if such a phone number exists" do
      stub_twilio(['+18015550100', '+18015550101'], '+18015550101' => 'CA', '+18015550102' => 'CA')
      Canvas::Twilio.client.account.messages.expects(:create).with(from: '+18015550101', to: '+18015550102', body: 'message text')

      Canvas::Twilio.deliver('+18015550102', 'message text')
    end

    it "defaults to the default country if we don't own any phone numbers in the recipient's country" do
      stub_twilio(['+18015550100', '+18015550101'], '+18015550101' => 'CA', '+18015550102' => Canvas::Twilio::DEFAULT_COUNTRY)
      Canvas::Twilio.client.account.messages.expects(:create).with(from: '+18015550100', to: '+18015550102', body: 'message text')

      Canvas::Twilio.deliver('+18015550102', 'message text')
    end

    it "defaults to the default country if we tell it not to send from the recipient's country" do
      stub_twilio(['+18015550100', '+18015550101'], '+18015550101' => 'CA', '+18015550102' => 'CA')
      Canvas::Twilio.client.account.messages.expects(:create).with(from: '+18015550100', to: '+18015550102', body: 'message text')

      Canvas::Twilio.deliver('+18015550102', 'message text', from_recipient_country: false)
    end

    it 'pings StatsD about outgoing messages' do
      stub_twilio(['+18015550100', '+18015550102'], '+18015550102' => 'CA', '+18015550103' => 'CA', '+18015550104' => 'GB')
      Canvas::Twilio.client.account.messages.expects(:create).times(3)

      CanvasStatsd::Statsd.expects(:increment).with('notifications.twilio.message_sent_from_number.US.+18015550100').twice
      CanvasStatsd::Statsd.expects(:increment).with('notifications.twilio.message_sent_from_number.CA.+18015550102')
      CanvasStatsd::Statsd.expects(:increment).with('notifications.twilio.no_outbound_numbers_for.GB')

      Canvas::Twilio.deliver('+18015550101', 'message text')
      Canvas::Twilio.deliver('+18015550103', 'message text')
      Canvas::Twilio.deliver('+18015550104', 'message text')
    end
  end
end
