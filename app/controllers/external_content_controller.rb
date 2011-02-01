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

class ExternalContentController < ApplicationController
  def success
    @equella_data = {}
    params.each do |key, value|
      if key.to_s.match(/\Aeq_/)
        @equella_data[key.to_s.gsub(/\Aeq_/, "")] = value
      end
    end
    @headers = false
  end
  
  def cancel
    @headers = false
  end
end
