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
  'i18n!discussions'
  'Backbone'
  '../models/Participant'
], (I18n, Backbone, Participant) ->

  class ParticipantCollection extends Backbone.Collection

    model: Participant

    defaults:
      currentUser: {}
      unknown:
        avatar_image_url: null
        display_name: I18n.t 'uknown_author', 'Unknown Author'
        id: null

    findOrUnknownAsJSON: (id) ->
      # might want to refactor this to return a real participant not the JSON
      participant = @get id
      if participant?
        participant.toJSON()
      else if id is ENV.current_user.id
        # current user isn't a participant (yet)
        ENV.current_user
      else
        # ¯\(°_o)/¯
        @options.unknown


