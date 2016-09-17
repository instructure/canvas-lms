module AddressBook

  # implementation of AddressBook interface backed by MessageableUser
  class MessageableUser < AddressBook::Base
    def known_users(users, options={})
      # in case we were handed something that's already a messageable user,
      # pass it in as just the id so we don't modify it in place
      # (MessageableUser was original built to want that optimization, but
      # now we don't)
      users = users.map(&:id) if users.first.is_a?(::MessageableUser)
      @sender.load_messageable_users(users,
        admin_context: options[:include_context],
        conversation_id: options[:conversation_id])
    end

    # in this implementation, the data just comes from the same call on the
    # MessageableUser recipient itself
    def common_courses(user)
      if user == @sender
        return {}
      else
        known = known_user(user)
        known ? known.common_courses : {}
      end
    end

    # in this implementation, the data just comes from the same call on the
    # MessageableUser recipient itself
    def common_groups(user)
      if user == @sender
        return {}
      else
        known = known_user(user)
        known ? known.common_groups : {}
      end
    end

    def known_in_context(context, is_admin=false)
      admin_context = context if is_admin
      @sender.
        messageable_user_calculator.
        messageable_users_in_context(context, admin_context: admin_context)
    end

    def count_in_context(context)
      @sender.count_messageable_users_in_context(context)
    end

    def search_users(options={})
      @sender.search_messageable_users(
        search: options[:search],
        exclude_ids: options[:exclude_ids],
        context: options[:context],
        admin_context: options[:context] && options[:is_admin],
        strict_checks: !options[:weak_checks]
      )
    end

    def preload_users(users)
      # in case we were handed something that's already a messageable user,
      # pass it in as just the id so we don't modify it in place
      # (MessageableUser was original built to want that optimization, but
      # now we don't)
      users = users.map(&:id) if users.first.is_a?(::MessageableUser)
      @sender.load_messageable_users(users, strict_checks: false)
    end

    def sections
      @sender.messageable_sections
    end

    def groups
      @sender.messageable_groups
    end
  end
end
