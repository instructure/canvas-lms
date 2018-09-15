/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import I18n from 'i18n!react_files'
import PropTypes from 'prop-types'
import $ from 'jquery'
import '../../jquery.rails_flash_notifications'

export default {
  displayName: 'UploadProgress',

  propTypes: {
    uploader: PropTypes.shape({
      getFileName: PropTypes.func.isRequired,
      roundProgress: PropTypes.func.isRequired,
      cancel: PropTypes.func.isRequired,
      file: PropTypes.instanceOf(File).isRequired
    })
  },

  getInitialState() {
    return {
      progress: 0,
      messages: {}
    }
  },

  componentWillMount() {
    return this.sendProgressUpdate(this.state.progress)
  },

  componentWillReceiveProps(nextProps) {
    const newProgress = nextProps.uploader.roundProgress()

    if (this.state.progress !== newProgress) {
      return this.sendProgressUpdate(newProgress)
    }
  },

  componentWillUnmount() {
    return this.sendProgressUpdate(this.state.progress)
  },

  sendProgressUpdate(progress) {
    // Track which status updates have been sent to prevent duplicate messages
    const {messages} = this.state

    if (!(progress in messages)) {
      const fileName = this.props.uploader.getFileName()

      const message =
        progress < 100
          ? I18n.t('%{fileName} - %{progress} percent uploaded', {fileName, progress})
          : I18n.t('%{fileName} uploaded successfully!', {fileName})

      $.screenReaderFlashMessage(message)
      messages[progress] = true

      this.setState({messages, progress})
    }
  }
}
