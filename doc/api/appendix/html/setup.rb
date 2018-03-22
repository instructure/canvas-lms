#
# Copyright (C) 2013 - present Instructure, Inc.
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

include T('default/appendix/html')

def init
  super
end

def appendix
  controllers = options[:controllers]
  
  if options[:all_resources]
    controllers = options[:resources].flatten.select { |o|
      o.is_a?(YARD::CodeObjects::NamespaceObject)
    }
  end

  return unless controllers && controllers.is_a?(Array)

  @appendixes = controllers.collect { |c|
    c.children.select { |o| :appendix == o.type }
  }.flatten

  super
end