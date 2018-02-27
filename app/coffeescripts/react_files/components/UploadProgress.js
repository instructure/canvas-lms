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
  'i18n!react_files'
  'react'
  'prop-types'
  'jquery'
  '../../jquery.rails_flash_notifications'
], (I18n, React, PropTypes, $) ->


  UploadProgress =
    displayName: 'UploadProgress'

    propTypes:
      uploader: PropTypes.shape({
        getFileName: PropTypes.func.isRequired
        roundProgress: PropTypes.func.isRequired
        cancel: PropTypes.func.isRequired
        file: PropTypes.instanceOf(File).isRequired
      })

    getInitialState: ->
      progress: 0
      messages: {}

    componentWillMount: ->
      @sendProgressUpdate @state.progress

    componentWillReceiveProps: (nextProps) ->
      newProgress = nextProps.uploader.roundProgress()

      if @state.progress isnt newProgress
        @sendProgressUpdate(newProgress)

    componentWillUnmount: ->
      @sendProgressUpdate @state.progress

    sendProgressUpdate: (progress) ->
      # Track which status updates have been sent to prevent duplicate messages
      messages = @state.messages

      unless progress of messages
        fileName = @props.uploader.getFileName()

        message = if progress < 100
                    I18n.t("%{fileName} - %{progress} percent uploaded", { fileName, progress })
                  else
                    I18n.t("%{fileName} uploaded successfully!", { fileName })

        $.screenReaderFlashMessage message
        messages[progress] = true

        @setState { messages, progress }
