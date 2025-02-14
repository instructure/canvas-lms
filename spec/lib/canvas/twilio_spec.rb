# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

describe "Canvas::Twilio" do
  def make_phone_number_stub(number, country_code)
    phone_number_stub = double("Canvas::Twilio.lookups_client.phone_numbers(#{number})")
    fetch_stub = double("Canvas::Twilio.lookups_client.phone_numbers(#{number}).fetch")
    allow(fetch_stub).to receive(:country_code).and_return(country_code)
    allow(phone_number_stub).to receive(:fetch).and_return(fetch_stub)
    phone_number_stub
  end

  def stub_twilio(available_phone_numbers, phone_number_countries = {})
    phone_number_objects = available_phone_numbers.map do |number|
      double("Canvas::Twilio.client.incoming_phone_numbers.list/#{number}",
             phone_number: number)
    end

    v2 = double("Canvas::Twilio.client.lookups.v2")
    # Expectations are matched last to first, so add our catch-all expectation before the number specific ones
    allow(v2).to receive(:phone_numbers).with(anything).and_return(
      make_phone_number_stub("anything", Canvas::Twilio::DEFAULT_COUNTRY)
    )
    lookups = double("Canvas::Twilio.client.lookups", v2:)

    # Now add one expectation for each number+country mapping
    phone_number_countries.each do |number, country_code|
      allow(v2).to receive(:phone_numbers).with(number).and_return(
        make_phone_number_stub(number.inspect, country_code)
      )
    end

    account = double("Canvas::Twilio.client.account")
    allow(account).to receive_messages(incoming_phone_numbers: double("Canvas::Twilio.client.api.account.client.incoming_phone_numbers",
                                                                      stream: phone_number_objects),
                                       messages: double)

    client = double("Canvas::Twilio.client")
    allow(client).to receive_messages(lookups:, api: double("Canvas::Twilio.client.api", account:))
    allow(Canvas::Twilio).to receive(:client).and_return(client)
  end

  def test_hrw(number_map)
    stub_twilio(number_map.keys.shuffle)

    number_map.each do |sender, recipients|
      recipients.each do |recipient|
        expect(Canvas::Twilio.client.api.account.messages).to receive(:create).with(from: sender, to: recipient, body: "message text")

        Canvas::Twilio.deliver(recipient, "message text")
      end
    end
  end

  describe ".deliver" do
    it "sends messages" do
      stub_twilio(["+18015550100"])
      expect(Canvas::Twilio.client.api.account.messages).to receive(:create).with(from: "+18015550100", to: "+18015550101", body: "message text")

      Canvas::Twilio.deliver("+18015550101", "message text")
    end

    it "uses HRW hashing to choose which numbers to send from" do
      test_hrw(
        "+18015550100" => ["+18015550110", "+18015550111", "+18015550113", "+18015550115", "+18015550119", "+18015550122"],
        "+18015550101" => ["+18015550112", "+18015550117", "+18015550118", "+18015550120"],
        "+18015550102" => ["+18015550114", "+18015550116", "+18015550121"]
      )

      test_hrw(
        "+18015550100" => ["+18015550110", "+18015550111", "+18015550113", "+18015550119"],
        "+18015550101" => ["+18015550117", "+18015550118", "+18015550120"],
        "+18015550102" => ["+18015550114", "+18015550116", "+18015550121"],
        "+18015550103" => ["+18015550112", "+18015550115", "+18015550122"]
      )

      test_hrw(
        "+18015550100" => ["+18015550110", "+18015550111", "+18015550113"],
        "+18015550101" => ["+18015550118"],
        "+18015550102" => ["+18015550114", "+18015550116", "+18015550121"],
        "+18015550103" => ["+18015550112", "+18015550115"],
        "+18015550104" => ["+18015550117", "+18015550119", "+18015550120", "+18015550122"]
      )
    end

    it "raises an exception when attempting to deliver without config" do
      allow(Rails.application.credentials).to receive(:twilio_creds).and_return(nil)

      expect { Canvas::Twilio.deliver("+18015550100", "message text") }.to raise_error("Twilio is not configured")
    end

    it "delivers to a phone number in the recipient's country if such a phone number exists" do
      stub_twilio(["+18015550100", "+18015550101"], "+18015550101" => "CA", "+18015550102" => "CA")
      expect(Canvas::Twilio.client.api.account.messages).to receive(:create).with(from: "+18015550101", to: "+18015550102", body: "message text")

      Canvas::Twilio.deliver("+18015550102", "message text")
    end

    it "defaults to the default country if we don't own any phone numbers in the recipient's country" do
      stub_twilio(["+18015550100", "+18015550101"], "+18015550101" => "CA", "+18015550102" => Canvas::Twilio::DEFAULT_COUNTRY)
      expect(Canvas::Twilio.client.api.account.messages).to receive(:create).with(from: "+18015550100", to: "+18015550102", body: "message text")

      Canvas::Twilio.deliver("+18015550102", "message text")
    end

    it "defaults to the default country if we tell it not to send from the recipient's country" do
      stub_twilio(["+18015550100", "+18015550101"], "+18015550101" => "CA", "+18015550102" => "CA")
      expect(Canvas::Twilio.client.api.account.messages).to receive(:create).with(from: "+18015550100", to: "+18015550102", body: "message text")

      Canvas::Twilio.deliver("+18015550102", "message text", from_recipient_country: false)
    end

    it "pings StatsD about outgoing messages" do
      allow(InstStatsd::Statsd).to receive(:increment)
      stub_twilio(["+18015550100", "+18015550102"], "+18015550102" => "CA", "+18015550103" => "CA", "+18015550104" => "GB")
      expect(Canvas::Twilio.client.api.account.messages).to receive(:create).exactly(3).times
      Canvas::Twilio.deliver("+18015550101", "message text")
      Canvas::Twilio.deliver("+18015550103", "message text")
      Canvas::Twilio.deliver("+18015550104", "message text")
      expect(InstStatsd::Statsd).to have_received(:increment)
        .with(
          "notifications.twilio.message_sent_from_number.US.+18015550100",
          short_stat: "notifications.twilio.message_sent",
          tags: { country: "US", number: "+18015550100" }
        ).twice
      expect(InstStatsd::Statsd).to have_received(:increment)
        .with(
          "notifications.twilio.message_sent_from_number.CA.+18015550102",
          short_stat: "notifications.twilio.message_sent",
          tags: { country: "CA", number: "+18015550102" }
        )
      expect(InstStatsd::Statsd).to have_received(:increment)
        .with("notifications.twilio.no_outbound_numbers_for.GB",
              short_stat: "notifications.twilio.no_outbound_numbers",
              tags: { country: "GB" })
    end
  end
end
