module ConversationsHelper
  def context_names(contexts)
    return [] unless @contexts
    contexts.inject([]) { |ary, (type, ids)|
      ary += ids.map { |id| @contexts[type][id.to_i] && @contexts[type][id.to_i][:name] || nil }.compact
    }
  end

  def formatted_contexts(contexts)
    if contexts.is_a? User
      contexts = {:courses => contexts.common_course_ids, :groups => contexts.common_group_ids}
    end
    "<em>#{ERB::Util.h(context_names(contexts).to_sentence)}</em>".html_safe
  end

  def formatted_audience(conversation, cutoff=2)
    audience = conversation.participants
    return "<span class='participant' data-id='#{audience.first.id}'>#{ERB::Util.h(audience.first.short_name)}</span> ".html_safe + formatted_contexts(audience.first) if audience.size == 1

    # get up to two contexts that are shared by >= 50% of the audience
    contexts = audience.inject({}) { |hash, user|
      user.common_course_ids.each { |id| (hash[[:courses, id]] ||= []) << user.id }
      user.common_group_ids.each { |id| (hash[[:groups, id]] ||= []) << user.id }
      hash
    }.
    sort_by{ |c| - c.last.size}.
    select{ |k, v| v.size >= audience.size / 2 }[0, 2].
    map(&:first).
    inject({}){ |hash, (type, id)|
      (hash[type] ||= []) << id
      hash
    }

    audience = audience[0, cutoff - 1] + [audience[cutoff - 1, audience.size - cutoff]] if audience.size > cutoff
    audience.map{ |user_or_array|
      if user_or_array.is_a?(User)
        "<span class='participant' data-id='#{user_or_array.id}'>#{ERB::Util.h(user_or_array.short_name)}</span>".html_safe
      else
        others = I18n.t('conversations.other_recipients', "other", :count => user_or_array.size)
        (
          "<span class='others'>#{ERB::Util.h(others)}" +
          "<ul>" + 
          user_or_array.map{ |user| "<li class='participant' data-id='#{user.id}'>#{ERB::Util.h(user.short_name)}</li>" }.join +
          "</ul>" +
          "</span>"
        ).html_safe
      end
    }.to_sentence.html_safe + " " + formatted_contexts(contexts)
  end

  def avatar_url_for(conversation)
    if conversation.participants.size == 1
      avatar_url_for_user(conversation.participants.first)
    else
      avatar_url_for_group
    end
  end

  def avatar_url_for_group
    "/images/messages/avatar-group-#{avatar_size}.png"
  end

  def avatar_url_for_user(user)
    default_avatar = "/images/messages/avatar-#{avatar_size}.png"
    if service_enabled?(:avatars)
      user.avatar_url(avatar_size, nil, "#{request.protocol}#{request.host_with_port}#{default_avatar}")
    else
      default_avatar
    end
  end
end