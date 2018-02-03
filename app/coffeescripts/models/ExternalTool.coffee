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
  'underscore'
  'Backbone'
  '../backbone-ext/DefaultUrlMixin'
], (_, {Model}, DefaultUrlMixin) ->

  class ExternalTool extends Model
    @mixin DefaultUrlMixin

    initialize: ->
      super
      delete @url if _.has(@, 'url')

    resourceName: 'external_tools'

    computedAttributes: [
      {
        name: 'custom_fields_string'
        deps: ['custom_fields']
      }
    ]

    urlRoot: ->
      "/api/v1/#{@_contextPath()}/create_tool_with_verification"

    custom_fields_string: ->
      ("#{k}=#{v}" for k,v of @get('custom_fields')).join("\n")

    launchUrl: (launchType, options = {})->
      params = for key, value of options
        "#{key}=#{value}"
      url = "/#{@_contextPath()}/external_tools/#{@id}/resource_selection?launch_type=#{launchType}"
      url = "#{url}&#{params.join('&')}" if params.length > 0
      url

    assetString: () ->
      "context_external_tool_#{@id}"
