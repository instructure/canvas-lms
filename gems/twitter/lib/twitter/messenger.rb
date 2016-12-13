module Twitter
  class Messenger
    attr_reader :message
    attr_reader :host
    attr_reader :id

    def initialize(message, twitter_service, host, id)
      @message = message
      @twitter_service = twitter_service
      @host = host
      @id = id
    end

    def deliver
      return unless @twitter_service
      twitter = Twitter::Connection.from_service_token(
        @twitter_service.token,
        @twitter_service.secret
      )
      twitter.send_direct_message(
        @twitter_service.service_user_name,
        @twitter_service.service_user_id,
        "#{body}"
      )
    end

    def url
      message.main_link || message.url || "http://#{host}/mr/#{id}"
    end

    def body
      truncated_body = HtmlTextHelper.strip_and_truncate(message.body, :max_length => (139 - url.length))
      "#{truncated_body} #{url}"
    end

    def asset_context
      @message.asset_context
    end
  end
end
