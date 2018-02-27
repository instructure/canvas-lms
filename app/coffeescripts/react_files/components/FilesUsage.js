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
  '../modules/customPropTypes'
], (customPropTypes) ->


  FilesUsage =
    displayName: 'FilesUsage'
    url: ->
      "/api/v1/#{@props.contextType}/#{@props.contextId}/files/quota"

    propTypes:
      contextType: customPropTypes.contextType.isRequired
      contextId: customPropTypes.contextId.isRequired

    update: ->
      $.get @url(), (data) =>
        @setState(data)

    componentDidMount: ->
      @update()
      @interval = setInterval @update, 1000*60*5 #refresh every 5 minutes

    componentWillUnmount: ->
      clearInterval @interval

