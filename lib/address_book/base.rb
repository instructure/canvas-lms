module AddressBook

  # base interface and partial implementation of AddressBook, including
  # documentation.
  #
  # also integrates the caching layer, so the implementations don't need to
  # worry about reading from the cache and skipping over precached recipients.
  # however, the implementations are responsible for storing results into the
  # cache.
  class Base
    def self.inherited(derived)
      derived.prepend(AddressBook::Caching)
    end

    attr_reader :sender

    def initialize(sender)
      @sender = sender
      @cache = AddressBook::Caching::Cache.new
      @cache.store(sender, {}, {})
    end

    def cached?(user)
      @cache.cached?(user)
    end

    # filters the list of given users to those actually known.
    #
    # the :include_context option ensures that the recipients' roles in that
    # context, if any, are included in the cached common contexts. this is
    # useful when the sender knows the recipient via and admin relationship
    # rather than through the context. note that this also causes the
    # recipients in the given context to be included even if not otherwise
    # known; pass only if you know the sender is an admin over that context.
    #
    # the :conversation_id option indicates that any participants in the
    # existing conversation should be considered known; ignored if the sender
    # is not already a participant in that conversation.
    def known_users(users, options={})
      raise NotImplemented
    end

    # as known_users, but for just the one user
    def known_user(user, options={})
      known_users([user], options).first
    end

    # returns a hash of the user's roles in their common courses with the
    # sender (key: course id, value: list of roles), assuming the user is
    # known. if not known, returns an empty hash
    def common_courses(user)
      if user == @sender
        return {}
      else
        known = known_user(user)
        known ? @cache.common_courses(known) : {}
      end
    end

    # returns a hash of the user's roles in their common groups with the
    # sender (key: group id, value: list of roles), assuming the user is
    # known. if not known, returns an empty hash
    def common_groups(user)
      if user == @sender
        return {}
      else
        known = known_user(user)
        known ? @cache.common_groups(known) : {}
      end
    end

    # returns the known users in the given context (passed as an asset string
    # such as `course_123` or `course_123_teachers`).
    #
    # the :is_admin flag causes the sender to be treated as having admin
    # visibility into the course; when false (default) the sender must have
    # legitimate visibility into the course to known any of its users.
    def known_in_context(context, is_admin=false)
      raise NotImplemented
    end

    # counts the known users in the given context
    def count_in_context(context)
      raise NotImplemented
    end

    # returns a paginatable collection for all known users matching the search
    # term. needs to be BookmarkedCollection::Proxy-like for use in a
    # BookmarkedCollection.merge. any bookmark into that collection will not be
    # provided until the pagination occurs so actual loading is deferred until
    # then, and then only the page's worth is loaded.
    #
    # options:
    #
    #   search:
    #     when present, only returns users whose names match the search term.
    #
    #   exclude_ids:
    #     when present, excludes the specified users from the search results.
    #
    #   context:
    #     when present, restricts the results to users known through the
    #     specified context (passed as an asset string the same as for
    #     `known_in_context`). defaults to nil
    #
    #   is_admin:
    #     allows searching the specified context even if not otherwise
    #     connected to the sender. ignored if the :context option is nil, and
    #     defaults to false. caller is responsible to only pass true after
    #     checking the sender has admin visibility into the context.
    #
    #   weak_checks:
    #     allows including "weak" users (with a workflow_state of
    #     'creation_pending') or enrollments (e.g. student enrollments in
    #     unpublished courses) when determining visibility; defaults to false.
    #
    # implementation note: we don't need to worry about top-level pagination of
    # the result -- we know it's used in a merge -- so all it needs to
    # implement are depth, new_pager, and execute_page.
    def search_users(options={})
      raise NotImplemented
    end

    # flag the provided users as known, even if they would not otherwise be, to
    # allow `lookup` to return entries for them. used when loading common
    # contexts for participants in existing conversations. future lookups of
    # users not otherwise known will provide empty sets common contexts.
    def preload_users(users)
      raise NotImplemented
    end

    # returns the course sections known to the sender
    def sections
      @sender.messageable_sections
    end

    # returns the groups known to the sender
    def groups
      @sender.messageable_groups
    end
  end
end
