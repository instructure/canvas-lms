class TwitterMessenger

  include TextHelper

  attr_reader :message
  delegate :asset_context, :to => :message

  def initialize(message, twitter_service)
    @message = message
    @twitter_service = twitter_service
  end

  def deliver
    return unless @twitter_service
    twitter_connection = Twitter.new(@twitter_service.token, @twitter_service.secret)
    twitter_connection.send_direct_message(@twitter_service.service_user_name, @twitter_service.service_user_id, "#{body}")
  end

  def url
    message.main_link || message.url || "http://#{host}/mr/#{id}"
  end

  def id
    AssetSignature.generate(@message)
  end

  def body
    truncated_body = HtmlTextHelper.strip_and_truncate(message.body, :max_length => (139 - url.length))
    "#{truncated_body} #{url}"
  end

  def host
    HostUrl.short_host(asset_context)
  end
end
