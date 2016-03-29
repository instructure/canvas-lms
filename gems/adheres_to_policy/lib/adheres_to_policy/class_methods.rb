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
      @_policy = Policy.new(nil, nil, *@_policy_blocks)
    end
  end
end