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

require 'spec_helper'

describe LtiOutbound::LTIAssignment do
  it_behaves_like 'it has a proc attribute setter and getter for', :id
  it_behaves_like 'it has a proc attribute setter and getter for', :source_id
  it_behaves_like 'it has a proc attribute setter and getter for', :title
  it_behaves_like 'it has a proc attribute setter and getter for', :points_possible
  it_behaves_like 'it has a proc attribute setter and getter for', :return_types
  it_behaves_like 'it has a proc attribute setter and getter for', :allowed_extensions
end