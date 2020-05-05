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

class CanvasTwitterConfig

  def self.call
    settings = Canvas::Plugin.find(:twitter).try(:settings)
    if settings
      {
        api_key: settings[:consumer_key],
        secret_key: settings[:consumer_secret_dec]
      }.with_indifferent_access
    else
      ConfigFile.load('twitter').dup
    end

  end
end


Twitter::Connection.config = CanvasTwitterConfig
