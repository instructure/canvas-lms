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

# Utilities to send text messages via Twilio.
require 'twilio-ruby'

module Canvas::Twilio
  DEFAULT_COUNTRY = 'US'

  def self.config
    @config ||= ConfigFile.load('twilio') || {}
  end

  def self.account_sid
    config['account_sid']
  end

  def self.auth_token
    config['auth_token']
  end

  def self.client
    @client ||= Twilio::REST::Client.new(account_sid, auth_token) if account_sid && auth_token
  end

  # Whether or not Twilio is currently enabled. Twilio is enabled when config/twilio.yml exists and specifies an
  # account_sid and auth_token. Calls to deliver will fail when this returns false.
  def self.enabled?
    !!client
  end

  # Look up the ISO country code for the specified phone number. Twilio must be enabled in order for this to work.
  def self.lookup_country(phone_number)
    Rails.cache.fetch(['twilio_phone_number_country_2', phone_number].cache_key) do
      client.lookups.phone_numbers(phone_number).fetch.country_code
    end
  end

  # Hash of ISO country codes to arrays of phone numbers that we own in those countries. This will be an empty hash if
  # Twilio is not enabled.
  def self.outbound_numbers
    return {} unless enabled?

    Rails.cache.fetch('twilio_source_phone_numbers_3', expires_in: 1.day) do
      numbers = Canvas::Twilio.client.api.account.incoming_phone_numbers.stream.to_a

      numbers_by_country = Hash.new { |h, k| h[k] = [] }
      numbers.sort_by(&:phone_number).each do |number|
        numbers_by_country[lookup_country(number.phone_number)] << number.phone_number
      end

      Hash[numbers_by_country]
    end
  end

  # Synchronously send a text message. recipient_number should be a phone number in E.164 format and body should be a
  # string to send. This method will take care of deciding what number to send the message from and all of the other
  # assorted magic that goes into delivering text messages via Twilio.
  def self.deliver(recipient_number, body, from_recipient_country: true)
    raise "Twilio is not configured" unless enabled?
    # Figure out what country the recipient number is in
    country = from_recipient_country ? lookup_country(recipient_number) : DEFAULT_COUNTRY

    # Get a list of numbers we own in that country, or numbers in the default country if we don't own any
    number_map = outbound_numbers
    outbound_country = number_map[country].present? ? country : DEFAULT_COUNTRY
    candidates = number_map[outbound_country]

    # Pick one using HRW/rendezvous hashing
    outbound_number = candidates.max_by do |number|
      Digest::SHA256.hexdigest([number, recipient_number].cache_key).hex
    end

    # Ping StatsD about sending from this number
    CanvasStatsd::Statsd.increment("notifications.twilio.message_sent_from_number.#{outbound_country}.#{outbound_number}")
    CanvasStatsd::Statsd.increment("notifications.twilio.no_outbound_numbers_for.#{country}") unless country == outbound_country

    # Then send the message.
    client.api.account.messages.create(from: outbound_number, to: recipient_number, body: body)
  end
end
