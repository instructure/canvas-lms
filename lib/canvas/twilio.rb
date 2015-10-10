# Utilities to send text messages via Twilio.
module Canvas::Twilio
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

  # Synchronously send a text message. recipient_number should be a phone number in E.164 format and body should be a
  # string to send. This method will take care of deciding what number to send the message from and all of the other
  # assorted magic that goes into delivering text messages via Twilio.
  def self.deliver(recipient_number, body)
    # Find all of the numbers we own
    outbound_numbers = Rails.cache.fetch('twilio_source_phone_numbers', expires_in: 1.day) do
      numbers = []
      page = client.incoming_phone_numbers.list
      while page.length > 0
        numbers.concat page
        page = page.next_page
      end

      numbers.map(&:phone_number).sort
    end

    # Pick one using HRW/rendezvous hashing
    outbound_number = outbound_numbers.max_by do |number|
      Digest::SHA256.hexdigest([number, recipient_number].cache_key).hex
    end

    # Ping StatsD about sending from this number
    CanvasStatsd::Statsd.increment("notifications.twilio.message_sent_from_number.#{outbound_number}")

    # Then send the message.
    client.account.messages.create(from: outbound_number, to: recipient_number, body: body)
  end
end