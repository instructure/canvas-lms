
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe 'Canvas::Twilio' do
  def make_phone_number_stub(number, country_code)
    phone_number_stub = double("Canvas::Twilio.lookups_client.phone_numbers.get(#{number})")
    allow(phone_number_stub).to receive(:country_code).and_return(country_code)
    allow(phone_number_stub).to receive(:try).and_raise(Exception, "Rails 4 #try breaks Twilio lazy load logic. Don't use it.")
    phone_number_stub
  end

  def stub_twilio(available_phone_numbers, phone_number_countries = {})
    phone_number_objects = available_phone_numbers.map do |number|
      double("Canvas::Twilio.client.incoming_phone_numbers.list/#{number}",
        phone_number: number
      )
    end

    allow(phone_number_objects).to receive(:next_page).and_return([])

    lookup_stub = double('Canvas::Twilio.lookups_client.phone_numbers')
    # Expectations are matched last to first, so add our catch-all expectation before the number specific ones
    allow(lookup_stub).to receive(:get).with(anything).and_return(
      make_phone_number_stub('anything', Canvas::Twilio::DEFAULT_COUNTRY)
    )
    # Now add one expectation for each number+country mapping
    phone_number_countries.each do |number, country_code|
      allow(lookup_stub).to receive(:get).with(number).and_return(
        make_phone_number_stub(number.inspect, country_code)
      )
    end

    allow(Canvas::Twilio).to receive(:client).and_return(
      double('Canvas::Twilio.client',
        account: double('Canvas::Twilio.client.account', messages: double),
        incoming_phone_numbers: double('Canvas::Twilio.client.incoming_phone_numbers',
          list: phone_number_objects,
        )
      )
    )

    allow(Canvas::Twilio).to receive(:lookups_client).and_return(
      double('Canvas::Twilio.lookups_client',
        phone_numbers: lookup_stub
      )
    )
  end

  def test_hrw(number_map)
    stub_twilio(number_map.keys.shuffle)

    number_map.each do |sender, recipients|
      recipients.each do |recipient|
        expect(Canvas::Twilio.client.account.messages).to receive(:create).with(from: sender, to: recipient, body: 'message text')

        Canvas::Twilio.deliver(recipient, 'message text')
      end
    end
  end

  describe '.deliver' do
    it 'sends messages' do
      stub_twilio(['+18015550100'])
      expect(Canvas::Twilio.client.account.messages).to receive(:create).with(from: '+18015550100', to: '+18015550101', body: 'message text')

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
      page = [double(phone_number: '+18015550101')]
      allow(page).to receive(:next_page).and_return([])
      allow(Canvas::Twilio.client.incoming_phone_numbers.list).to receive(:next_page).and_return(page)

      {
        '+18015550100' => '+18015550110',
        '+18015550101' => '+18015550112',
        '+18015550102' => '+18015550114'
      }.each do |sender, recipient|
        expect(Canvas::Twilio.client.account.messages).to receive(:create).with(from: sender, to: recipient, body: 'message text')

        Canvas::Twilio.deliver(recipient, 'message text')
      end
    end

    it 'raises an exception when attempting to deliver without a config file' do
      allow(Canvas::Twilio).to receive(:config).and_return({})

      expect { Canvas::Twilio.deliver('+18015550100', 'message text') }.to raise_exception
    end

    it "delivers to a phone number in the recipient's country if such a phone number exists" do
      stub_twilio(['+18015550100', '+18015550101'], '+18015550101' => 'CA', '+18015550102' => 'CA')
      expect(Canvas::Twilio.client.account.messages).to receive(:create).with(from: '+18015550101', to: '+18015550102', body: 'message text')

      Canvas::Twilio.deliver('+18015550102', 'message text')
    end

    it "defaults to the default country if we don't own any phone numbers in the recipient's country" do
      stub_twilio(['+18015550100', '+18015550101'], '+18015550101' => 'CA', '+18015550102' => Canvas::Twilio::DEFAULT_COUNTRY)
      expect(Canvas::Twilio.client.account.messages).to receive(:create).with(from: '+18015550100', to: '+18015550102', body: 'message text')

      Canvas::Twilio.deliver('+18015550102', 'message text')
    end

    it "defaults to the default country if we tell it not to send from the recipient's country" do
      stub_twilio(['+18015550100', '+18015550101'], '+18015550101' => 'CA', '+18015550102' => 'CA')
      expect(Canvas::Twilio.client.account.messages).to receive(:create).with(from: '+18015550100', to: '+18015550102', body: 'message text')

      Canvas::Twilio.deliver('+18015550102', 'message text', from_recipient_country: false)
    end

    it 'pings StatsD about outgoing messages' do
      stub_twilio(['+18015550100', '+18015550102'], '+18015550102' => 'CA', '+18015550103' => 'CA', '+18015550104' => 'GB')
      expect(Canvas::Twilio.client.account.messages).to receive(:create).exactly(3).times

      expect(CanvasStatsd::Statsd).to receive(:increment).with('notifications.twilio.message_sent_from_number.US.+18015550100').twice
      expect(CanvasStatsd::Statsd).to receive(:increment).with('notifications.twilio.message_sent_from_number.CA.+18015550102')
      expect(CanvasStatsd::Statsd).to receive(:increment).with('notifications.twilio.no_outbound_numbers_for.GB')

      Canvas::Twilio.deliver('+18015550101', 'message text')
      Canvas::Twilio.deliver('+18015550103', 'message text')
      Canvas::Twilio.deliver('+18015550104', 'message text')
    end
  end
end
