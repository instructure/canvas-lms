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

def init
  sections :header, [:topic_doc, :method_details_list, [T('method_details')]]
  @resource = object
end

def method_details_list
  @meths = options[:controllers].map { |c| c.meths(:inherited => false, :included => false) }.flatten
  @meths = run_verifier(@meths)
  erb(:method_details_list)
end

def topic_doc
  @docstring = options[:controllers].map { |c| c.docstring }.join("\n\n")
  htmlify(@docstring.strip, :markdown)
end
