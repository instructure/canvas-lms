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

import I18n from 'i18n!theme_editor'
import React from 'react'
import PropTypes from 'prop-types'
import Modal from 'react-modal'
import ProgressBar from '../shared/ProgressBar'

  Modal.setAppElement(document.body)

  const modalOverrides = {
    overlay : {
      backgroundColor: 'rgba(0,0,0,0.5)'
    },
    content : {
      position: 'static',
      top: '0',
      left: '0',
      right: 'auto',
      bottom: 'auto',
      borderRadius: '0',
      border: 'none',
      padding: '0'
    }
  };

export default React.createClass({
    displayName: 'ThemeEditorModal',

    propTypes: {
      showProgressModal: PropTypes.bool,
      showSubAccountProgress: PropTypes.bool,
      progress: PropTypes.number,
      activeSubAccountProgresses: PropTypes.array,
    },

    modalOpen(){
      return this.props.showProgressModal ||
        this.props.showSubAccountProgress
    },

    modalContent(){
      if (this.props.showProgressModal) {
        return this.previewGenerationModalContent();
      } else if (this.props.showSubAccountProgress) {
        return this.subAccountModalContent();
      }
    },

    previewGenerationModalContent() {
      return (
        <div className="ReactModal__Layout">
          <header className="ReactModal__Header">
            <div className="ReactModal__Header-Title">
              <h3>{I18n.t('Generating preview...')}</h3>
            </div>
          </header>
          <div className="ReactModal__Body">
            <ProgressBar
              progress={this.props.progress}
              title={I18n.t('%{percent} complete', {
                percent: I18n.toPercentage(this.props.progress, {precision: 0})
              })}
            />
          </div>
        </div>
      )
    },

    subAccountModalContent(){
      return (
        <div className="ReactModal__Layout">
          <header className="ReactModal__Header">
            <div className="ReactModal__Header-Title">
              <h3>{I18n.t('Applying new styles to subaccounts')}</h3>
            </div>
          </header>
          <div className="ReactModal__Body">
            <p>
              {I18n.t('Changes will still apply if you leave this page.')}
            </p>
            <ul className="unstyled_list">
              {this.props.activeSubAccountProgresses.map(this.subAccountProgressBar)}
            </ul>
          </div>
        </div>
      );
    },

    subAccountProgressBar(progress){
      return (
        <li className="Theme-editor-progress-list-item">
          <div className="Theme-editor-progress-list-item__title">
            {I18n.t('%{account_name}', {account_name: this.messageToName(progress.message)} )}
          </div>
          <div className="Theme-editor-progress-list-item__bar">
            <ProgressBar
              progress={progress.completion}
              title={I18n.t('Progress for %{account_name}', {
                account_name: this.messageToName(progress.message)
                })
              }
            />
          </div>
        </li>
      );
    },

    messageToName(message){
      return message.indexOf("Syncing for") > -1 ?
        message.replace("Syncing for ", "") :
        I18n.t("Unknown Account")
    },

    render() {
      return (
        <Modal
          isOpen={this.modalOpen()}
          className={
            (this.props.showProgressModal ? 'ReactModal__Content--canvas ReactModal__Content--mini-modal' : 'ReactModal__Content--canvas')
          }
          style={modalOverrides}
        >
          {this.modalContent()}
        </Modal>
      );
    }
  })
