# Utilities to send text messages via Twilio.
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

  def self.lookups_client
    @lookups_client ||= Twilio::REST::LookupsClient.new(account_sid, auth_token) if account_sid && auth_token
  end

  # Whether or not Twilio is currently enabled. Twilio is enabled when config/twilio.yml exists and specifies an
  # account_sid and auth_token. Calls to deliver will fail when this returns false.
  def self.enabled?
    !!client
  end

  # Look up the ISO country code for the specified phone number. Twilio must be enabled in order for this to work.
  def self.lookup_country(phone_number)
    Rails.cache.fetch(['twilio_phone_number_country_2', phone_number].cache_key) do
      lookups_client.phone_numbers.get(phone_number).try!(:country_code)
    end
  end

  # Hash of ISO country codes to arrays of phone numbers that we own in those countries. This will be an empty hash if
  # Twilio is not enabled.
  def self.outbound_numbers
    return {} unless enabled?

    Rails.cache.fetch('twilio_source_phone_numbers_3', expires_in: 1.day) do
      numbers = []
      page = client.incoming_phone_numbers.list
      while page.length > 0
        numbers.concat page
        page = page.next_page
      end

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
    client.account.messages.create(from: outbound_number, to: recipient_number, body: body)
  end
end
