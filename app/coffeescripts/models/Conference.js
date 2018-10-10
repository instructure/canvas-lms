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

define [
  'underscore'
  'Backbone'
], (_, {Model}) ->

  class Conference extends Model
    urlRoot: ->
      url = @get('url')
      url.replace(/([^\/]*$)/, '')

    special_urls: ->
      join_url: @get('url') + '/join'
      close_url: @get('url') + '/close'

    recordings_data: ->
      recording: @get('recordings')[0]
      recordingCount: @get('recordings').length
      multipleRecordings: @get('recordings').length > 1

    permissions_data: ->
      has_actions: @get('permissions')['update'] || @get('permissions')['delete']
      show_end: @get('permissions')['close'] && @get('started_at') && !@get('ended_at')

    schedule_data: ->
      scheduled: 'scheduled_date' of @get('user_settings')
      scheduled_at: @get('user_settings').scheduled_date

    toJSON: ->
      json = super
      for attr in ['special_urls', 'recordings_data', 'schedule_data', 'permissions_data']
        _.extend(json, @[attr]())
      json.isAdobeConnect = json.conference_type == "AdobeConnect"
      json
