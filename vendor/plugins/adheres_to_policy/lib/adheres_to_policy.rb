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
  module Adheres #:nodoc:
    # This should work like this:
    # 
    # class Account < ActiveRecord::Base
    #   adheres_to_policy
    # 
    #   set_policy do
    #     given { |u| self.user == u }
    #     set { can :read and can :write }
    #   end
    # end
    # 
    # u = User.find(:first)
    # a = Account.find(:first)
    # a.check_policy(u)
    module Policy

      class DummyPolicy
        def initialize(&block)
          @cans = []
          self.instance_eval(&block)
        end
        def can(right)
          @has_cans = true
          @cans << right
        end
        def affects(rights)
          !((@cans) & rights).empty?
        end
      end

      module ClassMethods #:nodoc:
        def adheres_to_policy
          extend Instructure::Adheres::Policy::SingletonMethods
          include Instructure::Adheres::Policy::InstanceMethods
        end
        
      end
      # This is where the DSL is defined.
      module SingletonMethods

        def self.extended(klass)
          klass.send(:class_inheritable_accessor, :policy_block)
        end
        attr_accessor :dummy_policies

        # This stores the policy or permissions for a class.  It works like a
        # macro.  The policy block will be stored in @policy_block.  Then, an
        # instance will use that to instantiate a Policy object. 
        def set_policy(&block)
          self.policy_block = block
        end
        alias :set_permissions :set_policy

        def dummy_policies
          return @dummy_policies if @dummy_policies
          @dummy_policies = {}
          self.new.policy._conditions.each_with_index do |args, idx|
            condition_block = args[1]
            @dummy_policies[idx] = DummyPolicy.new(&condition_block)
          end
          @dummy_policies
        end
      end

      # These are all available on an ActiveRecord model instance.  So a =
      # Account.find(:first); a.policy will return a Policy object. 
      module InstanceMethods

        # Pulls the blocks from the class and runs these, once.  If policies
        # change, we would re-deploy anyway. The methods no longer sit in
        # another class, on the instance itself. 
        def policy
          return @_policy if @_policy
          self.instance_eval(&self.class.policy_block)
          @_policy = self
        end
        
        # Keeps track of any given condition. 
        attr_accessor :implementing_condition

        # An array of conditions, in order of their definition.  This is
        # important, because the rules cascade: the lower ones overwrite the
        # higher ones. 
        def _conditions
          @_conditions ||= []
        end

        # Stores all the explicit permissions (positives only, a permission is
        # assumed denied unless explicitly set). 
        attr_accessor :_can_bucket

        # Stores a condition that will match with every permission that is set
        # until another condition is recorded. 
        def given(&block)
          self.implementing_condition = block
        end

        # Stores the permissions with an associated condition block.  The
        # convention is [condition, permission] in the conditions array. 
        def set(&block)
          # Applies to all instances, by default.
#          self.implementing_condition ||= lambda{ |u, s| true } if block.arity == 2
          self.implementing_condition ||= lambda{ |u| true } #if block.arity == 1
          _conditions << [ implementing_condition, block ]
          return true
        end

        # Adds an explicit permission for a user.
        def can(sym)
          _can_bucket << sym
          _can_bucket.uniq!
          true
        end

        # Returns all permissions available for a user.  If a specific set of
        # permissions is required, use grants_rights?. 
        def check_policy(user, session=nil, *sought_rights)
          # Always start with a fresh bucket of permissions.  Let the policy prove
          # every time what it should be doing.
          user #||= User.new

          sought_rights = (sought_rights || []).compact
          self.policy._can_bucket = []
          self.policy._conditions.each_with_index do |args, idx|
            condition = args[0]
            block = args[1]
            check = self.class.dummy_policies[idx] #|| DummyPolicy.new(&block)
            if sought_rights.empty? || (!(sought_rights - self.policy._can_bucket).empty? && check.affects(sought_rights))
              self.instance_eval(&block) if condition.arity == 2 && condition[user, session]
              self.instance_eval(&block) if condition.arity == 1 && condition[user]
            end
          end
          self.policy._can_bucket
        end
        alias :check_permissions :check_policy
        
        def blocks
          self.policy._conditions
        end
        
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

        # TODO: I don't think this is used anywhere, check and remove
        def true_user_grants_right?(user, *sought_rights)
          session = nil
          if !sought_rights[0].is_a? Symbol
            session = sought_rights.shift
          end
          sought_right = sought_rights[0].to_sym rescue nil
          grants_right?(user, {:session_affects_permissions => true}, sought_right)
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
    end # Policy
  end # Adheres
end # Instructure
