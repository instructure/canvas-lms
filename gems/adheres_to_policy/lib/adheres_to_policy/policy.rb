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

module AdheresToPolicy
  class Policy
    attr_reader :conditions, :available_rights, :parent_policy, :parent_condition

    def initialize(parent_policy, parent_condition, *blocks, &block)
      @parent_policy = parent_policy
      @parent_condition = parent_condition

      @conditions = {}
      @available_rights = Set.new
      blocks.each { |b| instance_eval(&b) }
      instance_eval(&block) if block
    end

    # Stores a condition that will match with every permission that is set
    # until another condition is recorded.
    def given(&block)
      @last_condition = Condition.new(block, @parent_condition)
    end

    # Stores the permissions, guarded by the condition given to the most
    # recent call of #given.
    def can(right, *rights)
      raise "must have a `given` block before calling `can`" if @conditions.empty? unless @last_condition
      rights = [right, rights].flatten.compact
      @last_condition.can(*rights)
      add_rights(rights, @last_condition)
      true
    end

    # Notes that the specified rights are granted by the specified condition.
    # This adds the rights to @available_rights, adds the condition to each of
    # the rights' lists of conditions in @conditions, and then invokes
    # add_rights on our parent condition if we have one.
    def add_rights(rights, condition)
      @available_rights.merge(rights)

      rights.each do |right|
        @conditions[right] ||= []
        @conditions[right] << condition unless @conditions[right].include?(condition)
      end

      @parent_policy.add_rights(rights, condition) if @parent_policy
    end

    # Stores a nested set of conditions and permissions. This can be used like:
    #
    #   given { foo }
    #   use_additional_policy {
    #     given { bar }
    #     can :baz
    #     given { stuff }
    #     can :things
    #   }
    #
    # which is equivalent to:
    #
    #   given { foo && bar }
    #   can :baz
    #   given { foo && stuff }
    #   can :things
    def use_additional_policy(&block)
      raise "must have a `given` block before calling `use_additional_policy`" unless @last_condition

      Policy.new(self, @last_condition, block)
    end
  end
end