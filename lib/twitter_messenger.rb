class TwitterMessenger

  include Twitter

  attr_reader :message
  delegate :asset_context, :to => :message

  def initialize(message)
    @message = message
  end

  def deliver
    twitter_self_dm(twitter_service, "#{body} #{url}") if twitter_service
  end

  def url
    "http://#{host}/mr/#{id}"
  end

  def id
    AssetSignature.generate(@message)
  end

  def body
    message.body[0, 139 - url.length]
  end

  def host
    HostUrl.short_host(asset_context)
  end

  def twitter_service
    message.user.user_services.find_by_service('twitter')
  end
end
