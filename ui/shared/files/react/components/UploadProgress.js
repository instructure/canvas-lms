/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import React from 'react'
import {func, instanceOf, shape} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import classnames from 'classnames'
import ProgressBar from '@canvas/progress/react/components/ProgressBar'
import mimeClass from '@canvas/mime/mimeClass'
import UploadQueue from '../modules/UploadQueue'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {isIWork, getIWorkType} from '@instructure/canvas-rce/es/rce/plugins/shared/fileTypeUtils'

const I18n = useI18nScope('files_upload_progress')

class UploadProgress extends React.Component {
  static propTypes = {
    uploader: shape({
      getFileName: func.isRequired,
      roundProgress: func.isRequired,
      abort: func.isRequired,
      file: instanceOf(File).isRequired,
      canAbort: func.isRequired,
    }),
  }

  constructor(props) {
    super(props)

    this.state = {
      progress: 0,
      messages: {},
    }

    this.resetProgress = this.resetProgress.bind(this)
  }

  componentDidMount() {
    const newProgress = this.props.uploader.roundProgress()

    if (this.state.progress !== newProgress) {
      return this.sendProgressUpdate(newProgress)
    }
  }

  UNSAFE_componentWillReceiveProps(nextProps) {
    const newProgress = nextProps.uploader.roundProgress()

    if (this.state.progress !== newProgress) {
      return this.sendProgressUpdate(newProgress)
    }
  }

  componentWillUnmount() {
    return this.sendProgressUpdate(this.state.progress)
  }

  sendProgressUpdate(progress) {
    // Track which status updates have been sent to prevent duplicate messages
    const {messages} = this.state

    if (!(progress in messages)) {
      const fileName = this.props.uploader.getFileName()

      const message =
        progress < 100
          ? I18n.t('%{fileName} - %{progress} percent uploaded', {fileName, progress})
          : I18n.t('%{fileName} uploaded successfully!', {fileName})

      showFlashAlert({message, err: null, type: 'info', srOnly: true})
      messages[progress] = true

      this.setState({messages, progress})
    }
  }

  resetProgress() {
    this.setState({messages: {}, progress: 0})
  }

  getFileType() {
    let type = this.props.uploader.getFileType()
    const name = this.props.uploader.getFileName()
    // Native JS File API returns empty string if it can't determine the type
    if (type === '' && isIWork(name)) {
      type = getIWorkType(name)
    }
    return type
  }

  renderProgressBar() {
    if (this.props.uploader.error) {
      const errorMessage = this.props.uploader.error.message
        ? I18n.t('Error: %{message}', {message: this.props.uploader.error.message})
        : I18n.t('Error uploading file.')

      showFlashAlert({message: errorMessage, type: 'error', srOnly: true})

      return (
        <span>
          {errorMessage}
          <button
            type="button"
            className="btn-link"
            onClick={() => {
              this.resetProgress()
              UploadQueue.attemptThisUpload(this.props.uploader)
            }}
          >
            {I18n.t('Retry')}
          </button>
        </span>
      )
    } else {
      return <ProgressBar progress={this.props.uploader.roundProgress()} />
    }
  }

  render() {
    const rowClassNames = classnames({
      'ef-item-row': true,
      'text-error': this.props.uploader.error,
    })

    return (
      <div className={rowClassNames}>
        <div className="col-xs-6">
          <div className="media ellipsis">
            <span className="pull-left">
              <i className={`media-object mimeClass-${mimeClass(this.getFileType())}`} />
            </span>
            <span className="media-body">{this.props.uploader.getFileName()}</span>
          </div>
        </div>
        <div className="col-xs-5">{this.renderProgressBar()}</div>
        {this.props.uploader.canAbort() && (
          <button
            type="button"
            onClick={this.props.uploader.cancel}
            aria-label={I18n.t('Cancel')}
            className="btn-link upload-progress-view__button"
          >
            x
          </button>
        )}
      </div>
    )
  }
}

export default UploadProgress
