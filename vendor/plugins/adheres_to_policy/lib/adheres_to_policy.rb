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
        check_rights = sought_rights
        # If you're going to add something to the user session that
        # affects permissions, you'd durn well better set :session_affects_permissions
        # to true as well
        session = nil if session && !session[:session_affects_permissions]
        # If this checking a course policy (which is the most expensive lookup)
        # then just grab all the permissions at once instead of just the one
        # being asked for.
        if user && (self.is_a_context?) && !session
          check_rights = []
        end
        # Generate cache key for memcached lookup
        cache_lookup = ['course_permissions', self.cache_key, (user.cache_key rescue 'nobody'), check_rights.join('/')].join('/')
        # Don't memcache the value unless it's checking all values for a course
        cache_lookup = nil unless self.is_a?(Course) && check_rights.empty?
        # Sometimes the session object holds information that can affect
        # permission policies.  If this is true, we shouldn't cache the
        # result, either.
        cache_lookup = nil if session && session[:session_affects_permissions]
        user_id = user ? user.id : nil
        cache_param = [user_id, sought_rights].flatten

        # According to my understanding, calling Rails.cache.fetch with an
        # empty string will always return the contents of the block, and
        # will not cache the value at all
        granted_rights = []
        if cache_lookup && RAILS_ENV != "test"
          granted_rights = Rails.cache.fetch(cache_lookup) do
            check_policy(user, session, *check_rights)
          end
        else
          granted_rights = check_policy(user, session, *check_rights)
        end

        sought_rights = granted_rights if sought_rights.empty?
        res = sought_rights.inject({}) { |h, r| h[r] = granted_rights.include?(r); h }
        res
      end

      def grants_right?(user, *sought_rights)
        session = nil
        if !sought_rights[0].is_a? Symbol
          session = sought_rights.shift
        end
        sought_right = sought_rights[0].to_sym rescue nil
        return false unless sought_right

        # if this is a course, call grants_rights which has specific logic to
        # cache course rights lookups. otherwise we lose the benefits of that cache.
        if self.is_a?(Course) && !(session && session[:session_affects_permissions])
          return !!(self.grants_rights?(user, *[session].compact)[sought_right])
        end

        granted_rights = check_policy(user, session, *sought_rights)
        granted_rights.include?(sought_right)
      end

      # Used for a more-natural: user.has_rights?(@account, :destroy)
      def has_rights?(obj, *sought_rights)
        obj.grants_rights?(self, *sought_rights)
      end

    end # InstanceMethods
  end # AdheresToPolicy
end # Instructure
