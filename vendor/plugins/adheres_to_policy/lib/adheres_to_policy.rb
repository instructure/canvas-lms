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

module Instructure #:nodoc:
  module AdheresToPolicy #:nodoc:
    # This should work like this:
    # 
    # class Account < ActiveRecord::Base
    #   set_policy do
    #     given { |u| self.user == u }
    #     can :read and can :write
    #   end
    # end
    # 
    # u = User.find(:first)
    # a = Account.find(:first)
    # a.check_policy(u)
    module ClassMethods
      # This stores the policy or permissions for a class.  It works like a
      # macro.  The policy block will be stored in @policy_block.  Then, an
      # instance will use that to instantiate a Policy object.
      def set_policy(&block)
        include InstanceMethods if @_policy_blocks.nil? || @_policy_blocks.empty?
        @_policy = nil
        @_policy_blocks ||= []
        @_policy_blocks << block
      end
      alias :set_permissions :set_policy

      def policy
        return superclass.policy if @_policy_blocks.nil? || @_policy_blocks.empty?
        return @_policy if @_policy
        @_policy = Policy.new(*@_policy_blocks)
      end
    end

    # This is where the DSL is defined.
    class Policy
      attr_reader :conditions

      def initialize(*blocks, &block)
        @conditions = []
        blocks.each{ |b| instance_eval(&b) }
        instance_eval(&block) if block
      end

      # Stores a condition that will match with every permission that is set
      # until another condition is recorded.
      def given(&block)
        @conditions << [ block, [] ]
      end

      # Stores the permissions with an associated condition block.  The
      # convention is [condition, [rights] ] in the conditions array.
      # Conditions is an array in order of their definition.  This is
      # important, because evaluation of later rules will be skipped if
      # the permission has already been granted.
      def can(*syms)
        @conditions << [ lambda { |u| true }, [] ] if @conditions.empty?

        @conditions.last.last.concat(syms.flatten)
        @conditions.last.last.uniq!
        true
      end
    end

    # These are all available on an ActiveRecord model instance.  So a =
    # Account.find(:first);

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
        ['context_permissions', self, user].cache_key
      end

    end # InstanceMethods
  end # AdheresToPolicy
end # Instructure
