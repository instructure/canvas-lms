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
  'react'
  '../mixins/BackboneMixin'
  '../../models/Folder'
  '../modules/customPropTypes'
  '../../util/mimeClass'
], (React, BackboneMixin, Folder, customPropTypes, mimeClass) ->

  FilesystemObjectThumbnail =
    displayName: 'FilesystemObjectThumbnail'

    propTypes:
      model: customPropTypes.filesystemObject

    mixins: [BackboneMixin('model')],

    getInitialState: ->
      thumbnail_url: @props.model?.get('thumbnail_url')

    componentDidMount: ->
      # Set an interval to check for thumbnails
      # if they don't currently exist (e.g. when
      # a thumbnail is being generated but not
      # immediately available after file upload)
      intervalMultiplier = 2.0
      delay = 10000
      attempts = 0
      maxAttempts = 4

      checkThumbnailTimeout = =>
        delay *= intervalMultiplier
        attempts++

        setTimeout =>
          @checkForThumbnail(checkThumbnailTimeout)
          return clearTimeout(checkThumbnailTimeout) if attempts >= maxAttempts
          checkThumbnailTimeout()
        , delay

      checkThumbnailTimeout()

    checkForThumbnail: (timeout) ->
      return if @state.thumbnail_url or
                @props.model?.attributes?.locked_for_user or
                @props.model instanceof Folder or
                @props.model?.get('content-type')?.match("audio")

      @props.model?.fetch
        success: (model, response, options) =>
          setTimeout =>
            @setState(thumbnail_url: response.thumbnail_url) if response?.thumbnail_url
          , 0
        error: () ->
          clearTimeout(timeout)