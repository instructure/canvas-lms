# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
module BroadcastPolicy
  # This is where the DSL is defined.
  module SingletonMethods
    def self.extended(klass)
      klass.send(:class_attribute, :broadcast_policy_list) unless klass.respond_to?(:broadcast_policy_list)
    end

    # This stores the policy for broadcasting changes on a class.  It works like a
    # macro.  The policy block will be stored in @broadcast_policy.
    def set_broadcast_policy(&)
      self.broadcast_policy_list ||= PolicyList.new
      self.broadcast_policy_list.populate(&)
    end

    def set_broadcast_policy!(&)
      self.broadcast_policy_list = PolicyList.new
      self.broadcast_policy_list.populate(&)
    end
  end
end
