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
import {func} from 'prop-types'
import classnames from 'classnames'
import UploadProgress from './UploadProgress'
import UploadQueue from '../modules/UploadQueue'

class CurrentUploads extends React.Component {
  state = {currentUploads: []}

  static propTypes = {
    onUploadChange: func,
  }

  static defaultProps = {
    onUploadChange: () => {},
  }

  handleUploadQueueChange = upload_queue => {
    this.setState({currentUploads: upload_queue.getAllUploaders()}, () => {
      this.props.onUploadChange(this.state.currentUploads.length)
    })
  }

  componentDidMount() {
    UploadQueue.addChangeListener(this.handleUploadQueueChange)
  }

  componentWillUnmount() {
    UploadQueue.removeChangeListener(this.handleUploadQueueChange)
  }

  renderUploadProgress = function () {
    if (this.state.currentUploads.length) {
      const progessComponents = this.state.currentUploads.map(uploader => {
        return <UploadProgress uploader={uploader} key={uploader.getFileName()} />
      })
      return <div className="current_uploads__uploaders">{progessComponents}</div>
    } else {
      return null
    }
  }

  render() {
    const classes = classnames({
      current_uploads: this.state.currentUploads.length,
    })

    return <div className={classes}>{this.renderUploadProgress()}</div>
  }
}

export default CurrentUploads
