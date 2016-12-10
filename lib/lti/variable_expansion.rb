#
# Copyright (C) 2015 Instructure, Inc.
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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

module Lti
  class VariableExpansion

    attr_reader :name, :permission_groups

    def initialize(name, permission_groups, expansion_proc, *guards)
      @name = name
      @permission_groups = permission_groups
      @expansion_proc = expansion_proc
      @guards = guards
      @guards << -> { true } if @guards.empty?
    end

    def expand(expander)
      expand_for?(expander) ? expander.instance_exec(&@expansion_proc) : "$#{name}"
    end

    private
    def expand_for?(expander)
      @guards.map {|guard| expander.instance_exec(&guard) }.
        inject { |memo, obj| memo && obj }
    end
  end
end
