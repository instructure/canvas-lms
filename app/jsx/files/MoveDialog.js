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

import I18n from 'i18n!react_files'
import React from 'react'
import MoveDialog from 'compiled/react_files/components/MoveDialog'
import Modal from '../shared/modal'
import ModalContent from '../shared/modal-content'
import ModalButtons from '../shared/modal-buttons'
import BBTreeBrowser from '../files/BBTreeBrowser'
import classnames from 'classnames'

  MoveDialog.renderMoveButton = function () {
    const buttonClassNames = classnames({
      'disabled': !this.state.destinationFolder,
      'btn': true,
      'btn-primary': true
    });
    if (this.state.isCopyingFile) {
      return (
        <button
          type='submit'
          aria-disabled={!this.state.destinationFolder}
          className={buttonClassNames}
          data-text-while-loading={I18n.t('Copying...')}
        >
          {I18n.t('Copy to Folder')}
        </button>
      );
    } else {
      return (
        <button
          type='submit'
          aria-disabled={!this.state.destinationFolder}
          className={buttonClassNames}
          data-text-while-loading={I18n.t('Moving...')}
        >
          {I18n.t('Move')}
        </button>
      );
    }
  };

  MoveDialog.render = function () {
    return (
      <Modal
        className='ReactModal__Content--canvas ReactModal__Content--mini-modal'
        overlayClassName='ReactModal__Overlay--canvas'
        ref='canvasModal'
        isOpen={this.state.isOpen}
        title={this.getTitle()}
        onRequestClose={this.closeDialog}
        onSubmit={this.submit}
      >
        <ModalContent>
          <BBTreeBrowser
            rootFoldersToShow={this.props.rootFoldersToShow}
            onSelectFolder={this.onSelectFolder}
          />
        </ModalContent>
        <ModalButtons>
          <button
            type='button'
            className='btn'
            onClick={this.closeDialog}
          >
            {I18n.t('Cancel')}
          </button>
          {this.renderMoveButton()}
        </ModalButtons>
      </Modal>
    );
  };

export default React.createClass(MoveDialog)
