module AvatarHelper

  def set_avatar_size
    @avatar_size = params[:avatar_size].to_i
    @avatar_size = 50 unless [32, 50].include?(@avatar_size)
  end

  def avatar_size
    @avatar_size || set_avatar_size
  end

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
      "/images/messages/avatar-group-#{avatar_size}.png"
    )
  end

  def avatar_url_for_user(user, blank_fallback=false)
    default_avatar = "#{request.protocol}#{request.host_with_port}" + (blank_fallback ?
      "/images/blank.png" :
      "/images/messages/avatar-#{avatar_size}.png"
    )
    if service_enabled?(:avatars)
      avatar_image_url(User.avatar_key(user.id), :fallback => default_avatar)
    else
      default_avatar
    end
  end

  def blank_fallback
    params[:blank_avatar_fallback] || @blank_fallback
  end

end
