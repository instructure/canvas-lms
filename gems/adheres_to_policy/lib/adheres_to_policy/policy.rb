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
    attr_reader :conditions, :available_rights

    def initialize(*blocks, &block)
      @conditions = {}
      @available_rights = Set.new
      blocks.each { |b| instance_eval(&b) }
      instance_eval(&block) if block
    end

    # Stores a condition that will match with every permission that is set
    # until another condition is recorded.
    def given(&block)
      @last_condition = Condition.new(block)
    end

    # Stores the permissions with an associated condition block.  The
    # convention is [condition, [rights] ] in the conditions array.
    # Conditions is an array in order of their definition.  This is
    # important, because evaluation of later rules will be skipped if
    # the permission has already been granted.
    def can(right, *rights)
      raise "must have a `given` block before calling `can`" if @conditions.empty? unless @last_condition
      rights = [right, rights].flatten.compact
      @last_condition.can(*rights)
      @available_rights.merge(rights)
      rights.each do |right|
        @conditions[right] ||= []
        @conditions[right] << @last_condition unless @conditions[right].include?(@last_condition)
      end
      true
    end
  end
end