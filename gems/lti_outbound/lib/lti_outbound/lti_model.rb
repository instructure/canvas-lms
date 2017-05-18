#
# Copyright (C) 2014 - present Instructure, Inc.
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

module LtiOutbound
  class LTIModel
    protected

    def self.proc_accessor(*methods)
      attr_writer(*methods)
      proc_writer(*methods)
    end

    def self.proc_writer(*methods)
      methods.each do |method|
        define_method(method) do
          variable_name = "@#{method}"
          value = self.instance_variable_get(variable_name)
          if value.is_a?(Proc)
            value = value.call
            self.instance_variable_set(variable_name, value)
          end
          return value
        end
      end
    end
  end
end