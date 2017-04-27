#
# Copyright (C) 2012 - present Instructure, Inc.
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

if ENV.badge_counts
  require.ensure [], () ->
    $ = require('jquery')
    $ ->
      for type, unread of ENV.badge_counts
        if unread > 0
          type = "grades" if type is "submissions"
          $badge = $("<b/>").text(unread).addClass("nav-badge")
          $("#section-tabs .#{type}").append($badge)
  , 'badgeCountsAsyncChunk'
