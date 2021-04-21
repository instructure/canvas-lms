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

import Backbone from 'Backbone'
import I18n from 'i18n!discussions'

UNKNOWN_AUTHOR =
  avatar_image_url: null
  display_name: I18n.t 'unknown_author', 'Unknown Author'
  id: null

##
# Model representing an entry in discussion topic
export default class DiscussionEntry extends Backbone.Model

  author: ->
    @findParticipant @get('user_id')

  editor: ->
    @findParticipant @get('editor_id')

  findParticipant: (user_id) ->
    if user_id && user = @collection?.participants.get user_id
      user.toJSON()
    else if user_id is ENV.current_user?.id
      ENV.current_user
    else
      UNKNOWN_AUTHOR

