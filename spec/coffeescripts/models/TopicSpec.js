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

define [
  'compiled/models/Topic'
], ( Topic ) ->
  QUnit.module "Topic"

#  test "#parse should set author on view entries", ->
#    topic = new Topic
#    participant = id: 1
#    entry = id: 1, user_id: participant.id
#    data = topic.parse
#      participants: [participant]
#      view: [entry]
#      new_entries: []
#      unread_entries: []
#    strictEqual data.entries[0].author, participant

  test "#parse should set author on new entries", ->
    topic = new Topic
    participant = id: 1
    entry = id: 1, user_id: participant.id
    data = topic.parse
      participants: [participant]
      view: []
      new_entries: [entry]
      unread_entries: []
      forced_entries: []
      entry_ratings: {}
    strictEqual data.entries[0].author, participant
