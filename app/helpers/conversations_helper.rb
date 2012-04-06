module ConversationsHelper
  def contexts_for(audience, context_tags)
    result = {:courses => {}, :groups => {}}
    return result if audience.empty?
    context_tags.inject(result) do |hash, tag|
      next unless tag =~ /\A(course|group)_(\d+)\z/
      hash["#{$1}s".to_sym][$2.to_i] = []
      hash
    end
    if audience.size == 1 && include_private_conversation_enrollments
      audience.first.common_courses.each do |id, enrollments|
        result[:courses][id] = enrollments if result[:courses][id]
      end
      audience.first.common_groups.each do |id, enrollments|
        result[:groups][id] = enrollments if result[:groups][id]
      end
    end
    result
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
      avatar_image_url(user.id, :fallback => default_avatar)
    else
      default_avatar
    end
  end
end
