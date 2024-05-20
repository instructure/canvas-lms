/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {extend} from '@canvas/backbone/utils'
import DiscussionTopic from './DiscussionTopic'

extend(Announcement, DiscussionTopic)

function Announcement() {
  return Announcement.__super__.constructor.apply(this, arguments)
}

// this is wonky, and admittitedly not the right way to do this, but it is a workaround
// to append the query string '?only_announcements=true' to the index action (which tells
// discussionTopicsController#index to show announcements instead of discussion topics)
// but remove it for create/show/update/delete
Announcement.prototype.urlRoot = function () {
  return (this.collection.url || '').replace(this.collection._stringToAppendToURL, '')
}

Announcement.prototype.defaults = {
  is_announcement: true,
}

export default Announcement
