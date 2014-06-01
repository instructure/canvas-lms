class TwitterMessenger

  include Twitter
  include TextHelper

  attr_reader :message
  delegate :asset_context, :to => :message

  def initialize(message)
    @message = message
  end

  def deliver
    twitter_self_dm(twitter_service, "#{body}") if twitter_service
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

  def twitter_service
    message.user.user_services.find_by_service('twitter')
  end
end
