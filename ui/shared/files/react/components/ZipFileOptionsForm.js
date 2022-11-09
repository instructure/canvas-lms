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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import PropTypes from 'prop-types'
import Modal from '@canvas/modal'
import ModalContent from '@canvas/modal/react/content'
import ModalButtons from '@canvas/modal/react/buttons'

const I18n = useI18nScope('zip_file_options_form')

class ZipFileOptionsForm extends React.Component {
  static displayName = 'ZipFileOptionsForm'

  static propTypes = {
    onZipOptionsResolved: PropTypes.func.isRequired,
  }

  handleExpandClick = () => {
    this.props.onZipOptionsResolved({file: this.props.fileOptions.file, expandZip: true})
  }

  handleUploadClick = () => {
    this.props.onZipOptionsResolved({file: this.props.fileOptions.file, expandZip: false})
  }

  buildMessage = _fileOptions => {
    let message
    if (this.props.fileOptions) {
      const name = this.props.fileOptions.file.name
      message = I18n.t(
        'message',
        'Would you like to expand the contents of "%{fileName}" into the current folder, or upload the zip file as is?',
        {fileName: name}
      )
    }
    return message
  }

  render() {
    return (
      <Modal
        className="ReactModal__Content--canvas ReactModal__Content--mini-modal"
        isOpen={!!this.props.fileOptions}
        ref="canvasModal"
        title={I18n.t('zip_options', 'Zip file options')}
        onRequestClose={this.props.onClose}
      >
        <ModalContent>
          <p className="modalMessage">{this.buildMessage()}</p>
        </ModalContent>
        <ModalButtons>
          <button type="button" className="btn" onClick={this.handleExpandClick}>
            {I18n.t('expand', 'Expand It')}
          </button>
          <button type="button" className="btn btn-primary" onClick={this.handleUploadClick}>
            {I18n.t('upload', 'Upload It')}
          </button>
        </ModalButtons>
      </Modal>
    )
  }
}

export default ZipFileOptionsForm
