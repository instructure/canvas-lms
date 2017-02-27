#
# Copyright (C) 2014 Instructure, Inc.
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
#

require 'canvas_statsd'

module AdheresToPolicy
  module InstanceMethods
    # Public: Gets the requested rights granted to a user.
    #
    # user - The user for which to get the rights.
    # session - The session to use if the rights are dependend upon the session.
    # args - The rights to get the status for.
    #
    # Examples
    #
    #   granted_rights(user, :read)
    #   # => [ :read ]
    #
    #   granted_rights(user, :read, :update)
    #   # => [ :read, :update ]
    #
    #   granted_rights(user, session, :update, :delete)
    #   # => [ :update ]
    #
    # Returns an array of rights granted to the user.
    def granted_rights(user, *args)
      session, sought_rights = parse_args(args)
      sought_rights ||= []
      sought_rights = self.class.policy.available_rights if sought_rights.empty?
      sought_rights.select do |r|
        check_right?(user, session, r)
      end
    end
    # alias so its backwards compatible.
    alias :check_policy :granted_rights

    # Public: Gets the requested rights and their status to a user.
    #
    # user - The user for which to get the rights.
    # session - The session to use if the rights are dependend upon the session.
    # args - The rights to get the status for.
    #
    # Examples
    #
    #   rights_status(user, :read)
    #   # => { :read => true }
    #
    #   rights_status(user, session, :update, :delete)
    #   # => { :update => true, :delete => false }
    #
    # Returns a hash with the requested rights and their status.
    def rights_status(user, *args)
      session, sought_rights = parse_args(args)
      sought_rights ||= []
      sought_rights = self.class.policy.available_rights if sought_rights.empty?
      sought_rights.inject({}) do |h, r|
        h[r] = check_right?(user, session, r)
        h
      end
    end

    # Public: Checks any of the rights passed in for a user.
    #
    # user - The user for which to determine the right.
    # session - The session to use if the rights are dependend upon the session.
    # rights - The rights to get the status for.  Will return true if the user
    #          is granted any of the rights provided.
    #
    # Examples
    #
    #   grants_any_right?(user, :read)
    #   # => true
    #
    #   grants_any_right?(user, session, :delete)
    #   # => false
    #
    #   grants_any_right?(user, session, :update, :delete)
    #   # => true
    #
    # Returns true if any of the provided rights are granted to the user.  False
    # if none of the provided rights are granted.
    def grants_any_right?(user, *args)
      session, sought_rights = parse_args(args)
      sought_rights.any? do |sought_right|
        check_right?(user, session, sought_right)
      end
    end

    # Public: Checks all of the rights passed in for a user.
    #
    # user - The user for which to determine the right.
    # session - The session to use if the rights are dependend upon the session.
    # rights - The rights to get the status for.  Will return true if the user
    #          is granted all of the rights provided.
    #
    # Examples
    #
    #   grants_all_rights?(user, :read)
    #   # => true
    #
    #   grants_all_rights?(user, session, :delete)
    #   # => false
    #
    #   grants_all_rights?(user, session, :update, :delete)
    #   # => false
    #
    # Returns true if any of the provided rights are granted to the user.  False
    # if any of the provided rights are not granted.
    def grants_all_rights?(user, *args)
      session, sought_rights = parse_args(args)
      return false if sought_rights.empty?
      sought_rights.none? do |sought_right|
        !check_right?(user, session, sought_right)
      end
    end

    # Public: Checks the right passed in for a user.
    #
    # user - The user for which to determine the right.
    # session - The session to use if the rights are dependend upon the session.
    # right - The right to get the status for.  Will return true if the user
    #         is granted the right provided.
    #
    # Examples
    #
    #   grants_right?(user, :read)
    #   # => true
    #
    #   grants_right?(user, session, :delete)
    #   # => false
    #
    #   grants_right?(user, session, :update)
    #   # => true
    #
    # Returns true if any of the provided rights are granted to the user.  False
    # if none of the provided rights are granted.
    def grants_right?(user, *args)
      session, sought_rights = parse_args(args)
      raise ArgumentError if sought_rights.length > 1
      check_right?(user, session, sought_rights.first)
    end

    # Public: Clears the cached permission states for the user.
    #
    # user - The user for which to clear the rights.
    # session - The session to use if the rights are dependend upon the session.
    #
    # Examples
    #
    #   clear_permissions_cache(user)
    #   # => nil
    #
    #   clear_permissions_cache(user, session)
    #   # => nil
    #
    def clear_permissions_cache(user, session = nil)
      return if respond_to?(:new_record?) && new_record?
      Cache.clear
      self.class.policy.available_rights.each do |available_right|
        Rails.cache.delete(permission_cache_key_for(user, session, available_right))
      end
    end

    private

    # Internal: Parses the arguments passed in for a session and sought rights
    #           array.
    #
    # args - The args containing the session and sought rights.
    #
    # Examples
    #
    #   parse_args([ session, :read, :write ])
    #   # => session, [ :read, :write ]
    #
    #   parse_args([ nil, :read, :write ])
    #   # => nil, [ :read, :write ]
    #
    # Returns a session object which is nil if it was not provided and an array
    # of the sought rights.
    def parse_args(args)
      session = nil
      if !args[0].is_a? Symbol
        session = args.shift
      end
      args.compact!
      args.uniq!

      return session, args
    end

    # Internal: Checks the right for a user based on session.
    #
    # user - The user to base the right check from.
    # session - The session to use when checking the right status.
    # sought_right - The right to check its status.
    #
    # Examples
    #
    #   check_right?(user, session, :read)
    #   # => true, :read
    #
    #   check_right?(user, nil, :delete)
    #   # => false, :delete
    #
    # Returns the rights status pertaining the user and session provided.
    def check_right?(user, session, sought_right)
      return false unless sought_right

      # Check the cache for the sought_right.  If it exists in the cache its
      # state (true or false) will be returned.  Otherwise we calculate the
      # state and cache it.
      value, how_it_got_it = Cache.fetch(permission_cache_key_for(user, session, sought_right)) do
        CanvasStatsd::BlockTracking.track("adheres_to_policy.#{self.class.name&.underscore}.#{sought_right}", category: :adheres_to_policy) do

          conditions = self.class.policy.conditions[sought_right]
          next false unless conditions

          # Loop through all the conditions until we find the first one that
          # grants us the sought_right.
          conditions.any? do |condition|
            if condition.applies?(self, user, session)

              # Since the condition is true we can loop through all the rights
              # that belong to it and cache them.  This will short circut the above
              # Rails.cache.fetch for future checks that we won't have to do again.
              condition.rights.each do |condition_right|

                # Skip the condition_right if its the one we are looking for.
                # The Rails.cache.fetch will take care of caching it for us.
                if condition_right != sought_right

                  # Cache the condition_right since we already know they have access.
                  Cache.write(permission_cache_key_for(user, session, condition_right), true)
                end
              end

              true
            end
          end
        end
      end
      CanvasStatsd::Statsd.instance&.increment("adheres_to_policy.#{self.class.name&.underscore}.#{sought_right}.#{how_it_got_it}")

      value
    end

    # Internal: Gets the cache key for the user and right.
    #
    # user - The user to derive the cache key from.
    # session - The session to pull session specific key information from.
    # right - The right to derive the cache key from.
    #
    # Examples
    #
    #   permission_cache_key_for(user, :read)
    #   # => '42/read'
    #
    #   permission_cache_key_for(user, { :permissions_key => 'student' }, :read)
    #   # => '42/read'
    #
    # Returns a string to use as a permissions cache key in the context of the
    # provided user and/or right.
    def permission_cache_key_for(user, session, right)
      return nil if respond_to?(:new_record?) && new_record?
      # If you're going to add something to the user session that
      # affects permissions, you'd durn well better a :permissions_key
      # on the session as well
      permissions_key = session ? (session[:permissions_key] || 'default') : nil # no session != no permissions_key
      ['permissions', self, user, permissions_key, right].compact.
        map{ |element| ActiveSupport::Cache.expand_cache_key(element) }.
        to_param
    end
  end
end
