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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

module Lti
  class VariableExpansion

    attr_reader :name, :permission_groups, :default_name

    def initialize(name, permission_groups, expansion_proc, *guards, default_name: nil)
      @name = name
      @permission_groups = permission_groups
      @expansion_proc = expansion_proc
      @guards = guards
      @guards << -> { true } if @guards.empty?
      @default_name = default_name
    end

    # Four scenarios are possible with the variable expansion. They are listed below:
    #
    # 1) an unsupported variable substitution request is made ->
    #    we send back the variable name
    #    (i.e. nonexistent=$CourseSection.nonexistent -> custom_nonexistent=$CourseSection.nonexistent)
    # 2) a request is made with an unauthorized user for a valid variable ->
    #    we send back nothing with the key
    #    (i.e. message_token=$com.instructure.PostMessageToken => custom_message_token= )
    # 3) a request is made with an authorized user for a valid variable but with no corresponding data ->
    #    we send back an empty string with the key
    #    (i.e. message_token=$com.instructure.PostMessageToken => custom_message_token='')
    # 4) a request is made with an authorized user for valid variable and with data ->
    #    we send back the data with the key
    #    (i.e. message_token=$com.instructure.PostMessageToken => custom_message_token=''message_token")
    #
    def expand(expander)
      expand_for?(expander) ? expander.instance_exec(&@expansion_proc) || '' : nil
    end

    private

    def expand_for?(expander)
      @guards.all? {|guard| expander.instance_exec(&guard) }
    end
  end
end
