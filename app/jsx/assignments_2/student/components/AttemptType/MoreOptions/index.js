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

import ExternalToolsQuery from './ExternalToolsQuery'
import {func, string} from 'prop-types'
import I18n from 'i18n!assignments_2_initial_query'
import React from 'react'

import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-elements'
import {Modal} from '@instructure/ui-overlays'

class MoreOptions extends React.Component {
  state = {
    open: false,
    selectedCanvasFileID: null
  }

  _isMounted = false

  componentDidMount() {
    this._isMounted = true
    window.addEventListener('message', this.handleIframeTask)
  }

  componentWillUnmount() {
    this._isMounted = false
    window.removeEventListener('message', this.handleIframeTask)
  }

  handleCanvasFileSelect = fileID => {
    if (this._isMounted) {
      this.setState({selectedCanvasFileID: fileID})
    }
  }

  handleIframeTask = e => {
    if (
      this._isMounted &&
      (e.data.messageType === 'LtiDeepLinkingResponse' ||
        e.data.messageType === 'A2ExternalContentReady')
    ) {
      this.handleModalClose()
    }
  }

  handleModalOpen = () => {
    if (this._isMounted) {
      this.setState({open: true})
    }
  }

  handleModalClose = () => {
    if (this._isMounted) {
      this.setState({open: false, selectedCanvasFileID: null})
    }
  }

  renderCloseButton = () => (
    <CloseButton placement="end" offset="medium" variant="icon" onClick={this.handleModalClose}>
      {I18n.t('Close')}
    </CloseButton>
  )

  render() {
    return (
      <>
        <div style={{display: 'block'}}>
          <Button
            data-testid="more-options-button"
            onClick={this.handleModalOpen}
            margin="medium 0"
          >
            {I18n.t('More Options')}
          </Button>
        </div>
        {this.state.open && (
          <Modal
            as="form"
            data-testid="more-options-modal"
            open={this.state.open}
            onDismiss={this.handleModalClose}
            size="large"
            label="More Options"
            shouldCloseOnDocumentClick
          >
            <Modal.Header>
              {this.renderCloseButton()}
              <Heading>{I18n.t('More Options')}</Heading>
            </Modal.Header>
            <Modal.Body padding="0 small">
              <ExternalToolsQuery
                assignmentID={this.props.assignmentID}
                courseID={this.props.courseID}
                handleCanvasFileSelect={this.handleCanvasFileSelect}
                userID={this.props.userID}
              />
            </Modal.Body>
            <Modal.Footer>
              <Button onClick={this.handleModalClose} margin="0 xx-small 0 0">
                {I18n.t('Cancel')}
              </Button>
              {this.state.selectedCanvasFileID && (
                <Button
                  variant="primary"
                  type="submit"
                  onClick={() => {
                    this.props.handleCanvasFiles(this.state.selectedCanvasFileID)
                    this.handleModalClose()
                  }}
                >
                  {I18n.t('Upload')}
                </Button>
              )}
            </Modal.Footer>
          </Modal>
        )}
      </>
    )
  }
}
MoreOptions.propTypes = {
  assignmentID: string.isRequired,
  courseID: string.isRequired,
  handleCanvasFiles: func.isRequired,
  userID: string.isRequired
}

export default MoreOptions
