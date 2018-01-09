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

import I18n from 'i18n!zip_file_options_form'
import React from 'react'
import PropTypes from 'prop-types'
import Modal from '../shared/modal'
import ModalContent from '../shared/modal-content'
import ModalButtons from '../shared/modal-buttons'

  var ZipFileOptionsForm = React.createClass({

    displayName: 'ZipFileOptionsForm',
    propTypes: {
      onZipOptionsResolved: PropTypes.func.isRequired
    },
    handleExpandClick: function () {
      this.props.onZipOptionsResolved({file: this.props.fileOptions.file, expandZip: true});
    },
    handleUploadClick: function () {
      this.props.onZipOptionsResolved({file: this.props.fileOptions.file, expandZip: false})
    },
    buildMessage: function (fileOptions) {
      var message = undefined
      if (this.props.fileOptions) {
        var name = this.props.fileOptions.file.name;
        message = I18n.t('message', 'Would you like to expand the contents of "%{fileName}" into the current folder, or upload the zip file as is?', {fileName: name});
      }
      return message;
    },
    render: function () {
      return (
        <Modal
          className='ReactModal__Content--canvas ReactModal__Content--mini-modal'
          isOpen={!!this.props.fileOptions}
          ref='canvasModal'
          title= { I18n.t('zip_options', 'Zip file options') }
          onRequestClose = {this.props.onClose}
        >
          <ModalContent>
            <p className="modalMessage">
              { this.buildMessage() }
            </p>
          </ModalContent>
          <ModalButtons>
            <button
              className='btn'
              onClick= { this.handleExpandClick }
              >
              { I18n.t('expand', 'Expand It') }
            </button>
            <button
              className='btn btn-primary'
              onClick= { this.handleUploadClick }
            >
              { I18n.t('upload', 'Upload It') }
            </button>
          </ModalButtons>
        </Modal>
      );
    }
  });

export default ZipFileOptionsForm
