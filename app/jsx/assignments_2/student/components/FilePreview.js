/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {AttachmentShape} from '../assignmentData'
import I18n from 'i18n!assignments_2'
import PropTypes from 'prop-types'
import React, {Component} from 'react'

import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'

export default class FilePreview extends Component {
  static propTypes = {
    files: PropTypes.arrayOf(AttachmentShape)
  }

  renderFilePreview = file => {
    const iframeContainerStyle = {
      maxWidth: '1366px',
      height: '0',
      margin: '-0.75rem',
      paddingBottom: '130%',
      position: 'relative'
    }

    const iframeStyle = {
      border: 'none',
      width: '100%',
      height: '100%',
      position: 'absolute'
    }

    return (
      <div style={iframeContainerStyle} data-testid="assignments_2_submission_preview">
        <ScreenReaderContent>{file.displayName}</ScreenReaderContent>
        <iframe src={file.submissionPreviewUrl} title="preview" style={iframeStyle} />
      </div>
    )
  }

  render() {
    // TODO: update this to allow previewing all attachments
    const file = this.props.files.find(f => {
      return f.submissionPreviewUrl !== null
    })

    // TODO: replace this with appropriate SVG when available
    if (!file) {
      return <p>{I18n.t('No preview available for file')}</p>
    }

    return this.renderFilePreview(file)
  }
}
