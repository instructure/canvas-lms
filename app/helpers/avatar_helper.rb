module AvatarHelper

  def avatar_url_for(conversation, participants = conversation.participants)
    if participants.size == 1
      avatar_url_for_user(participants.first)
    elsif participants.size == 2
      avatar_url_for_user(participants.select{ |u| u.id != conversation.user_id }.first)
    else
      avatar_url_for_group
    end
  end

  def avatar_url_for_group(blank_fallback=false)
    "#{request.protocol}#{request.host_with_port}" + (blank_fallback ?
      "/images/blank.png" :
      "/images/messages/avatar-group-50.png" # always fall back to -50, it'll get scaled down if a smaller size is wanted
    )
  end

  def avatar_url_for_user(user, blank_fallback=false)
    default_avatar = "#{request.protocol}#{request.host_with_port}" + (blank_fallback ?
      "/images/blank.png" :
      "/images/messages/avatar-50.png" # always fall back to -50, it'll get scaled down if a smaller size is wanted
    )

    url = if service_enabled?(:avatars)
      user.avatar_url(nil, (@domain_root_account && @domain_root_account.settings[:avatars] || 'enabled'), default_avatar)
    else
      default_avatar
    end

    if !url.match(%r{\Ahttps?://})
      # make sure that the url is not just a path
      url = "#{request.protocol}#{request.host_with_port}#{url}"
    end

    url
  end

  def blank_fallback
    params[:blank_avatar_fallback] || @blank_fallback
  end

end
