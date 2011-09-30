module ConversationsHelper
  def contexts_for(audience)
    result = {:courses => {}, :groups => {}}
    return result if audience.empty?
    return {:courses => audience.first.common_courses, :groups => audience.first.common_groups} if audience.size == 1

    # get up to two contexts that are shared by >= 50% of the audience
    contexts = audience.inject({}) { |hash, user|
      user.common_courses.each { |id, roles| (hash[[:courses, id]] ||= []) << user.id }
      user.common_groups.each { |id, roles| (hash[[:groups, id]] ||= []) << user.id }
      hash
    }.
    sort_by{ |c| - c.last.size}.
    select{ |k, v| v.size >= audience.size / 2 }[0, 2].
    map(&:first).
    inject(result){ |hash, (type, id)|
      (hash[type] ||= {})[id] = []
      hash
    }
  end

  def avatar_url_for(conversation)
    participants = conversation.participants
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
      user.avatar_url(avatar_size, nil, default_avatar).sub(%r{\A/}, "#{request.protocol}#{request.host_with_port}/")
    else
      default_avatar
    end
  end
end
