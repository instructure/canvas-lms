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
#

define [
  'jquery'
  'underscore'
  'Backbone'
  '../str/TextHelper'
  'jquery.instructure_misc_helpers' # $.parseUserAgentString
], ($, _, Backbone, {truncateText}) ->

  class PageView extends Backbone.Model

    computedAttributes: ['summarizedUserAgent', 'readableInteractionTime', 'truncatedURL', 'isLinkable']

    isLinkable: ->
      method = @get 'http_method'
      return true unless method?
      method is 'get'

    summarizedUserAgent: ->
      @get('app_name') || $.parseUserAgentString(@get 'user_agent')

    readableInteractionTime: ->
      seconds = @get 'interaction_seconds'
      if seconds > 5
        Math.round(seconds)
      else
        '--'

    truncatedURL: ->
      truncateText @get('url'), max: 90
