#
# Copyright (C) 2011 Instructure, Inc.
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

module AdheresToPolicy #:nodoc:
  module InstanceMethods
    # Returns all permissions available for a user.  If a specific set of
    # permissions is required, use grants_rights?.
    def check_policy(user, session=nil, *sought_rights)
      sought_rights = (sought_rights || []).compact
      seeking_all_rights = sought_rights.empty?
      granted_rights = []
      self.class.policy.conditions.each do |args|
        condition = args[0]
        condition_rights = args[1]
        if (seeking_all_rights && !(condition_rights - granted_rights).empty?) || !(sought_rights & condition_rights).empty?
          if (condition.arity == 1 && instance_exec(user, &condition) || condition.arity == 2 && instance_exec(user, session, &condition))
            sought_rights = sought_rights - condition_rights
            granted_rights.concat(condition_rights)
            break if sought_rights.empty? && !seeking_all_rights
          end
        end
      end
      granted_rights.uniq
    end

    alias :check_permissions :check_policy

    # Returns a hash of sought-after rights
    def grants_rights?(user, *sought_rights)
      session = nil
      if !sought_rights[0].is_a? Symbol
        session = sought_rights.shift
      end
      sought_rights = (sought_rights || []).compact.uniq

      cache_lookup = is_a_context? && !is_a?(User)
      # If you're going to add something to the user session that
      # affects permissions, you'd durn well better set :session_affects_permissions
      # to true as well
      cache_lookup = false if session && session[:session_affects_permissions]

      # Cache the lookup, iff this is a non-user context and the session
      # doesn't affect the policies. Since context policy lookups are
      # expensive (especially for courses), we grab all the permissions at
      # once
      granted_rights = if cache_lookup
                         # Check and cache all the things!
                         Rails.cache.fetch(permission_cache_key_for(user), :expires_in => 1.hour) do
                           check_policy(user)
                         end
                       else
                         check_policy(user, session, *sought_rights)
                       end

      sought_rights = granted_rights if sought_rights.empty?
      res = sought_rights.inject({}) { |h, r| h[r] = granted_rights.include?(r); h }
      res
    end

    # user [, session], [, sought_right]
    def grants_right?(user, *args)
      sought_right = args.first.is_a?(Symbol) ? args.first : args[1].to_sym rescue nil
      return false unless sought_right

      grants_rights?(user, *args)[sought_right]
    end

    # Used for a more-natural: user.has_rights?(@account, :destroy)
    def has_rights?(obj, *sought_rights)
      obj.grants_rights?(self, *sought_rights)
    end

    def permission_cache_key_for(user)
      adheres_to_policy_cache_key(['context_permissions', self, user])
    end

    private

    def adheres_to_policy_cache_key(some_array)
      cache_key = some_array.instance_variable_get("@cache_key")
      return cache_key if cache_key

      value = some_array.collect { |element| ActiveSupport::Cache.expand_cache_key(element) }.to_param
      some_array.instance_variable_set("@cache_key",  value) unless some_array.frozen?
      value
    end

  end
end
