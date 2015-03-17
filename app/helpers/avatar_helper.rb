module AvatarHelper

  def avatar_image_attrs(user_or_id)
    return ["/images/messages/avatar-50.png", ''] unless user_or_id
    user_id = user_or_id.is_a?(User) ? user_or_id.id : user_or_id
    user = user_or_id.is_a?(User) && user_or_id
    if session["reported_#{user_id}"]
      ["/images/messages/avatar-50.png", '']
    else
      avatar_settings = @domain_root_account && @domain_root_account.settings[:avatars] || 'enabled'
      user_id, user_shard = Shard.local_id_for(user_id)
      user_shard ||= Shard.current
      image_url, alt_tag = user_shard.activate do
        Rails.cache.fetch(Cacher.inline_avatar_cache_key(user_id, avatar_settings)) do
          if !user && user_id.to_i > 0
            user ||= User.find(user_id)
          end
          if user
            url = avatar_url_for_user(user)
          else
            url = "/images/messages/avatar-50.png"
          end
          alt = user ? user.short_name : ''
          [url, alt]
        end
      end
    end
  end

  def avatar(user_or_id, opts = {})
    return unless service_enabled?(:avatars)
    # same markup as _avatar.handlebars, essentially
    avatar_url, display_name = avatar_image_attrs(user_or_id)
    context_code = opts[:context_code] if opts[:context_code]
    url = nil
    if opts.has_key? :url
      url = opts[:url]
    elsif user_or_id
      if context_code
        url = context_prefix(context_code) + user_path(user_or_id)
      else
        url = user_url(user_or_id)
      end
    end
    link_opts = {}
    link_opts[:class] = 'avatar '+opts[:class].to_s
    link_opts[:style] = "background-image: url(#{avatar_url})"
    link_opts[:style] += ";width: #{opts[:size]}px;height: #{opts[:size]}px" if opts[:size]
    link_opts[:href] = url if url
    link_opts[:title] = opts[:title] if opts[:title]
    content = content_tag(:span, display_name, class: 'screenreader-only')
    content += (opts[:edit] ? content_tag(:i, nil, class: 'icon-edit') : '')
    content += (opts[:show_flag] ? content_tag(:i, nil, class: 'icon-flag') : '')
    content_tag(:a, content, link_opts)
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
    request.base_url + (blank_fallback ?
      "/images/blank.png" :
      "/images/messages/avatar-group-50.png" # always fall back to -50, it'll get scaled down if a smaller size is wanted
    )
  end

  def avatar_url_for_user(user, blank_fallback=false)
    default_avatar = User.avatar_fallback_url(blank_fallback ? '/images/blank.png' : User.default_avatar_fallback)
    url = if service_enabled?(:avatars)
      user.avatar_url(nil, (@domain_root_account && @domain_root_account.settings[:avatars] || 'enabled'), default_avatar)
    else
      default_avatar
    end

    if !url.match(%r{\Ahttps?://})
      # make sure that the url is not just a path
      url = "#{request.base_url}#{url}"
    end

    url
  end

  def blank_fallback
    params[:blank_avatar_fallback].nil? ? @blank_fallback : value_to_boolean(params[:blank_avatar_fallback])
  end

end
