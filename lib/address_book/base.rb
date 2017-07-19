#
# Copyright (C) 2016 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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
      return unless derived.superclass == AddressBook::Base
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
    # the :context option causes the users to be filtered to only those known
    # through the specified context. passed either as an asset string or an
    # object (as in `known_in_context`).
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
    # such as `course_123` or `course_123_teachers` or as a Course,
    # CourseSection, or Group object).
    def known_in_context(context)
      raise NotImplemented
    end

    # counts the known users in each of the given contexts
    def count_in_contexts(contexts)
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
    #     specified context. passed either as an asset string or an object (as
    #     in `known_in_context`). defaults to nil
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

    protected

    # determines whether the provided context (Course, CourseSection, or Group
    # object, or an asset_string) is a valid "admin context" for the sender: a
    # context on which they have :read_as_admin permission but in whose course
    # (if any) they do not participate.
    #
    # senders can see all users in a valid admin context, even if they don't
    # participate in that context. but if the context is or is in a course in
    # which the sender participates, then the constraints imposed by their
    # participation (e.g. section-limited) supercede the :read_as_admin
    # permission.
    def admin_context?(context)
      # expand context-as-asset-string to context-as-object
      context = AddressBook.load_context(context) if context.is_a?(String)

      # if the context doesn't exist, or the sender does not have read_as_admin
      # permission, they don't get an admin view
      return false unless context && context.grants_right?(@sender, :read_as_admin)

      # but even if they have read_as_admin permission, we need to check if the
      # context is part of a course they participate in. if so, they still
      # don't get an admin view (since we need to honor any constraints due to
      # their participation, such as section-limited)
      course_id =
        case context
        when Course then context.id
        when CourseSection then context.course_id
        when Group then context.context_type == 'Course' && context.context_id
        end
      return false if course_id && @sender.current_and_concluded_courses.where(id: course_id).exists?

      # this is a valid admin context
      true
    end
  end
end
