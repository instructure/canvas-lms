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

define [
  '../models/DiscussionTopic'
  'underscore'
], (DiscussionTopic, _) ->

  class Announcement extends DiscussionTopic

    # this is wonky, and admittitedly not the right way to do this, but it is a workaround
    # to append the query string '?only_announcements=true' to the index action (which tells
    # discussionTopicsController#index to show announcements instead of discussion topics)
    # but remove it for create/show/update/delete
    urlRoot: -> _.result(@collection, 'url').replace(@collection._stringToAppendToURL, '')

    defaults:
      is_announcement: true

