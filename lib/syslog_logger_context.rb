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

class SyslogLogger
  def message_with_context(message)
    context = Thread.current[:context] || {}
    "[#{context[:session_id] || "-"} #{context[:request_id] || "-"}] #{message && message.to_s.strip}"
  end
  
  def add_with_adding_context(severity, message = nil, progname = nil, &block)
    self.add_without_adding_context(severity, message_with_context(message || block.call), progname)
  end
  alias_method_chain :add, :adding_context
  
  def self.make_context_adding_method(meth)
    eval <<-EOM, nil, __FILE__, __LINE__ + 1
      def #{meth}_with_adding_context(message = nil)
        #{meth}_without_adding_context(message_with_context(message || yield))
      end
      alias_method_chain :#{meth}, :adding_context
    EOM
  end
  
  LOGGER_MAP.each_key do |level|
    make_context_adding_method level
  end
end
