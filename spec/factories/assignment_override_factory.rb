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

def assignment_override_model(opts={})
  assignment = opts.delete(:assignment) || assignment_model(opts)
  @override = factory_with_protected_attributes(assignment.assignment_overrides, assignment_override_valid_attributes.merge(opts))
  @override
end

def assignment_override_valid_attributes
  { :title => "Some Title" }
end
